#
# security.ps1
#
#Requires -Version 5.0

using namespace System.Runtime.InteropServices;

class Security {
	static [PSCredential] GetCredentials([string]$userName) {
		if (!([string]::IsNullOrWhiteSpace($userName))) {
			try {
				$password = Read-Host -Prompt "($username) Enter password" -AsSecureString
				return New-Object PSCredential -ArgumentList $userName, $password -ErrorAction Stop;
			}catch {
				return $null;
			}
		}
	
		return $null;
	}

	static [string] GetPlainTextPassword([SecureString]$password) {
		$Ptr = [Marshal]::SecureStringToCoTaskMemUnicode($password)
		$result = [Marshal]::PtrToStringUni($Ptr)
		[Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

		return $result;
	}
}