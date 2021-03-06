Param(
	[Parameter(Mandatory=$true)]
    [string]$computerName
)

$p = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process -ComputerName $computerName | Where {$_.IDProcess -ne 0};
$c = $p | Sort-Object PercentProcessorTime -Descending | Select -First 10;
$m = $p | Sort-Object WorkingSet -Descending | Select -First 10;
$cpu_array = @();
$mem_array = @();

foreach ($Process in $c) {
	$prop = @{"PID"=$Process.IDProcess;
	"Name"=$Process.Name;
	"Memory"=$Process.WorkingSet;
	"CPU"=$Process.PercentProcessorTime}
	$cpu_array += New-Object –TypeName PSObject –Prop $prop
}

foreach ($Process in $m) {
	$prop = @{"PID"=$Process.IDProcess;
	"Name"=$Process.Name;
	"Memory"=$Process.WorkingSet;
	"CPU"=$Process.PercentProcessorTime}
	$mem_array += New-Object –TypeName PSObject –Prop $prop;
}

Write-Host "Hostame: " $computerName "`n";
Write-Host "High CPU Usage";
$cpu_array | Sort-Object CPU -Descending | Format-Table;

Write-Host "`n`nHigh Memory Usage"
$mem_array | Sort-Object Memory -Descending | Format-Table;