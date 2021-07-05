# Be sure to run this script from your KAPE root folder, where kape.exe, gkape.exe, Targets, Modules, and Documentation folders exists

Set-ExecutionPolicy Bypass -Scope Process

# If kape.exe is running, comment out the below line 

.\Get-KAPEUpdate.ps1

# This provides the script the scope of what's to be downloaded and eventually extracted, copied, etc

$currentDirectory = Resolve-Path -Path ('.')
$baseUrl = 'https://f001.backblazeb2.com/file/EricZimmermanTools/'
$files = 'AmcacheParser.zip',
         'AppCompatCacheParser.zip',
         'bstrings.zip',
         'EvtxExplorer.zip',
         'JLECmd.zip',
         'LECmd.zip',
         'MFTECmd.zip',
         'PECmd.zip',
         'RBCmd.zip',
         'RecentFileCacheParser.zip',
         'RegistryExplorer_RECmd.zip',
         'ShellBagsExplorer.zip',
         'SQLECmd.zip',
         'SumECmd.zip',
         'SrumECmd.zip',
         'WxTCmd.zip'

# This tells the script that for each of the above, download the binary from the joined URL, send to a Temp folder, expand the contents of the archive, and delete the archive

foreach ($file in $files)
{
   $binPath = Join-Path -Path "$currentDirectory" -ChildPath "\Modules\bin" -Resolve
   Write-Host "Downloading $file"
   $dlUrl = "$($baseUrl)$file"
   $TempPath = Join-Path $currentDirectory -ChildPath "$file" 
   Invoke-WebRequest $dlUrl -OutFile $TempPath
   $progressPreference = 'Continue'
   Expand-Archive -Path $file -DestinationPath "$currentDirectory\Temp" -Force -ErrorAction:Stop -Verbose
   Remove-Item -Path $file # comment this line out if you want to maintain copies of the archives downloaded
}

# This ensures all the latest KAPE Targets and Modules are downloaded

Write-Host "Syncing KAPE with GitHub for the latest Targets and Modules"

& "$currentDirectory\kape.exe" --sync # works without Admin privs as of KAPE 1.0.0.3

# This ensures all the latest EvtxECmd Maps are downloaded

Write-Host "Syncing EvtxECmd with GitHub for the latest Maps"

& "$currentDirectory\Temp\EvtxExplorer\EvtxECmd.exe" --sync

# This ensures all the latest RECmd Batch files are downloaded

Write-Host "Syncing RECmd with GitHub for the latest Batch files"

& "$currentDirectory\Temp\RegistryExplorer\RECmd.exe" --sync

# This deletes the SQLECmd\Maps folder so old Maps don't collide with new ones

Write-Host "Deleting .\KAPE\Temp\SQLECmd\Maps for a fresh start prior to syncing SQLECmd with GitHub"

Remove-Item -Path $currentDirectory\Temp\SQLECmd\Maps\* -Recurse -Force

# This ensures all the latest SQLECmd Maps are downloaded

Write-Host "Syncing SQLECmd with GitHub for the latest Maps"

& "$currentDirectory\Temp\SQLECmd\SQLECmd.exe" --sync

# This removes GUI tools and other files/folders that the CLI tools don't utilize prior to copying to the KAPE\Modules\bin folder

Write-Host "Removing unnecessary files from .\KAPE\Temp"

Remove-Item -Path $currentDirectory\Temp\RegistryExplorer\Bookmarks -Recurse -Force
Remove-Item -Path $currentDirectory\Temp\RegistryExplorer\Settings -Recurse -Force 
Remove-Item -Path $currentDirectory\Temp\RegistryExplorer\RegistryExplorer.exe -Recurse -Force
Remove-Item -Path $currentDirectory\Temp\RegistryExplorer\RegistryExplorerManual.pdf -Recurse -Force
Remove-Item -Path $currentDirectory\Temp\ShellBagsExplorer\ShellBagsExplorer.exe -Recurse -Force

Write-Host "Removed unnecessary files from .\KAPE\Temp successfully"

# Copies tools that require subfolders for Maps, Batch Files, etc

Write-Host "Copying EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin"

Copy-Item -Path $currentDirectory\Temp\EvtxExplorer -Destination $binPath\EvtxECmd -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\RegistryExplorer -Destination $binPath\RECmd -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\SQLECmd -Destination $binPath\SQLECmd -Recurse -Force

Write-Host "Copied EvtxECmd, RECmd, and SQLECmd and all associated ancillary files to .\KAPE\Modules\bin successfully"

# Copies tools that don't require subfolders

Write-Host "Copying remaining EZ Tools binaries to .\KAPE\Modules\bin"

Copy-Item -Path $currentDirectory\Temp\AmcacheParser.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\AppCompatCacheParser.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\bstrings.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\JLECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\LECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\MFTECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\PECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\RBCmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\RecentFileCacheParser.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\ShellBagsExplorer\SBECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\SrumECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\SumECmd.exe -Destination $binPath\ -Recurse -Force
Copy-Item -Path $currentDirectory\Temp\WxTCmd.exe -Destination $binPath\ -Recurse -Force

Write-Host "Copied remaining EZ Tools binaries to .\KAPE\Modules\bin successfully"

Remove-Item -Path $currentDirectory\Temp -Recurse -Force

Write-Host "Removed .\KAPE\Temp and all its contents successfully"
Write-Host "Thank you for keeping this instance of KAPE updated! Please be sure to run this script on a regular basis and follow the GitHub repositories associated with KAPE and EZ Tools!"
