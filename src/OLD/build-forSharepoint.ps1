Copy-Item .\* .\build\ -Include "*.ps1";
Get-ChildItem .\build\ -Filter "*.ps1" | Rename-Item -NewName {$_.name -replace ‘.ps1’,’.ps1.txt’ } 