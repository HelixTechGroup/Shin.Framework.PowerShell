#
# Deloitte.GTS.CTO.PCS.psm1
#

#using namespace System.DirectoryServices.ActiveDirectory;

$m_api;
[string]$m_url;
[string]$m_proxyUrl;
$m_auth;
[string]$m_domain;
[string]$m_username;
[SecureString]$m_password;

function New-ApiInterface([PSCredential]$credentials, [string]$proxyUrl = $null) {
	$script:m_url = "";
	$script:m_proxyUrl = $proxyUrl;

	$script:m_domain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name;
	$script:m_username = $credentials.UserName;
	$script:m_password = $credentials.Password;
	if($credentials.UserName -match "\\") {
		$script:m_username = $credentials.UserName.Split("\")[1]
		$script:m_domain = $credentials.UserName.Split("\")[0]
	}

	$script:m_api = New-WsdlWebserviceProxy $script:m_url $script:m_proxyUrl
}

function Request-Authentication() {
	try {
		$res = $script:m_api.Authenticate($script:m_username, (Get-PlainTextPassword $script:m_password), $null, $script:m_domain);
		checkErrors($res);

		$script:m_auth = $res;
	} catch {
		throw (New-Object Exception "Could not authenticate with username: $($script:m_username)", $_.Exception);
	}
}

function Search-Folders([string]$filter) {
	$folders = @();
	$res = $null;

	try { 
		if (!(isTokenValid)) { Request-Authentication }
		$res = $script:m_api.SearchFolders($script:m_auth.Token, $filter);
		checkErrors($res);
	} catch {
		throw (New-Object Exception "Could not search for folders using filter: $filter", $_.Exception);
	}

	#Loop through folders.  Get the full folder path
	foreach($f in $res.Folders) {
		#if($f.Name -notlike $filter) { #-or $f.Id -notlike $Id) {
		#	continue;
		#}

		$id = $f.Id;
		$name = $f.Name;
		$parentId = $f.ParentFolderId;
		$typeId = $f.TypeId;

		$folder = New-Object PSObject
		$folder.PSTypeNames.Insert(0,"SecretServer.Folder");
			
		$fullPath = "$name";
		while($parentID -notlike $null) {
			$workingFolder = $res.Folders | Where-Object {$_.Id -eq $parentId}
			$fullPath = $workingFolder.Name, $fullPath -join "\"
			$parentID = $workingFolder.ParentFolderId
		}

	#	#if($fullPath -notlike $folderPath) {
	#	#	continue
	#	#}

		$type = "";
		switch ($typeId) {
			1 { $type = "Folder"; break; }
			2 { $type = "Customer"; break; }
			3 { $type = "Computer"; break; }
		}

		$folder | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
		$folder | Add-Member -MemberType NoteProperty -Name "Name" -Value $name
		$folder | Add-Member -MemberType NoteProperty -Name "Type" -Value $type 
		$folder | Add-Member -MemberType NoteProperty -Name "TypeId" -Value $typeId
		$folder | Add-Member -MemberType NoteProperty -Name "ParentId" -Value $parentId
		$folder | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $fullPath
			
		$folders += $folder;								
	}

	return $folders;
}

function Get-FolderSecrets($folderId, [switch]$includeSubFolders, [switch]$includeDeleted) {
	$secrets = @();
	$res = $null;

	try {
		if (!(isTokenValid)) { Request-Authentication }
		$res = $script:m_api.SearchSecretsByFolder($script:m_auth.Token, '', $folderId, $includeSubFolders, $includeDeleted, $True);
		checkErrors($res);
	} catch {
		throw (New-Object Exception "Could not search for secrets in folder: $folderId", $_.Exception);
	}

	foreach ($s in $res.SecretSummaries) {
		$id = $s.SecretId
        $name = $s.SecretName
        $type = $s.SecretTypeName
		$typeId = $s.SecretTypeId
        $folderId = $s.FolderId
        $restricted = $s.IsRestricted

		$summary = New-Object PSObject
		$summary.PSTypeNames.Insert(0,"SecretServer.SecretSummary");

		$summary | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
		$summary | Add-Member -MemberType NoteProperty -Name "Name" -Value $name
		$summary | Add-Member -MemberType NoteProperty -Name "TypeId" -Value $typeId
		$summary | Add-Member -MemberType NoteProperty -Name "Type" -Value $type 
		$summary | Add-Member -MemberType NoteProperty -Name "FolderId" -Value $folderId
		$summary | Add-Member -MemberType NoteProperty -Name "isRestricted" -Value $restricted
			
		$secrets += $summary;
	}

	return $secrets;
}

function Get-Secret([int]$secretId) {
	$secret = $null;
	$res = $null;

	try {
		if (!(isTokenValid)) { Request-Authentication }
		$res = $script:m_api.GetSecret($script:m_auth.Token, $secretId, $false, $null);
		checkErrors($res);
	} catch {
		throw (New-Object Exception "Could not get secret: $secretId", $_.Exception);
	}

	$s = $res.Secret;
	$id = $s.Id
    $name = $s.Name
	$typeId = $s.SecretTypeId
	$folderId = $s.FolderId
    $restricted = $s.IsRestricted
	$active = $s.Active
	$outOfSync = $s.IsOutOfSync
	$username = ($s.Items | Where-Object {$_.FieldName -eq "UserName"}).Value;
	$password = ($s.Items | Where-Object {$_.FieldName -eq "Password"}).Value;
	$domain = ($s.Items | Where-Object {$_.FieldName -like "Domain*"}).Value;	
	$server = ($s.Items | Where-Object {$_.FieldName -like "Server*"}).Value;
	$environment = ($s.Items | Where-Object {$_.FieldName -eq "Environment"}).Value;

	$secret = New-Object PSObject
	$secret.PSTypeNames.Insert(0,"SecretServer.Secret");

	$secret | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
	$secret | Add-Member -MemberType NoteProperty -Name "Name" -Value $name
	$secret | Add-Member -MemberType NoteProperty -Name "TypeId" -Value $typeId
	$secret | Add-Member -MemberType NoteProperty -Name "FolderId" -Value $folderId
	$secret | Add-Member -MemberType NoteProperty -Name "isRestricted" -Value $restricted
	$secret | Add-Member -MemberType NoteProperty -Name "isOutOfSync" -Value $outOfSync
	$secret | Add-Member -MemberType NoteProperty -Name "Active" -Value $active
	$secret | Add-Member -MemberType NoteProperty -Name "Domain" -Value $domain
	$secret | Add-Member -MemberType NoteProperty -Name "Server" -Value $server
	$secret | Add-Member -MemberType NoteProperty -Name "Username" -Value $username
	$secret | Add-Member -MemberType NoteProperty -Name "Password" -Value $password
	$secret | Add-Member -MemberType NoteProperty -Name "Environment" -Value $environment

	return $secret;
}

function isTokenValid() {
	try {
		$res = $script:m_api.GetTokenIsValid($script:m_auth.Token);
		return !($res.Errors)
	} catch {
		throw (New-Object Exception "Could not validate token.", $_.Exception);
	}

	return $false;
}

function checkErrors($result) {
	if ($result.Errors.Count -gt 0) {
		throw (New-Object Exception "Pcs api call errors: $($result.Errors)");
	}
}

Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.* |
ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *-*
