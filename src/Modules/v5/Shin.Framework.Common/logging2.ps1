
function Get-Logger([string]$applicationName, [bool]$writeConsole = $true, [int]$loggingLevel = 3) {
	$global:writeConsole=$writeConsole;
	$global:logLevel=$loggingLevel;#4-debug,3-info,2-warn,1-error      
	$global:logFile="$PSScriptRoot\logs\" + $applicationName + ".log";
	
	if (!(Test-Path "$PSScriptRoot\logs")) {
		$f = New-Item "$PSScriptRoot\logs" -ItemType Directory
	}
	
	if (!(Test-Path $global:logFile)) {
		try {
			$newLogFile = New-Item $global:logFile -Force -ItemType File;
		} catch {
			Write-Error "Unable to create new log file: $global:logFile.";
		}
	}
}

function _flushLog([string]$logLevel, [string]$message) {
	$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss";		
	$text = "[$logLevel] $date - $message";
	
	if ($global:writeConsole) {
		[System.ConsoleColor]$color = "White";
		switch($logLevel) {
			"WARN" {$color = "Yellow";}
			"ERROR" {$color = "Red";}
		}
		
		Write-Host $message -ForegroundColor $color;
	}
		
	try {
		$text | Out-File -FilePath $global:logFile -Append;
	} catch {
		Write-Error "Unable to write to log file: $global:logFile.";
	}
}

function Log-Debug([string]$message) {
	if ($global:logLevel -ge 4) {
		_flushLog "DEBUG" $message;						
	}
}

function Log-Info([string]$message) {
	if ($global:logLevel -ge 3) {
		_flushLog "INFO" $message;
	}
}

function Log-Warning([string]$message) {
	if ($global:logLevel -ge 2) {
		_flushLog "WARN" $message;
	}
}

function Log-Error([string]$message) {
	if ($global:logLevel -ge 1) {
		_flushLog "ERROR" $message;
	}
}

function Log-Exception([Exception]$exception) {
	if ($global:logLevel -ge 1) {
		$message = $exception.Message;
		
		foreach ($e in $exception.InnerException) {   
	       $message += "`r`n`t$e.Message";
		}
   
		_flushLog "ERROR" $message;
	}
}