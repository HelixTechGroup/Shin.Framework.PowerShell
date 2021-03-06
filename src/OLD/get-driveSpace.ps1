Param(
    [string]$serverNames,
    [string]$driveLetters,
	[string]$csvFilename,
	[switch]$listAllDrives,
	[string]$userName
)

. .\common-functions.ps1

function ConvertFrom-LinuxDfOutput {
    param([string] $Text)
    [regex] $HeaderRegex = '\s*File\s*system\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted\s*on\s*'
    [regex] $LineRegex = '^\s*(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\s*%)\s+(.+)\s*$'
    $Lines = @($Text -split '[\r\n]+')
    if ($Lines[0] -match $HeaderRegex) {
        foreach ($Line in ($Lines | Select -Skip 1)) {
            [regex]::Matches($Line, $LineRegex) | foreach {
                New-Object -TypeName PSObject -Property @{
                    Filesystem = $_.Groups[1].Value
                    '1024-blocks' = [decimal] $_.Groups[2].Value
                    Used = [decimal] $_.Groups[3].Value
                    Available = [decimal] $_.Groups[4].Value
                    CapacityPercent = [decimal] ($_.Groups[5].Value -replace '\D')
                    MountedOn = $_.Groups[6].Value
                } | Select Filesystem, 1024-blocks, Used, Available, CapacityPercent, MountedOn
            }
        }
    }
    else {
        Write-Warning -Message "Error in output. Failed to recognize headers from 'df --portability' output."
    }
} 

function get-drive([string]$serverName, [string]$driveLetter, [Management.Automation.PSCredential]$cred) {
	try {
		
		$filter = $null;
		if (!$listAllDrives) {
			if ($driveLetter -notlike "*:") {
				$driveLetter += ":";
			}

			$filter = "DeviceID='$driveLetter'";
		}

		$d = Get-WmiClass "win32_logicalDisk" $serverName $filter $cred
	}catch {
		log-Error("Could not get drives for server: $serverName");
		log-Exception($_.Exception);
		return;
	}
	
	$drives = @();
	if ($d -isnot [Object[]]) {
		$drives = @($d);
	}else { $drives = $d; }

	foreach ($d in $drives) {
		$size = convert-FileSizeFromBytes($d.Size);
		$freespace = convert-FileSizeFromBytes($d.FreeSpace);

		Write-Host "Hostname   : " $serverName
		Write-Host "Drive      : " $d.DeviceID; 
		Write-Host "Free Space : " $freespace; 
		Write-Host "Total Space: " $size;
		Write-Host "--------------------------";
	}
}

[PSCredential]$cred = $null;
Init-Script("DriveSpace");

if (([string]::IsNullOrWhiteSpace($serverNames) -or ([string]::IsNullOrWhiteSpace($driveLetters) -and !$listAllDrives)) -and ([string]::IsNullOrWhiteSpace($csvFileName))) {
	log-Error("Please provide a server name with drive letters or CSV filename.");
	return;
}

$serverList = @();
$driveList = @();
if(![string]::IsNullOrWhiteSpace($serverNames)){
	$serverList = $serverNames.Split(",");
	
	if(![string]::IsNullOrWhiteSpace($driveLetters)){
		$driveList = $driveLetters.Split(",");
	}
} elseif(![string]::IsNullOrWhiteSpace($csvFilename)) {
	$csv = import-CsvFile $csvFilename @("server","drives");
	if ($csv -eq $null) {
		log-Error("Csv output is null, please check log and csv file.");
		return;
	}
	
	foreach ($s in $csv) {
		$serverList += $s.server;
		$driveList += $s.drives.Split(",");
	}
}

foreach ($s in $serverList) {
	if (Test-Server $s -quiet -wmi) {
		if ($listAllDrives) {
			get-drive $s $null $cred;
		}else {
			foreach ($d in $driveList) {
				get-drive $s $d $cred;
			}
		}
	} else {
		log-Error("Could not connect to server: $s");
	}
}