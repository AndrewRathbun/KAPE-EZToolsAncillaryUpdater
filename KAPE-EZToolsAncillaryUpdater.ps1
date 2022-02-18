<#
	.SYNOPSIS
		Keep KAPE and all the included EZ Tools updated!
	
	.DESCRIPTION
		Updates the following:
		
		KAPE binary (.KAPE\kape.exe) - https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape
		KAPE Targets (.\KAPE\Targets\*.tkape) - https://github.com/EricZimmerman/KapeFiles/tree/master/Targets
		KAPE Modules (.\KAPE\Modules\*.mkape) - https://github.com/EricZimmerman/KapeFiles/tree/master/Modules
		RECmd Batch Files (.\KAPE\Modules\bin\RECmd\BatchExamples\*.reb) - https://github.com/EricZimmerman/RECmd/tree/master/BatchExamples
		EvtxECmd Maps (.\KAPE\Modules\bin\EvtxECmd\Maps\*.map) - https://github.com/EricZimmerman/evtx/tree/master/evtx/Maps
		SQLECmd Maps (.\KAPE\Modules\bin\SQLECmd\Maps\*.smap) - https://github.com/EricZimmerman/SQLECmd/tree/master/SQLMap/Maps
	
	.PARAMETER netVersion
		Please specify which .NET version of EZ Tools you want to download. 
		
		Valid parameters: 4 or 6

	.USAGE		
		Update KAPE and use .NET 4 version of EZ Tools:
		KAPE-EZToolsAncillaryUpdater.ps1 -netVersion 4

		Update KAPE and use .NET 6 version of EZ Tools:
		KAPE-EZToolsAncillaryUpdater.ps1 -netVersion 6
	
	.CHANGELOG
		1.0 - (Sep 09, 2021) Initial release
		2.0 - (Oct 22, 2021) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which leverages Get-KAPEUpdate.ps1 and Get-ZimmermanTools.ps1 as well as other various --sync commands to keep all of KAPE and the command line EZ Tools updated to their fullest potential with minimal effort. Signed script with certificate.
		3.0 - Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which gives user option to leverage either the .NET 4 or .NET 6 version of EZ Tools in the .\KAPE\Modules\bin folder. Changed logic so EZ Tools are downloaded using the script from .\KAPE\Modules\bin rather than $PSScriptRoot for cleaner operation and less change for issues. Added changelog.


	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.200
		Created on:   	2022-02-13 23:29
		Created by:   	Andrew Rathbun
		Organization: 	Kroll Cyber Risk
		Filename:		KAPE-EZToolsAncillaryUpdater.ps1
		Version:		3.0
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true)]
	[ValidateSet('4', '6')]
	[ValidateSet]$netVersion
)
# GitHub: https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater
# This script requires Get-KAPEUpdate.ps1 and kape.exe to be present. If you don't have those, download them from here: https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape
# Be sure to run this script from your KAPE root folder, i.e., where kape.exe, gkape.exe, Targets, Modules, and Documentation folders exists

function Get-TimeStamp
{
	return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
}

$logFilePath = "$PSScriptRoot\KAPEUpdateLog.log"
$kapeDownloadUrl = "https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape"

function Log
{
	param ([string]$logFilePath,
		[string]$msg)
	$msg = Write-Output "$(Get-TimeStamp) | $msg"
	Out-File $logFilePath -Append -InputObject $msg -encoding ASCII
}

# Establishes stopwatch to keep track of execution duration of this script

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Log -logFilePath $logFilePath -msg "--- Beginning of session --- |"

Set-ExecutionPolicy Bypass -Scope Process

<#
	.SYNOPSIS
		Downloads the .NET 4 version of EZ Tools
	
	.DESCRIPTION
		Downloads the .NET 4 version of EZ Tools
	
	.EXAMPLE
				PS C:\> Get-EZToolsNET4
	
	.NOTES
		Additional information about the function.
#>

<#
	.SYNOPSIS
		Updates the KAPE binary (kape.exe)
	
	.DESCRIPTION
		A detailed description of the Get-KAPEUpdate function.
	
	.EXAMPLE
				PS C:\> Get-KAPEUpdate
	
	.NOTES
		Additional information about the function.
#>
function Get-KAPEUpdateEXE
{
	[CmdletBinding()]
	param ()
	
	if (Test-Path -Path $PSScriptRoot\Get-KAPEUpdate.ps1)
	{
		Log -logFilePath $logFilePath -msg "| Running Get-KAPEUpdate.ps1 to update KAPE to the latest binary"
		& $PSScriptRoot\Get-KAPEUpdate.ps1
	}
	else
	{
		Log -logFilePath $logFilePath -msg "| Get-KAPEUpdate.ps1 not found, please go download KAPE from $kapeDownloadUrl"
		Exit
	}
}

<#
	.SYNOPSIS
		Downloads all EZ Tools!
	
	.DESCRIPTION
		Downloads Get-ZimmermanTools.zip, extracts Get-ZimmermanTools.ps1 from the ZIP file into .\KAPE\Modules\bin. 
	
	.EXAMPLE
				PS C:\> Get-ZimmermanTools
	
	.NOTES
		Additional information about the function.
#>
function Get-ZimmermanToolsScript
{
	[CmdletBinding()]
	param ()
	
	Log -logFilePath $logFilePath -msg "| Downloading $ZTZipFile from $ZTdlUrl to $kapeModulesBin"
	
	Start-BitsTransfer -Source $ZTdlUrl -Destination $kapeModulesBin
	
	Expand-Archive -Path $kapeModulesBin -DestinationPath $kapeModulesBin -Force -ErrorAction:Stop
}

# Let's update KAPE first

Get-KAPEUpdate

# Setting variables the script relies on

$kapeModulesBin = "$PSScriptRoot\Modules\bin"

$ZTZipFile = 'Get-ZimmermanTools.zip'

$ZTdlUrl = "https://f001.backblazeb2.com/file/EricZimmermanTools/$ZTZipFile"

# Let's download Get-ZimmermanTools.zip and extract Get-ZimmermanTools.ps1

Get-ZimmermanToolsScript

Get-KAPEUpdateEXE

# Download all EZ Tools and place in .\KAPE\Modules\bin

if ($netVersion -eq "4")
{
	
	Get-EZToolsNET4
	
}

elseif ($netVersion -eq "6")
{
	
	Get-EZToolsNET6
	
}


<#
	.SYNOPSIS
		Sync with GitHub for the latest Targets and Modules!
	
	.DESCRIPTION
		This function will download the latest Targets and Modules from https://github.com/EricZimmerman/KapeFiles
	
	.EXAMPLE
				PS C:\> Sync-KAPETargetsModules
	
	.NOTES
		Additional information about the function.
#>
function Sync-KAPETargetsModules
{
	[CmdletBinding()]
	param ()
	
	if (Test-Path -Path $PSScriptRoot\kape.exe)
	{
		Log -logFilePath $logFilePath -msg "| Syncing KAPE with GitHub for the latest Targets and Modules"
		& "$PSScriptRoot\kape.exe" --sync # works without Admin privs as of KAPE 1.0.0.3
	}
	else
	{
		Log -logFilePath $logFilePath -msg "| kape.exe not found, please go download KAPE from $kapeDownloadUrl"
		Exit
	}
}


Sync-KAPETargetsModules

<#
	.SYNOPSIS
		Sync with GitHub for the latest EvtxECmd Maps!
	
	.DESCRIPTION
		This function will download the latest EvtxECmd Maps from https://github.com/EricZimmerman/evtx
	
	.EXAMPLE
				PS C:\> Sync-EvtxECmdMaps
	
	.NOTES
		Additional information about the function.
#>
function Sync-EvtxECmdMaps
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\EvtxECmd\Maps folder so old Maps don't collide with new Maps
	
	Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\EvtxECmd\Maps\*" -Recurse -Force
	
	# This ensures all the latest EvtxECmd Maps are downloaded
	
	Log -logFilePath $logFilePath -msg "| Syncing EvtxECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\EvtxECmd\EvtxECmd.exe" --sync
	
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest RECmd Batch files!
	
	.DESCRIPTION
		This function will download the latest RECmd Batch Files from https://github.com/EricZimmerman/RECmd
	
	.EXAMPLE
				PS C:\> Sync-RECmdBatchFiles
	
	.NOTES
		Additional information about the function.
#>
function Sync-RECmdBatchFiles
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\RECmd\BatchExamples folder so old Batch files don't collide with new Batch files
	
	Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\RECmd\BatchExamples for a fresh start prior to syncing RECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\RECmd\BatchExamples\*" -Recurse -Force
	
	# This ensures all the latest RECmd Batch files are downloaded
	
	Log -logFilePath $logFilePath -msg "| Syncing RECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\RECmd\RECmd.exe" --sync
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest SQLECmd Maps!
	
	.DESCRIPTION
		This function will download the latest Maps from https://github.com/EricZimmerman/SQLECmd

	.EXAMPLE
				PS C:\> Sync-SQLECmdMaps
	
	.NOTES
		Additional information about the function.
#>
function Sync-SQLECmdMaps
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\SQLECmd\Maps folder so old Maps don't collide with new Maps
	
	Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\SQLECmd\Maps\*" -Recurse -Force
	
	# This ensures all the latest SQLECmd Maps are downloaded
	
	Log -logFilePath $logFilePath -msg "| Syncing SQLECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\SQLECmd\SQLECmd.exe" --sync
}

Sync-EvtxECmdMaps

Sync-RECmdBatchFiles

Sync-SQLECmdMaps

function Get-EZToolsNET4
{
	[CmdletBinding()]
	param ()
	
	& Start-Process -FilePath "$kapeModulesBin\Get-ZimmermanTools.ps1" -ArgumentList "$Netversion"
	
	#TODO: Place script here
}

<#
	.SYNOPSIS
		Downloads the .NET 6 version of EZ Tools
	
	.DESCRIPTION
		Downloads the .NET 6 version of EZ Tools
	
	.EXAMPLE
				PS C:\> Get-EZToolsNET4
	
	.NOTES
		Additional information about the function.
#>
function Get-EZToolsNET6
{
	[CmdletBinding()]
	param ()
	
	& Start-Process -FilePath "$kapeModulesBin\Get-ZimmermanTools.ps1" -ArgumentList "$Netversion"
	
	#TODO: Place script here
}




<#
	.SYNOPSIS
		Set up KAPE for use with .NET 6 EZ Tools!
	
	.DESCRIPTION
		blah
	
	.EXAMPLE
				PS C:\> Move-EZToolsNET6
	
	.NOTES
		Additional information about the function.
#>
function Move-EZToolsNET6
{
	[CmdletBinding()]
	param ()
	
	# Copies tools that require subfolders for Maps, Batch Files, etc
	
	Log -logFilePath $logFilePath -msg "| Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\EvtxExplorer -Destination $binPath\EvtxECmd -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RegistryExplorer -Destination $binPath\RECmd -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SQLECmd -Destination $binPath\SQLECmd -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "| Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin successfully"
	
	# Copies tools that don't require subfolders
	
	Log -logFilePath $logFilePath -msg "| Copying remaining EZ Tools binaries to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AmcacheParser.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AmcacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AmcacheParser.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AppCompatCacheParser.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AppCompatCacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\AppCompatCacheParser.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\bstrings.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\bstrings.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\bstrings.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\JLECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\JLECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\JLECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\LECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\LECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\LECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\MFTECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\MFTECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\MFTECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\PECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\PECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\PECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RBCmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RBCmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RBCmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RecentFileCacheParser.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RecentFileCacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RecentFileCacheParser.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SBECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SBECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\ShellBagsExplorer\SBECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
		
	Log -logFilePath $logFilePath -msg "| Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
	
	# need to remove all .net4 tools from here
	
	# This removes GUI tools and other files/folders that the CLI tools don't utilize within the KAPE\Modules\bin folder
	
	Log -logFilePath $logFilePath -msg "| Removing unnecessary files (GUI tools/unused files) from $kapeModulesBin"
	
}

<#
	.SYNOPSIS
		blah
	
	.DESCRIPTION
		blah
	
	.EXAMPLE
				PS C:\> Move-Move-EZToolsNET4
	
	.NOTES
		Additional information about the function.
#>
function Move-EZToolsNET4
{
	[CmdletBinding()]
	param ()
	
	# Copies tools that require subfolders for Maps, Batch Files, etc
	
	Log -logFilePath $logFilePath -msg "| Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\EvtxExplorer -Destination $binPath\EvtxECmd -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RegistryExplorer -Destination $binPath\RECmd -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SQLECmd -Destination $binPath\SQLECmd -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "| Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin successfully"
	
	# Copies tools that don't require subfolders
	
	Log -logFilePath $logFilePath -msg "| Copying remaining EZ Tools binaries to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\AmcacheParser.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\AppCompatCacheParser.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\bstrings.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\JLECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\LECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\MFTECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\PECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RBCmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RecentFileCacheParser.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\ShellBagsExplorer\SBECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SrumECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SumECmd.exe -Destination $binPath\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\WxTCmd.exe -Destination $binPath\ -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "| Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
	
	#need to remove all .net6 tools here
	
	# This removes GUI tools and other files/folders that the CLI tools don't utilize within the KAPE\Modules\bin folder
	
	Log -logFilePath $logFilePath -msg "| Removing unnecessary files (GUI tools/unused files) from $kapeModulesBin"
}




$RECmdBookmarks = "$binPath\RECmd\Bookmarks"
if (Test-Path -Path $RECmdBookmarks)
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\Bookmarks exists! These files are not needed for RECmd and will be deleted"
	Remove-Item -Path $binPath\RECmd\Bookmarks -Recurse -Force
}
else
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\Bookmarks does not exist. No further action needed"
}

$RECmdSettings = "$binPath\RECmd\Settings"
if (Test-Path -Path $RECmdSettings)
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\Settings exists! These files are not needed for RECmd and will be deleted"
	Remove-Item -Path $binPath\RECmd\Settings -Recurse -Force
}
else
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\Settings does not exist. No further action needed"
}

$RECmdRegistryExplorerGUI = "$binPath\RECmd\RegistryExplorer.exe"
if (Test-Path -Path $RECmdRegistryExplorerGUI)
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\RegistryExplorer.exe exists! This is a GUI tool and is not needed"
	Remove-Item -Path $binPath\RECmd\RegistryExplorer.exe -Recurse -Force
}
else
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\RegistryExplorer.exe does not exist. No further action needed"
}

$RECmdRegistryExplorerManual = "$binPath\RECmd\RegistryExplorerManual.pdf"
if (Test-Path -Path $RECmdRegistryExplorerManual)
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\RegistryExplorerManual.pdf exists! This is not needed by KAPE and will be deleted"
	Remove-Item -Path $binPath\RECmd\RegistryExplorerManual.pdf -Recurse -Force
}
else
{
	Log -logFilePath $logFilePath -msg "| .\KAPE\Modules\bin\RECmd\RegistryExplorerManual.pdf does not exist. No further action needed"
}

Log -logFilePath $logFilePath -msg "| Removed unnecessary files (GUI tools/unused files) from .\KAPE\Modules\bin successfully"

# & Remove-Item -Path $PSScriptRoot\ZimmermanTools -Recurse -Force # Remove comment if you want the ZimmermanTools folder to be gone
# Log -logFilePath $logFilePath -msg "| Removed .\KAPE\ZimmermanTools and all its contents successfully"

& Remove-Item -Path $PSScriptRoot\Get-ZimmermanTools.zip -Recurse -Force

Log -logFilePath $logFilePath -msg "| Removed .\KAPE\Get-ZimmermanTools.zip successfully"

Log -logFilePath $logFilePath -msg "| Thank you for keeping this instance of KAPE updated! Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!"


Log -logFilePath $logFilePath -msg "Processing Time:" $stopwatch.Elapsed | Out-File $logFileNamePath -Append
$stopwatch.stop()
Log -logFilePath $logFilePath -msg "Finished | Script completed in " $stopwatch.Elapsed | Out-File $logFileNamePath -Append
Log -logFilePath $logFilePath -msg "--- End of session --- |" Out-File $logFileNamePath -Append

Pause
