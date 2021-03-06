#
# logging.ps1
#
#Requires -Version 5.0

class Logging {
	hidden [string]$m_appName;
	
	[bool]$writeConsole = $true;
	[int]$loggingLevel = 3;#4-debug,3-info,2-warn,1-error
	[string]$logFile;
	
	Logging([string]$applicationName, $scriptRoot) {
		#$rootPath = split-path -parent $MyInvocation.MyCommand.Definition;
		$this.m_appName = $applicationName;        
		$this.logFile = $scriptRoot + "\log\" + $this.m_appName + ".log";
		
		if (!(Test-Path $this.logFile)) {
			try {
				$newLogFile = New-Item $this.logFile -Force -ItemType File;
			} catch {
				throw (New-Object Exception "Unable to create new log file: $($this.logFile)." $_.Exception)
			}
		}
	}
	
	ClearLog() {
		if ((Test-Path $this.logFile)) {
			try {
				$newLogFile = New-Item $this.logFile -Force -ItemType File;
			} catch {
				throw (New-Object Exception "Unable to create new log file: $($this.logFile)." $_.Exception)
			}
		}
	}

	WriteDebug([string]$message) {
		if ($this.loggingLevel -ge 4) {
			$this.flushLog("DEBUG", $message);						
		}
	}
	
	WriteInfo([string]$message) {
		if ($this.loggingLevel -ge 3) {
			$this.flushLog("INFO", $message);
		}
	}
	
	WriteWarning([string]$message) {
		if ($this.loggingLevel -ge 2) {
			$this.flushLog("WARN", $message);
		}
	}
	
	WriteError([string]$message) {
		if ($this.loggingLevel -ge 1) {
			$this.flushLog("ERROR", $message);
		}
	}
	
	WriteException([Exception]$exception) {
		if ($this.loggingLevel -ge 1) {
			$message = $exception.Message;
			
			foreach ($e in $exception.InnerException) {   
		       $message += "`r`n`t$($e.Message)";
			}
	   
			$this.flushLog("ERROR", $message);
		}
	}
	
	hidden flushLog([string]$logLevel, [string]$message) {
		$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss";		
		$text = "[$logLevel] $date - $message";
		
		if ($this.writeConsole) {
			[System.ConsoleColor]$color = "White";
			switch($logLevel) {
				"WARN" {$color = "Yellow";}
				"ERROR" {$color = "Red";}
				"INFO" {$color = "Cyan"}
			}
			
			Write-Host $text -ForegroundColor $color;
		}
			
		try {
			$text | Out-File -FilePath $this.logFile -Append;
		} catch {
			throw (New-Object Exception "Unable to write to log file: $($this.logFile)." $_.Exception)
		}
	}
}