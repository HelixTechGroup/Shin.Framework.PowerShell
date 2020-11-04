#
# Shin.Framework.Data.Csv.psm1
#

function Import-CsvFile([string]$csvFileName, [String[]]$headers) {
	if (!(Test-Path($csvFilename))) {
		throw (New-Object FileNotFoundException "CSV file does not exist: $csvFilename");
	}
	
	try {
		return Import-Csv $csvFileName -Header $headers -ErrorAction Stop | Where-Object { $_.PSObject.Properties.Value -ne $null};
	}catch {
		throw (New-Object Exception "Could not parse CSV file: $csvFileName" $_.Exception)
	}
}	

Export-ModuleMember -Function *-*