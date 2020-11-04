#
# Deloitte.GTS.CTO.Common.psm1
#

function Get-ScriptDirectory() {
	return Split-Path -Parent $MyInvocation.PSCommandPath;
}

function Get-PSVersion() {
	return $PSVersionTable.PSVersion.Major;
}

function Show-Progress([ScriptBlock]$code, [object[]]$argumentList = $null) {			

	$newPowerShell = [PowerShell]::Create().AddScript($code)
	
	if ($argumentList) {
		foreach ($a in $argumentList) {
			$newPowerShell = $newPowerShell.AddArgument($a)
		}
	}

	$handle = $newPowerShell.BeginInvoke()
	while ($handle.IsCompleted -eq $false) {     
		Write-Host '.' -NoNewline
		Start-Sleep -Milliseconds 500   
	}
	Write-Host ''
	if ($newPowerShell.Streams.Error.Count -gt 0) {
		$newPowerShell.Streams.Error
	}
	
	$result = $newPowerShell.EndInvoke($handle) 
	$newPowerShell.Runspace.Close()
	$newPowerShell.Dispose() 

	return $result;
}

function Invoke-DynamicCommand([string]$functionName, [object[]]$functionArgs, [System.Management.Automation.Runspaces.PSSession]$session = $null) {
	if (Test-Path Function:\$functionName) {
		$sb = (get-command $functionName -CommandType Function).ScriptBlock;		
	} else {
		$sb = {param($a) & $functionName @a };
	}
	
	if ($session -ne $null) {
		return Invoke-command -Session $session -scriptblock $sb -ArgumentList $functionArgs -ErrorAction Stop;
	}

	return Invoke-command -scriptblock $sb -ArgumentList $functionArgs -ErrorAction Stop;
}

function Get-ServerDomain([string]$serverName) {
	Write-verbose "`r`nAttempting to guess domain for: $serverName"

	switch -wildcard ($serverName) {
		"*test*"   { $domain = "test" }
		default     { Write-Verbose "`r`nUnable to guess domain for $serverName"; return $null }
	}

	return $domain
}

function Get-FunctionDefinition([string]$functionName) {
	if (Test-Path Function:\$functionName) {
		 return "function $functionName {$((Get-Command $functionName -CommandType Function).Definition)}"
	}

	throw (New-Object Exception "Function $functionName does not exist.")
}

Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.* |
ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *-*
