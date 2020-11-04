#
# Set-LocalGroup.ps1
#
#Requires -Version 3.0

#using module Shin.Framework.Common;

Param(
[Parameter(Mandatory=$True,Position=1)]
[string]$group,
[Parameter(Mandatory=$True,Position=2)]
[string]$serverCsv,
[Parameter(Mandatory=$True,Position=3)]
[string]$userCsv
)

function ImportCsvFile([string]$csvFileName, [String[]]$headers) {
	if (!(Test-Path($csvFilename))) {
		Write-Host "CSV file does not exist: $csvFilename"
		#$this.logger.WriteError("CSV file does not exist: $csvFilename");
		return $null;
	}
	
	try {
		return Import-Csv $csvFileName -Header $headers -ErrorAction Stop | Where-Object { $_.PSObject.Properties.Value -ne $null};
	}catch {
		$message = "Could not parse CSV file: $csvFileName";
		Write-Host $message	
		#$this.logger.WriteError($message);
		#$this.logger.WriteException($_.Exception);
		
		return $null;
	}
}

function Add-ToGroup([string]$username, [string]$domain, [string]$server, [string]$group) {
	try {
		#$common.logger.WriteInfo("Adding $username to $group on $server");
		Write-Host "Adding $username to $group on $server"
		$de = [ADSI]"WinNT://$server/$group,group";
		$de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$username").path);
	} catch {
		$message = "Could not add $username to $group on $server";	
		Write-Host $message
		Write-Host $_.Exception.Message
		foreach ($e in $_.Exception.InnerException) {   
		       Write-Host "`r`n`t$e.Message";
		}
		#$common.logger.WriteError($message);
		#$common.logger.WriteException($_.Exception);

	}
}

function List-GroupMembers([string]$group, [string]$server) {
	$members = @();
	try {
		#$common.logger.WriteInfo("Getting members for $group on $server");
		Write-Host "Getting members for $group on $server"
		$de = [ADSI]"WinNT://$server/$group,group";
		$de.psbase.invoke("members") | foreach{ $members += ([ADSI]$_).InvokeGet("Name") }
	} catch {
		$message = "Could not list $group members on $server";	
		Write-Host $message
		Write-Host $_.Exception.Message
		foreach ($e in $_.Exception.InnerException) {   
		       Write-Host "`r`n`t$e.Message";
		}
		#$common.logger.WriteError($message);
		#$common.logger.WriteException($_.Exception);
	}

	return $members;
}

#[Common]$common = [Common]::new("LocalAdmin", $null);
$domain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name;
$users = ImportCsvFile "$PSScriptRoot/$userCsv" @('Name', 'Domain')
$servers = ImportCsvFile "$PSScriptRoot/$serverCsv" @('Name')
Unsupported node: GlobalStatementSyntax


foreach ($server in $servers) {
	foreach ($user in $users) {
		$domain = $user.Domain
		if ($user.Domain -eq 'local') {
			$domain = $server.Name
		}
		Add-ToGroup $user.Name $domain $server.Name $group
	}
}

foreach ($server in $servers) {
	$members = List-GroupMembers $group $server.Name
	foreach ($user in $users) {
		if ($members -contains $user.Name) {
			Write-Host "$user was successfully added to $group"
			#$common.logger.WriteInfo("$user was successfully added to $group");
		} else {
			Write-Host "$user was not successfully added to $group" -BackgroundColor Red
		}
	}
}
