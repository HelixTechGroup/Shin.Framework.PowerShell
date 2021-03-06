Param(
    [string]$sourceGroup,
	[string]$destinationGroup,
	#[string]$groupCsv,
	[string]$groupScope="Global",
	[string]$groupCatagory="Security",
	[string]$groupDescription,
	[string]$groupPath,
	[string]$additionalUsers,
	#[string]$userCsv,
	[switch]$force,
	[string]$userName,
	[string]$domain
)

. .\common-functions.ps1

Import-Module ActiveDirectory;

#$path = "OU=security,OU=groups,OU=test,DC=mikefrobbins,DC=com"

[PSCredential]$cred = $null;
Init-Script("CloneGroup");

if (([string]::IsNullOrWhiteSpace($sourceGroup)) -or ([string]::IsNullOrWhiteSpace($destinationGroup))) {
	log-Error("Please provide a source and destination group name.");
	return;
}

if ([string]::IsNullOrWhiteSpace($domain)) {
	$domain = (Get-ADDomain -current LoggedOnUser).DnsRoot;
}

$path = convert-ToLdapDN $domain $groupPath;

if ((Get-ADGroup -Filter {SamAccountName -eq $sourceGroup}) -eq $null) {
	log-Error("Source group does not exist.");
	return;
}

if (((Get-ADGroup -Filter {SamAccountName -eq $destinationGroup}) -ne $null) -and !($force)) {
	log-Error("Destination group already exists.");
	return;
} else {
	New-ADGroup -name $destinationGroup -GroupScope $groupScope -Description $groupDescription -GroupCategory $groupCatagory -Path $path;	
}

$members = Get-ADGroupMember $sourceGroup
if ($mebers.Count -gt 0) {
	Add-AdGroupMember $destinationGroup -Members $members
}

Get-ADGroupMember $destinationGroup | Get-ADUser | Select-Object Name