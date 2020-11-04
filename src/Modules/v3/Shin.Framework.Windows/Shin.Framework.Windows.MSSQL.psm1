#
# Deloitte.GTS.CTO.Windows.MSSQL.psm1
#

$assemblylist =   
		"Microsoft.SqlServer.Management.Common",  
		"Microsoft.SqlServer.Smo",  
		"Microsoft.SqlServer.Dmf ",  
		"Microsoft.SqlServer.Instapi ",  
		"Microsoft.SqlServer.SqlWmiManagement ",  
		"Microsoft.SqlServer.ConnectionInfo ",  
		"Microsoft.SqlServer.SmoExtended ",  
		"Microsoft.SqlServer.SqlTDiagM ",  
		"Microsoft.SqlServer.SString ",  
		"Microsoft.SqlServer.Management.RegisteredServers ",  
		"Microsoft.SqlServer.Management.Sdk.Sfc ",  
		"Microsoft.SqlServer.SqlEnum ",  
		"Microsoft.SqlServer.RegSvrEnum ",  
		"Microsoft.SqlServer.WmiEnum ",  
		"Microsoft.SqlServer.ServiceBrokerEnum ",  
		"Microsoft.SqlServer.ConnectionInfoExtended ",  
		"Microsoft.SqlServer.Management.Collector ",  
		"Microsoft.SqlServer.Management.CollectorEnum",  
		"Microsoft.SqlServer.Management.Dac",  
		"Microsoft.SqlServer.Management.DacEnum",  
		"Microsoft.SqlServer.Management.Utility"

function Get-MSSQLUsers([string]$serverName, [string]$instance, [switch]$includeSystemUsers) {
	$sm = Get-MSSQLServerManager $serverName $instance
	$users = $sm.Logins
	if (!$includeSystemUsers) {
		$users = $users | Where-Object { $_.IsSystemObject -eq $false }
	}

	return $users
}

function Get-MSSQLServerManager([string]$serverName, [string]$instance) {
	if (!([string]::IsNullOrWhiteSpace($instance))) {
		$serverName += "\$instance"
	}

	try {		
		$sm = New-Object ('Microsoft.SqlServer.Management.Smo.Server')$serverName
	} catch {
		#$psproviders="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\"
		#$sqlpsreg=Get-ChildItem $psproviders|?{$_.name -match 'sqlps'}|%{$_.pspath}
  
		#if (Get-ChildItem $sqlpsreg -ErrorAction SilentlyContinue) {  
		#	throw (New-Object Exception "SQL Server Provider for Windows PowerShell is not installed.")
		#} else {  
		#	$item = Get-ItemProperty $sqlpsreg  
		#	$sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)  
		#}  		  
  
		foreach ($asm in $script:assemblylist) {  
			[void][Reflection.Assembly]::LoadWithPartialName($asm)  
		}  
  
		#Push-Location  
		#cd $sqlpsPath  
		#update-FormatData -prependpath SQLProvider.Format.ps1xml   
		#Pop-Location  

		$sm = New-Object ('Microsoft.SqlServer.Management.Smo.Server')$serverName
	}

	return $sm
}

Export-ModuleMember -Function *-*