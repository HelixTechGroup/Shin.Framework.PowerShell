#
# Deloitte.GTS.CTO.Windows.IIS.psm1
#

function Get-IISAllWebsites() {
	$sm = Get-IISServerManager
	return $sm.Sites;
}

function Get-IISWebsite([string]$siteName) {
	$sm = Get-IISServerManager

	try {
		return $sm.Sites | Where-Object { $_.Name -eq $siteName }
	} catch {
		throw (New-Object Exception "Could not get $siteName configuration" $_.Exception)
	}
}

function Get-IISWebsiteApplicationPool([string]$siteName) {
	$sm = Get-IISServerManager
	$site = Get-IISWebsite $siteName

	try {
		$poolName = ($site.Applications | where { $_.Path -eq "/" }).ApplicationPoolName
		return $sm.ApplicationPools | Where-Object { $_.Name -eq $poolName }
	} catch {
		throw (New-Object Exception "Could not get $siteName Application pool configuration" $_.Exception)
	}
}

function Get-IISWebsiteAnonymousUser([string]$siteName) {
	$sm = Get-IISServerManager
	$conf = $sm.GetApplicationHostConfiguration()

	try {
		return $conf.GetSection("system.webServer/security/authentication/anonymousAuthentication", $siteName)["userName"]
	} catch {
		throw (New-Object Exception "Could not get $siteName Anonymous user configuration" $_.Exception)
	}
}

function Get-IISWebsiteApplicationPoolUser([string]$siteName) {
	#$sm = Get-IISServerManager
	$appPool = Get-IISWebsiteApplicationPool $siteName

	try {
		return $appPool.ProcessModel["userName"]
	} catch {
		throw (New-Object Exception "Could not get $siteName Application pool user configuration" $_.Exception)
	}
}

function Get-IISServerManager() {
	try {
		$sm = New-Object Microsoft.Web.Administration.ServerManager
	}
	catch {
		[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration");
		$sm = New-Object Microsoft.Web.Administration.ServerManager
	}

	return $sm
}

Export-ModuleMember -Function *-*