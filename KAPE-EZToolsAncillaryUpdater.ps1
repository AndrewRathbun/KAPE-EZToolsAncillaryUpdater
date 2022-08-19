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
        All other EZ Tools used by KAPE in the !EZParser Module
    
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
        2.0 - (Oct 22, 2021) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which leverages Get-KAPEUpdate.ps1 and Get-ZimmermanTools.ps1 as well as other various --sync commands to keep all of KAPE and the command line EZ Tools updated to their fullest potential with minimal effort. Signed script with certificate
        3.0 - (Feb 22, 2022) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which gives user option to leverage either the .NET 4 or .NET 6 version of EZ Tools in the .\KAPE\Modules\bin folder. Changed logic so EZ Tools are downloaded using the script from .\KAPE\Modules\bin rather than $PSScriptRoot for cleaner operation and less chance for issues. Added changelog. Added logging capabilities
        3.1 - (Mar 17, 2022) Added a "silent" parameter that disables the progress bar and exits the script without pausing in the end
        3.2 - (Apr 04, 2022) Updated Move-EZToolNET6 to use glob searching instead of hardcoded folder and file paths
        3.3 - (Apr 25, 2022) Updated Move-EZToolsNET6 to correct Issue #9 - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/9. Also updated content and formatting of some of the comments
        3.4 - (Jun 24, 2022) Added version checker for the script - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/11. Added new messages re: GitHub repositories to follow at the end of each successful run
        3.5 - (Jul 27, 2022) Bug fix for version checker added in 3.4 - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/pull/15
        3.6 - (Aug 17, 2022) Added iisGeolocate now that a KAPE Module exists for it, updated comments and log messages
    
    .PARAMETER silent
        Disable the progress bar and exit the script without pausing in the end
    
    .NOTES
        ===========================================================================
        Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.201
        Created on:   	2022-02-22 23:29
        Created by:   	Andrew Rathbun
        Organization: 	Kroll
        Filename:		KAPE-EZToolsAncillaryUpdater.ps1
        GitHub:			https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater
        Version:		3.6
        ===========================================================================
#>
param
(
    [Parameter(Mandatory = $true,
               Position = 1,
               HelpMessage = '.NET version of EZ Tools (Options: 4 or 6)')]
    [ValidateSet('4', '6')]
    [String]$netVersion,
    [Parameter(Position = 2,
               HelpMessage = 'Disable the progress bar and exit the script without pausing in the end')]
    [Switch]$silent,
    [Parameter(Position = 3,
               HelpMessage = 'Use this if you do not want to check for and update the script')]
    [Switch]$DoNotUpdate
)

function Get-TimeStamp
{
    return '[{0:yyyy/MM/dd} {0:HH:mm:ss}]' -f (Get-Date)
}

$logFilePath = "$PSScriptRoot\KAPEUpdateLog.log"
$kapeDownloadUrl = 'https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape'
if ($silent)
{
    $ProgressPreference = 'SilentlyContinue'
}

function Log
{
    param ([string]$logFilePath,
        [string]$msg)
    $msg = Write-Output "$(Get-TimeStamp) | $msg"
    Out-File $logFilePath -Append -InputObject $msg -Encoding ASCII
    Write-Host $msg
}

# Establishes stopwatch to keep track of execution duration of this script
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

$Stopwatch.Start()

Log -logFilePath $logFilePath -msg ' --- Beginning of session ---'

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
        Log -logFilePath $logFilePath -msg 'Running Get-KAPEUpdate.ps1 to update KAPE to the latest binary'
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
		Makes sure the Updater is Up-To-Date!

	.DESCRIPTION
		Checks the latest version of this updater and updates if there is a newer version and $NoUpdates is $false
#>
function Get-LatestEZToolsUpdater
{
    [CmdletBinding()]
    param ()
    
    # First check the version of the current script show line number of match
    $currentScriptVersion = Get-Content $('.\KAPE-EZToolsAncillaryUpdater.ps1') | Select-String -SimpleMatch 'Version:' | Select-Object -First 1
    [System.Single]$CurrentScriptVersionNumber = $currentScriptVersion.ToString().Split("`t")[2]
    Log -logFilePath $logFilePath -msg "Current script version is $CurrentScriptVersionNumber"
    
    # Now get the latest version from github
    $webRequest = Invoke-WebRequest -Uri 'https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/releases/latest'
    $strings = $webRequest.RawContent
    $latestVersion = $strings | Select-String -Pattern 'EZToolsAncillaryUpdater/releases/tag/[0-9].[0-9]+' | Select-Object -First 1
    $latestVersionToSplit = $latestVersion.Matches[0].Value
    [System.Single]$LatestVersionNumber = $latestVersionToSplit.Split('/')[-1]
    Log -logFilePath $logFilePath -msg "Latest version of this script is $LatestVersionNumber"
    
    if ($($CurrentScriptVersionNumber -lt $LatestVersionNumber) -and $($NoUpdates -eq $false))
    {
        Log -logFilePath $logFilePath -msg 'Updating script to the latest version'
        
        #Start a new powershell process so we can replace the existing file and run the new script
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Donovoi/KAPE-EZToolsAncillaryUpdater/main/KAPE-EZToolsAncillaryUpdater.ps1' -OutFile "$PSScriptRoot\KAPE-EZToolsAncillaryUpdater.ps1"
        Log -logFilePath $logFilePath -msg "Successfully updated script to $CurrentScriptVersionNumber"
        Log -logFilePath $logFilePath -msg 'Starting updated script in new Window'
        Start-Process PowerShell -ArgumentList "$PSScriptRoot\KAPE-EZToolsAncillaryUpdater.ps1 $netVersion $(if ($PSBoundParameters.Keys.Contains('silent')) { $silent = $true })"
        Log -logFilePath $logFilePath -msg 'Please observe the script in the new window'
        Log -logFilePath $logFilePath -msg 'Exiting old script'
        Exit
    }
    else
    {
        Log -logFilePath $logFilePath -msg 'Script is up-to-date'
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
        Log -logFilePath $logFilePath -msg 'Syncing KAPE with GitHub for the latest Targets and Modules'
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
    Log -logFilePath $logFilePath -msg 'Syncing EvtxECmd with GitHub for the latest Maps'
    
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
    
    # This ensures all the latest RECmd Batch files are present on disk
    Log -logFilePath $logFilePath -msg 'Syncing RECmd with GitHub for the latest Maps'
    
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
    Log -logFilePath $logFilePath -msg 'Syncing SQLECmd with GitHub for the latest Maps'
    
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
    & Copy-Item -Path $kapeModulesBin\ZimmermanTools\iisGeolocate -Destination $kapeModulesBin -Recurse -Force
    
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
    Log -logFilePath $logFilePath -msg 'Removed .\KAPE\Modules\bin\ZimmermanTools\Get-ZimmermanTools.zip successfully'
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
    
    # Only copy if Get-ZimmermanTools.ps1 has downloaded new .NET 6 tools, otherwise continue on.
    if (Test-Path -Path "$kapeModulesBin\ZimmermanTools\net6")
    {
        
        # Copies tools that require subfolders for Maps, Batch Files, etc
        Log -logFilePath $logFilePath -msg "Copying EvtxECmd, RECmd, SQLECmd, iisGeolocate, and all associated ancillary files to $kapeModulesBin"
        
        # Create array of folders to be copied
        $folders = @(
            "$kapeModulesBin\ZimmermanTools\net6\EvtxECmd",
            "$kapeModulesBin\ZimmermanTools\net6\RECmd",
            "$kapeModulesBin\ZimmermanTools\net6\SQLECmd"
            "$kapeModulesBin\ZimmermanTools\net6\iisGeolocate"
        )
        
        # Copy each folder that exists
        $folderSuccess = @()
        foreach ($folder in $folders)
        {
            if (Test-Path -Path $folder)
            {
                Copy-Item -Path $folder -Destination $kapeModulesBin -Recurse -Force
                $folderSuccess += $folder.Split('\')[-1]
            }
            
        }
        # Log only the folders that were copied
        Log -logFilePath $logFilePath -msg "Copied$($folderSuccess.foreach({ ", $PSItem" })) and all associated ancillary files to $kapeModulesBin successfully"
        
        # Copies tools that don't require subfolders
        Log -logFilePath $logFilePath -msg "Copying remaining EZ Tools binaries to $kapeModulesBin"
        
        # Create an array of the files to copy
        $files = @('*.dll', '*.exe', '*.json')
        
        # Copy the files to the destination
        foreach ($file in $files)
        {
            
            # Only copy if Get-ZimmermanTools.ps1 has downloaded new .NET 6 tools, otherwise continue on
            if (Test-Path -Path "$kapeModulesBin\ZimmermanTools\net6")
            {
                Log -logFilePath $logFilePath -msg 'Please ensure you have the latest version of the .NET 6 Runtime installed. You can download it here: https://dotnet.microsoft.com/en-us/download/dotnet/6.0. Please note that the .NET 6 Desktop Runtime includes the Runtime needed for Desktop AND Console applications, aka Registry Explorer AND RECmd, for example'
                
                # Copies tools that require subfolders for Maps, Batch Files, etc
                Log -logFilePath $logFilePath -msg "Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
                
                # Create array of folders for the tools that have dedicated subfolders
                $folders = @(
                    "$kapeModulesBin\ZimmermanTools\net6\EvtxECmd",
                    "$kapeModulesBin\ZimmermanTools\net6\RECmd",
                    "$kapeModulesBin\ZimmermanTools\net6\SQLECmd"
                    "$kapeModulesBin\ZimmermanTools\net6\iisGeolocate"
                )
                
                # Copy contents of each subfolder
                foreach ($folder in $folders)
                {
                    Copy-Item -Path $folder -Destination $kapeModulesBin -Recurse -Force
                }
                
                Log -logFilePath $logFilePath -msg "Copied EvtxECmd, RECmd, SQLECmd, iisGeolocate, and all associated ancillary files to $kapeModulesBin successfully"
                
                # Copies tools that don't require subfolders
                Log -logFilePath $logFilePath -msg "Copying remaining EZ Tools binaries to $kapeModulesBin"
                
                # Create an array of the files to copy
                $files = @('*.dll', '*.exe', '*.json')
                
                # Copy the files to the destination
                foreach ($file in $files)
                {
                    if (Test-Path $kapeModulesBin\ZimmermanTools\net6\$file)
                    {
                        Copy-Item -Path $kapeModulesBin\ZimmermanTools\net6\$file -Destination $kapeModulesBin -Recurse -Force
                    }
                    else
                    {
                        Log -logFilePath $logFilePath -msg "$file not found."
                        Log -logFilePath $logFilePath -msg "If this continues to happen, try deleting $kapeModulesBin\ZimmermanTools\!!!RemoteFileDetails.csv and re-running this script"
                    }
                }
                
                Log -logFilePath $logFilePath -msg "Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
            }
            else
            {
                Log -logFilePath $logFilePath -msg 'No new .NET 6 EZ tools were downloaded. Continuing on.'
            }
            
        }
        
        # This removes the downloaded EZ Tools that we no longer need to reside on disk
        Log -logFilePath $logFilePath -msg "Removing extra copies of EZ Tools from $kapeModulesBin\ZimmermanTools"
        
        Remove-Item -Path $kapeModulesBin\ZimmermanTools\net6 -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Lets make sure this script is up to date
if ($PSBoundParameters.Keys.Contains('DoNotUpdate'))
{
    Write-Host 'Skipping check for updated KAPE-EZToolsAncillaryUpdater.ps1 script because -DoNotUpdate parameter set.'
}
else
{
    Get-LatestEZToolsUpdater
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
elseif ($netVersion -eq '6')
{
    Move-EZToolsNET6
}
else
{
    Write-Host 'Cannot validate whether the .NET version is 4 or 6. Please let Andrew Rathbun know of this message if you see it!'
}

& Sync-KAPETargetsModules
& Sync-EvtxECmdMaps
& Sync-RECmdBatchFiles
& Sync-SQLECmdMaps

Log -logFilePath $logFilePath -msg 'Thank you for keeping this instance of KAPE updated! Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!'
Log -logFilePath $logFilePath -msg 'KapeFiles (Targets/Modules): https://github.com/EricZimmerman/KapeFiles'
Log -logFilePath $logFilePath -msg 'RECmd (RECmd Batch Files): https://github.com/EricZimmerman/RECmd/tree/master/BatchExamples'
Log -logFilePath $logFilePath -msg 'EvtxECmd (EvtxECmd Maps): https://github.com/EricZimmerman/evtx/tree/master/evtx/Maps'
Log -logFilePath $logFilePath -msg 'SQLECmd (SQLECmd Maps): https://github.com/EricZimmerman/SQLECmd/tree/master/SQLMap/Maps'

$stopwatch.stop()

$Elapsed = $stopwatch.Elapsed.TotalSeconds

Log -logFilePath $logFilePath -msg "Total Processing Time: $Elapsed seconds"

Log -logFilePath $logFilePath -msg ' --- End of session ---'

if (-not $silent)
{
    Pause
}


# SIG # Begin signature block
# MIIpGgYJKoZIhvcNAQcCoIIpCzCCKQcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8WiqyS3XaUtmh
# VPFZBVMjbD6/2jzs1uR9HNuXWSgVvKCCEgowggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# Yur4z3eWEsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMYIWZjCCFmICAQEw
# aDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYD
# VQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA1nosluv9R
# C3xO0e22wmkkMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEINbS6wMThhSXayNG6QmVIzYNSWdS3DS5gfFu
# uX8PIFirMA0GCSqGSIb3DQEBAQUABIICAH2dV+t7EcCFUVtFrNX3Fra/ZqEQ8HgC
# fL7MulAKYJc900x3C2rvoOTd8uzYCh8daa04bsRwLsz4K9iCMVIEbnpQW5kJK0B8
# /plbXTxBXUtwpANrrrdIFnbC7VwIsmiu9+KIkP53e3OSdvOKgrOIKju4bdRjT1F4
# owG7KgHVt6KzMDQkXcEWqrBij7ec7Iibp9emgpjkEpu3kl22iPPeeFhfxia5DWfa
# K7yD4+HARZqvTSU0sGBIyfbnWXjmhc5Iqy1OOFYOKekuQmf0rVHpmifl7sPF7OEV
# GfYfBX9XP55bd//Bu3BdE9W7hDk+ce9DlOdfnHiD1aqxG8ZXmHR9WDIAErBXokOT
# Zal4e6a70PDjScFwv5PMD+rYdZ2rg+ruqCXqiHK1VPOHy+tAqaj3IQUj9eAR37w+
# vyEsMvMhig7QXSfDJkGnprv50l+LUN3z4ZjW2hk7ZSjeDxHAxFIDpFlpn1UIR/hl
# xo2HudtgcrU9wgc+WXR0RG6tVH10t7kp9k5dpI5JRr+rULkibS6dTzLw1xCx97b0
# SNxiqEFRZfJ9du6aJ76oT/3mz46LtXDjzZtohiEmnmITEpcErjF0eI5H9XgRHzaE
# SEmoRRQ/0MU1bWd0go7UoOXsDeRYm7vFeHGSVrkndDjcWmTZD9zXa68lN4vutsSo
# gh9OPun9bTgGoYITUTCCE00GCisGAQQBgjcDAwExghM9MIITOQYJKoZIhvcNAQcC
# oIITKjCCEyYCAQMxDzANBglghkgBZQMEAgIFADCB8AYLKoZIhvcNAQkQAQSggeAE
# gd0wgdoCAQEGCisGAQQBsjECAQEwMTANBglghkgBZQMEAgEFAAQgGZCQh4DJGOAL
# O2FlU5mPsHBAPzzi0jilMBZMjXPWItMCFQDUTt1dB/T4346X4/P6jNW/u4f8QRgP
# MjAyMjA4MTcxMjUwMzNaoG6kbDBqMQswCQYDVQQGEwJHQjETMBEGA1UECBMKTWFu
# Y2hlc3RlcjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0
# aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25lciAjM6CCDeowggb2MIIE3qADAgEC
# AhEAkDl/mtJKOhPyvZFfCDipQzANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJH
# QjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3Jk
# MRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNB
# IFRpbWUgU3RhbXBpbmcgQ0EwHhcNMjIwNTExMDAwMDAwWhcNMzMwODEwMjM1OTU5
# WjBqMQswCQYDVQQGEwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMP
# U2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1w
# aW5nIFNpZ25lciAjMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJCy
# cT954dS5ihfMw5fCkJRy7Vo6bwFDf3NaKJ8kfKA1QAb6lK8KoYO2E+RLFQZeaoog
# NHF7uyWtP1sKpB8vbH0uYVHQjFk3PqZd8R5dgLbYH2DjzRJqiB/G/hjLk0NWesfO
# A9YAZChWIrFLGdLwlslEHzldnLCW7VpJjX5y5ENrf8mgP2xKrdUAT70KuIPFvZgs
# B3YBcEXew/BCaer/JswDRB8WKOFqdLacRfq2Os6U0R+9jGWq/fzDPOgNnDhm1fx9
# HptZjJFaQldVUBYNS3Ry7qAqMfwmAjT5ZBtZ/eM61Oi4QSl0AT8N4BN3KxE8+z3N
# 0Ofhl1tV9yoDbdXNYtrOnB786nB95n1LaM5aKWHToFwls6UnaKNY/fUta8pfZMdr
# KAzarHhB3pLvD8Xsq98tbxpUUWwzs41ZYOff6Bcio3lBYs/8e/OS2q7gPE8PWsxu
# 3x+8Iq+3OBCaNKcL//4dXqTz7hY4Kz+sdpRBnWQd+oD9AOH++DrUw167aU1ymeXx
# Mi1R+mGtTeomjm38qUiYPvJGDWmxt270BdtBBcYYwFDk+K3+rGNhR5G8RrVGU2zF
# 9OGGJ5OEOWx14B0MelmLLsv0ZCxCR/RUWIU35cdpp9Ili5a/xq3gvbE39x/fQnuq
# 6xzp6z1a3fjSkNVJmjodgxpXfxwBws4cfcz7lhXFAgMBAAGjggGCMIIBfjAfBgNV
# HSMEGDAWgBQaofhhGSAPw0F3RSiO0TVfBhIEVTAdBgNVHQ4EFgQUJS5oPGuaKyQU
# qR+i3yY6zxSm8eAwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwgwJTAj
# BggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQCMEQG
# A1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JT
# QVRpbWVTdGFtcGluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPwYIKwYBBQUHMAKG
# M2h0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NB
# LmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZI
# hvcNAQEMBQADggIBAHPa7Whyy8K5QKExu7QDoy0UeyTntFsVfajp/a3Rkg18PTag
# adnzmjDarGnWdFckP34PPNn1w3klbCbojWiTzvF3iTl/qAQF2jTDFOqfCFSr/8R+
# lmwr05TrtGzgRU0ssvc7O1q1wfvXiXVtmHJy9vcHKPPTstDrGb4VLHjvzUWgAOT4
# BHa7V8WQvndUkHSeC09NxKoTj5evATUry5sReOny+YkEPE7jghJi67REDHVBwg80
# uIidyCLxE2rbGC9ueK3EBbTohAiTB/l9g/5omDTkd+WxzoyUbNsDbSgFR36bLvBk
# +9ukAzEQfBr7PBmA0QtwuVVfR745ZM632iNUMuNGsjLY0imGyRVdgJWvAvu00S6d
# OHw14A8c7RtHSJwialWC2fK6CGUD5fEp80iKCQFMpnnyorYamZTrlyjhvn0boXzt
# VoCm9CIzkOSEU/wq+sCnl6jqtY16zuTgS6Ezqwt2oNVpFreOZr9f+h/EqH+noUgU
# kQ2C/L1Nme3J5mw2/ndDmbhpLXxhL+2jsEn+W75pJJH/k/xXaZJL2QU/bYZy06LQ
# wGTSOkLBGgP70O2aIbg/r6ayUVTVTMXKHxKNV8Y57Vz/7J8mdq1kZmfoqjDg0q23
# fbFqQSduA4qjdOCKCYJuv+P2t7yeCykYaIGhnD9uFllLFAkJmuauv2AV3Yb1MIIG
# 7DCCBNSgAwIBAgIQMA9vrN1mmHR8qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNl
# eSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMT
# JVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAy
# MDAwMDAwWhcNMzgwMTE4MjM1OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9T
# ZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBp
# bmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9
# AZg/IJC9nIAhVJO5z6A+U++zWsB21hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9Uy
# UnkuyWPCE5u2hj8BBZJmbyGr1XEQeYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzO
# WEnTv/M5u7mkI0Ks0BXDf56iXNc48RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0B
# KLwPDU+zkQGObp0ndVXRFzs0IXuXAZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBg
# frhN9Q0/29DqhYyKVnHRLZRMyIw80xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUX
# x7gpGaQpL0bj3duRX58/Nj4OMGcrRrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1
# IXMSHv2qyghYh3ekFesZVf/QOVQtJu5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0
# bdonigbSlofe6GsO8Ft96XZpkyAcSpcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2f
# A179g6JTZ8qx+o2hZMmIklnLqEbAyfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmL
# QTkUAx4p+hulIq6lw02C0I3aa7fb9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5
# WDLvbxhQiddPnTO9GrWdod6VQXqngwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAU
# U3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8G
# EgRVMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBEGA1UdIAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BB
# hj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNh
# dGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNo
# dHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5j
# cnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZI
# hvcNAQEMBQADggIBAG1UgaUzXRbhtVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/Ra
# oLlJWZApbGHLtVDb4n35nwDvQMOt0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAc
# Jlhc87QRD9XVw+K81Vh4v0h24URnbY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0
# llYIuM1cfwGWvnJSajtCN3wWeDmTk5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbk
# s8VmBvbz1kteraMrQoohkv6ob1olcGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALW
# PncEvAQ2ted3y5wujSMYuaPCRx3wXdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/R
# oZSmTqo9CfUFbLfSZFrYKiLCS53xOV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1
# H3G/W0NdZT1QgW6r8NDT/LKzH7aZlib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurw
# ROYybxzrF06Uw3hlIDsPQaof6aFBnf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQ
# xH/qEZ0eBsambTJdtDgJK0kHqv3sMNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsau
# sfm2usg1XTN2jvF8IAwqd661ogKGuinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMYIE
# LTCCBCkCAQEwgZIwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFu
# Y2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBAhEAkDl/
# mtJKOhPyvZFfCDipQzANBglghkgBZQMEAgIFAKCCAWswGgYJKoZIhvcNAQkDMQ0G
# CyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yMjA4MTcxMjUwMzNaMD8GCSqG
# SIb3DQEJBDEyBDBdJIfwts1Vv09xOTCWdxvrbropev+wPiRPzaH6xon8qkILHohW
# 5ZORsfGgVUZRfBwwge0GCyqGSIb3DQEJEAIMMYHdMIHaMIHXMBYEFKs0ATqsQJcx
# nwga8LMY4YP4D3iBMIG8BBQC1luV4oNwwVcAlfqI+SPdk3+tjzCBozCBjqSBizCB
# iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0pl
# cnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNV
# BAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkCEDAPb6zd
# Zph0fKlGNqd4LbkwDQYJKoZIhvcNAQEBBQAEggIAHtjCCbC0p4xIQqnGzXOmkkvY
# heYfWnkeXmJu6bGHZn9foupx7rwtQuGVdegISz03h43MjF0YNe4ezOTeVDQVpabF
# 1yJEuOYLbojHQSQNKwMwuqLgohEWgT430bce/aLnP619MrP8qmePPXGTuj1VzciY
# MizVMX7FjfRcwnIq5ztfq+LPTeca2g73MXPoHwVp+ZuJ1QevTzal4ASiFQ105LLU
# uU3ZMiYhLSt3ha/4GxqheGKRfMG6u8WnGkVj1CZnsA6jVaobULkEOzqzKjWIkJf9
# w87/+W+x2kGaEq5MEAf9kec0z/QWOicp2QttuWKW6GMQEAoN1oJEp3Ju02HGg5yD
# /mnNCLsMFsVj6ludlNzbTIoY0Lhkcgo5DrskFfpFUWPhaGUs5infSlfE4TiPTb4a
# hAJbUVppY3lIiVuZfJc8Xb/YEzjte9uRdtkwHG5cVZpGTVB6xYj4YqsesS/bi0ET
# SC1WAOaRauzOIXslrcM7U3lAY0ILsR/Hz5kF3RK2eljAlglf14jwgMR3cbRpFWJp
# OTXSUSuojohp8zoLuf6SjHagDB2tNZb6MFRFX/eWuEesD8UHHR085cTZv6OaE5k/
# CEJU3jdV/YiawyRujJQGwJhQ7gVLleHahFJ7FT14bxckuMpk7ILS4HnidgecqYdt
# lIpPso97HB27JK35GjE=
# SIG # End signature block
