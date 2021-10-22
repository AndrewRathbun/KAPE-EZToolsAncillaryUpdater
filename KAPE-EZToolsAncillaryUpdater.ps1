# Written by: Andrew Rathbun, Senior Associate, Kroll
# Email: andrew.rathbun@kroll.com
# Version: 2.0
# GitHub: https://github.com/AndrewRathbun/KAPE-EZToolsAncillaryUpdater
# This script requires Get-KAPEUpdate.ps1 and kape.exe to be present. If you don't have those, download them from here: https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape
# Be sure to run this script from your KAPE root folder, i.e., where kape.exe, gkape.exe, Targets, Modules, and Documentation folders exists

Set-ExecutionPolicy Bypass -Scope Process

# If kape.exe is running, comment out the below line

if (Test-Path -Path $PSScriptRoot\Get-KAPEUpdate.ps1)
{
Write-Host (Get-Date).ToString() "| Running Get-KAPEUpdate.ps1 to update KAPE to the latest binary" -ForegroundColor Yellow
.\Get-KAPEUpdate.ps1
}
else
{
Write-Host (Get-Date).ToString() "| Get-KAPEUpdate.ps1 not found, please go download KAPE from https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape" -ForegroundColor Red
Exit
}

# Setting variables the script relies on

$currentDirectory = Resolve-Path -Path ('.')

$zToolsDir = Join-Path -Path $currentDirectory -ChildPath 'ZimmermanTools'

$ZTZipFile = 'Get-ZimmermanTools.zip'

$ZTdlUrl = 'https://f001.backblazeb2.com/file/EricZimmermanTools/Get-ZimmermanTools.zip'

# Download Get-ZimmermanTools.zip and extract from archive

Write-Host (Get-Date).ToString() "| Downloading $ZTZipFile" from $ZTdlUrl to $zToolsDir -ForegroundColor Yellow

Start-BitsTransfer -Source $ZTdlUrl -Destination $currentDirectory

Expand-Archive -Path $currentDirectory\$ZTZipFile -DestinationPath "$currentDirectory\ZimmermanTools" -Force -ErrorAction:Stop

# Download all EZ Tools and place in .\KAPE\ZimmermanTools

& "$zToolsDir\Get-ZimmermanTools.ps1" -Dest $zToolsDir

# This ensures all the latest KAPE Targets and Modules are downloaded

if (Test-Path -Path $PSScriptRoot\kape.exe)
{
Write-Host (Get-Date).ToString() "| Syncing KAPE with GitHub for the latest Targets and Modules" -ForegroundColor Yellow
& "$PSScriptRoot\kape.exe" --sync # works without Admin privs as of KAPE 1.0.0.3
}
else
{
Write-Host (Get-Date).ToString() "| kape.exe not found, please go download KAPE from https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape" -ForegroundColor Red
Exit
}

# This ensures all the latest EvtxECmd Maps are downloaded

Write-Host (Get-Date).ToString() "| Syncing EvtxECmd with GitHub for the latest Maps" -ForegroundColor Yellow

& "$currentDirectory\ZimmermanTools\EvtxExplorer\EvtxECmd.exe" --sync

# This ensures all the latest RECmd Batch files are downloaded

Write-Host (Get-Date).ToString() "| Syncing RECmd with GitHub for the latest Batch files" -ForegroundColor Yellow

& "$currentDirectory\ZimmermanTools\RegistryExplorer\RECmd.exe" --sync

# This deletes the SQLECmd\Maps folder so old Maps don't collide with new ones

Write-Host (Get-Date).ToString() "| Deleting .\KAPE\ZimmermanTools\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub" -ForegroundColor Yellow

Remove-Item -Path $currentDirectory\ZimmermanTools\SQLECmd\Maps\* -Recurse -Force

# This ensures all the latest SQLECmd Maps are downloaded

Write-Host (Get-Date).ToString() "| Syncing SQLECmd with GitHub for the latest Maps" -ForegroundColor Yellow

& "$currentDirectory\ZimmermanTools\SQLECmd\SQLECmd.exe" --sync

$binPath = "$PSScriptRoot\Modules\bin"

# Copies tools that require subfolders for Maps, Batch Files, etc

Write-Host (Get-Date).ToString() "| Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin" -ForegroundColor Yellow

& Copy-Item -Path $PSScriptRoot\ZimmermanTools\EvtxExplorer -Destination $binPath\EvtxECmd -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\RegistryExplorer -Destination $binPath\RECmd -Recurse -Force
& Copy-Item -Path $PSScriptRoot\ZimmermanTools\SQLECmd -Destination $binPath\SQLECmd -Recurse -Force

Write-Host (Get-Date).ToString() "| Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin successfully" -ForegroundColor Yellow

# Copies tools that don't require subfolders

Write-Host (Get-Date).ToString() "| Copying remaining EZ Tools binaries to .\KAPE\Modules\bin" -ForegroundColor Yellow

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

Write-Host (Get-Date).ToString() "| Copied remaining EZ Tools binaries to .\KAPE\Modules\bin successfully" -ForegroundColor Yellow

# This removes GUI tools and other files/folders that the CLI tools don't utilize within the KAPE\Modules\bin folder

Write-Host (Get-Date).ToString() "| Removing unnecessary files (GUI tools/unused files) from .\KAPE\Modules\bin" -ForegroundColor Yellow

$RECmdBookmarks = "$binPath\RECmd\Bookmarks"
if (Test-Path -Path $RECmdBookmarks)
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\Bookmarks exists! These files are not needed for RECmd and will be deleted" -ForegroundColor Red
Remove-Item -Path $binPath\RECmd\Bookmarks -Recurse -Force
}
else
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\Bookmarks does not exist. No further action needed" -ForegroundColor Green
}

$RECmdSettings = "$binPath\RECmd\Settings"
if (Test-Path -Path $RECmdSettings)
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\Settings exists! These files are not needed for RECmd and will be deleted" -ForegroundColor Red
Remove-Item -Path $binPath\RECmd\Settings -Recurse -Force
}
else
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\Settings does not exist. No further action needed" -ForegroundColor Green
}

$RECmdRegistryExplorerGUI = "$binPath\RECmd\RegistryExplorer.exe"
if (Test-Path -Path $RECmdRegistryExplorerGUI)
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\RegistryExplorer.exe exists! This is a GUI tool and is not needed" -ForegroundColor Red
Remove-Item -Path $binPath\RECmd\RegistryExplorer.exe -Recurse -Force
}
else
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\RegistryExplorer.exe does not exist. No further action needed" -ForegroundColor Green
}

$RECmdRegistryExplorerManual = "$binPath\RECmd\RegistryExplorerManual.pdf"
if (Test-Path -Path $RECmdRegistryExplorerManual)
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\RegistryExplorerManual.pdf exists! This is not needed by KAPE and will be deleted" -ForegroundColor Red
Remove-Item -Path $binPath\RECmd\RegistryExplorerManual.pdf -Recurse -Force
}
else
{
Write-Host (Get-Date).ToString() "| .\KAPE\Modules\bin\RECmd\RegistryExplorerManual.pdf does not exist. No further action needed" -ForegroundColor Green
}

Write-Host (Get-Date).ToString() "| Removed unnecessary files (GUI tools/unused files) from .\KAPE\Modules\bin successfully" -ForegroundColor Yellow

# & Remove-Item -Path $PSScriptRoot\ZimmermanTools -Recurse -Force # Remove comment if you want the ZimmermanTools folder to be gone
# Write-Host (Get-Date).ToString() "| Removed .\KAPE\ZimmermanTools and all its contents successfully"

& Remove-Item -Path $PSScriptRoot\Get-ZimmermanTools.zip -Recurse -Force

Write-Host (Get-Date).ToString() "| Removed .\KAPE\Get-ZimmermanTools.zip successfully" -ForegroundColor Yellow

Write-Host (Get-Date).ToString() "| Thank you for keeping this instance of KAPE updated! Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!" -ForegroundColor Green

Pause
