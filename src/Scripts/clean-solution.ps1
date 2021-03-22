param
(
    [string] $solution = "MyProduct.sln"
)
 
Set-Alias msbuild "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MsBuild.exe"
 
$configurations = @("Debug", "Release")
 
foreach ($configuration in $configurations)
{
    msbuild $solution /t:clean /p:configuration=$configuration /v:minimal | Out-Null
}
 
$directories = @("bin", "obj")
 
foreach ($directory in $directories)
{
    Get-ChildItem -Directory -Recurse | ? { $_.Name -eq $directory } | Remove-Item -Recurse -Confirm:$false
}