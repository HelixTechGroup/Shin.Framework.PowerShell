#
# Shin.Framework.Webservices.psm1
#

function Get-WsdlWebserviceProxy([string]$wsdlUrl, [string]$proxyUrl, [switch]$useDefaultCredential) {
	if (([string]::IsNullOrWhiteSpace($wsdlUrl))) {
		throw (New-Object ArgumentException "WSDL url cannot be empty or null.")
	}

	## Create the web service cache, if it doesn?t already exist
	if(!(Test-Path Variable:\Shin.Framework.WebServiceCache)) {
		${GLOBAL:Shin.Framework.WebServiceCache} = @{}
	}
 
	## Check if there was an instance from a previous connection to
	## this web service. If so, return that instead.
	$oldInstance = ${GLOBAL:Shin.Framework.WebServiceCache}[$wsdlUrl]
	if($oldInstance) {
		return $oldInstance
	}
 
	## Load the required Web Services DLL
	[void] [Reflection.Assembly]::LoadWithPartialName("System.Web.Services")
 
	## Download the WSDL for the service, and create a service description from
	## it.
	$wc = new-object System.Net.WebClient

	$proxy = $null
	if (!([string]::IsNullOrWhiteSpace($proxyUrl))) {
		## Set the Proxy url
		$proxy = new-object System.Net.WebProxy
		$proxy.Address = $proxyUrl
		$wc.proxy = $proxy
	}
 
	$wc.UseDefaultCredentials = $useDefaultCredential;
 
	$wsdlStream = $wc.OpenRead($wsdlUrl)
 
	## Ensure that we were able to fetch the WSDL
	if(!(Test-Path Variable:\wsdlStream)) {
		throw (New-Object Exception "Could not fetch WSDL.")
	}
 
	$serviceDescription = [System.Web.Services.Description.ServiceDescription]::Read($wsdlStream)
	$wsdlStream.Close()
 
	## Ensure that we were able to read the WSDL into a service description
	if(!(Test-Path Variable:\serviceDescription)) {
		throw (New-Object Exception "Service description is null.")
	}
 
	## Import the web service into a CodeDom
	$serviceNamespace = New-Object System.CodeDom.CodeNamespace
	#if($namespace) {
	#	$serviceNamespace.Name = $namespace
	#}
 
	$codeCompileUnit = New-Object System.CodeDom.CodeCompileUnit
	$serviceDescriptionImporter = New-Object Web.Services.Description.ServiceDescriptionImporter
	$serviceDescriptionImporter.AddServiceDescription($serviceDescription, $null, $null)
	[void] $codeCompileUnit.Namespaces.Add($serviceNamespace)
	[void] $serviceDescriptionImporter.Import($serviceNamespace, $codeCompileUnit)
 
	## Generate the code from that CodeDom into a string
	$generatedCode = New-Object Text.StringBuilder
	$stringWriter = New-Object IO.StringWriter $generatedCode
	$provider = New-Object Microsoft.CSharp.CSharpCodeProvider
	$provider.GenerateCodeFromCompileUnit($codeCompileUnit, $stringWriter, $null)
 
	## Compile the source code.
	$references = @("System.dll", "System.Web.Services.dll", "System.Xml.dll")
	$compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
	$compilerParameters.ReferencedAssemblies.AddRange($references)
	$compilerParameters.GenerateInMemory = $true
 
	$compilerResults = $provider.CompileAssemblyFromSource($compilerParameters, $generatedCode)
 
	## Write any errors if generated.        
	if($compilerResults.Errors.Count -gt 0) {
		$errorLines = ??
		foreach($error in $compilerResults.Errors) {
			$errorLines += ?`n`t? + $error.Line + ?:`t? + $error.ErrorText
		}
 
		Write-Error $errorLines
		return $null
	}
	## There were no errors.  Create the webservice object and return it.
	else {
		## Get the assembly that we just compiled
		$assembly = $compilerResults.CompiledAssembly

		## Find the type that had the WebServiceBindingAttribute.
		## There may be other ?helper types? in this file, but they will
		## not have this attribute
		$type = $assembly.GetTypes() |
			Where-Object { $_.GetCustomAttributes(
				[System.Web.Services.WebServiceBindingAttribute], $false) }
 
		if(-not $type) {
			throw (New-Object Exception "Could not generate web service proxy.")
		}

		## Create an instance of the type, store it in the cache,
		## and return it to the user.
		$instance = $assembly.CreateInstance($type.Name)

		if ($proxy) {
			$instance.Proxy = $proxy;
		}
		$instance.UseDefaultCredentials = $useDefaultCredential;

		${GLOBAL:Shin.Framework.WebServiceCache}[$wsdlUrl] = $instance
		return $instance
	}
}

function New-WsdlWebserviceProxy([string]$url, [string]$proxyUrl = $null) {
	try {
		if ($proxyUrl) {
			return Get-WsdlWebserviceProxy -wsdlUrl "$url`?WSDL" -proxyUrl $proxyUrl  -useDefaultCredential
		}

		return New-WebServiceProxy -uri $url -UseDefaultCredential -ErrorAction Stop
	}
	catch {
		throw (New-Object Exception "Error creating proxy for $url", $_.Exception);
	}
}

Export-ModuleMember -Function *-*