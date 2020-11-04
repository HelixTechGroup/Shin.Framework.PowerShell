#Requires -Version 3.0

Param(
	[string]$SecretServerUsername,
	[string]$domainUsername = [Environment]::UserName,
	[string]$outputFile = "svc_accts.txt",
	[string]$proxyUrl = $null,
	[switch]$allDomains,
	[switch]$debug,
	[switch]$allUsers = $true,
	[switch]$serviceUsers,
	[switch]$iisUsers,
	[switch]$sqlUsers
)

Import-Module Shin.Framework.Common
Import-Module Shin.Framework.Data
Import-Module Shin.Framework.SecretServer
Import-Module Shin.Framework.Windows

. "$PSScriptRoot\functions.ps1"

$l = New-Logger "ServiceAccounts" "$PSScriptRoot\log\"
#Clear-Log
if ($debug) {
	Set-LoggingLevel Debug
	Set-LoggingWriteToConsole $true
}

$outFile = "$PSScriptRoot\$outputFile";
if ((Test-Path $outFile)) {
	Remove-Item $outFile -Force
}

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name;
$user = [Environment]::UserName;
if ([string]::IsNullOrWhiteSpace($SecretServerUsername)) {
	$SecretServerUsername = "$domain\$user";
}

[PSCredential]$creds = Get-ConsoleCredentials $SecretServerUsername

try {
	New-GlbApiInterface
} catch {
	Write-LogException "Could not initialize GLB Api interface" $_.Exception
	return;
}

try {
	New-SecretServerApiInterface $creds $proxyUrl
} catch {
	Write-LogException "Could not initialize SecretServer Api interface" $_.Exception
	return;
}

$domains = Import-CsvFile "$PSScriptRoot/domains.csv" @('Name')
$templates = Import-CsvFile "$PSScriptRoot/templates.csv" @('Id', 'Name')
$appList = @{Name = ''};
$credList = @{};

if ($allDomains) {
	foreach ($d in $domains) {
		Write-LogDebug "Domain: $domain`tDomain2: $($d.Name)"
		Set-DomainCredentials $d.Name
	}
} else {
	Set-DomainCredentials $domain
}

foreach ($app in $appList) {
	$appId = $null;
	$servers = @();
	$appUsers = @();	

	#$glbInfo = Get-GlbInfo $app.Name
	#if (!$glbInfo) {
	#	continue;
	#}

	#$appId = $glbInfo.Id
	#$servers = $glbInfo.Servers
	#$appUsers = Get-SecretServerAppUsers $appId

	Write-LogDebug "APPLICATION NAME: $($app.Name)"			
	Write-Output "$($app.Name) - $appId";
	
	foreach ($username in $appUsers) {
		Write-Output "`t$username";
	}

	foreach ($server in $servers) {
		$sDomain = $server."Domain FQDN";		
		if ([string]::IsNullOrWhiteSpace($sDomain)) {
			continue;
		}
		
		$hostname = $server.Asset;
		$serverFqdn = "$hostname.$sDomain"
		#if ([string]::IsNullOrWhiteSpace($hostname)) { $hostname = $server.Ip }

		Write-LogDebug "Domain: $domain`tServer Domain: $sDomain"
		if (($domain -contains $sDomain) -or $allDomains) {
			if ($sDomain -eq "atrema.deloitte.com") {
				$sDomain = "atrame.deloitte.com";
			}

			if (!($credList.ContainsKey($sDomain))) {
				Write-LogWarn "Authentication for Domain is not available: $sDomain"
				continue;				
			}			

			if (!(Test-Server $server.Ip $credList[$sDomain] -quiet)) {
				Write-LogWarn "Server is unreachable: $serverFqdn"
				Write-Output "`t$serverFqdn - Unreachable";
				continue;
			} 

			Write-LogInfo "Server is reachable: $serverFqdn"
			$found = $false;
			$services = Get-ServiceUsers $serverFqdn $credList[$sDomain]
			if ($services.Count -gt 0) {
				$found = $true;
				Write-Output "`t$serverFqdn";
									
				foreach ($service in $services) {				
					Write-Output "`t`tService: $($service.Name), User: $($service.StartName)";
				}
			}

			$sites = Get-IISUsers $serverFqdn $credList[$sDomain]
			if ($sites.Count -gt 0) {
				if (!$found) {
					$found = $true;
					Write-Output "`t$serverFqdn";
				}

				foreach ($site in $sites) {
					Write-Output "`t`tWebsite: $($site.Name), Anonymous User: $($site.AnonUser), AppPool User: $($site.AppPoolUser)";
				}
			}
		}
	}

	Clear-RemoteSessionCache
}
