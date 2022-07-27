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
        2.0 - (Oct 22, 2021) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which leverages Get-KAPEUpdate.ps1 and Get-ZimmermanTools.ps1 as well as other various --sync commands to keep all of KAPE and the command line EZ Tools updated to their fullest potential with minimal effort. Signed script with certificate
        3.0 - (Feb 22, 2022) Updated version of KAPE-EZToolsAncillaryUpdater PowerShell script which gives user option to leverage either the .NET 4 or .NET 6 version of EZ Tools in the .\KAPE\Modules\bin folder. Changed logic so EZ Tools are downloaded using the script from .\KAPE\Modules\bin rather than $PSScriptRoot for cleaner operation and less chance for issues. Added changelog. Added logging capabilities
        3.1 - (Mar 17, 2022) Added a "silent" parameter that disables the progress bar and exits the script without pausing in the end
        3.2 - (Apr 04, 2022) Updated Move-EZToolNET6 to use glob searching instead of hardcoded folder and file paths
        3.3 - (Apr 25, 2022) Updated Move-EZToolsNET6 to correct Issue #9 - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/9. Also updated content and formatting of some of the comments
        3.4 - (Jun 24, 2022) Added version checker for the script - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/11. Added new messages re: GitHub repositories to follow at the end of each successful run
        3.5 - (Jul 27, 2022) Bug fix for version checker added in 3.4 - https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/pull/15
    
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
        Version:		3.5
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
    
    
    # Only copy if Get-ZimmermanTools.ps1 has downloaded new net6 tools, otherwise continue on.
    if (Test-Path -Path "$kapeModulesBin\ZimmermanTools\net6")
    {
        
        # Copies tools that require subfolders for Maps, Batch Files, etc
        Log -logFilePath $logFilePath -msg "Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin"
        
        # Create array of folders to be copied
        $folders = @(
            "$kapeModulesBin\ZimmermanTools\net6\EvtxECmd",
            "$kapeModulesBin\ZimmermanTools\net6\RECmd",
            "$kapeModulesBin\ZimmermanTools\net6\SQLECmd"
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
                )
                
                # Copy contents of each subfolder
                foreach ($folder in $folders)
                {
                    Copy-Item -Path $folder -Destination $kapeModulesBin -Recurse -Force
                }
                
                Log -logFilePath $logFilePath -msg "Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to $kapeModulesBin successfully"
                
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

