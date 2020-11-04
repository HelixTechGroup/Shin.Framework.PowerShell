#
# Shin.Framework.Security.psm1
#

#  .ExternalHelp Shin.Framework.Security.psm1-help.xml
function Get-SecurePassword([Parameter(Mandatory=$true)][string]$password, [string]$key = $null) {
	if ([string]::IsNullOrWhiteSpace($key)) {
		return ConvertTo-SecureString $password
	}
}

function Get-ConsoleCredentials([Parameter(Mandatory=$true)][string]$userName, [SecureString]$securePassword = $null, [string]$plaintextPassword = $null) {
	if (([string]::IsNullOrWhiteSpace($userName))) {
		throw (New-Object ArgumentException "Username is empty or null.");
	}

	if ($userName.Contains('/')) {
		$userName = $userName.Replace('/','\');
	}

	try {
		$password = $securePassword
		if ([string]::IsNullOrWhiteSpace($password)) {
			$password = Read-Host -Prompt "($username) Enter password" -AsSecureString
		} elseif (![string]::IsNullOrWhiteSpace($plaintextPassword)){
			$password = Get-SecurePassword $plaintextPassword
		}

		return New-Object PSCredential -ArgumentList $userName, $password -ErrorAction Stop;
	}catch {
		return $null;
	}
	
	return $null;
}

function Get-PlainTextPassword([SecureString]$password) {
	$Ptr = [System.Runtime.Interopservices.Marshal]::SecureStringToCoTaskMemUnicode($password)
	$result = [System.Runtime.Interopservices.Marshal]::PtrToStringUni($Ptr)
	[System.Runtime.Interopservices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

	return $result;
}

function Grant-AdminPSSessionClient {
	Set-Service WinRM -StartupType Automatic
	Start-Service WinRM
	Enable-WSManCredSSP -Role client -DelegateComputer * -Force | Out-Null
}

function Get-AdminPSSession([string]$serverName, [PSCredential]$credentials) {
	return New-PSSession $serverName -Auth CredSSP -Credential $credentials
}

function Set-Ps1RunAsAdmin() {
	New-Item -Path "Registry::HKEY_CLASSES_ROOT\Microsoft.PowershellScript.1\Shell\runas\command" -Force -Name '' -Value '"c:\windows\system32\windowspowershell\v1.0\powershell.exe" -noexit "%1"' | Out-Null
}

function Get-IsRunningAsAdmin() {
	return ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Export-ModuleMember -Function *-*