#
# Deloitte.GTS.CTO.Data.psm1
#

function Select-DataTableColumns([System.Data.DataTable]$table, [string[]]$columns) {
	[System.Data.DataTable]$tmp = $table;
	return ([System.Data.DataView]::new($tmp)).ToTable($table.TableName, $false, $columns);
}

function ConvertFrom-DataTableToObject([System.Data.DataTable]$data) {
	$result = @()
	if ($data.Rows.Count -gt 0) {
		$attr = $data.Rows | Get-Member -MemberType Property
		ForEach ($r in $data.Rows) {
			$prop = @{}
			ForEach ($a in $attr) {
				$prop.Add(($a.Name),($r.($a.Name)))
			}	

			$object = New-Object PSObject -Property $prop;
			$result += $object; 
		}
	}

	return $result;
}

function ConvertFrom-DataSetToObject([System.Data.DataSet]$data) {
	ForEach ($t in $data.Tables) {	
		$object = ConvertFrom-DataTableToObject $t
		$result += $object; 
	}

	return $result;
}

Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.* |
ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *-*