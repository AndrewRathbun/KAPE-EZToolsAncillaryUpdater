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
		
		.USAGE
		As of 4.0, this script will only download .NET 6 tools, so you can just run the script in your .\KAPE folder!
		
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
		4.0 - (June 13, 2023) Made adjustments to script based on Get-ZimmermanTools.ps1 update - https://github.com/EricZimmerman/Get-ZimmermanTools/commit/c40e8ddc8df5a210c5d9155194e602a81532f23d, script now defaults to .NET 6, modifed lots of comments, variables, etc, and overall made the script more readable and maintainable
		4.1 - (June 16, 2023) Minor adjustments based on feedback from version 4.0. Additionally, added script info to the log output
		4.2 - (August 04, 2023) Added PowerShell 5 requirement to avoid any potential complications
		4.3 - (January 25, 2025) Added netVersion parameter, with options for .NET 6 or .NET 9 tools, with a default to .NET 9. Simplify and consolidate GitHub sync functions.
	
	.PARAMETER silent
		Disable the progress bar and exit the script without pausing in the end
	
	.PARAMETER DoNotUpdate
		Use this if you do not want to check for and update the script
	
	.PARAMETER net
		Provide the .NET version of EZ Tools you want to download. Please note, 0 (all versions) and 4 are not options due to not needing ALL versions of EZ Tools, and frankly, .NET 4 versions of EZ Tools should be your last resort, (I.E. running them on a version of Windows that doesn't support .NET 6 or .NET 9)
	
	.NOTES
		===========================================================================
		Created with:	 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.201
		Created on:   		2022-02-22 23:29
		Created by:	   		Andrew Rathbun
		Filename:			KAPE-EZToolsAncillaryUpdater.ps1
		GitHub:				https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater
		Version:			4.3
		===========================================================================
#>
param
(
	[Parameter(HelpMessage = 'Disable the progress bar and exit the script without pausing in the end')]
	[Switch]$silent,
	[Parameter(HelpMessage = 'Use this if you do not want to check for and update the script')]
	[Switch]$DoNotUpdate,
	[ValidateSet('6', '9')]
	[string]$net = '9'
)

function Get-TimeStamp
{
	return '[{0:yyyy/MM/dd} {0:HH:mm:ss}]' -f (Get-Date)
}

function Log
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$logFilePath,
		[string]$msg
	)
	
	if ([string]::IsNullOrWhiteSpace($logFilePath))
	{
		Log -logFilePath $logFilePath -msg "Error: logFilePath parameter is null or empty"
		return
	}
	
	$msg = Write-Output "$(Get-TimeStamp) | $msg"
	Out-File $logFilePath -Append -InputObject $msg -Encoding ASCII
	Write-Host $msg
}

$script:logFilePath = Join-Path $PSScriptRoot -ChildPath "KAPEUpdateLog.log"

if ($silent)
{
	$ProgressPreference = 'SilentlyContinue'
}

function Start-Script
{
	[CmdletBinding()]
	param ()
	
	# Establishes stopwatch to keep track of execution duration of this script
	$script:stopwatch = [system.diagnostics.stopwatch]::StartNew()
	
	$Stopwatch.Start()
	
	Log -logFilePath $logFilePath -msg ' --- Beginning of session ---' # start of Log
	
	Set-ExecutionPolicy Bypass -Scope Process
	
	# Let's get some script info and provide it to the end user for the purpose of the log
	# establish name of script to pass to Log-ToFile Module, so it outputs to the correctly named log file
	$scriptPath = $PSCommandPath
	
	$scriptNameWithoutExtension = (Split-Path -Path $scriptPath -Leaf).TrimEnd('.ps1') # this isn't currently used
	$scriptName = Split-Path -Path $scriptPath -Leaf
	
	$fileInfo = Get-Item $scriptPath
	$fileSizeInBytes = $fileInfo.Length
	$fileSizeInMegabytes = $fileSizeInBytes / 1MB
	
	$signature = Get-AuthenticodeSignature $scriptPath
	
	if ($signature -and $signature.SignerCertificate)
	{
		$lastSignedTime = $signature.SignerCertificate.NotAfter
	}
	else
	{
		$lastSignedTime = "Invalid or not signed"
	}
	
	$fileHash = (Get-FileHash -Path $scriptPath -Algorithm SHA1).Hash
	
	$fileSizeFormatted = "{0:N2}" -f $fileSizeInMegabytes
	
	# Output all of the above stats about this script. Examples are in comments at end of each line
	Log -logFilePath $logFilePath -msg "Script Name: $scriptName" # [2023-06-13 22:23:13] | Script Name: KAPE-EZToolsAncillaryUpdater.ps1
	Log -logFilePath $logFilePath -msg "Full Path: $scriptPath" # [2023-06-13 22:23:13] | Full Path: D:\KAPE-EZToolsAncillaryUpdater\KAPE-EZToolsAncillaryUpdater.ps1
	Log -logFilePath $logFilePath -msg "Last Modified Date: $($fileInfo.LastWriteTime)" # [2023-06-13 22:23:13] | Last Modified Date: 06/13/2023 22:23:07
	Log -logFilePath $logFilePath -msg "File Size: $fileSizeInBytes bytes | $fileSizeFormatted MB" # [2023-06-13 22:23:13] | File Size: 43655 bytes | 0.04 MB
	Log -logFilePath $logFilePath -msg "Certificate Expiration: $lastSignedTime" # [2023-06-13 22:23:13] | Certificate Expiration: 01/26/2025 18:59:59
	Log -logFilePath $logFilePath -msg "SHA1 Hash: $fileHash" # [2023-06-13 22:23:13] | SHA1 Hash: A9E7D1DB7A8C41B9424DEC57297CC9E6
	Log -logFilePath $logFilePath -msg "--------- Script Log ---------"
	
	# Validate that logFilePath exists and shoot a message to the user one way or another
	try
	{
		if (!(Test-Path -Path $logFilePath))
		{
			New-Item -ItemType File -Path $logFilePath -Force | Out-Null
			Log -logFilePath $logFilePath -msg "Created new log file at $logFilePath"
		}
		else
		{
			Log -logFilePath $logFilePath -msg "Log file already exists at $logFilePath"
		}
	}
	catch
	{
		Write-Host $_.Exception.Message
	}
}

function Set-Variables
{
	[CmdletBinding()]
	param ()
	
	# Setting variables the script relies on. Comments show expected values stored within each respective variable
	$script:kapeTargetsFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Targets' # .\KAPE\Targets
	$script:kapeModulesFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Modules' # .\KAPE\Modules
	$script:kapeModulesBin = Join-Path -Path $kapeModulesFolder -ChildPath 'bin' # .\KAPE\Modules\bin
	$script:getZimmermanToolsFolderKape = Join-Path -Path $kapeModulesBin -ChildPath 'ZimmermanTools' # .\KAPE\Modules\bin\ZimmermanTools, also serves as our .NET 4 folder, if needed
	if ($net = '6')
	{
		$script:dotNetText = '.NET 6'
		$script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net6' # .\KAPE\Modules\bin\ZimmermanTools\net6
	}
	elseif ($net = '9')
	{
		$script:dotNetText = '.NET 9'
		$script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net9' # .\KAPE\Modules\bin\ZimmermanTools\net9
	}
	
	$script:ZTZipFile = 'Get-ZimmermanTools.zip'
	$script:ZTdlUrl = "https://f001.backblazeb2.com/file/EricZimmermanTools/$ZTZipFile" # https://f001.backblazeb2.com/file/EricZimmermanTools\Get-ZimmermanTools.zip
	$script:getZimmermanToolsFolderKapeZip = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath $ZTZipFile # .\KAPE\Modules\bin\ZimmermanTools\Get-ZimmermanTools.zip - this currently doesn't get used...
	$script:kapeDownloadUrl = 'https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape'
	$script:kapeEzToolsAncillaryUpdaterFileName = 'KAPE-EZToolsAncillaryUpdater.ps1'
	$script:getZimmermanToolsFileName = 'Get-ZimmermanTools.ps1'
	$script:getKapeUpdatePs1FileName = 'Get-KAPEUpdate.ps1'
	$script:kape = Join-Path -Path $PSScriptRoot -ChildPath 'kape.exe' # .\KAPE\kape.exe
	$script:getZimmermanToolsZipKape = Join-Path -Path $kapeModulesBin -ChildPath $ZTZipFile # .\KAPE\Modules\bin\Get-ZimmermanTools.zip
	$script:getZimmermanToolsPs1Kape = Join-Path -Path $kapeModulesBin -ChildPath $getZimmermanToolsFileName # .\KAPE\Modules\bin\Get-ZimmermanTools.ps1
	
	# setting variables for EZ Tools binaries, folders, and folders containing ancillary files within .\KAPE\Modules\bin
	$script:kapeRecmd = Join-Path $kapeModulesBin -ChildPath 'RECmd' #.\KAPE\Modules\bin\RECmd
	$script:kapeRecmdExe = Get-ChildItem $kapeRecmd -Filter 'RECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName #.\KAPE\Modules\bin\RECmd\RECmd.exe
	$script:kapeRecmdBatchExamples = Join-Path $kapeRecmd -ChildPath 'BatchExamples' #.\KAPE\Modules\bin\RECmd\BatchExamples
	$script:kapeEvtxECmd = Join-Path $kapeModulesBin -ChildPath 'EvtxECmd' #.\KAPE\Modules\bin\EvtxECmd
	$script:kapeEvtxECmdExe = Get-ChildItem $kapeEvtxECmd -Filter 'EvtxECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName #.\KAPE\Modules\bin\EvtxECmd\EvtxECmd.exe
	$script:kapeEvtxECmdMaps = Join-Path $kapeEvtxECmd -ChildPath 'Maps' #.\KAPE\Modules\bin\EvtxECmd\Maps
	$script:kapeSQLECmd = Join-Path $kapeModulesBin -ChildPath 'SQLECmd' #.\KAPE\Modules\bin\SQLECmd
	$script:kapeSQLECmdExe = Get-ChildItem $kapeSQLECmd -Filter 'SQLECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName #.\KAPE\Modules\bin\SQLECmd\SQLECmd.exe
	$script:kapeSQLECmdMaps = Join-Path $kapeSQLECmd -ChildPath 'Maps' #.\KAPE\Modules\bin\SQLECmd\Maps
}

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
	
	Log -logFilePath $logFilePath -msg ' --- Update KAPE ---'
	
	$script:getKapeUpdatePs1 = Get-ChildItem -Path $PSScriptRoot -Filter $getKapeUpdatePs1FileName # .\KAPE\Get-KAPEUpdate.ps1
	
	if ($null -ne $getKapeUpdatePs1)
	{
		Log -logFilePath $logFilePath -msg "Running $getKapeUpdatePs1FileName to update KAPE to the latest binary"
		try
		{
			# Start-Process is used here to execute the PowerShell script
			Start-Process -FilePath "powershell.exe" -ArgumentList "-File `"$($getKapeUpdatePs1.FullName)`"" -NoNewWindow -Wait
		}
		catch
		{
			Log -logFilePath $logFilePath -msg "Error when running Get-KAPEUpdate.ps1: $_"
			Log -logFilePath $logFilePath -msg "KAPE was not updated properly, please try again"
			break
		}
	}
	else
	{
		Log -logFilePath $logFilePath -msg "$getKapeUpdatePs1FileName not found, please go download KAPE from $kapeDownloadUrl"
		exit
	}
}

<#
	.SYNOPSIS
		Makes sure the KAPE-EZToolsAncillaryUpdater.ps1 script is updated!

	.DESCRIPTION
		Checks the latest version of this updater and updates if there is a newer version and $DoNotUpdate is $false
#>
function Get-LatestKAPEEZToolsAncillaryUpdater
{
	[CmdletBinding()]
	param ()
	
	Log -logFilePath $logFilePath -msg ' --- KAPE-EZToolsAncillaryUpdater.ps1 ---'
	
	# First check the version of the current script show line number of match
	$currentScriptVersion = Get-Content $('.\KAPE-EZToolsAncillaryUpdater.ps1') | Select-String -SimpleMatch 'Version:' | Select-Object -First 1 # Version: 3.7
	$versionString = $currentScriptVersion.ToString().Split(':')[1].Trim() # Split by colon and remove leading/trailing spaces
	[System.Single]$CurrentScriptVersionNumber = $versionString # 3.7
	try
	{
		Log -logFilePath $logFilePath -msg "Current version of this script is $CurrentScriptVersionNumber"
	}
	catch
	{
		Log -logFilePath $logFilePath -msg "Caught an error: $_"
	}
	
	# Now get the latest version from GitHub
	$script:kapeEzToolsAncillaryUpdaterReleasesUrl = 'https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/releases/latest'
	$webRequest = Invoke-WebRequest -Uri $kapeEzToolsAncillaryUpdaterReleasesUrl -UseBasicParsing
	$strings = $webRequest.RawContent
	$script:kapeEzToolsAncillaryUpdaterPattern = 'EZToolsAncillaryUpdater/releases/tag/[0-9].[0-9]+'
	$latestVersion = $strings | Select-String -Pattern $kapeEzToolsAncillaryUpdaterPattern | Select-Object -First 1
	$latestVersionToSplit = $latestVersion.Matches[0].Value
	[System.Single]$LatestVersionNumber = $latestVersionToSplit.Split('/')[-1]
	Log -logFilePath $logFilePath -msg "Latest version of this script is $LatestVersionNumber"
	
	if ($($CurrentScriptVersionNumber -lt $LatestVersionNumber) -and $($DoNotUpdate -eq $false))
	{
		Log -logFilePath $logFilePath -msg 'Updating script to the latest version'
		
		# Start a new PowerShell process so we can replace the existing file and run the new script
		$script:kapeEzToolsAncillaryUpdaterScriptUrl = 'https://raw.githubusercontent.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/main/KAPE-EZToolsAncillaryUpdater.ps1'
		$script:kapeEzToolsAncillaryUpdaterOutFile = Join-Path -Path $PSScriptRoot -ChildPath 'KAPE-EZToolsAncillaryUpdater.ps1'
		
		try
		{
			Invoke-WebRequest -Uri $kapeEzToolsAncillaryUpdaterScriptUrl -OutFile $kapeEzToolsAncillaryUpdaterOutFile -UseBasicParsing -ErrorAction Stop
		}
		catch
		{
			Log -logFilePath $logFilePath -msg 'Failed to download updated script'
			Log -logFilePath $logFilePath -msg $_.Exception.Message
			Exit
		}
		
		Log -logFilePath $logFilePath -msg "Successfully updated script to $CurrentScriptVersionNumber"
		Log -logFilePath $logFilePath -msg 'Starting updated script in new window'
		
		# Store the arguments in a variable
		# Get-ZimmermanTools.ps1 -
		$argList = "$kapeEzToolsAncillaryUpdaterOutFile" # no netVersion specified which defaults to .NET 6 tools as of 3.7
		if ($PSBoundParameters.Keys.Contains('silent'))
		{
			$argList += " $true"
		}
		
		# Output a message with the command that's being executed
		Log -logFilePath $logFilePath -msg "Executing: Start-Process PowerShell -ArgumentList `"$argList`""
		
		# Execute the command
		Start-Process PowerShell -ArgumentList $argList
		
		Log -logFilePath $logFilePath -msg 'Please observe the script in the new window'
		Log -logFilePath $logFilePath -msg 'Exiting old script'
		Exit
	}
	else
	{
		Log -logFilePath $logFilePath -msg 'Script is current'
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
	
	Log -logFilePath $logFilePath -msg ' --- Get-ZimmermanTools.ps1 ---'
	
	Log -logFilePath $logFilePath -msg "$dotNetText specified. Downloading the $dotNetText version of EZ Tools"
	
	# Get all instances of !!!RemoteFileDetails.csv from $PSScriptRoot recursively
	$remoteFileDetailsCsvFilename = '!!!RemoteFileDetails.csv'
	$remoteFileDetailsCSVs = Get-ChildItem -Path $PSScriptRoot -Filter $remoteFileDetailsCsvFilename -Recurse
	
	# Iterate over each file and remove it forcefully
	foreach ($remoteFileDetailsCSV in $remoteFileDetailsCSVs)
	{
		# Check if the file exists before trying to remove it
		if (Test-Path $remoteFileDetailsCSV.FullName)
		{
			# Remove the file
			Remove-Item -Path $remoteFileDetailsCSV.FullName -Force
			
			# Confirm the file was removed
			if (Test-Path $remoteFileDetailsCSV.FullName)
			{
				Log -logFilePath $logFilePath -msg "Warning: Failed to delete $($remoteFileDetailsCSV.FullName)"
			}
			else
			{
				Log -logFilePath $logFilePath -msg "Deleted $($remoteFileDetailsCSV.FullName)"
			}
		}
	}
	
	# if .\KAPE\Modules\bin\ZimmermanTools doesn't exist, create it!
	Log -logFilePath $logFilePath -msg "Checking if $getZimmermanToolsFolderKape exists"
	
	if (-not (Test-Path $getZimmermanToolsFolderKape))
	{
		Log -logFilePath $logFilePath -msg "Creating $getZimmermanToolsFolderKape"
		New-Item -ItemType Directory -Path $getZimmermanToolsFolderKape | Out-Null
	}
	else
	{
		Log -logFilePath $logFilePath -msg "$getZimmermanToolsFolderKape already exists!"
	}
	
	# Get-ZimmermanTools.ps1 -Dest .\KAPE\Modules\bin\ZimmermanTools -NetVersion $net
	$scriptArgs = @{
		Dest = "$getZimmermanToolsFolderKape"
		NetVersion = $net
	}
	
	Log -logFilePath $logFilePath -msg "Downloading $ZTZipFile from $ZTdlUrl to $kapeModulesBin" # message saying we're downloading Get-ZimmermanTools.zip to .\KAPE\Modules\bin
	
	try
	{
		Start-BitsTransfer -Source $ZTdlUrl -Destination $kapeModulesBin -ErrorAction Stop
	}
	catch
	{
		Log -logFilePath $logFilePath -msg "Failed to download $ZTZipFile from $ZTdlUrl. Error: $($_.Exception.Message)"
	}
	
	Log -logFilePath $logFilePath -msg "Extracting $ZTZipFile from $kapeModulesBin to $kapeModulesBin" # extracting Get-ZimmermanTools.zip from .\KAPE\Modules\bin to .\KAPE\Modules\bin
	
	Expand-Archive -Path "$getZimmermanToolsZipKape" -DestinationPath "$kapeModulesBin" -Force # actually expanding Get-ZimmermanTools.zip to .\KAPE\Modules\bin
	
	Log -logFilePath $logFilePath -msg "Moving $getZimmermanToolsFileName from $kapeModulesBin to $getZimmermanToolsFolderKape"
	
	$getZimmermanToolsPs1 = (Get-ChildItem -Path $kapeModulesBin -Filter $getZimmermanToolsFileName).FullName
	
	# Move Get-ZimmermanTools.ps1 from .\KAPE\Modules\bin to .\KAPE\Modules\bin\ZimmermanTools
	Move-Item -Path $getZimmermanToolsPs1 -Destination $getZimmermanToolsFolderKape -Force
	
	$getZimmermanToolsPs1ZT = (Get-ChildItem -Path $getZimmermanToolsFolderKape -Filter $getZimmermanToolsFileName).FullName
	
	# Check if file was moved successfully
	if (-not (Test-Path "$getZimmermanToolsPs1ZT"))
	{
		Log -logFilePath $logFilePath -msg "Failed to move $getZimmermanToolsFileName from $kapeModulesBin to $getZimmermanToolsFolderKape"
	}
	else
	{
		Log -logFilePath $logFilePath -msg "Successfully moved $getZimmermanToolsFileName from $kapeModulesBin to $getZimmermanToolsFolderKape"
	}
	
	Start-Sleep -Seconds 1
	
	Log -logFilePath $logFilePath -msg "Running $getZimmermanToolsFileName! Downloading .NET 6 version of EZ Tools to $getZimmermanToolsFolderKape"
	
	Log -logFilePath $logFilePath -msg "Running script at path $getZimmermanToolsPs1ZT with arguments -Dest $($scriptArgs.Dest) -NetVersion $($scriptArgs.NetVersion)"
	
	# executing .\KAPE\Modules\bin\Get-ZimmermanTools.ps1 -Dest .\KAPE\Modules\bin\ZimmermanTools -NetVersion $net
	$argumentList = "-NoProfile -File ""$getZimmermanToolsPs1ZT"" -Dest ""$($scriptArgs.Dest)"" -NetVersion ""$($scriptArgs.NetVersion)"""
	
	# Execute the script
	Start-Process -FilePath "powershell.exe" -ArgumentList $argumentList -Wait
	Start-Sleep -Seconds 3
}

<#
	.SYNOPSIS
		Run --sync with whatever EZ Tool needs to be synced with GitHub
	
	.PARAMETER tool
		Provide the name of the tool to be synced with GitHub
	
	.EXAMPLE
		PS C:\> Sync-WithGitHub -tool 'Value1'
#>
function Sync-WithGitHub
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateSet('KAPE', 'EvtxECmd', 'RECmd', 'SQLECmd')]
		[string]$Tool
	)
	
	Log -logFilePath $logFilePath -msg " --- $Tool Sync ---"
	
	# Define paths and variables based on the tool
	switch ($Tool)
	{
		'KAPE' {
			$toolPath = $kape
			$toolExe = $kape
			$syncTarget = "KAPE Targets and Modules"
		}
		'EvtxECmd' {
			$toolPath = $kapeEvtxECmd
			$toolExe = Get-ChildItem $toolPath -Filter 'EvtxECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
			$syncTarget = "EvtxECmd Maps"
			$folderToDelete = $kapeEvtxecmdMaps
		}
		'RECmd' {
			$toolPath = $kapeRecmd
			$toolExe = Get-ChildItem $toolPath -Filter 'RECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
			$syncTarget = "RECmd Batch files"
			$folderToDelete = $kapeRecmdBatchExamples
		}
		'SQLECmd' {
			$toolPath = $kapeSQLECmd
			$toolExe = Get-ChildItem $toolPath -Filter 'SQLECmd.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
			$syncTarget = "SQLECmd Maps"
			$folderToDelete = $kapeSQLECmdMaps
		}
	}
	
	# Check if the tool exists
	if (!(Test-Path $toolPath))
	{
		Log -logFilePath $logFilePath -msg "'$Tool' not found. Please ensure it exists where you expect it to"
		return
	}
	
	# Delete the target folder if it exists (except for KAPE)
	if ($Tool -ne 'KAPE' -and (Test-Path $folderToDelete -PathType Container))
	{
		Remove-Item -Path $folderToDelete -Recurse -Force
		Log -logFilePath $logFilePath -msg "Deleting $folderToDelete for a fresh start prior to syncing $Tool with GitHub"
	}
	
	# Sync the tool with GitHub
	Log -logFilePath $logFilePath -msg "Syncing $Tool with GitHub for the latest $syncTarget"
	Start-Process $toolExe -ArgumentList '--sync' -NoNewWindow -Wait
	Start-Sleep -Seconds 3
}

function Move-EZTools
{
	[CmdletBinding()]
	param ()
	
	# Only run if Get-ZimmermanTools.ps1 has downloaded new .NET 6/9 tools, otherwise continue on.
	if (Test-Path -Path "$getZimmermanToolsFolderKapeNetVersion")
	{
		if ($net = '6')
		{
			Log -logFilePath $logFilePath -msg 'Please ensure you have the latest version of the .NET 6 Runtime installed. You can download it here: https://dotnet.microsoft.com/en-us/download/dotnet/6.0. Please note that the .NET 6 Desktop Runtime includes the Runtime needed for Desktop AND Console applications, aka Registry Explorer AND RECmd, for example'
		}
		else
		{
			Log -logFilePath $logFilePath -msg 'Please ensure you have the latest version of the .NET 9 Runtime installed. You can download it here: https://dotnet.microsoft.com/en-us/download/dotnet/9.0. Please note that the .NET 9 Desktop Runtime includes the Runtime needed for Desktop AND Console applications, aka Registry Explorer AND RECmd, for example'
		}
		
		# Create array of folders to be copied
		$folders = @(
			Join-Path $getZimmermanToolsFolderKapeNetVersion "EvtxECmd"
			Join-Path $getZimmermanToolsFolderKapeNetVersion "RECmd"
			Join-Path $getZimmermanToolsFolderKapeNetVersion "SQLECmd"
			Join-Path $getZimmermanToolsFolderKapeNetVersion "iisGeolocate"
		)
		
		Log -logFilePath $logFilePath -msg ' --- EZ Tools Folder Copy ---'
		
		# Copy each folder that exists
		$folderSuccess = @()
		foreach ($folder in $folders)
		{
			if (Test-Path -Path $folder)
			{
				Copy-Item -Path $folder -Destination $kapeModulesBin -Recurse -Force
				$folderSuccess += $folder.Split('\')[-1]
				Log -logFilePath $logFilePath -msg "Copying $folder and all contents to $kapeModulesBin"
			}
		}
		
		# Log only the folders that were copied
		Log -logFilePath $logFilePath -msg "Copied $($folderSuccess -join ', ') and all associated ancillary files to $kapeModulesBin successfully"
		
		Log -logFilePath $logFilePath -msg ' --- EZ Tools File Copy ---'
		
		# Create an array of the file extensions to copy
		$fileExts = @('*.dll', '*.exe', '*.json')
		
		# Get all files in $getZimmermanToolsFolderKapeNetVersion that match any of the extensions in $fileExts
		$files = Get-ChildItem -Path "$getZimmermanToolsFolderKapeNetVersion\*" -Include $fileExts
		
		# Copy the files to the destination
		foreach ($file in $files)
		{
			if (Test-Path $file)
			{
				Copy-Item -Path $file -Destination $kapeModulesBin -Recurse -Force
				Log -logFilePath $logFilePath -msg "Copying $file to $kapeModulesBin"
			}
			else
			{
				Log -logFilePath $logFilePath -msg "$file not found."
				$remoteFileDetailsCsvFullPath = Join-Path $getZimmermanToolsFolderKapeNetVersion $remoteFileDetailsCsvFilename
				Log -logFilePath $logFilePath -msg "If this continues to happen, try deleting $remoteFileDetailsCsvFullPath and re-running this script"
			}
		}
		
		Log -logFilePath $logFilePath -msg "Copied remaining EZ Tools binaries to $kapeModulesBin successfully"
		
		# This removes the downloaded EZ Tools that we no longer need to reside on disk
		Log -logFilePath $logFilePath -msg "Removing extra copies of EZ Tools from $getZimmermanToolsFolderKapeNetVersion"
		Remove-Item -Path $getZimmermanToolsFolderKapeNetVersion -Recurse -Force -ErrorAction SilentlyContinue
	}
	else
	{
		Log -logFilePath $logFilePath -msg "$getZimmermanToolsFolderKapeNetVersion doesn't exist. Make sure you have the latest version of Get-ZimmermanTools.ps1 in $kapeModulesBin"
	}
}

function Conclude-Script
{
	[CmdletBinding()]
	param ()
	
	Log -logFilePath $logFilePath -msg ' --- Administrative ---'
	Log -logFilePath $logFilePath -msg 'Thank you for keeping this instance of KAPE updated!'
	Log -logFilePath $logFilePath -msg 'Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!'
	Log -logFilePath $logFilePath -msg ' --- GitHub Repositories of Interest ---'
	Log -logFilePath $logFilePath -msg 'KapeFiles (Targets/Modules): https://github.com/EricZimmerman/KapeFiles'
	Log -logFilePath $logFilePath -msg 'RECmd (RECmd Batch Files): https://github.com/EricZimmerman/RECmd/tree/master/BatchExamples'
	Log -logFilePath $logFilePath -msg 'EvtxECmd (EvtxECmd Maps): https://github.com/EricZimmerman/evtx/tree/master/evtx/Maps'
	Log -logFilePath $logFilePath -msg 'SQLECmd (SQLECmd Maps): https://github.com/EricZimmerman/SQLECmd/tree/master/SQLMap/Maps'
	
	$stopwatch.stop()
	
	$Elapsed = $stopwatch.Elapsed.TotalSeconds
	
	Log -logFilePath $logFilePath -msg "Total Processing Time: $Elapsed seconds"
}

# Now that all functions have been declared, let's start executing them in order
try
{
	# Let's get some basic info about the script and output it to the log
	Start-Script
	
	# Let's set up the variables we're going to need for the rest of the script
	Set-Variables
	
	# Lets make sure this script is up to date
	if ($PSBoundParameters.Keys.Contains('DoNotUpdate'))
	{
		Log -logFilePath $logFilePath -msg 'Skipping check for updated $kapeEzToolsAncillaryUpdaterFileName script because -DoNotUpdate parameter set.'
	}
	else
	{
		Get-LatestKAPEEZToolsAncillaryUpdater
	}
	
	# Let's update KAPE first
	& Get-KAPEUpdateEXE
	
	# Let's download Get-ZimmermanTools.zip and extract Get-ZimmermanTools.ps1
	& Get-ZimmermanTools
	
	# Let's move all EZ Tools and place them into .\KAPE\Modules\bin
	Move-EZTools
	
	# Let's update KAPE, EvtxECmd, RECmd, and SQLECmd's ancillary files
	Sync-WithGitHub -Tool 'KAPE'
	Sync-WithGitHub -Tool 'EvtxECmd'
	Sync-WithGitHub -Tool 'RECmd'
	Sync-WithGitHub -Tool 'SQLECmd'
	
	# Let's output our final administrative messages to close out the script
	Conclude-Script
}
catch [System.IO.IOException] {
	# Handle specific IOException related to file operations
	Log -logFilePath $logFilePath -msg "IOException occurred: $($_.Message)"
}
catch [System.Exception] {
	# Handle any other exception that may have occurred
	Log -logFilePath $logFilePath -msg "Exception occurred: $($_.Exception.Message)"
}
finally
{
	# This block will always run, even if there was an exception
	Log -logFilePath $logFilePath -msg ' --- End of session ---'
	
	if (-not $silent)
	{
		Pause
	}
}

# SIG # Begin signature block
# MIIvngYJKoZIhvcNAQcCoIIvjzCCL4sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjyv+kK8NC93ZQ
# MCPC98aG+Ci6VgXLlnYllI79L1i8mKCCKKMwggQyMIIDGqADAgECAgEBMA0GCSqG
# SIb3DQEBBQUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQIDBJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoMEUNvbW9kbyBDQSBMaW1p
# dGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2VydmljZXMwHhcNMDQwMTAx
# MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFD
# b21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZp
# Y2VzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkCd9G7h6naHHE1F
# RI6+RsiDBp3BKv4YH47kAvrzq11QihYxC5oG0MVwIs1JLVRjzLZuaEYLU+rLTCTA
# vHJO6vEVrvRUmhIKw3qyM2Di2olV8yJY897cz++DhqKMlE+faPKYkEaEJ8d2v+PM
# NSyLXgdkZYLASLCokflhn3YgUKiRx2a163hiA1bwihoT6jGjHqCZ/Tj29icyWG8H
# 9Wu4+xQrr7eqzNZjX3OM2gWZqDioyxd4NlGs6Z70eDqNzw/ZQuKYDKsvnw4B3u+f
# mUnxLd+sdE0bmLVHxeUp0fmQGMdinL6DxyZ7Poolx8DdneY1aBAgnY/Y3tLDhJwN
# XugvyQIDAQABo4HAMIG9MB0GA1UdDgQWBBSgEQojPpbxB+zirynvgqV/0DCktDAO
# BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zB7BgNVHR8EdDByMDigNqA0
# hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2Vz
# LmNybDA2oDSgMoYwaHR0cDovL2NybC5jb21vZG8ubmV0L0FBQUNlcnRpZmljYXRl
# U2VydmljZXMuY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQAIVvwC8Jvo/6T61nvGRIDO
# T8TF9gBYzKa2vBRJaAR26ObuXewCD2DWjVAYTyZOAePmsKXuv7x0VEG//fwSuMdP
# WvSJYAV/YLcFSvP28cK/xLl0hrYtfWvM0vNG3S/G4GrDwzQDLH2W3VrCDqcKmcEF
# i6sML/NcOs9sN1UJh95TQGxY7/y2q2VuBPYb3DzgWhXGntnxWUgwIWUDbOzpIXPs
# mwOh4DetoBUYj/q6As6nLKkQEyzU5QgmqyKXYPiQXnTUoppTvfKpaOCibsLXbLGj
# D56/62jnVvKu8uMrODoJgbVrhde+Le0/GreyY+L1YiyC1GoAQVDxOYOflek2lphu
# MIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0BAQwFADB7
# MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
# AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAwMFoXDTI4
# MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGlt
# aXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIEJHQu/xYj
# ApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7fbu2ir29
# BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGrYbNzszwL
# DO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTHqi0Eq8Nq
# 6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv64IplXCN
# /7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2JmRCxrds+
# LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0POM1nqFOI
# +rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXybGWfv1Vb
# HJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyheBe6QTHrn
# xvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXycuu7D1fkK
# dvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7idFT/+IAx1
# yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQYMBaAFKAR
# CiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJwIDaRXBeF
# 5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmljYXRlU2Vy
# dmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3SamES4aUa1
# qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+BtlcY2fU
# QBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8ZsBRNraJ
# AlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx2jLsFeSm
# TD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyoXZ3JHFuu
# 2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p1FiAhORF
# e1rYMIIFgzCCA2ugAwIBAgIORea7A4Mzw4VlSOb/RVEwDQYJKoZIhvcNAQEMBQAw
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjYxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTQxMjEwMDAwMDAwWhcN
# MzQxMjEwMDAwMDAwWjBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBS
# NjETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJUH6HPKZvnsFMp7PPcNCPG0RQss
# grRIxutbPK6DuEGSMxSkb3/pKszGsIhrxbaJ0cay/xTOURQh7ErdG1rG1ofuTToV
# Bu1kZguSgMpE3nOUTvOniX9PeGMIyBJQbUJmL025eShNUhqKGoC3GYEOfsSKvGRM
# IRxDaNc9PIrFsmbVkJq3MQbFvuJtMgamHvm566qjuL++gmNQ0PAYid/kD3n16qIf
# KtJwLnvnvJO7bVPiSHyMEAc4/2ayd2F+4OqMPKq0pPbzlUoSB239jLKJz9CgYXfI
# WHSw1CM69106yqLbnQneXUQtkPGBzVeS+n68UARjNN9rkxi+azayOeSsJDa38O+2
# HBNXk7besvjihbdzorg1qkXy4J02oW9UivFyVm4uiMVRQkQVlO6jxTiWm05OWgtH
# 8wY2SXcwvHE35absIQh1/OZhFj931dmRl4QKbNQCTXTAFO39OfuD8l4UoQSwC+n+
# 7o/hbguyCLNhZglqsQY6ZZZZwPA1/cnaKI0aEYdwgQqomnUdnjqGBQCe24DWJfnc
# BZ4nWUx2OVvq+aWh2IMP0f/fMBH5hc8zSPXKbWQULHpYT9NLCEnFlWQaYw55PfWz
# jMpYrZxCRXluDocZXFSxZba/jJvcE+kNb7gu3GduyYsRtYQUigAZcIN5kZeR1Bon
# vzceMgfYFGM8KEyvAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
# BTADAQH/MB0GA1UdDgQWBBSubAWjkxPioufi1xzWx/B/yGdToDAfBgNVHSMEGDAW
# gBSubAWjkxPioufi1xzWx/B/yGdToDANBgkqhkiG9w0BAQwFAAOCAgEAgyXt6NH9
# lVLNnsAEoJFp5lzQhN7craJP6Ed41mWYqVuoPId8AorRbrcWc+ZfwFSY1XS+wc3i
# EZGtIxg93eFyRJa0lV7Ae46ZeBZDE1ZXs6KzO7V33EByrKPrmzU+sQghoefEQzd5
# Mr6155wsTLxDKZmOMNOsIeDjHfrYBzN2VAAiKrlNIC5waNrlU/yDXNOd8v9EDERm
# 8tLjvUYAGm0CuiVdjaExUd1URhxN25mW7xocBFymFe944Hn+Xds+qkxV/ZoVqW/h
# pvvfcDDpw+5CRu3CkwWJ+n1jez/QcYF8AOiYrg54NMMl+68KnyBr3TsTjxKM4kEa
# SHpzoHdpx7Zcf4LIHv5YGygrqGytXm3ABdJ7t+uA/iU3/gKbaKxCXcPu9czc8FB1
# 0jZpnOZ7BN9uBmm23goJSFmH63sUYHpkqmlD75HHTOwY3WzvUy2MmeFe8nI+z1TI
# vWfspA9MRf/TuTAjB0yPEL+GltmZWrSZVxykzLsViVO6LAUP5MSeGbEYNNVMnbrt
# 9x+vJJUEeKgDu+6B5dpffItKoZB0JaezPkvILFa9x8jvOOJckvB595yEunQtYQEg
# fn7R8k8HWV+LLUNS60YMlOH1Zkd5d9VUWx+tJDfLRVpOoERIyNiwmcUVhAn21klJ
# wGW45hpxbqCo8YLoRT5s1gLXCmeDBVrJpBAwggYaMIIEAqADAgECAhBiHW0MUgGe
# O5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENvZGUg
# U2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5NTla
# MFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNV
# BAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0GCSqG
# SIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjIztNs
# fvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NVDgFi
# gOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/36F09
# fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05ZwmRmT
# nAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm+qxp
# 4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUedyz8
# rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz44MPZ
# 1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBMdlyh
# 2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaA
# FDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritUpimq
# F6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsGA1Ud
# HwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1Ymxp
# Y0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsGAQUF
# BzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2ln
# bmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdv
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURhw1aV
# cdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0ZdOaWT
# syNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajjcw5+
# w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNcWbWD
# RF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalOhOfC
# ipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJszkye
# iaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z76mKn
# zAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5JKdGv
# spbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHHj95E
# jza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2Bev6
# SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/L9Uo
# 2bC5a4CH2RwwggZZMIIEQaADAgECAg0B7BySQN79LkBdfEd0MA0GCSqGSIb3DQEB
# DAUAMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFI2MRMwEQYDVQQK
# EwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTE4MDYyMDAwMDAw
# MFoXDTM0MTIxMDAwMDAwMFowWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2Jh
# bFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENB
# IC0gU0hBMzg0IC0gRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDw
# AuIwI/rgG+GadLOvdYNfqUdSx2E6Y3w5I3ltdPwx5HQSGZb6zidiW64HiifuV6PE
# Ne2zNMeswwzrgGZt0ShKwSy7uXDycq6M95laXXauv0SofEEkjo+6xU//NkGrpy39
# eE5DiP6TGRfZ7jHPvIo7bmrEiPDul/bc8xigS5kcDoenJuGIyaDlmeKe9JxMP11b
# 7Lbv0mXPRQtUPbFUUweLmW64VJmKqDGSO/J6ffwOWN+BauGwbB5lgirUIceU/kKW
# O/ELsX9/RpgOhz16ZevRVqkuvftYPbWF+lOZTVt07XJLog2CNxkM0KvqWsHvD9WZ
# uT/0TzXxnA/TNxNS2SU07Zbv+GfqCL6PSXr/kLHU9ykV1/kNXdaHQx50xHAotIB7
# vSqbu4ThDqxvDbm19m1W/oodCT4kDmcmx/yyDaCUsLKUzHvmZ/6mWLLU2EESwVX9
# bpHFu7FMCEue1EIGbxsY1TbqZK7O/fUF5uJm0A4FIayxEQYjGeT7BTRE6giunUln
# EYuC5a1ahqdm/TMDAd6ZJflxbumcXQJMYDzPAo8B/XLukvGnEt5CEk3sqSbldwKs
# DlcMCdFhniaI/MiyTdtk8EWfusE/VKPYdgKVbGqNyiJc9gwE4yn6S7Ac0zd0hNkd
# Zqs0c48efXxeltY9GbCX6oxQkW2vV4Z+EDcdaxoU3wIDAQABo4IBKTCCASUwDgYD
# VR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFOoWxmnn
# 48tXRTkzpPBAvtDDvWWWMB8GA1UdIwQYMBaAFK5sBaOTE+Ki5+LXHNbH8H/IZ1Og
# MD4GCCsGAQUFBwEBBDIwMDAuBggrBgEFBQcwAYYiaHR0cDovL29jc3AyLmdsb2Jh
# bHNpZ24uY29tL3Jvb3RyNjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmds
# b2JhbHNpZ24uY29tL3Jvb3QtcjYuY3JsMEcGA1UdIARAMD4wPAYEVR0gADA0MDIG
# CCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5
# LzANBgkqhkiG9w0BAQwFAAOCAgEAf+KI2VdnK0JfgacJC7rEuygYVtZMv9sbB3DG
# +wsJrQA6YDMfOcYWaxlASSUIHuSb99akDY8elvKGohfeQb9P4byrze7AI4zGhf5L
# FST5GETsH8KkrNCyz+zCVmUdvX/23oLIt59h07VGSJiXAmd6FpVK22LG0LMCzDRI
# RVXd7OlKn14U7XIQcXZw0g+W8+o3V5SRGK/cjZk4GVjCqaF+om4VJuq0+X8q5+dI
# ZGkv0pqhcvb3JEt0Wn1yhjWzAlcfi5z8u6xM3vreU0yD/RKxtklVT3WdrG9KyC5q
# ucqIwxIwTrIIc59eodaZzul9S5YszBZrGM3kWTeGCSziRdayzW6CdaXajR63Wy+I
# Lj198fKRMAWcznt8oMWsr1EG8BHHHTDFUVZg6HyVPSLj1QokUyeXgPpIiScseeI8
# 5Zse46qEgok+wEr1If5iEO0dMPz2zOpIJ3yLdUJ/a8vzpWuVHwRYNAqJ7YJQ5NF7
# qMnmvkiqK1XZjbclIA4bUaDUY6qD6mxyYUrJ+kPExlfFnbY8sIuwuRwx773vFNgU
# QGwgHcIt6AvGjW2MtnHtUiH+PvafnzkarqzSL3ogsfSsqh3iLRSd+pZqHcY8yvPZ
# HL9TTaRHWXyVxENB+SXiLBB+gfkNlKd98rUJ9dhgckBQlSDUQ0S++qCV5yBZtnjG
# pGqqIpswggZ1MIIE3aADAgECAhA1nosluv9RC3xO0e22wmkkMA0GCSqGSIb3DQEB
# DAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwHhcNMjIw
# MTI3MDAwMDAwWhcNMjUwMTI2MjM1OTU5WjBSMQswCQYDVQQGEwJVUzERMA8GA1UE
# CAwITWljaGlnYW4xFzAVBgNVBAoMDkFuZHJldyBSYXRoYnVuMRcwFQYDVQQDDA5B
# bmRyZXcgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALe0
# CgT89ev6jRIhHdrp9cdPnRoF5AV3wQdWzNG8JiY4dpN1YVwGLlw8aBosm0NIRz2/
# y/kriL+Jdu/FFakJdpB8l/J+mesliYhN+zj9vFviBjrElMASEBS9DXKaUFuqZMGi
# C6k6yASGfyqF121OkLZ2JImy4a0C43Pd74dbf+/Ae4QHj66otahUBL++7ayba/TJ
# ebhRdEq0wFiaxYsZOt18c3LLfAw0fniHfMBZXXJAQhgu1xfgpw7OE4N/M5or5VDV
# Q4ovtSFDVRzRARIF4ibZZqB76Rp5MuI0pMCs74TPN6WdlzGTDBu4pTS064iGx5hl
# P+GB5s/w/YW1BDigFV6yaERsbet9G2lsMmNwZtI6zUuGd9HEtd5isz/9ENhLcFoa
# JE7/KK8CL5jt8i9I3Lx+5EOgEwm65eHm45bq63AVKvSHrjisuxX89jWTeslKMM/r
# pw8GMrNBxo9DZvDS4+kCloFKARiwKHJIKpNWUT3T8Kw6Q/ayxUt7TKp+cqh0U9Yo
# XLbXIYMpLa5KfOsf21SqfSrhJ+rSEPEBM11uX41T/mQD5sArN9AIPQxp6X7qLckz
# ClylAQgzF2OVHEEi5m2kmb0lvfMOMGQ3BgwQHCRcd65wugzCIipb5KBTq+HJLgRW
# FwYGraxcfsLkkwBY1ssKPaVpAgMDmlWJo6hDoYR9AgMBAAGjggHDMIIBvzAfBgNV
# HSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUUwhn1KEy//RT
# 4cMg1UJfMUX5lBcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoGA1UdIARDMEEwNQYM
# KwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20v
# Q1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3Rp
# Z28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEF
# BQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2Vj
# dGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRw
# Oi8vb2NzcC5zZWN0aWdvLmNvbTAlBgNVHREEHjAcgRphbmRyZXcuZC5yYXRoYnVu
# QGdtYWlsLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEATPy2wx+JfB71i+UCYCOjFFBq
# rA4kCxsHv3ihLjF4N3g8jb7A156vBangR3BDPQ6lF0YCPwEFE9MQzqG7OgkUauX0
# vfPeuVe8cEadUFlrmb6xCmXsxKdGXObaITeGABz97AzLKxgxRf7xCEKsAzvbuaK3
# lvb3Me9jtRVn9Q69sBTE5I/IDf2PoG/tO/ibPYXC1KpilBNT0A28xMtQ1ijTS0dn
# bOyTMaUBCZUrNR/9qY2sOBhvxuvSouWjuEazDLTCs6zsMBQH9vfrLoNlvEXI5YO9
# Ck19kT9pZ2rGFO7y8ySRmoVpZvHI29Z4bXBtGUGb2g/RRppid5anuRtN+Skr7S1w
# drNlhBIYErmCUPH2RPMphN2wmUy6IsDpdTPJkPTmU83q3tpOBGwvyTdxhiPIurZM
# XSDXfUyGB2iiXoyUHP2caVUmsarEb3BgCEf0PT2rO971WCDnG0mMgle2Yur4z3eW
# EsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMIIGezCCBGOgAwIBAgIQAQdk
# mwiwp/591lSo8vQp9jANBgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBTSEEzODQgLSBHNDAeFw0yMzExMDcxNzEzNDBaFw0zNDEy
# MDkxNzEzNDBaMGwxCzAJBgNVBAYTAkJFMRkwFwYDVQQKDBBHbG9iYWxTaWduIG52
# LXNhMUIwQAYDVQQDDDlHbG9iYWxzaWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2Rl
# IEFkdmFuY2VkIC0gRzQgLSAyMDIzMTEwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAw
# ggGKAoIBgQC5qJs+qabcQtNBn4pNQ0cJ+WiLE/t1j5lcyoBCYe+OuuFx1keQrZlN
# YwO276kmo/s26m4UR/fXTUR0sipenTJfBGivt8nPWwsnLyhOgt6OtbOJ+ucRScgn
# QF6TbwkhxtZfmPO3uqFAcq7dD9/OIUIEVDjqyiLdA7kaoeC3HJcocywgjT9msnaZ
# 2jrJ9nKWUnTYfWVu4CJv/q9G/X6vTsiJgTKhmCuPd+eyo9Wanx/RgyBOTe9MO1F7
# kSPhg0qib7gE5mQUSy47fOm1/bNuNkRANvW+Iebo0Pp+96hORqyUsNApdOKxl6p/
# OPGJ4nq3ymwFMBhYb31bfjqR1HxvTv/pMX6lgjXhLv8KYOpShVeHeuQqrzyi33nb
# 4HmP35Ht/yY9dkBL3xtL9oKo6oMorVO2t5bXHS2M7799ip6UfFOpZARrfMwWZxkx
# gpLp9Dq81IiovY7uTxJ52P/glpBQfgEV//DjbF4a9K9AxeUnPUb4OkE4/zlItNwG
# Afs7CChoaakCAwEAAaOCAagwggGkMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDAdBgNVHQ4EFgQU+KOn5SN1VtGlpTuJbhZxy1XWiAkwVgYD
# VR0gBE8wTTAIBgZngQwBBAIwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0
# dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAwGA1UdEwEB/wQC
# MAAwgZAGCCsGAQUFBwEBBIGDMIGAMDkGCCsGAQUFBzABhi1odHRwOi8vb2NzcC5n
# bG9iYWxzaWduLmNvbS9jYS9nc3RzYWNhc2hhMzg0ZzQwQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdHNhY2FzaGEzODRn
# NC5jcnQwHwYDVR0jBBgwFoAU6hbGaefjy1dFOTOk8EC+0MO9ZZYwQQYDVR0fBDow
# ODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9jYS9nc3RzYWNhc2hh
# Mzg0ZzQuY3JsMA0GCSqGSIb3DQEBCwUAA4ICAQBwK1kuawVStSZXIbXPEOia8KzL
# clRobVVFmZY5WEcb0GlrKGzwk4umRMt4yatOYsSCHwWQ3qwGljuuoEYNgYbskHDc
# sjUuy1UtQ0dvi3pOQT/+siGcQDHYrY+VNxqC68i3DqehXBqqwGpJ/Q+KBAcmwtkO
# zyYDfTBFv2xQeg/pJDZMgKToIkErYGa8rAvPMsiAfypGx5zC5R8P1lX5Agxhxbxi
# j12jImHraph4sGQvCbANybgIHFpeBjAkXXGDdjj9SGqYXT9CSG8shDb85v6SwtJw
# Y0GDtfSgCmVa1UH0g6gwG8jWW25A6MPN5jfiyelVXItTxO7h37vTtZGKu2dztQjw
# qEirDhvgRHC+4gTnEanhP1BBmgxmClZFwQVB+UIV/QSmkbX6TBaKfn4FmqGHdFT9
# x6fA5pNnnaQdKlw6BLVO1Rceo+KN7j48CoFPWTH7Bf+YGdOYuAbYSJtJk+ECx22y
# LIrc6l7b1G/9B6wePDZRd/E+LJJk9ZjwTyuaEPPaXzj6SkLJf2Cjm0mhMwsQzsJP
# pdOygFgZJvpDCUq1ddWe2K8Nrx62+0tJeP1fseqG7Xrqd7rR7OeGNQn5WruW4fYK
# V/n91v4kGgBQvZ5NyJEYN+zSKM4PrpdGHcJ8YMu7mmSulrW55cp65XrWeEEk3mbJ
# 9lAXRaV/0x/qHtrv6DGCBlEwggZNAgEBMGgwVDELMAkGA1UEBhMCR0IxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29k
# ZSBTaWduaW5nIENBIFIzNgIQNZ6LJbr/UQt8TtHttsJpJDANBglghkgBZQMEAgEF
# AKBMMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMC8GCSqGSIb3DQEJBDEiBCDx
# +ZtsaUKr0ukuq0SYfd4FiG95pzatBWmea6OvfIJEOjANBgkqhkiG9w0BAQEFAASC
# AgBVrN8Qy8s4H/QYTsSITJ9fpjIZUVLGeJevdoOf1FQVh4RcnNShxdal8JKLwwq0
# efKKOueuvB2AvRymW7LlTSIJM6qY5E2sCZbstf0zgw5unNNRDUrDEjF5G+0DmhMB
# Lv7q/inWo0ec4T/vtfchS43W9lZs7rj9YIGuMX8kgDM+G5/Emxp+Gh1H+YgW7N+D
# wPmYnM+gDxj7g0ORLnuWkHgAuWN1SFdOhOCVLsEuqaRS09tkLZRrlz+GTNCJ3LAA
# dWaQtGR/H6K6NBCQ7tI5Ga3hux2qeBB7NN92H6YU0SS3V6LEWNW0BpMSs4K8cEEk
# wgzhT23/OSR23U9x6fa949FyxqO7E8+HOJ3llVWKV2geqElxbS5n4Zof0/0DPmhL
# Rj9lUIExzCf9RixOzNWVGobYiniIMPlw+6LWYxdasDcM0K67gfXIvLbKqYVPz4kp
# dLMd8gKJ/2aBVcT/3cZp4JlcVO+hQtAfh6l2BW2N9KJM8z1QkPXC8+vL5QilKl29
# SJZS+Y6aLYkdRfVGHLaBiekQtTpfOi9O7J2dpFmfDiqCbPONYS31q1d+qtipR4tf
# gOhP/ATxeTijQYh/nhlHqo4ZSs0vAAb5uo7N4XpLMm5DHyVeWii4EkR0NmeRYMYE
# DS4UMSEb/vxxqt2Z/0rEkPJd7jlDQ2DnDIslYpMAsMG34KGCA2wwggNoBgkqhkiG
# 9w0BCQYxggNZMIIDVQIBATBvMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIFNIQTM4NCAtIEc0AhABB2SbCLCn/n3WVKjy9Cn2MAsGCWCGSAFlAwQCAaCC
# AT0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjUw
# MTI1MTYyMTIzWjArBgkqhkiG9w0BCTQxHjAcMAsGCWCGSAFlAwQCAaENBgkqhkiG
# 9w0BAQsFADAvBgkqhkiG9w0BCQQxIgQgo8DrSYZFi5YQIwDRIH5asJ3kMjo4PzLw
# 4KnlKlrA37AwgaQGCyqGSIb3DQEJEAIMMYGUMIGRMIGOMIGLBBRE05OczRuIf4Z6
# zNqB7K8PZfzSWTBzMF+kXTBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0Eg
# LSBTSEEzODQgLSBHNAIQAQdkmwiwp/591lSo8vQp9jANBgkqhkiG9w0BAQsFAASC
# AYCtEJj6oOuNj35+rj81vpE0M8pINoacxXbWckKYA6gxiFB067sny6Q6eCCcGI2h
# +I6L64Pv+qJnTQdKINMl2YDjqdA3PE1MtKv4dkagi5BhHe01NRhiKwiYSwzoVMr8
# 0BCpyXxiyE+qm/cQQ+PhDC3ZaefzaYSWRggR6xoJpgMdrDg+OL4LGSVrtNGO8zra
# XbsDyvU26xaYIHNjyaGJRF0O21ttHqH2QT1WsBNxJN5uov/w98TK2PS9Nf1NCMRT
# HQsRkN/yH7b6VmQviaJxInxEV8z6V3upbBlEo79l077Hw36VEwHX4JFjTw0zNFp0
# Zlz00QkCQKRlQmI6bQuLrw65df+FRHw9rVrOo7NcXj709so22G0Ro1te8FJxFym4
# dbWgcSgqvHlH/93EY1L6LYWksbsSJhUWbJciqXi4I/TS7HiPHq1AQAcmVcmvVwfx
# 33dnWCq6ZyNihfiIaPcuGDFA3tmPZ7qU41S09Ajh7g1ZR+7MhtcnLFE93ZzyIUTM
# zHQ=
# SIG # End signature block
