                                                                                                                                                       <#
	.SYNOPSIS
		Keep KAPE and all the included EZ Tools updated! Be sure to run this script from the root of your KAPE folder, i.e., where kape.exe, gkape.exe, Targets, Modules, and Documentation folders exists
	
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
		OR 
		KAPE-EZToolsAncillaryUpdater.ps1 4
		
		Update KAPE and use .NET 6 version of EZ Tools:
		KAPE-EZToolsAncillaryUpdater.ps1 -netVersion 6
		OR
		KAPE-EZToolsAncillaryUpdater.ps1 6
		
		.CHANGELOG
		1.0 - (Sep 09, 2021) Initial release
		2.0 - (Oct 22, 2021) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which leverages Get-KAPEUpdate.ps1 and Get-ZimmermanTools.ps1 as well as other various --sync commands to keep all of KAPE and the command line EZ Tools updated to their fullest potential with minimal effort. Signed script with certificate.
		3.0 - (Feb 22, 2022) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which gives user option to leverage either the .NET 4 or .NET 6 version of EZ Tools in the .\KAPE\Modules\bin folder. Changed logic so EZ Tools are downloaded using the script from .\KAPE\Modules\bin rather than $PSScriptRoot for cleaner operation and less change for issues. Added changelog. Added logging capabilities.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.201
		Created on:   	2022-02-22 23:29
		Created by:   	Andrew Rathbun
		Organization: 	Kroll Cyber Risk
		Filename:		KAPE-EZToolsAncillaryUpdater.ps1
		GitHub:			https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater
		Version:		3.0
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = '.NET version of EZ Tools (Options: 4 or 6)')]
	[ValidateSet('4', '6')]
	[String]$netVersion
)

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
	Write-Host $msg
}

# Establishes stopwatch to keep track of execution duration of this script

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

$Stopwatch.Start()

Log -logFilePath $logFilePath -msg " --- Beginning of session ---"

Set-ExecutionPolicy Bypass -Scope Process

# Setting variables the script relies on

$kapeModulesBin = "$PSScriptRoot\Modules\bin"

$ZTZipFile = 'Get-ZimmermanTools.zip'

$ZTdlUrl = "https://f001.backblazeb2.com/file/EricZimmermanTools/$ZTZipFile"

<#
	.SYNOPSIS
		Updates the KAPE binary (kape.exe)
	
	.DESCRIPTION
		Uses the preexisting .\Get-KAPEUpdate.ps1 script to update the KAPE binary (kape.exe)
#>
function Get-KAPEUpdateEXE
{
	[CmdletBinding()]
	param ()
	
	if (Test-Path -Path "$PSScriptRoot\Get-KAPEUpdate.ps1")
	{
		Log -logFilePath $logFilePath -msg "Running Get-KAPEUpdate.ps1 to update KAPE to the latest binary"
		& $PSScriptRoot\Get-KAPEUpdate.ps1
	}
	else
	{
		Log -logFilePath $logFilePath -msg "Get-KAPEUpdate.ps1 not found, please go download KAPE from $kapeDownloadUrl"
		Exit
	}
}

<#
	.SYNOPSIS
		Downloads all EZ Tools!
	
	.DESCRIPTION
		Downloads Get-ZimmermanTools.zip, extracts Get-ZimmermanTools.ps1 from the ZIP file into .\KAPE\Modules\bin\ZimmermanTools 
#>
function Get-ZimmermanTools
{
	[CmdletBinding()]
	param ()
	
	if (Test-Path -Path "$kapeModulesBin\Get-ZimmermanTools.ps1")
	{
		
		Log -logFilePath $logFilePath -msg "Get-ZimmermanTools.ps1 already exists! Downloading .NET $netVersion version of EZ Tools to $kapeModulesBin\ZimmermanTools"
		
		& "$kapeModulesBin\Get-ZimmermanTools.ps1" -netVersion $netVersion -Dest $kapeModulesBin\ZimmermanTools
		
		Start-Sleep -Seconds 3
		
	}
	else
	{
		
		Log -logFilePath $logFilePath -msg "Downloading $ZTZipFile from $ZTdlUrl to $kapeModulesBin"
		
		Start-BitsTransfer -Source $ZTdlUrl -Destination $kapeModulesBin
		
		Log -logFilePath $logFilePath -msg "Extracting $ZTZipFile from $kapeModulesBin to $kapeModulesBin"
		
		Expand-Archive -Path "$kapeModulesBin\$ZTZipFile" -DestinationPath "$kapeModulesBin" -Force
		
		Log -logFilePath $logFilePath -msg "Running Get-ZimmermanTools.ps1! Downloading .NET $netVersion version of EZ Tools to $kapeModulesBin\ZimmermanTools"
		
		& "$kapeModulesBin\Get-ZimmermanTools.ps1" -netVersion $netVersion -Dest $kapeModulesBin\ZimmermanTools
		
		Start-Sleep -Seconds 3
		
	}
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest KAPE Targets and Modules!
	
	.DESCRIPTION
		This function will download the latest KAPE Targets and Modules from https://github.com/EricZimmerman/KapeFiles
	
	.NOTES
		Sync works without Admin privileges as of KAPE 1.0.0.3
#>
function Sync-KAPETargetsModules
{
	[CmdletBinding()]
	param ()
	
	if (Test-Path -Path $PSScriptRoot\kape.exe)
	{
		Log -logFilePath $logFilePath -msg "Syncing KAPE with GitHub for the latest Targets and Modules"
		Set-Location $PSScriptRoot
		.\kape.exe --sync
		Start-Sleep -Seconds 3
	}
	else
	{
		Log -logFilePath $logFilePath -msg "kape.exe not found, please go download KAPE from $kapeDownloadUrl"
		Exit
	}
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest EvtxECmd Maps!
	
	.DESCRIPTION
		This function will download the latest EvtxECmd Maps from https://github.com/EricZimmerman/evtx
#>
function Sync-EvtxECmdMaps
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\EvtxECmd\Maps folder so old Maps don't collide with new Maps
	
	Log -logFilePath $logFilePath -msg "Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\EvtxECmd\Maps" -Recurse -Force
	
	# This ensures all the latest EvtxECmd Maps are downloaded
	
	Log -logFilePath $logFilePath -msg "Syncing EvtxECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\EvtxECmd\EvtxECmd.exe" --sync
	
	Start-Sleep -Seconds 3
	
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest RECmd Batch files!
	
	.DESCRIPTION
		This function will download the latest RECmd Batch Files from https://github.com/EricZimmerman/RECmd
#>
function Sync-RECmdBatchFiles
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\RECmd\BatchExamples folder so old Batch files don't collide with new Batch files
	
	Log -logFilePath $logFilePath -msg "Deleting $kapeModulesBin\RECmd\BatchExamples for a fresh start prior to syncing RECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\RECmd\BatchExamples\*" -Recurse -Force
	
	# This ensures all the latest RECmd Batch files are downloaded
	
	Log -logFilePath $logFilePath -msg "Syncing RECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\RECmd\RECmd.exe" --sync
	
	Start-Sleep -Seconds 3
}

<#
	.SYNOPSIS
		Sync with GitHub for the latest SQLECmd Maps!
	
	.DESCRIPTION
		This function will download the latest Maps from https://github.com/EricZimmerman/SQLECmd
#>
function Sync-SQLECmdMaps
{
	[CmdletBinding()]
	param ()
	
	# This deletes the .\KAPE\Modules\bin\SQLECmd\Maps folder so old Maps don't collide with new Maps
	
	Log -logFilePath $logFilePath -msg "Deleting $kapeModulesBin\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"
	
	Remove-Item -Path "$kapeModulesBin\SQLECmd\Maps\*" -Recurse -Force
	
	# This ensures all the latest SQLECmd Maps are downloaded
	
	Log -logFilePath $logFilePath -msg "Syncing SQLECmd with GitHub for the latest Maps"
	
	& "$kapeModulesBin\SQLECmd\SQLECmd.exe" --sync
	
	Start-Sleep -Seconds 3
}

<#
	.SYNOPSIS
		Set up KAPE for use with .NET 4 EZ Tools!
	
	.DESCRIPTION
		Ensures all .NET 4 EZ Tools that were downloaded using Get-ZimmermanTools.ps1 are copied into the correct folders within .\KAPE\Modules\bin
#>
function Move-EZToolsNET4
{
	[CmdletBinding()]
	param ()
	
	# Let's remove files no longer needed if you're switching from .NET 6 to .NET 4 version of EZ Tools
	
	if ((Test-Path -Path $kapeModulesBin\*runtimeconfig.json) -and (Test-Path -Path $kapeModulesBin\*.dll))
	{
		Log -logFilePath $logFilePath -msg ".NET 6 EZ Tools lefovers detected! Removing unnecessary .dll and .json files from $kapeModulesBin"
		Remove-Item -Path $kapeModulesBin\*runtimeconfig.json -Recurse -Force
		Remove-Item -Path $kapeModulesBin\*.dll -Recurse -Force
		Start-Sleep -Seconds 2
	}
	else
	{
		Log -logFilePath $logFilePath -msg "No indication of leftover files from the .NET 6 version of EZ Tools from $kapeModulesBin"
	}
	
	# Copies tools that require subfolders for Maps, Batch Files, etc
	
	Log -logFilePath $logFilePath -msg "Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\EvtxECmd -Destination $kapeModulesBin -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RECmd -Destination $kapeModulesBin -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SQLECmd -Destination $kapeModulesBin -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin successfully"
	
	# Copies tools that don't require subfolders
	
	Log -logFilePath $logFilePath -msg "Copying remaining EZ Tools binaries to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\AmcacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\AppCompatCacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\bstrings.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\JLECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\LECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\MFTECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\PECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RBCmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\RecentFileCacheParser.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SBECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SrumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\SumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\WxTCmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
	
	# This removes the downloaded EZ Tools that we no longer need to reside on disk
	
	& Remove-Item -Path $kapeModulesBin\ZimmermanTools\* -Exclude Get-ZimmermanTools.ps1 -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Removing extra copies of EZ Tools from $kapeModulesBin\ZimmermanTools"
	
	# & Remove-Item -Path $kapeModulesBin\Get-ZimmermanTools.zip -Recurse -Force TODO MAYBE DELETE THIS?
	
	Log -logFilePath $logFilePath -msg "Removed .\KAPE\Modules\bin\ZimmermanTools\Get-ZimmermanTools.zip successfully"
}

<#
	.SYNOPSIS
		Set up KAPE for use with .NET 6 EZ Tools!
	
	.DESCRIPTION
		Ensures all .NET 6 EZ Tools that were downloaded using Get-ZimmermanTools.ps1 are copied into the correct folders within .\KAPE\Modules\bin
#>
function Move-EZToolsNET6
{
	[CmdletBinding()]
	param ()
	
	# Copies tools that require subfolders for Maps, Batch Files, etc
	
	Log -logFilePath $logFilePath -msg "Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
	
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\EvtxECmd -Destination $kapeModulesBin -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\RECmd -Destination $kapeModulesBin -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SQLECmd -Destination $kapeModulesBin -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin successfully"
	
	# Copies tools that don't require subfolders
	
	Log -logFilePath $logFilePath -msg "Copying remaining EZ Tools binaries to $kapeModulesBin"
	
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
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SBECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SrumECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\SumECmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.dll -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.exe -Destination $kapeModulesBin\ -Recurse -Force
	& Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\WxTCmd.runtimeconfig.json -Destination $kapeModulesBin\ -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
	
	# This removes the downloaded EZ Tools that we no longer need to reside on disk
	
	& Remove-Item -Path $kapeModulesBin\ZimmermanTools\net6 -Recurse -Force
	
	Log -logFilePath $logFilePath -msg "Removing extra copies of EZ Tools from $kapeModulesBin\ZimmermanTools"
	
}

# Let's update KAPE first

& Get-KAPEUpdateEXE

# Let's download Get-ZimmermanTools.zip and extract Get-ZimmermanTools.ps1

& Get-ZimmermanTools

# Let's move all EZ Tools and place them into .\KAPE\Modules\bin

if ($netVersion -eq '4')
{
	Move-EZToolsNET4
}

if ($netVersion -eq '6')
{
	Move-EZToolsNET6
}
else
{
	Write-Host "If you're seeing this message, please let Andrew Rathbun know so he can troubleshoot!"
}

& Sync-KAPETargetsModules
& Sync-EvtxECmdMaps
& Sync-RECmdBatchFiles
& Sync-SQLECmdMaps

Log -logFilePath $logFilePath -msg "Thank you for keeping this instance of KAPE updated! Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!"

$stopwatch.stop()

$Elapsed = $stopwatch.Elapsed.TotalSeconds

Log -logFilePath $logFilePath -msg "Total Processing Time: $Elapsed seconds"

Log -logFilePath $logFilePath -msg " --- End of session ---" Out-File $logFilePath -Append

Pause

# SIG # Begin signature block
# MIIpSQYJKoZIhvcNAQcCoIIpOjCCKTYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAw+zyTR2ZDszko
# PJQ5dwsMjOfNLR4s7YLmPReSV2ZPcqCCEgowggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZ1MIIE3aADAgECAhA1nosluv9RC3xO0e22wmkkMA0GCSqG
# SIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYw
# HhcNMjIwMTI3MDAwMDAwWhcNMjUwMTI2MjM1OTU5WjBSMQswCQYDVQQGEwJVUzER
# MA8GA1UECAwITWljaGlnYW4xFzAVBgNVBAoMDkFuZHJldyBSYXRoYnVuMRcwFQYD
# VQQDDA5BbmRyZXcgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBALe0CgT89ev6jRIhHdrp9cdPnRoF5AV3wQdWzNG8JiY4dpN1YVwGLlw8aBos
# m0NIRz2/y/kriL+Jdu/FFakJdpB8l/J+mesliYhN+zj9vFviBjrElMASEBS9DXKa
# UFuqZMGiC6k6yASGfyqF121OkLZ2JImy4a0C43Pd74dbf+/Ae4QHj66otahUBL++
# 7ayba/TJebhRdEq0wFiaxYsZOt18c3LLfAw0fniHfMBZXXJAQhgu1xfgpw7OE4N/
# M5or5VDVQ4ovtSFDVRzRARIF4ibZZqB76Rp5MuI0pMCs74TPN6WdlzGTDBu4pTS0
# 64iGx5hlP+GB5s/w/YW1BDigFV6yaERsbet9G2lsMmNwZtI6zUuGd9HEtd5isz/9
# ENhLcFoaJE7/KK8CL5jt8i9I3Lx+5EOgEwm65eHm45bq63AVKvSHrjisuxX89jWT
# eslKMM/rpw8GMrNBxo9DZvDS4+kCloFKARiwKHJIKpNWUT3T8Kw6Q/ayxUt7TKp+
# cqh0U9YoXLbXIYMpLa5KfOsf21SqfSrhJ+rSEPEBM11uX41T/mQD5sArN9AIPQxp
# 6X7qLckzClylAQgzF2OVHEEi5m2kmb0lvfMOMGQ3BgwQHCRcd65wugzCIipb5KBT
# q+HJLgRWFwYGraxcfsLkkwBY1ssKPaVpAgMDmlWJo6hDoYR9AgMBAAGjggHDMIIB
# vzAfBgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUUwhn
# 1KEy//RT4cMg1UJfMUX5lBcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoGA1UdIARD
# MEEwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGln
# by5jb20vQ1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3Js
# LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5
# BggrBgEFBQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5j
# b20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzAB
# hhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAlBgNVHREEHjAcgRphbmRyZXcuZC5y
# YXRoYnVuQGdtYWlsLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEATPy2wx+JfB71i+UC
# YCOjFFBqrA4kCxsHv3ihLjF4N3g8jb7A156vBangR3BDPQ6lF0YCPwEFE9MQzqG7
# OgkUauX0vfPeuVe8cEadUFlrmb6xCmXsxKdGXObaITeGABz97AzLKxgxRf7xCEKs
# AzvbuaK3lvb3Me9jtRVn9Q69sBTE5I/IDf2PoG/tO/ibPYXC1KpilBNT0A28xMtQ
# 1ijTS0dnbOyTMaUBCZUrNR/9qY2sOBhvxuvSouWjuEazDLTCs6zsMBQH9vfrLoNl
# vEXI5YO9Ck19kT9pZ2rGFO7y8ySRmoVpZvHI29Z4bXBtGUGb2g/RRppid5anuRtN
# +Skr7S1wdrNlhBIYErmCUPH2RPMphN2wmUy6IsDpdTPJkPTmU83q3tpOBGwvyTdx
# hiPIurZMXSDXfUyGB2iiXoyUHP2caVUmsarEb3BgCEf0PT2rO971WCDnG0mMgle2
# Yur4z3eWEsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMYIWlTCCFpECAQEw
# aDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYD
# VQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA1nosluv9R
# C3xO0e22wmkkMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEICev/dIlGQ60oBQVsf90NYf9aE5sR5JltX8q
# HxtVq3s0MA0GCSqGSIb3DQEBAQUABIICACxVqR2Y/k5+s3XZWcLeah01Cs50wAun
# NjVDJmSc1rq8Z5aQ1W1pDMJJYw52SU6a18Pu+s7iQb7tPgL/LP7NPu1jpNAylubk
# X8JdzM5Y707N5JERXPzm0WWqeYfh3WPelAVFxl0p0YP8iqUPZR8cbqdAC64psH13
# wNDDudYRFULkpoqmIsQgzEuLtAOsYqjXbE3F6L7U2gcXnSwnMn5LEMmJw4jskr8/
# YEYkC9PHOhb7h81SsTXY7jp0uln6ZeBE76vBMeS9BCWO0aS8vMyrnsX6Ein75RmP
# 1ZUfs4TkTgloVUpufN97GuZuo/7P9v8ctsltU/QQMWQ4FzZ4YuaLpBHY5G95Bx0I
# hGzVEHst/IxcnB/D4uE7rDmr9Qw7Vwr+6tomNHTAOI+OKCrhcCAWaEYmN35hsUkq
# w6AAzDD2sAsLbQtm7kmzCJcEKywWYNDxTa7dSmslSXn7T5XwgDwXjSTuVnKGpljZ
# t68wipUwPGgGlM05lZ7S8yOa3q42x4ZcxeV2TOB3PkdDD3EZvIQMfpVTtBmQT94f
# 6o00PhwzVP3+y2XuV1t2qTKaN0Kpi5aphCwk3+xve2TzfMBHYByca5LrvtqzVe14
# AvB6YG7UXUMTFZfIqHXP030Tsyjzr/vciAs2vbHSS6JEcZTx8ulPbRi4TzzvN8lq
# Ahjo2StrR7YyoYITgDCCE3wGCisGAQQBgjcDAwExghNsMIITaAYJKoZIhvcNAQcC
# oIITWTCCE1UCAQMxDzANBglghkgBZQMEAgIFADCCAQ0GCyqGSIb3DQEJEAEEoIH9
# BIH6MIH3AgEBBgorBgEEAbIxAgEBMDEwDQYJYIZIAWUDBAIBBQAEIDkyqq4bXM9/
# JwiCAgImAqZ5okk2BRcih1hsEHjohyJ+AhUAryGg/sWcSkmoiPgTytyIzvMAfIIY
# DzIwMjIwMjIyMjMxMzQxWqCBiqSBhzCBhDELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
# EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMP
# U2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1w
# aW5nIFNpZ25lciAjMqCCDfswggcHMIIE76ADAgECAhEAjHegAI/00bDGPZ86SION
# azANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0Ew
# HhcNMjAxMDIzMDAwMDAwWhcNMzIwMTIyMjM1OTU5WjCBhDELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBU
# aW1lIFN0YW1waW5nIFNpZ25lciAjMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAJGHSyyLwfEeoJ7TB8YBylKwvnl5XQlmBi0vNX27wPsn2kJqWRslTOrv
# QNaafjLIaoF9tFw+VhCBNToiNoz7+CAph6x00BtivD9khwJf78WA7wYc3F5Ok4e4
# mt5MB06FzHDFDXvsw9njl+nLGdtWRWzuSyBsyT5s/fCb8Sj4kZmq/FrBmoIgOrfv
# 59a4JUnCORuHgTnLw7c6zZ9QBB8amaSAAk0dBahV021SgIPmbkilX8GJWGCK7/Gs
# zYdjGI50y4SHQWljgbz2H6p818FBzq2rdosggNQtlQeNx/ULFx6a5daZaVHHTqad
# KW/neZMNMmNTrszGKYogwWDG8gIsxPnIIt/5J4Khg1HCvMmCGiGEspe81K9EHJaC
# IpUqhVSu8f0+SXR0/I6uP6Vy9MNaAapQpYt2lRtm6+/a35Qu2RrrTCd9TAX3+CNd
# xFfIJgV6/IEjX1QJOCpi1arK3+3PU6sf9kSc1ZlZxVZkW/eOUg9m/Jg/RAYTZG7p
# 4RVgUKWx7M+46MkLvsWE990Kndq8KWw9Vu2/eGe2W8heFBy5r4Qtd6L3OZU3b05/
# HMY8BNYxxX7vPehRfnGtJHQbLNz5fKrvwnZJaGLVi/UD3759jg82dUZbk3bEg+6C
# viyuNxLxvFbD5K1Dw7dmll6UMvqg9quJUPrOoPMIgRrRRKfM97gxAgMBAAGjggF4
# MIIBdDAfBgNVHSMEGDAWgBQaofhhGSAPw0F3RSiO0TVfBhIEVTAdBgNVHQ4EFgQU
# aXU3e7udNUJOv1fTmtufAdGu3tAwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQC
# MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQAYDVR0gBDkwNzA1BgwrBgEEAbIx
# AQIBAwgwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwRAYD
# VR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNB
# VGltZVN0YW1waW5nQ0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA/BggrBgEFBQcwAoYz
# aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0YW1waW5nQ0Eu
# Y3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAgEASgN4kEIz7Hsagwk2M5hVu51ABjBrRWrxlA4ZUP9bJV474TnE
# W7rplZA3N73f+2Ts5YK3lcxXVXBLTvSoh90ihaZXu7ghJ9SgKjGUigchnoq9pxr1
# AhXLRFCZjOw+ugN3poICkMIuk6m+ITR1Y7ngLQ/PATfLjaL6uFqarqF6nhOTGVWP
# CZAu3+qIFxbradbhJb1FCJeA11QgKE/Ke7OzpdIAsGA0ZcTjxcOl5LqFqnpp23Wk
# PnlomjaLQ6421GFyPA6FYg2gXnDbZC8Bx8GhxySUo7I8brJeotD6qNG4JRwW5sDV
# f2gaxGUpNSotiLzqrnTWgufAiLjhT3jwXMrAQFzCn9UyHCzaPKw29wZSmqNAMBew
# KRaZyaq3iEn36AslM7U/ba+fXwpW3xKxw+7OkXfoIBPpXCTH6kQLSuYThBxN6w21
# uIagMKeLoZ+0LMzAFiPJkeVCA0uAzuRN5ioBPsBehaAkoRdA1dvb55gQpPHqGRuA
# VPpHieiYgal1wA7f0GiUeaGgno62t0Jmy9nZay9N2N4+Mh4g5OycTUKNncczmYI3
# RNQmKSZAjngvue76L/Hxj/5QuHjdFJbeHA5wsCqFarFsaOkq5BArbiH903ydN+Qq
# BtbD8ddo408HeYEIE/6yZF7psTzm0Hgjsgks4iZivzupl1HMx0QygbKvz98wggbs
# MIIE1KADAgECAhAwD2+s3WaYdHypRjaneC25MA0GCSqGSIb3DQEBDAUAMIGIMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMl
# VVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xOTA1MDIw
# MDAwMDBaFw0zODAxMTgyMzU5NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJH
# cmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1Nl
# Y3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGlu
# ZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMgbAa/ZLH6ImX0B
# mD8gkL2cgCFUk7nPoD5T77NawHbWGgSlzkeDtevEzEk0y/NFZbn5p2QWJgn71TJS
# eS7JY8ITm7aGPwEFkmZvIavVcRB5h/RGKs3EWsnb111JTXJWD9zJ41OYOioe/M5Y
# SdO/8zm7uaQjQqzQFcN/nqJc1zjxFrJw06PE37PFcqwuCnf8DZRSt/wflXMkPQEo
# vA8NT7ORAY5unSd1VdEXOzQhe5cBlK9/gM/REQpXhMl/VuC9RpyCvpSdv7QgsGB+
# uE31DT/b0OqFjIpWcdEtlEzIjDzTFKKcvSb/01Mgx2Bpm1gKVPQF5/0xrPnIhRfH
# uCkZpCkvRuPd25Ffnz82Pg4wZytGtzWvlr7aTGDMqLufDRTUGMQwmHSCIc9iVrUh
# cxIe/arKCFiHd6QV6xlV/9A5VC0m7kUaOm/N14Tw1/AoxU9kgwLU++Le8bwCKPRt
# 2ieKBtKWh97oaw7wW33pdmmTIBxKlyx3GSuTlZicl57rjsF4VsZEJd8GEpoGLZ8D
# Xv2DolNnyrH6jaFkyYiSWcuoRsDJ8qb/fVfbEnb6ikEk1Bv8cqUUotStQxykSYtB
# ORQDHin6G6UirqXDTYLQjdprt9v3GEBXc/Bxo/tKfUU2wfeNgvq5yQ1TgH36tjlY
# Mu9vGFCJ10+dM70atZ2h3pVBeqeDAgMBAAGjggFaMIIBVjAfBgNVHSMEGDAWgBRT
# eb9aqitKz1SA4dibwJ3ysgNmyzAdBgNVHQ4EFgQUGqH4YRkgD8NBd0UojtE1XwYS
# BFUwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwEQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGG
# P2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0
# aW9uQXV0aG9yaXR5LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0
# dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNy
# dDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAgEAbVSBpTNdFuG1U4GRdd8DejILLSWEEbKw2yp9KgX1vDsn9Fqg
# uUlZkClsYcu1UNviffmfAO9Aw63T4uRW+VhBz/FC5RB9/7B0H4/GXAn5M17qoBwm
# WFzztBEP1dXD4rzVWHi/SHbhRGdtj7BDEA+N5Pk4Yr8TAcWFo0zFzLJTMJWk1vSW
# Vgi4zVx/AZa+clJqO0I3fBZ4OZOTlJux3LJtQW1nzclvkD1/RXLBGyPWwlWEZuSz
# xWYG9vPWS16toytCiiGS/qhvWiVwYoFzY16gu9jc10rTPa+DBjgSHSSHLeT8AtY+
# dwS8BDa153fLnC6NIxi5o8JHHfBd1qFzVwVomqfJN2Udvuq82EKDQwWli6YJ/9Gh
# lKZOqj0J9QVst9JkWtgqIsJLnfE5XkzeSD2bNJaaCV+O/fexUpHOP4n2HKG1qXUf
# cb9bQ11lPVCBbqvw0NP8srMftpmWJvQ8eYtcZMzN7iea5aDADHKHwW5NWtMe6vBE
# 5jJvHOsXTpTDeGUgOw9Bqh/poUGd/rG4oGUqNODeqPk85sEwu8CgYyz8XBYAqNDE
# f+oRnR4GxqZtMl20OAkrSQeq/eww2vGnL8+3/frQo4TZJ577AWZ3uVYQ4SBuxq6x
# +ba6yDVdM3aO8XwgDCp3rrWiAoa6Ke60WgCxjKvj+QrJVF3UuWp0nr1IrpgxggQt
# MIIEKQIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5j
# aGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0ECEQCMd6AA
# j/TRsMY9nzpIg41rMA0GCWCGSAFlAwQCAgUAoIIBazAaBgkqhkiG9w0BCQMxDQYL
# KoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTIyMDIyMjIzMTM0MVowPwYJKoZI
# hvcNAQkEMTIEMLAPJkt+o8HaTSVpxbztfA5zyt27m/TgAIn8548YEzwEff0DqTPQ
# 0668JA336BTO5zCB7QYLKoZIhvcNAQkQAgwxgd0wgdowgdcwFgQUlRE3EB2ILzG9
# UT+UmtpMaK2MCPUwgbwEFALWW5Xig3DBVwCV+oj5I92Tf62PMIGjMIGOpIGLMIGI
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVy
# c2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UE
# AxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQIQMA9vrN1m
# mHR8qUY2p3gtuTANBgkqhkiG9w0BAQEFAASCAgBNibwhn6CZexE0+xgBlKnK57wV
# 7E7Hx7j1Ylk0vzv6e0eTglqbdck+P3wM/4mwgd+1K8FzeHDnIL2khptyvy09PE9e
# 9bLXKUC0UkLJpykwIbukhwKd60SaB/keKnLqou72KDKQmSMouKThZC57yg4uYp29
# w39ACI5hbveRHZrhjYNXeUCYtqktJvwUdWfY3nr4JZGOzQG6NTgW5R11sILrpndj
# Npt5sUylDJCZZtaABvR4IMygc59u4pFR/dtNEwAIhV5ixD+ZhXXea89TyDPzKYiZ
# hD1HJ9SlSL3S7BGi/3Ga7p6Aw5tduFKse/ja4QFa7kK6U3iFxPujuphw9hrRGZPj
# PEgKpJEEyT3USqojtsajfXEhZOsE7DO9YVyLIZmnx23MBPBHlH2wS//3FWHnfkXa
# pA/FoZ9WqXtYYHIA59x6lFoIOdwVxIf10H+/s0StvSvJqIRwT6PzrccwW56ERtbJ
# CQlyPZKQszbV/KQ8HZOeyuo/38/2wrCtiTYSBe4hpHJyDsz4dbNVbsvOPHBK1ICo
# HKDvILOd6iIojqzHGH4KGORUCD6bl65CzNhBZlIgsGGHRXtSXS3LBWP6js+9fDd+
# rkChiyAodC2wFVS66YfbFvSmmWzQ29KXyIuS+zf9350cT+Ktz0onC8y4uR6nKcKI
# sVII9xsaF5v4TXWpqw==
# SIG # End signature block
