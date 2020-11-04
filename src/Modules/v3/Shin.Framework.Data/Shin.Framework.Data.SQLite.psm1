#
# Deloitte.GTS.CTO.Data.SQLite.psm1
#

function Open-SQLiteDatabase([string]$name, [string]$location, [switch]$force) {
	if ((Test-Path "$name`:\") -and !($force)) {
		throw (New-Object Exception "Database already open with that name. Use -Force to override.")
	}

	if (!(Test-Path $location)) {
		throw (New-Object Exception "Database location does not exist.")
	}

	if (!($location.EndsWith("\"))) {
		$location += "\"
	}

	try {
		Close-SQLiteDatabase $name
		$fullPath = "$location$name.db"
		New-PSDrive -PSProvider SQLite -Name $name -Root "Data Source=$fullPath" -ErrorAction Stop -Scope Global
	} catch {
		throw (New-Object Exception "Could not open SQLite database" $_.Exception)
	}
}

function New-SQLiteDatabase([string]$name, [string]$location, [string]$schemaFilename=$null) {
	Open-SQLiteDatabase $name $location
}

function Remove-SQLiteDatabase([string]$name) {
	try {
		Close-SQLiteDatabase $name

		$fullPath = "$location$name.db"
		Remove-Item $fullPath -ErrorAction Stop -Force
	} catch {
		throw (New-Object Exception "Could not remove SQLite database" $_.Exception)
	}
}

function Close-SQLiteDatabase([string]$name) {
	if ((Test-Path "$name`:\")) {
		try {
			Remove-PSDrive -Name $name -Force
		} catch {
			throw (New-Object Exception "Could not close SQLite database" $_.Exception)
		}
	}
}

function New-SQLiteTable([string]$dbName, [string]$name, [hashtable]$columns) {
	if ((Test-SQLiteTable $dbName $name)) {
		throw (New-Object Exception "Table $name in $dbName already exists.")
	}

	$path = "$dbName`:\$name"
	try {
		New-Item -Path $path -Value $columns -ErrorAction Stop
	} catch {
		throw (New-Object Exception "Could not create SQLite table in $dbName" $_.Exception)
	}
}

function Remove-SQLiteTable([string]$dbName, [string]$name) {
	if (!(Test-SQLiteTable $dbName $name)) {
		throw (New-Object Exception "Table $name in $dbName does not exist.")
	}

	$path = "$dbName`:\$name"
	try {
		Remove-Item -Path $path -ErrorAction Stop
	} catch {
		throw (New-Object Exception "Could not remove SQLite table in $dbName" $_.Exception)
	}
}

function Get-SQLiteTable([string]$dbName, [string]$name) {
	if (!(Test-SQLiteTable $dbName $name)) {
		throw (New-Object Exception "Table $name in $dbName does not exist.")
	}

	$path = "$dbName`:\$name"
	try {
		Get-Item -Path $path -ErrorAction Stop
	} catch {
		throw (New-Object Exception "Could not get SQLite table in $dbName" $_.Exception)
	}
}

function Test-SQLiteTable([string]$dbName, [string]$name) {
	$path = "$dbName`:\$name"
	if (!(Test-Path $path)) {
		return $false;
	}

	return $true;
}

function New-SQLiteRecord([string]$dbName, [string]$tableName, [hashtable]$record) {	
	$path = "$dbName`:\$tableName"
	try {
		$o = New-Object PSObject -Property $record
		$o | New-Item -Path $path -ErrorAction Stop
	} catch {
		throw (New-Object Exception "Could not create SQLite record in $tableName in $dbName" $_.Exception)
	}
}

function Remove-SQLiteRecord([string]$dbName, [string]$tableName, [string]$recordId, [string]$filter) {
	$path = "$dbName`:\$tableName"
	if (!([string]::IsNullOrWhiteSpace($recordId))) {
		$path += "\$recordId"
		try {
			Remove-Item $path -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not remove SQLite record in $tableName in $dbName" $_.Exception)
		}
		return;		
	}

	if (!([string]::IsNullOrWhiteSpace($filter))) {
		try {
			Remove-Item $path -Filter $filter -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not remove SQLite record(s) in $tableName in $dbName" $_.Exception)
		}
	} 
}
 
function Get-SQLiteRecord([string]$dbName, [string]$tableName, [string]$recordId, [string]$filter) {
	$path = "$dbName`:\$tableName"
	if (!([string]::IsNullOrWhiteSpace($recordId))) {
		$path += "\$recordId"
		try {
			Get-Item $path -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not get SQLite record in $tableName in $dbName" $_.Exception)
		}
		return;		
	}

	if (!([string]::IsNullOrWhiteSpace($filter))) {
		try {
			Get-Item $path -Filter $filter -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not get SQLite record(s) in $tableName in $dbName" $_.Exception)
		}
	} 
}

function Update-SQLiteRecord([string]$dbName, [string]$tableName, [string]$recordId, [string]$filter, [hashtable]$record) {
	$path = "$dbName`:\$tableName"
	if (!([string]::IsNullOrWhiteSpace($recordId))) {
		$path += "\$recordId"
		try {
			Set-Item $path -Value $record -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not set SQLite record in $tableName in $dbName" $_.Exception)
		}
		return;		
	}

	if (!([string]::IsNullOrWhiteSpace($filter))) {
		try {
			Set-Item $path -Filter $filter -Value $record -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not set SQLite record(s) in $tableName in $dbName" $_.Exception)
		}
	} 
}

function Use-SQLiteQuery([string]$dbName, [string]$query) {
	$path = "$dbName`:"
	if (!([string]::IsNullOrWhiteSpace($query))) {
		try {
			Invoke-Item $path -Sql $query -ErrorAction Stop
		} catch {
			throw (New-Object Exception "Could not query SQLite database $dbName" $_.Exception)
		}
	} 
}

function Test64bit() {
    if ([IntPtr]::Size -eq 4) { return $false }
    else { return $true }
}

Write-Verbose 'loading sqlite provider assemblies...';
ls $PSScriptRoot/bin/SQLite/*.dll | Import-Module;

if (Test64Bit) {
	Write-Verbose 'loading 64-bit sqlite assemblies...';
	ls $PSScriptRoot/bin/SQLite/x64/*.dll | Import-Module;
} else {
	Write-Verbose 'loading 32-bit sqlite assemblies...';
	ls $PSScriptRoot/bin/SQLite/x32/*.dll | Import-Module;
}

Export-ModuleMember -Function *-*