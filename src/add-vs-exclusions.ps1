$userPath = $env:USERPROFILE
$pathExclusions = New-Object System.Collections.ArrayList
$processExclusions = New-Object System.Collections.ArrayList

$pathExclusions.Add('C:\Windows\Microsoft.NET') > $null
$pathExclusions.Add('C:\Windows\assembly') > $null
$pathExclusions.Add($userPath + '\AppData\Local\Microsoft\VisualStudio') > $null
$pathExclusions.Add('C:\ProgramData\Microsoft\VisualStudio\Packages') > $null
$pathExclusions.Add('C:\Program Files (x86)\MSBuild') > $null
$pathExclusions.Add('C:\Program Files (x86)\Microsoft Visual Studio 14.0') > $null
$pathExclusions.Add('C:\Program Files (x86)\Microsoft Visual Studio 10.0') > $null
$pathExclusions.Add('C:\Program Files (x86)\Microsoft Visual Studio') > $null
$pathExclusions.Add('C:\Program Files (x86)\Microsoft SDKs\NuGetPackages') > $null
$pathExclusions.Add('C:\Program Files (x86)\Microsoft SDKs') > $null

$processExclusions.Add('devenv.exe') > $null
$processExclusions.Add('dotnet.exe') > $null
$processExclusions.Add('msbuild.exe') > $null
$processExclusions.Add('node.exe') > $null
$processExclusions.Add('node.js') > $null
$processExclusions.Add('perfwatson2.exe') > $null
$processExclusions.Add('ServiceHub.Host.Node.x86.exe') > $null
$processExclusions.Add('vbcscompiler.exe') > $null

Write-Host "This script will create Windows Defender exclusions for common Visual Studio 2017 folders and processes."
Write-Host ""
$projectsFolder = Read-Host 'What is the path to your Projects folder? (example: c:\projects)'

Write-Host ""
Write-Host "Adding Path Exclusion: " $projectsFolder
Add-MpPreference -ExclusionPath $projectsFolder

foreach ($exclusion in $pathExclusions) 
{
    Write-Host "Adding Path Exclusion: " $exclusion
    Add-MpPreference -ExclusionPath $exclusion
}

foreach ($exclusion in $processExclusions)
{
    Write-Host "Adding Process Exclusion: " $exclusion
    Add-MpPreference -ExclusionProcess $exclusion
}

Write-Host ""
Write-Host "Your Exclusions:"

$prefs = Get-MpPreference
$prefs.ExclusionPath
$prefs.ExclusionProcess

Write-Host ""
Write-Host "Enjoy faster build times and coding!"
Write-Host ""