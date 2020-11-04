## Load the required Web Services DLL
[void] [Reflection.Assembly]::LoadWithPartialName("System.Web.Services")

Get-ChildItem -Path $PSScriptRoot\*.ps1 |
ForEach-Object {
    . $_.FullName
}