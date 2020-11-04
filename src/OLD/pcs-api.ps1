#
# api.ps1
#
#Requires -Version 5.0

using module Deloitte.Platform.Common;
using namespace System.DirectoryServices.ActiveDirectory;

class PcsApi {
	hidden $m_api;
	hidden $m_auth;
	hidden [string]$m_domain;
	hidden [string]$m_username;
	hidden [SecureString]$m_password;

	[string]$url;
	[string]$proxyUrl;

	PcsApi([PSCredential]$credentials, [string]$proxyUrl) {

		$this.m_domain =  [Domain]::GetCurrentDomain().Name;
		$this.m_username = $credentials.UserName;
		$this.m_password = $credentials.Password;
		if($credentials.UserName -match "\\") {
			$this.m_username = $credentials.UserName.Split("\")[1]
			$this.m_domain = $credentials.UserName.Split("\")[0]
		}
		
		$this.url = "https://pcs.deloitteresources.com/PCS/webservices/sswebservice.asmx";
		$this.proxyUrl = $proxyUrl;
		$this.createProxy();		
		$this.Autenticate();
	}

	Autenticate() {
		try {
			$res = $this.m_api.Authenticate($this.m_username, [Security]::GetPlainTextPassword($this.m_password), $null, $this.m_domain);
			$this::checkErrors($res);

			$this.m_auth = $res;
		} catch {
			throw (New-Object Exception "Could not authenticate with username: $($this.m_username)", $_.Exception);
		}
	}

	[object[]] SearchFolders([string]$filter) {
		$folders = @();
		$res = $null;

		try { 
			if (!($this.isTokenValid())) { $this.Autenticate(); }
			$res = $this.m_api.SearchFolders($this.m_auth.Token, $filter);
			$this::checkErrors($res);
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

	[object[]] GetFolderSecrets($folderId, [bool]$includeSubFolders, [bool]$includeDeleted) {
		$secrets = @();
		$res = $null;

		try {
			if (!($this.isTokenValid())) { $this.Autenticate(); }
			$res = $this.m_api.SearchSecretsByFolder($this.m_auth.Token, '', $folderId, $includeSubFolders, $includeDeleted, $True);
			$this::checkErrors($res);
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

	[object] GetSecret([int]$secretId) {
		$secret = $null;
		$res = $null;

		try {
			if (!($this.isTokenValid())) { $this.Autenticate(); }
			$res = $this.m_api.GetSecret($this.m_auth.Token, $secretId, $false, $null);
			$this::checkErrors($res);
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

	hidden [bool] isTokenValid() {
		try {
			$res = $this.m_api.GetTokenIsValid($this.m_auth.Token);
			return !($res.Errors)
		} catch {
			throw (New-Object Exception "Could not validate token.", $_.Exception);
		}

		return $false;
	}

	hidden createProxy() {
		#if ($this.m_api -eq $null -or !($this.m_api.whoami)) {
            try {
				if ($this.proxyUrl) {
					$this.m_api = [webservice]::NewWebServiceProxy("$($this.url)?WSDL", $this.proxyUrl, $true);
					return;
				}

                $this.m_api = New-WebServiceProxy -uri $this.url -UseDefaultCredential -ErrorAction Stop
            }
            catch {
                throw (New-Object Exception "Error creating proxy for $($this.url)", $_.Exception);
            }
        #}
	}

	static hidden checkErrors($result) {
		if ($result.Errors.Count -gt 0) {
			throw (New-Object Exception "Pcs api call errors: $($result.Errors)");
		}
	}
}