#
# Module manifest for module 'Shin.Framework.GLB'
#
# Generated by: Bryan M. Longacre
#
# Generated on: 11/22/2016
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Shin.Framework.GLB.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '32dd6936-0684-4196-afba-782ce61b18ae'

# Author of this module
Author = 'Bryan M. Longacre'

# Company or vendor of this module
CompanyName = 'Deloitte'

# Copyright statement for this module
Copyright = '(c) 2016 . All rights reserved.'

# Description of the functionality provided by this module
Description = 'Contains GLB Api Functionality'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('Shin.Framework.Common', 'Shin.Framework.Data')

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('System.Data')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @('api.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @('Shin.Framework.GLB')

# List of all files packaged with this module
# FileList = @('api.ps1', 'Deloitte.GLB.API.dll', 'Deloitte.GLB.API.dll.config')

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
DefaultCommandPrefix = 'Glb'

}
