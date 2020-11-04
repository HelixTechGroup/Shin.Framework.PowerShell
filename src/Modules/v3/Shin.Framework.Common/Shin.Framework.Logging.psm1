#
# Deloitte.GTS.CTO.Logging.psm1
#

#using namespace Deloitte.GTS.CTO.Infrastructure;
#using namespace Deloitte.GTS.CTO.Infrastructure.Logging;

[Deloitte.GTS.CTO.Infrastructure.ILogManager]$logger;

function New-Logger([switch]$fileLogger = $true, [switch]$eventLogger, [string]$applicationName, [string]$logLocation, [switch]$witeToConsole) {
	if ($fileLogger) {
		$script:logger = [Deloitte.GTS.CTO.Infrastructure.Logging.FileLogger]::new($applicationName, $logLocation);
	} elseif ($eventLogger) {
		$script:logger = [Deloitte.GTS.CTO.Infrastructure.Logging.EventViewerLogger]::new($applicationName, $logLocation);
	}		
	
	$script:logger.WriteToConsole = $witeToConsole;
		
	return $script:logger;
}

function Set-LoggingLevel([Deloitte.GTS.CTO.Infrastructure.Logging.LogLevel]$loggingLevel) {
	$script:logger.LoggingLevel = $loggingLevel;
}

function Get-LoggingLevel() {
	return $script:logger.LoggingLevel;
}

function Set-LoggingWriteToConsole([bool]$writeToConsole) {
	$script:logger.WriteToConsole = $writeToConsole;
}

function Clear-Log() {
	$script:logger.ClearLog(); 
}

function Write-LogDebug([string]$message) {
	$script:logger.LogDebug($message);
}

function Write-LogInfo([string]$message) {
	$script:logger.LogInfo($message);
}

function Write-LogWarn([string]$message) {
	$script:logger.LogWarning($message);
}

function Write-LogError([string]$message) {
	$script:logger.LogError($message);
}

function Write-LogException([string]$message, [Exception]$exception) {
	$script:logger.LogException($message, $exception);
}

Export-ModuleMember -Function *-*