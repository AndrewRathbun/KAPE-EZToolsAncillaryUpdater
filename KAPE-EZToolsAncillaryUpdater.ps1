<#
	.SYNOPSIS
		Keep KAPE and all the tools that make it work updated!
	
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
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.200
		Created on:   	2022-02-13 23:29
		Created by:   	Andrew Rathbun
		Organization: 	Kroll Cyber Risk
		Filename:
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
function Get-EZToolsNET4
{
	[CmdletBinding()]
	param ()
	
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
	
	#TODO: Place script here
}






if (Test-Path -Path $PSScriptRoot\Get-KAPEUpdate.ps1)
{
	Log -logFilePath $logFilePath -msg "| Running Get-KAPEUpdate.ps1 to update KAPE to the latest binary"
	.\Get-KAPEUpdate.ps1
}
else
{
	Log -logFilePath $logFilePath -msg "| Get-KAPEUpdate.ps1 not found, please go download KAPE from $kapeDownloadUrl"
	Exit
}

# Setting variables the script relies on

$kapeModulesBin = "$PSScriptRoot\Modules\bin"

$ZTZipFile = 'Get-ZimmermanTools.zip'

$ZTdlUrl = "https://f001.backblazeb2.com/file/EricZimmermanTools/$ZTZipFile"

# Download Get-ZimmermanTools.zip and extract from archive

Log -logFilePath $logFilePath -msg "| Downloading $ZTZipFile from $ZTdlUrl to $kapeModulesBin"

Start-BitsTransfer -Source $ZTdlUrl -Destination $kapeModulesBin

Expand-Archive -Path $kapeModulesBin -DestinationPath $kapeModulesBin -Force -ErrorAction:Stop

# Download all EZ Tools and place in .\KAPE\Modules\bin

if ($netVersion -eq "4")
{
	
	Get-EZToolsNET4
	
}

elseif ($netVersion -eq "6")
{
	
	Get-EZToolsNET6
	
}


& Start-Process -FilePath "$kapeModulesBin\Get-ZimmermanTools.ps1" -ArgumentList "$Netversion"

# This ensures all the latest KAPE Targets and Modules are downloaded

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


# This deletes the .\KAPE\Modules\bin\EvtxECmd\Maps folder so old Maps don't collide with new Maps

Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"

Remove-Item -Path "$kapeModulesBin\EvtxECmd\Maps\*" -Recurse -Force

# This ensures all the latest EvtxECmd Maps are downloaded

Log -logFilePath $logFilePath -msg "| Syncing EvtxECmd with GitHub for the latest Maps"

& "$kapeModulesBin\EvtxECmd\EvtxECmd.exe" --sync

# This deletes the .\KAPE\Modules\bin\RECmd\BatchExamples folder so old Batch files don't collide with new Batch files

Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\RECmd\BatchExamples for a fresh start prior to syncing RECmd with GitHub"

Remove-Item -Path "$kapeModulesBin\RECmd\BatchExamples\*" -Recurse -Force

# This ensures all the latest RECmd Batch files are downloaded

Log -logFilePath $logFilePath -msg "| Syncing RECmd with GitHub for the latest Maps"

& "$kapeModulesBin\RECmd\RECmd.exe" --sync

# This deletes the .\KAPE\Modules\bin\SQLECmd\Maps folder so old Maps don't collide with new Maps

Log -logFilePath $logFilePath -msg "| Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"

Remove-Item -Path "$kapeModulesBin\SQLECmd\Maps\*" -Recurse -Force

# This ensures all the latest SQLECmd Maps are downloaded

Log -logFilePath $logFilePath -msg "| Syncing SQLECmd with GitHub for the latest Maps"

& "$kapeModulesBin\SQLECmd\SQLECmd.exe" --sync

# Copies tools that require subfolders for Maps, Batch Files, etc

Log -logFilePath $logFilePath -msg "| Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin"

& Copy-Item -Path $PSScriptRoot\ZimmermanTools\EvtxExplorer -Destination $binPath\EvtxECmd -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\RegistryExplorer -Destination $binPath\RECmd -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\SQLECmd -Destination $binPath\SQLECmd -Recurse -Force

Log -logFilePath $logFilePath -msg "| Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin successfully"

# Copies tools that don't require subfolders

Log -logFilePath $logFilePath -msg "| Copying remaining EZ Tools binaries to .\KAPE\Modules\bin"

& Copy-Item -Path $PSScriptRoot\ZimmermanTools\AmcacheParser.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\AppCompatCacheParser.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\bstrings.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\JLECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\LECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\MFTECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\PECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\RBCmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\RecentFileCacheParser.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\ShellBagsExplorer\SBECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\SrumECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\SumECmd.exe -Destination $binPath\ -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\WxTCmd.exe -Destination $binPath\ -Recurse -Force

Log -logFilePath $logFilePath -msg "| Copied remaining EZ Tools binaries to .\KAPE\Modules\bin successfully"

# This removes GUI tools and other files/folders that the CLI tools don't utilize within the KAPE\Modules\bin folder

Log -logFilePath $logFilePath -msg "| Removing unnecessary files (GUI tools/unused files) from .\KAPE\Modules\bin"

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
