#
# api.ps1
#
#Requires -Version 5.0

using namespace System.Data;
#using namespace Deloitte.GLB.API;
using module Deloitte.Platform.Common;

class GlbApi {
	#hidden [GLBTasksWorker]$m_api;
	hidden $m_api;

	[string]$url;
	[string]$proxyUrl;

	GlbApi([string]$proxyUrl) {
		# Set this to the full path of your App.config
		#$dll = "$PSScriptRoot\Deloitte.GLB.API.dll";;
		#$configPath = "$dll.config";

		#$tmp = [reflection.assembly]::LoadWithPartialName("System.Configuration");
		#[System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE", $configPath);
		#[Configuration.ConfigurationManager].GetField("s_initState", "NonPublic, Static").SetValue($null, 0);
		#[Configuration.ConfigurationManager].GetField("s_configSystem", "NonPublic, Static").SetValue($null, $null);
		#([Configuration.ConfigurationManager].Assembly.GetTypes() | where {$_.FullName -eq "System.Configuration.ClientConfigPaths"})[0].GetField("s_current", "NonPublic, Static").SetValue($null, $null);
		#$tmp = [reflection.assembly]::LoadFrom($dll);

		#$this.m_api = [GLBTasksWorker]::new();

		$this.url = "http://crsws.deloitteresources.com/GLBWS.asmx";
		$this.proxyUrl = $proxyUrl;
		$this.createProxy();
	}

	[object[]] GetApplicationContacts([string]$appname) {
		#$app = $this.m_api.GetAppContacts($appname);
		$app = $this.m_api.GetApplicationContactsBASIC($appname);
		return $this::convertTableToObject($app);
	}

	[object[]] GetApplicationServers([string]$appname) {
		#$app = $this.m_api.GetAppServers($appname);
		$app = $this.m_api.Get_Application_Inventory_By_Application_By_ServerTypesOnly($appname);
		return $this::convertTableToObject($app);
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

	hidden static [object[]] convertTableToObject([Dataset]$data) {
		$result    = @()
		$attr = $data.Tables.Rows | Get-Member -MemberType Property
	
		ForEach ($r in $data.Tables.Rows) {
			$prop = @{}
	
			ForEach ($a in $attr) {
				$prop.Add(($a.Name),($r.($a.Name)))
			}	

			$object = New-Object PSObject -Property $prop;
			$result += $object; 
		}
		
		return $result;
	}
}
