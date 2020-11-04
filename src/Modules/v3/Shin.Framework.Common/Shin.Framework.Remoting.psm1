#
# Deloitte.GTS.CTO.Remoting.psm1
#

function Test-Server([string]$server, [PSCredential]$credentials, [switch]$quiet) {
	$runPing = $runRdp = $runWmi = $true;
	$pingRes = $rdpRes = $wmiRes = $false;
	#$ping = $wmi = $true

	#if ($rdp) { $runWmi = $runPing = $false; }
	#if ($wmi) { $runRdp = $runPing = $false; }
	#if ($ping) { $runRdp = $runWmi = $false; }
	
	if ($runPing) { try { $pingRes = Test-Connection $server -Count 1 -Quiet -ErrorAction Stop; }catch{ $pingRes = $false; } }
	#if ($runRdp) { try { $rdpRes = Test-NetConnection $server -CommonTcpPort RDP -InformationLevel Quiet -ErrorAction Stop; }catch{ $rdpRes = $false } }
	#if ($runWmi) { try { if((Get-WmiObject Win32_ComputerSystem -ComputerName $server -Credential $credentials -ErrorAction Stop) -ne $null){ $wmiRes = $true; }}catch{ $wmiRes = $false; } }
	
	if ($quiet) {
		#-or (!$rdpRes -and $runRdp)
		if ((!$pingRes -and $runPing)) { #-or (!$wmiRes -and $runWmi)) {
			return $false;
		}			
	} else { 
		if (!$runPing) { $pingRes = "N/A"; }
		if (!$runRdp) { $rdpRes = "N/A"; }
		if (!$runWmi) { $wmiRes = "N/A"; }
		
		Write-Host "Hostname: $server";
		Write-Host "Ping    : $pingRes";
		Write-Host "RDP     : $rdpRes";
		Write-Host "WMI     : $wmiRes";
	}
		
	return $true;
}	

function Test-WMIRemoting([string]$serverName, [PSCredential]$credentials = $null) {
	try { 
		if ($credentials) {
			$result = Get-WmiObject Win32_ComputerSystem -ComputerName $serverName -Credential $credentials -ErrorAction Stop
		} else {
			$result = Get-WmiObject Win32_ComputerSystem -ComputerName $serverName -ErrorAction Stop
		}
	}catch{ 
		Write-Verbose $_ 
		Write-warning -message "WMI Remoting is not enabled on $serverName"
        return $false 
	}

	## Error Catching
    if($result -eq $null) { 
        Write-warning -message "Remoting to $serverName returned an unexpected result." 
        return $false 
    } 
    Write-warning -message "WMI Remoting is enabled on $serverName"
    
	return $true
}

function Test-PSRemoting([string]$serverName, [PSCredential]$credentials = $null) {
	try { 
		if ($credentials) {
			$result = Invoke-Command -ComputerName $serverName -Credential $credentials -ErrorAction Stop { 1 } 
		} else {
			$result = Invoke-Command -ComputerName $serverName -ErrorAction Stop { 1 } 
		}
    } 
    catch { 
        Write-Verbose $_ 
		Write-warning -message "PSRemoting is not enabled on $serverName"
        return $false 
    } 
    
    ## Error Catching
    if($result -ne 1) { 
        Write-warning -message "Remoting to $serverName returned an unexpected result." 
        return $false 
    } 
    Write-warning -message "PSRemoting is enabled on $serverName"
    
	return $true
}

function Invoke-RemoteCommand([string]$serverName, [string]$functionName, [object[]]$arguments, [PSCredential]$credentials=$null, [switch]$adminSession, [ScriptBlock]$scriptBlock, [string[]]$additionalFunctionNames) {
	if (!([string]::IsNullOrWhiteSpace($serverName))) {
		$session = GetRemoteSession $serverName $credentials $adminSession
	}

	foreach ($f in $additionalFunctionNames) {
		$funcDef += (Get-FunctionDefinition $f) + ";"
	}

	if (!([string]::IsNullOrWhiteSpace($functionName))) {
		try {
			return Invoke-DynamicCommand $functionName $arguments $session	
		} catch {
			if ($arguments) {
				foreach ($a in $arguments) {
					$args += "$a,"
				}
				$args = $args.Substring(0,$args.Length-1)
			}

			$sb = [ScriptBlock]::Create("Param(`$funcDef) . ([ScriptBlock]::Create(`$funcDef)); $functionName $args");
			$funcDef += (Get-FunctionDefinition $functionName) + ";"			
			
			if ($session) {
				return Invoke-command -Session $session -scriptblock $sb -ArgumentList $funcDef;
			} 

			return Invoke-command -scriptblock $sb -ArgumentList $funcDef;
		}
	}

	if ($funcDef) {
		$scriptBlock = [ScriptBlock]::Create($scriptBlock.ToString() + ";" + $funcDef);
	}

	if ($session) {
		return Invoke-command -Session $session -scriptblock $scriptBlock -ArgumentList $arguments;
	}

	return Invoke-command -scriptblock $scriptBlock -ArgumentList $arguments;
}

function Clear-RemoteSessionCache() {
	if(!(Test-Path Variable:\Deloitte.GTS.CTO.RemoteSessionCache)) {
		return;
	}

	$cache = ${GLOBAL:Deloitte.GTS.CTO.RemoteSessionCache};
	foreach ($s in $cache.Values) {
		Remove-PSSession $s.Id
		$s = $null
	}

	${GLOBAL:Deloitte.GTS.CTO.RemoteSessionCache} = @{}
}

function GetRemoteSession([string]$serverName, [PSCredential]$credentials, [bool]$adminSession) {
	$session = $null;
	if(!(Test-Path Variable:\Deloitte.GTS.CTO.RemoteSessionCache)) {
		${GLOBAL:Deloitte.GTS.CTO.RemoteSessionCache} = @{}
	}
 
	$session = ${GLOBAL:Deloitte.GTS.CTO.RemoteSessionCache}["$serverName"]
	if(!$session) {
		if ($adminSession) {
			$session = Get-AdminPSSession $serverName $credentials
		} else {
			$session = New-PSSession $serverName -Credential $credentials
		}

		${GLOBAL:Deloitte.GTS.CTO.RemoteSessionCache}["$serverName"] = $session
	}

	return $session
}

Export-ModuleMember -Function *-*