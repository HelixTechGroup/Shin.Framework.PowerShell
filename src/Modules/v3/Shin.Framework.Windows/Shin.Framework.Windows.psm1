#
# Deloitte.GTS.CTO.Windows.psm1
#

#using namespace System.Management.Automation.Runspaces;

function Get-WmiClass([string]$class, [string]$serverName, [string]$filter, [PSCredential]$credentials) {
	$args = @{};
	$args.Add("Class", $class);
	$args.Add("ErrorAction", "Stop");

	if (!([string]::IsNullOrWhiteSpace($serverName))) {
		$args.Add("ComputerName", $serverName);
	}
	
	if ($credentials -ne $null) {
		$args.Add("Credential", $credentials);
	}
	
	if (!([string]::IsNullOrWhiteSpace($filter))) {
		$args.Add("Filter", $filter);
	}
	
	return Invoke-DynamicCommand "Get-WmiObject"  $args
}	

Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.* |
ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *-*