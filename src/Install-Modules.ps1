#Requires -Version 3.0

Param (
	[switch]$installForAllUsers,
	[switch]$verifyInstall,
	[switch]$skipVerification
)

$moduleNamespace = "deloitte.gts.cto"

Remove-Module Deloitte.GTS.CTO.* -Force
Import-Module "$PSScriptRoot/Modules/Deloitte.GTS.CTO.Common/Deloitte.GTS.CTO.Common.psd1" -DisableNameChecking

function Clean-Solution($moduleSource) {
	# Define files and directories to delete
	#"bin",
	$include = @("*.suo","*.user","*.cache","*.docstates","obj","build",".vs")

	# Define files and directories to exclude
	$exclude = @()

	$items = Get-ChildItem "$moduleSource" -recurse -force -include $include -exclude $exclude

	if ($items) {
		foreach ($item in $items) {
			Remove-Item "$item.FullName" -Force -Recurse -ErrorAction SilentlyContinue
		}
	}
}

function Install-Modules($moduleSourceDirectory, $moduleDirectory) {
	$exclude = @('*.pssproj*','docs')
	#Write-Host "Copying modules from $moduleSourceDirectory to $moduleDirectory"
	try {
		Copy-Item "$moduleSourceDirectory\*" "$moduleDirectory" -Recurse -Exclude $exclude -Force 
	} catch {
		Write-Host "Could not copy file. $($_.Exception)"
	}
}

function Verify-Install($moduleNamespace) {
	$modules = Get-Module -ListAvailable | Where-Object { $_.Name.ToLower() -like "*$moduleNamespace*" }
	if ($modules.Count -gt 0) {
		foreach ($m in $modules) {
			"Name: $($m.Name)"
			"Description: $($m.Description)"
			"Functions:
$((Get-Command -Module $m.Name).Name | Sort | foreach-object { `"`t$_`n`" })"
			"Nested Modules:
$($m.NestedModules.Name | Sort | foreach-object { `"`t$_`n`" })"
		}
	}
} 

if (!(Get-IsRunningAsAdmin)) {
	Write-Error "Please run Install-Modules.ps1 as an Administrator"
	return;
}

$ver = Get-PSVersion

if ($ver -lt 3) {
	Write-Host "The Powershell Modules require powershell version 3 or higher.`rCurrent version is $ver" -ForegroundColor Red
}

$moduleRootDirectory = "$HOME\Documents\WindowsPowerShell"

if ($installForAllUsers) {
	$moduleRootDirectory = "$env:ProgramFiles\WindowsPowerShell"
}

if (!$verifyInstall) {
	Write-Host "Cleaning Solution"
	$clean = (Get-Command Clean-Solution -CommandType Function).ScriptBlock
	Show-Progress $clean @("$PSScriptRoot\Modules")

	Write-Host "Verifying Module Directory"
	$create = [ScriptBlock]::Create(
	"if (!(Test-Path `"$moduleRootDirectory\Modules`")) {
		Write-Host `"Creating Modules directory: $moduleRootDirectory\Modules`"
		New-Item $moduleRootDirectory\Modules -ItemType Directory
	}"
	);
	Show-Progress $create

	Write-Host "Installing Modules"
	$install = (Get-Command Install-Modules -CommandType Function).ScriptBlock
	Show-Progress $install @("$PSScriptRoot\Modules", "$moduleRootDirectory\Modules")

	Write-Host "Configuring System"
	Write-Host "`r`tAllowing Admin PS Sessions"
	$adminSession = (Get-Command Grant-AdminPSSessionClient -CommandType Function).ScriptBlock
	Show-Progress $adminSession
	Write-Host "`tAdding Context RunAs Admin menu option for .ps1 files"
	$runas = (Get-Command Set-Ps1RunAsAdmin -CommandType Function).ScriptBlock
	Show-Progress $runas
}

if (!$skipVerification) {
	Write-Host "Verifying Module Installation"
	$verify = (Get-Command Verify-Install -CommandType Function).ScriptBlock
	Show-Progress $verify @($moduleNamespace)
}

Remove-Module Deloitte.GTS.CTO.* -Force