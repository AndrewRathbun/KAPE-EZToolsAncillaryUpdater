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
		4.4 - (May 1, 2025) Fixed https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/25
		4.5 - (June 18, 2025) Fixed https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/26
		4.6 - (October 23, 2026) Update for .NET 10 versions of EZ Tools - https://x.com/EricRZimmerman/status/2113684106416365769
	
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
		Version:			4.6
		===========================================================================
#>
param
(
	[Parameter(HelpMessage = 'Disable the progress bar and exit the script without pausing in the end')]
	[Alias('s')]
	[Switch]$silent,
	[Parameter(HelpMessage = 'Use this if you do not want to check for and update the script')]
	[Alias('dnu')]
	[Switch]$DoNotUpdate,
	[ValidateSet('9', '10')]
	[Alias('n')]
	[string]$net = '10'
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
	
	# https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater/issues/25
	try
	{
		Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
	}
	catch
	{
		Log -logFilePath $logFilePath -msg "ExecutionPolicy cannot be changed to Bypass."
		Log -logFilePath $logFilePath -msg "Current ExecutionPolicy: $(Get-ExecutionPolicy)"
	}
	
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
		'9' { $script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net9' }
		'10' { $script:getZimmermanToolsFolderKapeNetVersion = Join-Path -Path $getZimmermanToolsFolderKape -ChildPath 'net' }
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
		[ValidateSet('9', '10')]
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
		Log -logFilePath $logFilePath -msg "Start-BitsTransfer failed to download $ZTZipFile from $ZTdlUrl. Error: $($_.Exception.Message). Attempting Invoke-WebRequest."
		try
		{
			Invoke-WebRequest -Uri $ZTdlUrl -OutFile (Join-Path $kapeModulesBin $ZTZipFile) -ErrorAction Stop
		}
		catch
		{
			Log -logFilePath $logFilePath -msg "Invoke-WebRequest also failed to download $ZTZipFile from $ZTdlUrl. Error: $($_.Exception.Message)"
		}
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
	
	# Only run if Get-ZimmermanTools.ps1 has downloaded new .NET 6/9/10 tools, otherwise continue on.
	if (Test-Path -Path "$getZimmermanToolsFolderKapeNetVersion")
	{
		if ($net -eq '9')
		{
			Log -logFilePath $logFilePath -msg 'Please ensure you have the latest version of the .NET 9 Runtime installed. You can download it here: https://dotnet.microsoft.com/en-us/download/dotnet/9.0. Please note that the .NET 9 Desktop Runtime includes the Runtime needed for Desktop AND Console applications, aka Registry Explorer AND RECmd, for example'
		}
		else
		{
			Log -logFilePath $logFilePath -msg 'Please ensure you have the latest version of the .NET 10 Runtime installed. You can download it here: https://dotnet.microsoft.com/en-us/download/dotnet/10.0. Please note that the .NET 10 Desktop Runtime includes the Runtime needed for Desktop AND Console applications, aka Registry Explorer AND RECmd, for example'
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
# MIIv7gYJKoZIhvcNAQcCoIIv3zCCL9sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCguo9OFyEd+R4S
# 7lga0irMzoHzlFVVsaXgPp/BzLUgQqCCKNswggQyMIIDGqADAgECAgEBMA0GCSqG
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
# e1rYMIIFcjCCA1qgAwIBAgIQdlP+uT3Z5+kmMqzWCr6sODANBgkqhkiG9w0BAQwF
# ADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEpMCcG
# A1UEAxMgR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgUm9vdCBSNDUwHhcNMjAwMzE4
# MDAwMDAwWhcNNDUwMzE4MDAwMDAwWjBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEpMCcGA1UEAxMgR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgUm9vdCBSNDUwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC6dDPs
# J9wSOCEbxdNhKNZavE/fi8yRhEMkV7xkIbw7HB89T4ytB7fzxdcC6REUgpqqtJRy
# O3ENGu9oa4V5jq9m6liYDbrBfHnS/82zbzFF0AV0BAByaid+uDc/Oojtl4P1qzVN
# D59ZO/Uv31nFfKUydmCWyO3u+AR+GVFyqL9EQXq8ex47AJu8uuCWv5D+jZvDcosA
# EvggOmA498HMhYr7h3kuoSsg5sughZEjtsQoB1Qo3uwQMU+K8s0UHx7dVRzqKDFM
# +SFqqM3zlmf6AUGbzQ8LaH+73vFD6hflsNxwIrNpNll0a8bliSp85QuBXas/j7jR
# dnLzfKKp4pdBv8yMRf5hyfZsBwsABOgVI0+CKi3278P6ETZIodH9ejk6NF2jLA6b
# d1AgNEDdsQMxrV/pYodzlgNh95Sw2VxsT+cUxeHxew0jnM1wjB1q3kotiyq720IU
# BQeq+xTcMdP2H2zLvmhmRHBNbRf5cesFc46RknXraFwe9kRhGCli3RdmiOwouklv
# 2z53/rkxH3UcGKKmR73Y7kiFO/2z4g8/KpjGmvqCb7GlpYYdWjr6pGx0D3dSYWp/
# hyneOZuL7rNFYDAklxUSKoUwkyaslqYt6HBtC6kyrSybKAp2QvJVYVGYlN7t9sUX
# bzwVELAOrbDexRb0ZdHML1pWCM+ZxPBVkcIseQIDAQABo0IwQDAOBgNVHQ8BAf8E
# BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQURrIcd+F7FfClOaFw3tHE
# Luptst4wDQYJKoZIhvcNAQEMBQADggIBABZ8CmdKAzyTKj4cT0ZVsJqeiOHrU/1M
# VXmE+Wy2n6kKtomrVAcUFkpJWvS4LoYUxH4ZifmHiLzsstKVjOAM+fKUZqaYVxuh
# 39FxfYy1+HEC3RO2vvqwMcMsZ+saGA4aTdwszzFcYSipneNqLK5QSw460Gn7ijRE
# 335LjhqQCdox2sovpff0Nyw1DRpizTx7PFZ3ZZVclHNwn2EvaWQjHUx5B8IXfDrt
# qm1xAxRiRcy3PlTYUXFC6juSQqUvVIGjsAxWWFa75JjuZscR+ahFF+JlKore4qjO
# xS329c6t8OMKCd1Te2ypbIZ+od42NQAPX4D9RbtxZkPURCzQuwFOmZ4+TeFeVh8F
# eoIdssstpTO5OeXEt9pC4b3QlEKA+hiUO5NDqMiUOm1+nfxPoMLT5aWqECZvBiJb
# 4AHiSr8Z5USesK2rGdLN60fEYoHs8MJ6jUz9wiW3vCxwjqqtUvQUPKp4HQTTydUl
# gqday4x8H1cCO4cbyNf5VBodyhpLJ7HiSu/nmkAUT6U8n9WjvpQ1nMLXPyjupBcr
# Q71kp9ev6VPnp3cexRIbMeJLxn+eHO6jOpRQXaZQBlJeRQMrtADgwe3YDcGuu0kJ
# gYJaQkOvmWO4FNE8i93V8FTtcmfC9so+NYSHgA1SlVBB1rINGUAvthNN97Fg1HbF
# VzluWqJeCnncMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG
# 9w0BAQwFADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MS0wKwYDVQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYw
# HhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAmyudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxD
# eEDIArCS2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk
# 9vT0k2oWJMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7Xw
# iunD7mBxNtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ
# 0arWZVeffvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZX
# nYvZQgWx/SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+t
# AfiWu01TPhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvr
# n35XGf2RPaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn
# 3UayWW9bAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaR
# XBeF5jAdBgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYD
# VR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RS
# NDYuY3JsMHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEM
# BQADggIBAAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXK
# ZDk8+Y1LoNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWk
# vfPkKaAQsiqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3d
# MapandPfYgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwF
# kvjFV3jS49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZa
# PATHvNIzt+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8b
# kinLrYrKpii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7Ew
# oIJB0kak6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TW
# SenLbjBQUGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg
# 51Tbnio1lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoU
# KD85gnJ+t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGbjCCBNag
# AwIBAgIQIapISB4a5+iZkwwD5xvshjANBgkqhkiG9w0BAQwFADBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTI1MDEyNzAwMDAwMFoXDTI4
# MDEyNzIzNTk1OVowXjELMAkGA1UEBhMCVVMxETAPBgNVBAgMCE1pY2hpZ2FuMR0w
# GwYDVQQKDBRBbmRyZXcgRGF2aWQgUmF0aGJ1bjEdMBsGA1UEAwwUQW5kcmV3IERh
# dmlkIFJhdGhidW4wggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDJCbv0
# c7KjV3stU62ygRxeIhyg8SdDveJlrmmaRELBq9J1s/vyr/kzAW7A8Z3v0wCGOkxg
# J0vLpetrQ/ZUyfIrTCqFJERdjDR4h3tVCb27UzH9ItGHPJr5OxOuacwg/Y4XzwsZ
# heLBP3oMD3wr1sB9ttiNdvDd3SKWW5DKO1zeSVUUSqZ8c87wAnxBeM6cShQa0w2v
# XDuJ3D+EPr2NZTznhHlyT2ilJANynMSI3XWUiuD/s7O5mtUfZJOifNElHToYLrTS
# kdMDxSkXFEuYfm+BeNUZROssM/POgG+Nw++6uc4sgybw1JWCwc2SQgK/VjDyldOL
# GGyGtAAdsKlhH10//MUwlkplW+Li+yd2Cpol8wiWQIDWrHUY7OojDrvLjzTWro3b
# s80T3/2rkKHd2Q92o3tGDDD9ltRhcpVjCMQDfSMh46KMWRCZJRLtqg1hxFYVbcA8
# EEbJx/fNFu4A0xD0nQB3u3kPrL1alsBb2ij7ddpO9z5FyLaMuRwETj1HubX3Yll3
# FSkTNalMFp1VH1xiOR7SZqsa3zpeMFTkdEug9S5YiNnFQIxCdX8oALFT4FxKOW36
# ZaGUL1Gcxd2pEwLynZHOX2lCKAbjt1pzTGzt8vH/m7fU4WhUOc+qkx+qdRFajeMP
# Tt7fcjCB7J1KwxHYPcqocYhG5GnqUGvdsfZhOQIDAQABo4IBsDCCAawwHwYDVR0j
# BBgwFoAUDyrLIIcouOxvSK4rVKYpqhekzQwwHQYDVR0OBBYEFKfATcFPS7aQV95I
# VPJzfC1md5UUMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMEoGA1UdIARDMEEwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYB
# BQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAEEATBJBgNVHR8E
# QjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWND
# b2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEFBQcBAQRtMGswRAYIKwYBBQUHMAKG
# OGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5n
# Q0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAl
# BgNVHREEHjAcgRphbmRyZXcuZC5yYXRoYnVuQGdtYWlsLmNvbTANBgkqhkiG9w0B
# AQwFAAOCAYEABgv/sv2xG4nFHHS9zUjSKjHngWpluXn5tF/G/Lo/jOGaF4vpW3aQ
# njbRpD2845oAqHYlEm2VyG5MUDZUbRlv+zcVwJSMKm8CZ8KtOraL/7HJCbMzpNHe
# MeJGc+CBWUfMYru6OHqG7BBNmyL/xT+chqhBFGwrDrk+RmxhSZ7pbQRevLzaXk2+
# QqCeJ9kU+EiWqXOpuyiDGasxchZvr+9Gb/Ndj+1bpE6laWIfY0VvdG6u+se+V5Za
# zf4j0km8735LJ/Nwm/DPUg3JCI6cCIYCU2CovzWA1I56rjia8jHX6M894eadY3AJ
# Cm95n1iYF7UNx2dgwfbyD6ClYAN0O5eGJSU+5V1gt+SLiFOod0JZqVxCq/lBFZjz
# lLgXMr6Gf6d9TTmN7gWy6F1ELo/pb+LKwlc9RO6BhjzBlF+EEbhYlWcRcMkoKb7j
# NTgL50zdeg0v+9EhCrzPN6BUTrB1nMnfQzsIljQ9RjwvvznlHYmfKfoyv19B4rdU
# ByEj3Te1C1+SMIIGhDCCBGygAwIBAgIRAIRyP7gwDfuodbM7V8wmN4IwDQYJKoZI
# hvcNAQEMBQAwXjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExNDAyBgNVBAMTK0dsb2JhbFNpZ24gT2ZmbGluZSBSNDUgVGltZXN0YW1waW5n
# IENBIDIwMjUwHhcNMjUxMDE1MDcyNDU2WhcNMzcwMTEwMDAwMDAwWjBdMQswCQYD
# VQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEzMDEGA1UEAxMqR2xv
# YmFsc2lnbiBSNDUgVFNBIGZvciBBdXRoZW50aWNvZGUgMjAyNTEwMIIBojANBgkq
# hkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAo5qib0LzOmONbaHJo3ptJ5114tIqUelW
# QN9js0nuN9WjqaPiWBNL5AOxM/dr0tmxVohS4Chuz4W2U6J3IWR+eKF19ZaRti+3
# qylKyGrYFaThdEnRlJ+EB1in0Irq6BSGGL7kAGOviVGvH4hlnvFL4N5XhswQ3l1H
# a3sXdUOCQ5AiXhZPccq60xCJjEEGLdABWJIRKU0mk3ngJGj7X8ryWqCxTUrA//hy
# 2iCY5OscrNA4y+k6xrvFR3pglhgdNAATbIDnwByrxLp7VyaYprrUpY0wxuxc1DjR
# NhrKV+Xf2DK77Huj88GMem2i4WCmSrpU/G2qbl5WbzNN/5w9iig1KY1wg3LrHzs3
# c6RdJh/iHLR9Sjkc7qJLidH3QQzT8TKmZX4weJLb5l17/Z53TFzQ/WO969H3MSCj
# RIsPJC5umBp70EK7CE3GEfFWtgvYig0hVmak3m81VBKI1zG5LcZxbYt3cQmJhZZa
# COvcTjOaIHbYwEzQ8rOEXCHAe8rvW1GJAgMBAAGjggG8MIIBuDAOBgNVHQ8BAf8E
# BAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDAYDVR0TAQH/BAIwADAdBgNV
# HQ4EFgQUpFtFrgk/9CUBPthTUQJp85AI2BYwHwYDVR0jBBgwFoAUdwI7ATEPHnR3
# w0jIwwdjVYilO6IwgaUGCCsGAQUFBwEBBIGYMIGVMEIGCCsGAQUFBzABhjZodHRw
# Oi8vb2NzcC5nbG9iYWxzaWduLmNvbS9nc29mZmxpbmVyNDV0aW1lc3RhbXBjYTIw
# MjUwTwYIKwYBBQUHMAKGQ2h0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2Fj
# ZXJ0L2dzb2ZmbGluZXI0NXRpbWVzdGFtcGNhMjAyNS5jcnQwSgYDVR0fBEMwQTA/
# oD2gO4Y5aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9nc29mZmxpbmVyNDV0aW1l
# c3RhbXBjYTIwMjUuY3JsMEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMA0G
# CSqGSIb3DQEBDAUAA4ICAQBwzMXQamU+SQhZibXBp31NqVIF4I/z0kZD0ozcFy20
# 5DhbUAu8YViH+c82ypDkH3wk2LLrVB/T21VBcfjqDS9p2ormMMBCSJrOB2WBno9H
# ckZzSUgpdPCkH9s7ynoX4RZS/UBL9M2DJVc+hpKbzCNmrQWhkoSTHbTk8/JFhmhi
# X5HPp+hiB8Pc3cX1zHLTN+uNDBoxyzJ6tkmevgalUWKNxCHpICYj9lrJ+bVvBDkx
# Bgr9+bfFuamAUwK2SHW6dEtzHp55mfeTAJNIORc/95V+h+QM8wFgwtpV1EVB1ze4
# po3pxcWjSfAZo4qEvyknEQqqf8yDmNsBmgH7qg/a4NEbgnS+4QuEqLL+5hZvd+Ay
# Jh/nyNw6Rp8lXObSNvahrS23Qm6+Fy90gx2wALq86i70p+QYMcADZcO6NQABlqbG
# h92BzaLYXo7RlC6vMikqGjLgJe4KC5dfiA5E/uEIseLYcD2e4RbL/jHs4TGU91Os
# x3O+S+2dEl65H2HZADgVLJETeXZDvUe4WBOiN6ZwmVf9mIBjvHwt4f6GHWcWg5ZY
# akjdoW+eHKet5xRzkUAJP/wCRCcX9QiyB9WCOLwRWmTycPaLhLO6gt1JgaT8xsX9
# 7eVfaJXs6mkMSzUkz+t++6KWyKOctzAVozo11N9rl4BtPJXVW5VyQTV+bJ059TGL
# oTCCBqAwggSIoAMCAQICEQCD2oY3t58MhAyUe4QKUngfMA0GCSqGSIb3DQEBDAUA
# MFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYD
# VQQDEyBHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBSb290IFI0NTAeFw0yNTA3MTYw
# MzA1MDRaFw00MTA3MTYwMDAwMDBaMF4xCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBH
# bG9iYWxTaWduIG52LXNhMTQwMgYDVQQDEytHbG9iYWxTaWduIE9mZmxpbmUgUjQ1
# IFRpbWVzdGFtcGluZyBDQSAyMDI1MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEApHcW+O19i+LdAoZFYzS+5X+WYvnWoFqXAfir1hynhUTdH4RW1Db+yOmr
# Q275jlsQ6bzoZ3nN0CMncZX4E0Qhpp6Qvx27+flpfzeMQacD7VciWUiF3TLiu7wT
# 2bBCSENUn3hfGMG4PJvYFvO5o4DA1iNvHhG4oSzctodoJfb4c8EjVahCw/NLizB3
# ra+NWe2gZBSaZKraMxFt676yqx7RcQnjbF4R0OLGovsZt23vU69A5BdoPxdA9zu9
# rM+qTBsPDVUJexYwEVU0GY7BJ5mUWWniyAPHW0Wv4Azk5t7I0XUIjA3+2OGkr0dV
# BXVBDyEeGBVrYXEdhfVLwuh6HBGJFdIrEY5KoGlpoT+4BBQe4XCH5sv15Uo+M72V
# KWjPA5Ex3nfFJC4P5FW1SR6olCSaIrtnZzc+zgmpSyiD+GcE2udQRQHbDi74enXg
# azk0+ktpHZ1Z8oTvSaSIREovXSLbH3KC8uFIkXucl7XPH7ZGIrmF9eF4zuoo5FIU
# nsvV60kLqFDzPk+UbLmgZDUCPlFFBBehaaNvixEymx9ON2KXev+MfK6OZChqGbrO
# C2wvvAFHyKlTZbVHdqNiu0u5a2T1C9dSTRny1/hxLwcxL9BWPzQLwhsiyXqUzM7u
# D0lD9+PYMaxUYgoVSxqb4xvPCiVqLNabI+WtjEzYfQ0P+6tBTFsCAwEAAaOCAWIw
# ggFeMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBR3AjsBMQ8edHfDSMjDB2NViKU7ojAfBgNV
# HSMEGDAWgBRGshx34XsV8KU5oXDe0cQu6m2y3jCBjgYIKwYBBQUHAQEEgYEwfzA3
# BggrBgEFBQcwAYYraHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vdGltZXN0YW1w
# cm9vdHI0NTBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvdGltZXN0YW1wcm9vdHI0NS5jcnQwPwYDVR0fBDgwNjA0oDKgMIYu
# aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS90aW1lc3RhbXByb290cjQ1LmNybDAR
# BgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggIBADKj7n7RbuRmMZZY
# XqlMPRJoR6X1n//quXGLVfOpFoR9Ya05L94w0ywBjelyGGf+nAB+CZFQ7gUOd2a2
# bpfpW8Xw5ArM+YjPEf8AtC4E6Yr105U1YNjlTSERoWJKc1hkSN5m4dpsYteFykzF
# QVwX50hYKH3yZ6Vcu6Ha0EA5ofzLpi2jK2jbRDCXbFNLi5mO1xKRdB2AzAF0f5C0
# 0b4H3d5sCOB8njTvAwaTMGEMeTkLWM4Z9Y+3UOtOpo1QuxXbDpXVkLXraG25iL1V
# tvjxEAy4534nUINB9whORicJJSTLba6fOK2f/1QGWEdewWLHAzE+N5oH0QoNRALp
# J5JjIfeInvO+sQdBidnPuLKJ95HTj7XyMvJhFZjtbHJGlEWx4UgKcuNKLDLXWALf
# wQDN2Dey3kTfd4yw4nQdk1PctLLK3F4L2nnLv94BMkpY+Rfl53oOEN4yTvtwCYP+
# VDuZrktc7NacoTVxZnKGkv8a1akckdOwQZC+i8Ay1VyzMAX/Tb4+r3c65B7cpAtq
# 3OoUijXUJgvZxci6TX78smL2TYy2tWn+8G4krnXvy2ELR2XYnKEOS4MVmrSCsjM5
# nxSrghE10VDXQbEfa93lhikfFoIuINKzWDLqvu8ZucmxEufxpHjNnnRVXX/Zv5KQ
# q8pu/MQoOz6DC74n5+O5bSwvT5sgMYIGaTCCBmUCAQEwaDBUMQswCQYDVQQGEwJH
# QjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1
# YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhAhqkhIHhrn6JmTDAPnG+yGMA0GCWCG
# SAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwLwYJKoZIhvcN
# AQkEMSIEIOQC8R8bw5DkXdkfuXmyvAlG1P/RMViod06SR8uUvInlMA0GCSqGSIb3
# DQEBAQUABIICABIXCRtpFZZFvom0doq7Nc3GPoM9DobZcgbpfEZLyzTF+QQUdq9D
# sFBW6W71HVV7ULsp0XC9dGr4SUk8OEauGEZ5frbamXVEod2NDswpVU0iHCzs2sq2
# X6pbqJ9vfCFEwkAoZXjN1z1JXxci5AL+/MAHqwIKquB9e5uW88Fqdd3eua5TRd/X
# vZboK60kU7RFoqkuNoOlOO26iIwjrlyzVUpYStlmKBS7rmuoSNbSfk37okRUkWTO
# TdkPCyq9lBsYqdIV68g0ALUZV0K9FJy2SQr5h0R0j5Yn4yquvO9XCl0+pB6s9VaK
# 8oisd0/j0RsEzEoEF/4hvriD/vMr+Hte/9LIJzZHpyF+I53kiLScXcsQ/zH5XvI1
# sFAgr9bOnQ+AMv9N+QqikJ259SV5Vs73YIOnSFYIrtfqY4eqE3ebW0lB27PS0FfK
# wxhKdtfmwdPAnfJx/F2xmo5Cq9ENLIPzIa/YL77VpdCrju0fjisPtoeeCKapoNaw
# SBKpNpwKHKX+zJGq3S6vpJNj5nPvSRiIz+vTyE1cZ/v8GfWPJr6hfq/ldOxpjgo8
# puuRc03DynRnDNB66SJLf9w4jZuGzX/LKNL8CbTcYJvGRTmQ8OUV0ktQHGifw4CA
# 8LaDfMC5SBAflb8SkQqA56ML8aK/+fGEeulsXT9yfzhSOsOffGtDaM86oYIDhDCC
# A4AGCSqGSIb3DQEJBjGCA3EwggNtAgEBMHMwXjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExNDAyBgNVBAMTK0dsb2JhbFNpZ24gT2ZmbGlu
# ZSBSNDUgVGltZXN0YW1waW5nIENBIDIwMjUCEQCEcj+4MA37qHWzO1fMJjeCMAsG
# CWCGSAFlAwQCAqCCAVEwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG
# 9w0BCQUxDxcNMjYxMDIzMTkyNDMyWjArBgkqhkiG9w0BCTQxHjAcMAsGCWCGSAFl
# AwQCAqENBgkqhkiG9w0BAQwFADA/BgkqhkiG9w0BCQQxMgQwp75jII3bTUy7EooA
# 2VXUuVqCrQfKwkCHcWDH0oJaEgTM5H9mrMy2rLI2Pe/vpI9AMIGoBgsqhkiG9w0B
# CRACDDGBmDCBlTCBkjCBjwQUHSS/Gatriz8ckaZYxdNUZIEjnS4wdzBipGAwXjEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExNDAyBgNVBAMT
# K0dsb2JhbFNpZ24gT2ZmbGluZSBSNDUgVGltZXN0YW1waW5nIENBIDIwMjUCEQCE
# cj+4MA37qHWzO1fMJjeCMA0GCSqGSIb3DQEBDAUABIIBgDGWhmuCOG+zbGjj22A5
# f5S+uu6RMCxg3oGKsQSnygYNOr4VKNqtgZezthbDIk9gg4eAWPTc8lWIyc9GC0W8
# eslSXb3GTpL+2Whsto2FYhnz/iqogfIBmSAw/G5DWBPYEj8dxZyMi5HnScNkgHMU
# pdQ58S2zqERtPPofdNjvQ+9TmY647WIjZ3O0FiUvNPEEU4om/Q055DExrXZhjAfA
# DGvidlGNGfM6hw+Ri1V9bGQ5O2GSWQ9vZ/xMH48SyyvWCgV7eoU7GOVQ9CvDKUPy
# lfkUZKiYajbIrhSA5ks/0D8LqxbbtnHElma+E1U86F/Qa0h4OVIdh8jzQUJtiTkW
# DuzzYBh9cCRuFZOV+6hapDfEQCAWicB/2mkArg065w8ow4S2Bz3FdWjRPliIYqzE
# HL8dRMBSdrLi7VPRodSTdQ6cW3CCexOCMnAxWwcqF3/xbjgwqDR3uNTukFiCD1tW
# y0EjE+oAabC0VnnELkzsQqFZJyMDwDVVM5mnGcq9gf4TyA==
# SIG # End signature block
