#
# Deloitte.GTS.CTO.GLB.psm1
#

#using namespace System.Data
#$dataType = [System.Data];
#$sysData = New-Object $dataType.FullName;
#[void] [Reflection.Assembly]::LoadWithPartialName("System.Data");

$m_api;
[string]$m_url;
[string]$m_proxyUrl;

function New-ApiInterface([string]$proxyUrl = $null) {
	$script:m_url = "";
	$script:m_proxyUrl = $proxyUrl;

	$script:m_api = New-WsdlWebserviceProxy $script:m_url $script:m_proxyUrl
}

function Get-ApplicationContacts([string]$appname) {
	$app = $script:m_api.GetApplicationContactsBASIC($appname);
	return ConvertFrom-DataSetToObject $app
}

function Get-ApplicationServers([string]$appname) {
	$app = $script:m_api.Get_Application_Inventory_By_Application_By_ServerTypesOnly($appname);
	return ConvertFrom-DataSetToObject $app
}

Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.* |
ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *-*
