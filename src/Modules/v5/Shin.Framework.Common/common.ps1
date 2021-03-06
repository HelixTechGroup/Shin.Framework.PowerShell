#
# common.ps1
#
#Requires -Version 5.0

using namespace System.Management.Automation;
using namespace System.Data;
using namespace System.IO;

class Common {
	[string] GetScriptDirectory() {
	  return Split-Path -Parent $MyInvocation.PSCommandPath;
	}

	[int] GetPSVersion() {
		return $this::PSVersionTable.PSVersion.Major;
	}

	static [string] ConvertFileSizeFromBytes([float]$size) {
		if (($size/1024) -ge 1024) {
			$free = $size/1024/1024;
			if ($free -ge 1024) {
				$free /= 1024;
				if ($free -ge 1024) {
					$free /= 1024;
					$fPostfix = "TB";
				}else {
					$fPostfix = "GB"
				}
			}else{
				$fPostfix = "MB";
			}
		} else {
			$free = $size/1024;
			$fPostfix = "KB";
		}
	
		$free = [Math]::Round($free, 2);
		return "$free$fPostfix";
	}	

	static [string] ConvertToLdapDN([string]$domain, [string]$objectPath) {
		$path = "";
		$dc = $domain.Split('.');
		$op = $objectPath.Split('\');
	
		foreach ($d in $dc) {
			$path += ",DC=$d";
		}
	
		foreach ($o in $op) {
			$path = ",OU=$o" + $path;
		}

		return $path -replace '^(.*?),', '$1';
	}

	[object] ImportCsvFile([string]$csvFileName, [String[]]$headers) {
		if (!(Test-Path($csvFilename))) {
			throw (New-Object FileNotFoundException "CSV file does not exist: $csvFilename");
		}
	
		try {
			return Import-Csv $csvFileName -Header $headers -ErrorAction Stop | Where-Object { $_.PSObject.Properties.Value -ne $null};
		}catch {
			throw (New-Object Exception "Could not parse CSV file: $csvFileName" $_.Exception)
		}
	}	

	static [bool] TestServer([string]$server, [bool]$quiet) {
		$runPing = $runRdp = $runWmi = $true;
		$pingRes = $rdpRes = $wmiRes = $false;
		#$ping = $wmi = $true

		#if ($rdp) { $runWmi = $runPing = $false; }
		#if ($wmi) { $runRdp = $runPing = $false; }
		#if ($ping) { $runRdp = $runWmi = $false; }
	
		if ($runPing) { try { $pingRes = Test-Connection $server -Count 1 -Quiet -ErrorAction Stop; }catch{ $pingRes = $false; } }
		#if ($runRdp) { try { $rdpRes = Test-NetConnection $server -CommonTcpPort RDP -InformationLevel Quiet -ErrorAction Stop; }catch{ $rdpRes = $false } }
		if ($runWmi) { try { if((Get-WmiObject Win32_ComputerSystem -ComputerName $server -ErrorAction Stop) -ne $null){ $wmiRes = $true; }}catch{ $wmiRes = $false; } }
	
		if ($quiet) {
			#-or (!$rdpRes -and $runRdp)
			if ((!$pingRes -and $runPing) -or (!$wmiRes -and $runWmi)) {
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

	static [PSObject] InvokeDynamicCommand([string]$functionName, [object[]]$functionArgs) {
		if (Test-Path Function:\$functionName) {
			$sb = (get-command $functionName -CommandType Function).ScriptBlock;
			return Invoke-command -scriptblock $sb -ArgumentList $functionArgs;
		}else {
			return Invoke-Command -ScriptBlock {param($a) & $functionName @a } -ArgumentList $functionArgs
		}
	
		return $null;
	}

	[PSObject] GetWmiClass([string]$class, [string]$serverName, [string]$filter, [Management.Automation.PSCredential]$cred) {
		$args = @{};
		$args.Add("Class", $class);
		$args.Add("ErrorAction", "Stop");
		$args.Add("ComputerName", $serverName);
	
		if ($cred -ne $null) {
			$args.Add("Credential", $cred);
		}
	
		if (!([string]::IsNullOrWhiteSpace($filter))) {
			$args.Add("Filter", $filter);
		}
	
		return $this::InvokeDynamicCommand("Get-WmiObject", $args);
	}	

	static [DataTable] SelectColumns([DataTable]$table, [string[]]$columns) {
		[DataTable]$tmp = $table;
		if ($tmp.Rows.Count -gt 0) {
			return ([DataView]::new($tmp)).ToTable($table.TableName, $false, $columns);
		}

		return $null;
	}
}