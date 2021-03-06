Param(
    [string]$serverNames,
	[string]$csvFilename,
	[switch]$showOnlyHighCpuUsage,
	[switch]$showOnlyHighMemoryUsage,
	[string]$userName
)

. .\common-functions.ps1

function Get-ServerProcesses([string]$serverName, [Management.Automation.PSCredential]$cred) {
	$p = @();
	try {
		$p = Get-WmiClass "Win32_PerfFormattedData_PerfProc_Process" $serverName $null $cred | Where {$_.IDProcess -ne 0};
		#$p = $p 
	} catch {
		$message = "Could not get processes for server: $serverName";	
		Log-Error($message);
		Log-Exception($_.Exception);
		
		return;
	}

	Write-Host "Hostame: " $computerName;
	Write-Host "--------------------------";
	
	if (!$showOnlyHighMemoryUsage) {
		$c = $p | Sort-Object PercentProcessorTime -Descending | Select -First 10;
		$cpu_array = @();
		
		foreach ($Process in $c) {
			$prop = @{"PID"=$Process.IDProcess;
			"Name"=$Process.Name;
			"CPU"=$Process.PercentProcessorTime
			"Memory"=convert-FileSizeFromBytes($Process.WorkingSet);}
			$cpu_array += New-Object –TypeName PSObject –Prop $prop
		}
		
		Write-Host "High CPU Usage";
		Write-Host "--------------------------";
		$cpu_array | Sort-Object CPU -Descending | Format-Table PID,Name,CPU,Memory
	}

	if (!$showOnlyHighCpuUsage) {
		$m = $p | Sort-Object WorkingSet -Descending | Select -First 10;
		$mem_array = @();

		foreach ($Process in $m) {
			$prop = @{"PID"=$Process.IDProcess;
			"Name"=$Process.Name;
			"Memory"=convert-FileSizeFromBytes($Process.WorkingSet);
			"CPU"=$Process.PercentProcessorTime}
			$mem_array += New-Object –TypeName PSObject –Prop $prop;
		}

		Write-Host "==========================";
		Write-Host "`High Memory Usage"
		Write-Host "--------------------------";
		
		$mem_array | Sort-Object Memory -Descending | Format-Table PID,Name,Memory,CPU;
	}
}

[PSCredential]$cred = $null;
Init-Script("ProcessUsage");

if (([string]::IsNullOrWhiteSpace($serverNames)) -and ([string]::IsNullOrWhiteSpace($csvFileName))) {
	Log-Error("Please provide a list of servers or CSV filename.");
	return;
}

$serverList = @();
if(![string]::IsNullOrWhiteSpace($serverNames)){
	$serverList = $serverNames.Split(",");
} elseif(![string]::IsNullOrWhiteSpace($csvFilename)) {
	$csv = Import-CsvFile $csvFilename @("server");	
	if ($csv -eq $null) {
		Log-Error("Csv output is null, please check log and csv file.");
		return;
	}
	
	foreach ($s in $csv) {
		$serverList += $s.server;
	}
}

foreach($s in $serverList) {
	if (Test-Server $s -quiet -wmi) {
		get-ServerProcesses $s $cred;
	} else {
		Log-Error("Could not connect to server: $s");
	}
}