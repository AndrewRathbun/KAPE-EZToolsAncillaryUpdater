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
        Version:		3.4
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

# SIG # Begin signature block
# MIIpGQYJKoZIhvcNAQcCoIIpCjCCKQYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB5sPEY3U0Bj2eN
# KfZk0lHoXPSwhSRQSqyigUr6DUEmFaCCEgowggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# Yur4z3eWEsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMYIWZTCCFmECAQEw
# aDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYD
# VQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA1nosluv9R
# C3xO0e22wmkkMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIAn6ca1rR+o1BKSTLILKPzMmPPYd5PwmFoA1
# 9SsN4mPaMA0GCSqGSIb3DQEBAQUABIICAB5PFp/VA0Kluwj6JmOqoB6B3f16kJG+
# Q0wYxCe9QDhxOVnPzKp8tdQSMbFbQ2UQ1/kgJp/PI2jvpoZtW1lr5yeS45g8bXa5
# 1Vl21bt3z6LfWBf3k1OD32O+Y9qFMNsRJJ2yu/P0rXwCs5I/xxGpxayDaN//TFQz
# n4JiDvGR7yDsIA06Bn2AvwXf+2EvkmeGuggLg4Ez+YaKfdm2sBCIT7780cDth66y
# bIOjV3914UGe3iS+bllajk7/WrZSVlMmThTDwpek5As1gigrTYihwVUnEC2dc2Nq
# bQGOvXSo01pTjx1Jz5BLf5WWw4KRXpQgeCRj07AOrgTFGe+lEKelz/uYoBFvgERa
# +wVFkRCJOIsG6TQk2JmeYcEciqfHTa133rFKsPxa0YWuBvC/WG3hclc+VXqco85C
# i1GSmOj3yZikGFMdqwQo5yA/feKiLTE3CNomv4Kg76JfxLY8tanKQ2DaARWs+S5Z
# xpN5A8eMLMnmV004m/2uaMh1Ov7o/TLYjaJm8EBEYmsIubM0+F8F3oAZLQ44ZSzb
# f4sMvFI85p64JSzBwzIxHdIC9ALYDaXAQtE8aAf4zxvbQal+9Q4beUI2QnZXQIMm
# JQVIxPWG9UR68omwkgariyg1/UkoyFXVWa46WQ2OAZlWzji+zM1I5T2BabWiVhy+
# fTxKjbw8mZzEoYITUDCCE0wGCisGAQQBgjcDAwExghM8MIITOAYJKoZIhvcNAQcC
# oIITKTCCEyUCAQMxDzANBglghkgBZQMEAgIFADCB7wYLKoZIhvcNAQkQAQSggd8E
# gdwwgdkCAQEGCisGAQQBsjECAQEwMTANBglghkgBZQMEAgEFAAQggL91MnwR5YKd
# tAKUMLLLMSoo68so2o6sKeKBykX3OeYCFF48gvW9ADpDaZ2rr4XE5UHhI0K3GA8y
# MDIyMDcyNzExNTA0NlqgbqRsMGoxCzAJBgNVBAYTAkdCMRMwEQYDVQQIEwpNYW5j
# aGVzdGVyMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMMI1NlY3Rp
# Z28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICMzoIIN6jCCBvYwggTeoAMCAQIC
# EQCQOX+a0ko6E/K9kV8IOKlDMA0GCSqGSIb3DQEBDAUAMH0xCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0Eg
# VGltZSBTdGFtcGluZyBDQTAeFw0yMjA1MTEwMDAwMDBaFw0zMzA4MTAyMzU5NTla
# MGoxCzAJBgNVBAYTAkdCMRMwEQYDVQQIEwpNYW5jaGVzdGVyMRgwFgYDVQQKEw9T
# ZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMMI1NlY3RpZ28gUlNBIFRpbWUgU3RhbXBp
# bmcgU2lnbmVyICMzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkLJx
# P3nh1LmKF8zDl8KQlHLtWjpvAUN/c1oonyR8oDVABvqUrwqhg7YT5EsVBl5qiiA0
# cXu7Ja0/WwqkHy9sfS5hUdCMWTc+pl3xHl2AttgfYOPNEmqIH8b+GMuTQ1Z6x84D
# 1gBkKFYisUsZ0vCWyUQfOV2csJbtWkmNfnLkQ2t/yaA/bEqt1QBPvQq4g8W9mCwH
# dgFwRd7D8EJp6v8mzANEHxYo4Wp0tpxF+rY6zpTRH72MZar9/MM86A2cOGbV/H0e
# m1mMkVpCV1VQFg1LdHLuoCox/CYCNPlkG1n94zrU6LhBKXQBPw3gE3crETz7Pc3Q
# 5+GXW1X3KgNt1c1i2s6cHvzqcH3mfUtozlopYdOgXCWzpSdoo1j99S1ryl9kx2so
# DNqseEHeku8Pxeyr3y1vGlRRbDOzjVlg59/oFyKjeUFiz/x785LaruA8Tw9azG7f
# H7wir7c4EJo0pwv//h1epPPuFjgrP6x2lEGdZB36gP0A4f74OtTDXrtpTXKZ5fEy
# LVH6Ya1N6iaObfypSJg+8kYNabG3bvQF20EFxhjAUOT4rf6sY2FHkbxGtUZTbMX0
# 4YYnk4Q5bHXgHQx6WYsuy/RkLEJH9FRYhTflx2mn0iWLlr/GreC9sTf3H99Ce6rr
# HOnrPVrd+NKQ1UmaOh2DGld/HAHCzhx9zPuWFcUCAwEAAaOCAYIwggF+MB8GA1Ud
# IwQYMBaAFBqh+GEZIA/DQXdFKI7RNV8GEgRVMB0GA1UdDgQWBBQlLmg8a5orJBSp
# H6LfJjrPFKbx4DAOBgNVHQ8BAf8EBAMCBsAwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEBAgEDCDAlMCMG
# CCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBBAIwRAYD
# VR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNB
# VGltZVN0YW1waW5nQ0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA/BggrBgEFBQcwAoYz
# aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0YW1waW5nQ0Eu
# Y3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAgEAc9rtaHLLwrlAoTG7tAOjLRR7JOe0WxV9qOn9rdGSDXw9NqBp
# 2fOaMNqsadZ0VyQ/fg882fXDeSVsJuiNaJPO8XeJOX+oBAXaNMMU6p8IVKv/xH6W
# bCvTlOu0bOBFTSyy9zs7WrXB+9eJdW2YcnL29wco89Oy0OsZvhUseO/NRaAA5PgE
# drtXxZC+d1SQdJ4LT03EqhOPl68BNSvLmxF46fL5iQQ8TuOCEmLrtEQMdUHCDzS4
# iJ3IIvETatsYL254rcQFtOiECJMH+X2D/miYNOR35bHOjJRs2wNtKAVHfpsu8GT7
# 26QDMRB8Gvs8GYDRC3C5VV9HvjlkzrfaI1Qy40ayMtjSKYbJFV2Ala8C+7TRLp04
# fDXgDxztG0dInCJqVYLZ8roIZQPl8SnzSIoJAUymefKithqZlOuXKOG+fRuhfO1W
# gKb0IjOQ5IRT/Cr6wKeXqOq1jXrO5OBLoTOrC3ag1WkWt45mv1/6H8Sof6ehSBSR
# DYL8vU2Z7cnmbDb+d0OZuGktfGEv7aOwSf5bvmkkkf+T/FdpkkvZBT9thnLTotDA
# ZNI6QsEaA/vQ7ZohuD+vprJRVNVMxcofEo1XxjntXP/snyZ2rWRmZ+iqMODSrbd9
# sWpBJ24DiqN04IoJgm6/4/a3vJ4LKRhogaGcP24WWUsUCQma5q6/YBXdhvUwggbs
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
# ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0ECEQCQOX+a
# 0ko6E/K9kV8IOKlDMA0GCWCGSAFlAwQCAgUAoIIBazAaBgkqhkiG9w0BCQMxDQYL
# KoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTIyMDcyNzExNTA0NlowPwYJKoZI
# hvcNAQkEMTIEMKTXc28W0z7YEip19ZDvdRXITEnZsOb7hWf+10Y++O7bBW626DBj
# ntXCw78Zj8270jCB7QYLKoZIhvcNAQkQAgwxgd0wgdowgdcwFgQUqzQBOqxAlzGf
# CBrwsxjhg/gPeIEwgbwEFALWW5Xig3DBVwCV+oj5I92Tf62PMIGjMIGOpIGLMIGI
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVy
# c2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UE
# AxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQIQMA9vrN1m
# mHR8qUY2p3gtuTANBgkqhkiG9w0BAQEFAASCAgBDiXs030GKCw9GMKmDWYbj8d7X
# u2EO4V9n9tLJM6g2q5X2csLDcF3CgfsFYGgudsqn8jq/u5Q14ytHAwH8aPxesLMd
# DMJ4U86Dl1pKDxPC1SieVVuU9eqMyEo0io4ufBLKeDoEu+RMdbr+ZJqQveXsqk6J
# ntFnoV2im2E0lF1ElNMhDdq5mDhStQuX84uPa/VkiVNKJ27mEFzLeCuhLZef6Tuc
# N7ZFnzFIzivEay88CSni6xmc4ydHPcy6m6h2/HoHv3bVth1Y4U27XLlsbUgUGHlD
# C9v9zf6OWk3q1zL9DmdjWHSuYkPzcuGbvQg0uhZzq5ZqDK3bnQ4s5RU3q86NDKKT
# NwYroBxDq++dNcqw1MYmAQ+xzs7+vNVZlDguiYwfmZjKZ5sfINeSiBxoiLvDg8Dm
# cWuWa/BE+Df5pJit0cy24vuZxT/92ja9CIORE3+qHx+cno5yrxupRciIchBhkP89
# 09qPD9Tzt+oErSRgJm1Y5WzWKn5HlclGVBjt4PHj1laMza70z/o9q1JmhVx7W7QJ
# 4fXbjF4TrL3RhG4sQAdiv0bGCd3tbQYcxZXw/vyqrtTCgUkkLC88faqS0kr+nxPp
# tZZu1eVdjtCcxVRUbl9Z/rbQltbWEDnTtWIK55MuSuMRruZGcN0o8XPCzIxYTGvu
# l9xqWJHjYYmFzO9YPw==
# SIG # End signature block
