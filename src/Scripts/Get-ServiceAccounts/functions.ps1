#
# functions.ps1
#

function Set-DomainCredentials($domainName) {
	$tmpDomain = $domainName;
	if ($domainName -eq "test.com") {
			$tmpDomain = "test.com";
	}

	if (!($credList.ContainsKey($tmpDomain))) {
		$c = Get-ConsoleCredentials "$tmpDomain\$domainUsername"
		$credList.Add($tmpDomain,$c);
	}
}

function Write-Output($message) {
	Write-Host $message;
	$message | Out-File $outFile -Append
}

function Get-GlbInfo([string]$appName) {
	$appServers = @();
	$contacts = @();

	#GLB
	try {		
		$contacts = Get-GlbApplicationContacts $appName
		if ($contacts -ne $null) {
			$appId = $contacts."App GUID";
		} else {
			Write-LogWarn "Could not find Application in GLB: $($appName)"
			Write-Output "$($appName) - Does not exist in GLB"

			return;
		}			
	} catch {
		$message = "Could not get AppId(GLBID) for Application: $($appName)";	
		Write-LogException $message $_.Exception

		return;
	}

	try {
		$appServers = Get-GlbApplicationServers $appName
		if ($appServers -ne $null) {
			$servers = $appServers;
		} else {
			Write-LogWarn "Could not find Application Assets in GLB: $($appName)"
			Write-Output "`tCould not find Application Assets in GLB"
		}			
	} catch {
		$message = "Could not get Assets for Application: $($appName)";	
		Write-LogException $message $_.Exception

		return;
	}
	
	return @{'Id'=$appId; 'Servers'=$servers}
}

function Get-PcsAppUsers([string]$appId) {
	$appUsers = @();

	try {
		$appFolders = Search-PcsFolders $appId	
	} catch {
		$message = "Could not get Pcs folder for Application: $($app.Name)";	
		Write-LogException $message $_.Exception

		return;
	}	

	if ($appFolders) {
		foreach ($folder in $appFolders) {
			$secrets = (Get-PcsFolderSecrets $folder.Id -includeSubFolders) | Where-Object { $_.TypeId -in $templates.Id };
			foreach($summary in $secrets) {
				$secret = Get-PcsSecret $summary.Id
				$username = $secret.Username	
				if($username -notlike "*\*") {
					$secretDomain = $secret.Domain
					if([string]::IsNullOrWhiteSpace($secretDomain)) {
						$secretDomain = $secret.Server
					}

					$username = "$secretDomain\$username";
				}

				if (!($appUsers -contains $username)) {					
					$appUsers += $username;					
				}
			}		
		}
	} else {
		Write-LogWarn "Could not find Application in PCS: $($app.Name) - $appId"
		Write-Output "`tCould not find Application in PCS"
	}

	return $appUsers;
}

function Get-ServiceUsers([string]$server, [PSCredential]$credentials) {
	if ((Test-WMIRemoting $server $credentials)) {
		try {
			$services = (Get-WmiClass "Win32_Service" $server "" $credentials) | Where-Object { $_.StartName -NotMatch "[Nn]etwork|[Ll]ocal|[Ss]ystem" }
			Write-LogDebug "Service count using non-local user: $($services.Count)"
		} catch {
			$message = "Could not get Services for Server: $serverFqdn";	
			Write-LogException $message $_.Exception

			return;
		}	
	}

	return $services
}

function Get-IISUsers([string]$server, [PSCredential]$credentials) {
	$rSites = @();
	if ((Test-PSRemoting $server $credentials)) {
		$w3svc = Get-WmiClass "Win32_Service" $server "NAME='W3SVC'" $credentials
		if ($w3svc -ne $null) {				
			$sites = Invoke-RemoteCommand -serverName $server -functionName "Get-IISAllWebsites" -credentials $credentials -adminSession -additionalFunctionNames "Get-IISServerManager"
			foreach ($s in $sites) {					
				$anonUser = Invoke-RemoteCommand -serverName $server -functionName "Get-IISWebsiteAnonymousUser" -arguments $s.Name -credentials $credentials -adminSession -additionalFunctionNames "Get-IISServerManager"
				$appPoolUser = Invoke-RemoteCommand -serverName $server -functionName "Get-IISWebsiteApplicationPoolUser" -arguments $s.Name -credentials $credentials -adminSession -additionalFunctionNames @("Get-IISServerManager", "Get-IISWebsiteApplicationPool", "Get-IISWebsite")

				if ($anonUser -eq "IUSR") { $anonUser = "" }

				if (!([string]::IsNullOrWhiteSpace($anonUser)) -and !([string]::IsNullOrWhiteSpace($appPoolUser))) {
					$rSites += @{'Name' = $s.Name; 'AnonUser' = $anonUser; 'AppPoolUser' = $appPoolUser}
				}
			}
		}
	} else {
		Write-LogWarn "Server is unreachable via PSRemoting: $serverFqdn"
	}

	return $rSites
}
