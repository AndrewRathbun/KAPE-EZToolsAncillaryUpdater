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
		4.3 - (January 25, 2025) Added net parameter, with options for .NET 6 or .NET 9 tools, with a default to .NET 9. Simplify and consolidate GitHub sync functions. Update Get-ZimmermanTools.ps1 URL. Improve code readability and maintainability throughout.
	
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
	$script:dotNetText = ".NET $net"
	
	switch ($net)
	{
		'6' { $script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net6' }
		'9' { $script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net9' }
	}
	
	$script:ZTZipFile = 'Get-ZimmermanTools.zip'
	$script:ZTdlUrl = "https://download.ericzimmermanstools.com/$ZTZipFile" # https://download.ericzimmermanstools.com/Get-ZimmermanTools.zip
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
	
	.PARAMETER netVersion
		A description of the netVersion parameter.
	
	.NOTES
		Additional information about the function.
#>
function Get-ZimmermanTools
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateSet('6', '9')]
		[string]$netVersion
	)
	
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
		NetVersion = $netVersion
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
	Log -logFilePath $logFilePath -msg "Finished syncing $Tool with GitHub for the latest $syncTarget"
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
	& Get-ZimmermanTools -netVersion $net
	
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
# MIIvlwYJKoZIhvcNAQcCoIIviDCCL4QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCARCoFD7WBVjPoG
# sXzoouCocQnVXsdmU2ns/rmO9lt31aCCKJwwggQyMIIDGqADAgECAgEBMA0GCSqG
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
# pGqqIpswggZuMIIE1qADAgECAhAhqkhIHhrn6JmTDAPnG+yGMA0GCSqGSIb3DQEB
# DAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwHhcNMjUw
# MTI3MDAwMDAwWhcNMjgwMTI3MjM1OTU5WjBeMQswCQYDVQQGEwJVUzERMA8GA1UE
# CAwITWljaGlnYW4xHTAbBgNVBAoMFEFuZHJldyBEYXZpZCBSYXRoYnVuMR0wGwYD
# VQQDDBRBbmRyZXcgRGF2aWQgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAMkJu/RzsqNXey1TrbKBHF4iHKDxJ0O94mWuaZpEQsGr0nWz+/Kv
# +TMBbsDxne/TAIY6TGAnS8ul62tD9lTJ8itMKoUkRF2MNHiHe1UJvbtTMf0i0Yc8
# mvk7E65pzCD9jhfPCxmF4sE/egwPfCvWwH222I128N3dIpZbkMo7XN5JVRRKpnxz
# zvACfEF4zpxKFBrTDa9cO4ncP4Q+vY1lPOeEeXJPaKUkA3KcxIjddZSK4P+zs7ma
# 1R9kk6J80SUdOhgutNKR0wPFKRcUS5h+b4F41RlE6ywz886Ab43D77q5ziyDJvDU
# lYLBzZJCAr9WMPKV04sYbIa0AB2wqWEfXT/8xTCWSmVb4uL7J3YKmiXzCJZAgNas
# dRjs6iMOu8uPNNaujduzzRPf/auQod3ZD3aje0YMMP2W1GFylWMIxAN9IyHjooxZ
# EJklEu2qDWHEVhVtwDwQRsnH980W7gDTEPSdAHe7eQ+svVqWwFvaKPt12k73PkXI
# toy5HAROPUe5tfdiWXcVKRM1qUwWnVUfXGI5HtJmqxrfOl4wVOR0S6D1LliI2cVA
# jEJ1fygAsVPgXEo5bfploZQvUZzF3akTAvKdkc5faUIoBuO3WnNMbO3y8f+bt9Th
# aFQ5z6qTH6p1EVqN4w9O3t9yMIHsnUrDEdg9yqhxiEbkaepQa92x9mE5AgMBAAGj
# ggGwMIIBrDAfBgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4E
# FgQUp8BNwU9LtpBX3khU8nN8LWZ3lRQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwSgYDVR0gBEMwQTA1BgwrBgEEAbIx
# AQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYG
# Z4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqGOGh0dHA6Ly9jcmwuc2VjdGlnby5jb20v
# U2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3JsMHkGCCsGAQUFBwEBBG0w
# azBEBggrBgEFBQcwAoY4aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVi
# bGljQ29kZVNpZ25pbmdDQVIzNi5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3Nw
# LnNlY3RpZ28uY29tMCUGA1UdEQQeMByBGmFuZHJldy5kLnJhdGhidW5AZ21haWwu
# Y29tMA0GCSqGSIb3DQEBDAUAA4IBgQAGC/+y/bEbicUcdL3NSNIqMeeBamW5efm0
# X8b8uj+M4ZoXi+lbdpCeNtGkPbzjmgCodiUSbZXIbkxQNlRtGW/7NxXAlIwqbwJn
# wq06tov/sckJszOk0d4x4kZz4IFZR8xiu7o4eobsEE2bIv/FP5yGqEEUbCsOuT5G
# bGFJnultBF68vNpeTb5CoJ4n2RT4SJapc6m7KIMZqzFyFm+v70Zv812P7VukTqVp
# Yh9jRW90bq76x75XllrN/iPSSbzvfksn83Cb8M9SDckIjpwIhgJTYKi/NYDUjnqu
# OJryMdfozz3h5p1jcAkKb3mfWJgXtQ3HZ2DB9vIPoKVgA3Q7l4YlJT7lXWC35IuI
# U6h3QlmpXEKr+UEVmPOUuBcyvoZ/p31NOY3uBbLoXUQuj+lv4srCVz1E7oGGPMGU
# X4QRuFiVZxFwySgpvuM1OAvnTN16DS/70SEKvM83oFROsHWcyd9DOwiWND1GPC+/
# OeUdiZ8p+jK/X0Hit1QHISPdN7ULX5IwggZ7MIIEY6ADAgECAhABB2SbCLCn/n3W
# VKjy9Cn2MA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBH
# bG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGlu
# ZyBDQSAtIFNIQTM4NCAtIEc0MB4XDTIzMTEwNzE3MTM0MFoXDTM0MTIwOTE3MTM0
# MFowbDELMAkGA1UEBhMCQkUxGTAXBgNVBAoMEEdsb2JhbFNpZ24gbnYtc2ExQjBA
# BgNVBAMMOUdsb2JhbHNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgQWR2YW5j
# ZWQgLSBHNCAtIDIwMjMxMTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGB
# ALmomz6pptxC00Gfik1DRwn5aIsT+3WPmVzKgEJh74664XHWR5CtmU1jA7bvqSaj
# +zbqbhRH99dNRHSyKl6dMl8EaK+3yc9bCycvKE6C3o61s4n65xFJyCdAXpNvCSHG
# 1l+Y87e6oUByrt0P384hQgRUOOrKIt0DuRqh4LcclyhzLCCNP2aydpnaOsn2cpZS
# dNh9ZW7gIm/+r0b9fq9OyImBMqGYK49357Kj1ZqfH9GDIE5N70w7UXuRI+GDSqJv
# uATmZBRLLjt86bX9s242REA29b4h5ujQ+n73qE5GrJSw0Cl04rGXqn848YnierfK
# bAUwGFhvfVt+OpHUfG9O/+kxfqWCNeEu/wpg6lKFV4d65CqvPKLfedvgeY/fke3/
# Jj12QEvfG0v2gqjqgyitU7a3ltcdLYzvv32KnpR8U6lkBGt8zBZnGTGCkun0OrzU
# iKi9ju5PEnnY/+CWkFB+ARX/8ONsXhr0r0DF5Sc9Rvg6QTj/OUi03AYB+zsIKGhp
# qQIDAQABo4IBqDCCAaQwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMB0GA1UdDgQWBBT4o6flI3VW0aWlO4luFnHLVdaICTBWBgNVHSAETzBN
# MAgGBmeBDAEEAjBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93
# d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wDAYDVR0TAQH/BAIwADCBkAYI
# KwYBBQUHAQEEgYMwgYAwOQYIKwYBBQUHMAGGLWh0dHA6Ly9vY3NwLmdsb2JhbHNp
# Z24uY29tL2NhL2dzdHNhY2FzaGEzODRnNDBDBggrBgEFBQcwAoY3aHR0cDovL3Nl
# Y3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0c2FjYXNoYTM4NGc0LmNydDAf
# BgNVHSMEGDAWgBTqFsZp5+PLV0U5M6TwQL7Qw71lljBBBgNVHR8EOjA4MDagNKAy
# hjBodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2NhL2dzdHNhY2FzaGEzODRnNC5j
# cmwwDQYJKoZIhvcNAQELBQADggIBAHArWS5rBVK1Jlchtc8Q6JrwrMtyVGhtVUWZ
# ljlYRxvQaWsobPCTi6ZEy3jJq05ixIIfBZDerAaWO66gRg2BhuyQcNyyNS7LVS1D
# R2+Lek5BP/6yIZxAMditj5U3GoLryLcOp6FcGqrAakn9D4oEBybC2Q7PJgN9MEW/
# bFB6D+kkNkyApOgiQStgZrysC88yyIB/KkbHnMLlHw/WVfkCDGHFvGKPXaMiYetq
# mHiwZC8JsA3JuAgcWl4GMCRdcYN2OP1IaphdP0JIbyyENvzm/pLC0nBjQYO19KAK
# ZVrVQfSDqDAbyNZbbkDow83mN+LJ6VVci1PE7uHfu9O1kYq7Z3O1CPCoSKsOG+BE
# cL7iBOcRqeE/UEGaDGYKVkXBBUH5QhX9BKaRtfpMFop+fgWaoYd0VP3Hp8Dmk2ed
# pB0qXDoEtU7VFx6j4o3uPjwKgU9ZMfsF/5gZ05i4BthIm0mT4QLHbbIsitzqXtvU
# b/0HrB48NlF38T4skmT1mPBPK5oQ89pfOPpKQsl/YKObSaEzCxDOwk+l07KAWBkm
# +kMJSrV11Z7Yrw2vHrb7S0l4/V+x6obteup3utHs54Y1Cflau5bh9gpX+f3W/iQa
# AFC9nk3IkRg37NIozg+ul0Ydwnxgy7uaZK6WtbnlynrletZ4QSTeZsn2UBdFpX/T
# H+oe2u/oMYIGUTCCBk0CAQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2Vj
# dGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25p
# bmcgQ0EgUjM2AhAhqkhIHhrn6JmTDAPnG+yGMA0GCWCGSAFlAwQCAQUAoEwwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIOT46my4Pn7E
# 2da21+Pf6Wv5ZwiW/deuB89eVtWdRkFAMA0GCSqGSIb3DQEBAQUABIICAJO0cq5e
# 4g24ie7zxzWvabmLFFrDulDwPl5SDcXHUbaIzQfLKNyD9OORTUSs29P4jrGdmsTj
# L5I0SURdLXwEH/txoyr9R+Wm9Kfn4x82grEk/6A4sdz/cT5VaKIoDuobkaDYeF9E
# gvccmy+QDmVZlzC4E0c37SX/kgKNppxHvxQAQxOXZQtc67pZVmDz++wcl2ubRfxM
# WF0TBG9u6hR8IQUwu+y5N/A62RlVzlq5GpWVL3V49EiPEBC9H3g7vjl438Y626T+
# d8u56B8Tebdq/9WWRs8XpNLWmHWW8bexgCe9My2SQW2qdZs7d3gFMpJ2jZtjeaI5
# MglC0mS2ZOf38mXhdQL7PdpIpK7ch5up+2b+v4ikz1gLX9467p0Dx40kFBYRJ7JQ
# pmVwjnUVpgaOmnSba0kGgRylks+1+OfqSWhb1GRNwHriDtvGvJzfsSp1bKfDKlaw
# u5oKQ2bou2mZfb2ufJlxLNI6tYNCkzJEXKr5GkSPAW2t2RK7dJxl4kSzD0R+gYGy
# HlVLewePAlE9u1gCpZhdvjD1Utm8IVJSbfa7+PoI/znmXkGC0J0oatuG2chBsejK
# FI1VZ2U5WRiX2R31llfOKgzTrxTxB8HlYMkRubtj1qyNBmpPQBx9CFWQ8ZhUvJ9z
# LO9nWtashZJjn71J4sznaJeWZ1pYcdnhM/AuoYIDbDCCA2gGCSqGSIb3DQEJBjGC
# A1kwggNVAgEBMG8wWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# Mzg0IC0gRzQCEAEHZJsIsKf+fdZUqPL0KfYwCwYJYIZIAWUDBAIBoIIBPTAYBgkq
# hkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTAyMDIyMjQ0
# MjdaMCsGCSqGSIb3DQEJNDEeMBwwCwYJYIZIAWUDBAIBoQ0GCSqGSIb3DQEBCwUA
# MC8GCSqGSIb3DQEJBDEiBCCsDFbsC196FXmT2Z3L/VOKoTOFffV3zUypSE4IlV4Q
# 4zCBpAYLKoZIhvcNAQkQAgwxgZQwgZEwgY4wgYsEFETTk5zNG4h/hnrM2oHsrw9l
# /NJZMHMwX6RdMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52
# LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4
# NCAtIEc0AhABB2SbCLCn/n3WVKjy9Cn2MA0GCSqGSIb3DQEBCwUABIIBgDb4qCMi
# TvV3b2DJRv3iwKlXGMIXCMRziWEs9NeN+Pjh2MRqM2Mbxnt3xaGYvaFFHJYTKN5P
# FJzBhgfMQ6CW1UFraZn3fjzmYm+ACX9feOb7WCd64G1GhkaqKZbq1xfaIrXB6Zj9
# 1UAS4rDpWGA6oDOukRg0tlT1gADA7GDX4NpWno2QXw+G0W16VKIQebyZ7KmBdfD6
# r2p+3mEMqZxCPDdUaYyYt+8VcQc9GTnJJo7DG5TL1WmJhkv1sa4QrwOY2cHOZz+e
# ZKOD8iRuftqwHRpALuByDlr+jP02+7yFivxWN7C7usdqqcYj1lSdW+vnuPLV3ctf
# vLjS/np6u/RHTcCoeVQKJTrICPPAK+5Rfelj7g4Wv0dzSWf8UFc9wZT8V5hY9Y3q
# ebOA2vA72jecX2CFu+L1WqNDKioTPr/yNrTVtl5piwFBy9fOSv170jWle7kRP7Dc
# BsBkUKR697zjq9+/D5hXlf2MjM0TdkcXeyaalPC0GFvMFW+iNOLwZm9lNg==
# SIG # End signature block
