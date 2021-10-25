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
# SIG # Begin signature block
# MIIOCQYJKoZIhvcNAQcCoIIN+jCCDfYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVs3UvuuEuB01GT+sMq4Cf8Nh
# hwugggtAMIIFQzCCBCugAwIBAgIRAOhGMy2+0dm4G+A32Y4gvJwwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3Rl
# cjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQw
# IgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EwHhcNMTkxMjI1MDAw
# MDAwWhcNMjMwMzI0MjM1OTU5WjCBkjELMAkGA1UEBhMCVVMxDjAMBgNVBBEMBTQ2
# MDQwMQswCQYDVQQIDAJJTjEQMA4GA1UEBwwHRmlzaGVyczEcMBoGA1UECQwTMTU2
# NzIgUHJvdmluY2lhbCBMbjEaMBgGA1UECgwRRXJpYyBSLiBaaW1tZXJtYW4xGjAY
# BgNVBAMMEUVyaWMgUi4gWmltbWVybWFuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAtU2gix6QVzDg+YBDDNyZj1kPFwPDhTbojEup24x3swWNCI14P4dM
# Cs6SKDUPmKhe8k5aLpv9eacsgyndyYkrcSGFCwUwbTnetrn8lzOFu53Vz4sjFIMl
# mKVSPfKE7GBoBcJ8jT3LKoB7YzZF6khoQY84fOJPNOj7snfExN64J6KVQlDsgOjL
# wY720m8bN/Rn+Vp+FBXHyUIjHhhvb+o29xFmemxzfTWXhDM2oIX4kRuF/Zmfo9l8
# n3J+iOBL/IiIVTi68adYxq3s0ASxgrQ4HO3veGgzNZ9KSB1ltXyNVGstInIs+UZP
# lKynweRQJO5cc7zK64sSotjgwlcaQdBAHQIDAQABo4IBpzCCAaMwHwYDVR0jBBgw
# FoAUDuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFGsRm7mtwiWCh8MSEbEX
# TwjtcryvMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsGAQQB
# sjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzBD
# BgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29S
# U0FDb2RlU2lnbmluZ0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUHMAKG
# Mmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0Eu
# Y3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAfBgNVHREE
# GDAWgRRlcmljQG1pa2VzdGFtbWVyLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAhX//
# xLBhfLf4X2OPavhp/AlmnpkQU8yIZv8DjVQKJ0j8YhxClIAgyuSb/6+q+njOsxMn
# ZDoCAPlzG0P74e1nYTiw3beG6ePr3uDc9PjUBxDiHgxlI69mlXYdjiAircV5Z8iU
# TcmqJ9LpnTcrvtmQAvN1ldoSW4hmHIJuV0XLOhvAlURuPM1/C9lh0K65nH3wYIoU
# /0pELlDfIdUxL2vOLnElxCv0z07Hf9yw+3grWHJb54Vms6o/xYxZgqCu02DH0q1f
# KrNBwtDkLKKObBF54wA7LdaDGbl3CJXQVRmgokcDI/izmZJxHAHebdbj4zVFyCND
# sMRySmbR+m58q/jv3DCCBfUwggPdoAMCAQICEB2iSDBvmyYY0ILgln0z02owDQYJ
# KoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5
# MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBO
# ZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0
# aG9yaXR5MB4XDTE4MTEwMjAwMDAwMFoXDTMwMTIzMTIzNTk1OVowfDELMAkGA1UE
# BhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2Fs
# Zm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdv
# IFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCGIo0yhXoYn0nwli9jCB4t3HyfFM/jJrYlZilAhlRGdDFixRDtsocnppnL
# lTDAVvWkdcapDlBipVGREGrgS2Ku/fD4GKyn/+4uMyD6DBmJqGx7rQDDYaHcaWVt
# H24nlteXUYam9CflfGqLlR5bYNV+1xaSnAAvaPeX7Wpyvjg7Y96Pv25MQV0SIAhZ
# 6DnNj9LWzwa0VwW2TqE+V2sfmLzEYtYbC43HZhtKn52BxHJAteJf7wtF/6POF6Yt
# VbC3sLxUap28jVZTxvC6eVBJLPcDuf4vZTXyIuosB69G2flGHNyMfHEo8/6nxhTd
# VZFuihEN3wYklX0Pp6F8OtqGNWHTAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBRT
# eb9aqitKz1SA4dibwJ3ysgNmyzAdBgNVHQ4EFgQUDuE6qFM6MdWKvsG7rWcaA4Wt
# NA4wDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0lBBYw
# FAYIKwYBBQUHAwMGCCsGAQUFBwMIMBEGA1UdIAQKMAgwBgYEVR0gADBQBgNVHR8E
# STBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNB
# Q2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEEajBoMD8GCCsG
# AQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQWRk
# VHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5j
# b20wDQYJKoZIhvcNAQEMBQADggIBAE1jUO1HNEphpNveaiqMm/EAAB4dYns61zLC
# 9rPgY7P7YQCImhttEAcET7646ol4IusPRuzzRl5ARokS9At3WpwqQTr81vTr5/cV
# lTPDoYMot94v5JT3hTODLUpASL+awk9KsY8k9LOBN9O3ZLCmI2pZaFJCX/8E6+F0
# ZXkI9amT3mtxQJmWunjxucjiwwgWsatjWsgVgG10Xkp1fqW4w2y1z99KeYdcx0BN
# YzX2MNPPtQoOCwR/oEuuu6Ol0IQAkz5TXTSlADVpbL6fICUQDRn7UJBhvjmPeo5N
# 9p8OHv4HURJmgyYZSJXOSsnBf/M6BZv5b9+If8AjntIeQ3pFMcGcTanwWbJZGehq
# jSkEAnd8S0vNcL46slVaeD68u28DECV3FTSK+TbMQ5Lkuk/xYpMoJVcp+1EZx6El
# QGqEV8aynbG8HArafGd+fS7pKEwYfsR7MUFxmksp7As9V1DSyt39ngVR5UR43QHe
# sXWYDVQk/fBO4+L4g71yuss9Ou7wXheSaG3IYfmm8SoKC6W59J7umDIFhZ7r+YMp
# 08Ysfb06dy6LN0KgaoLtO0qqlBCk4Q34F8W2WnkzGJLjtXX4oemOCiUe5B7xn1qH
# I/+fpFGe+zmAEc3btcSnqIBv5VPU4OOiwtJbGvoyJi1qV3AcPKRYLqPzW0sH3DJZ
# 84enGm1YMYICMzCCAi8CAQEwgZEwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2Vj
# dGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcg
# Q0ECEQDoRjMtvtHZuBvgN9mOILycMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTuFWauqVXNz11C
# 7aiinRgBL0HXDDANBgkqhkiG9w0BAQEFAASCAQCNkEs9ZzpU1PiYXA5T7f07sOet
# 5wNyV/ruSkU7FElNqHI5jEDQNfN+ve+ItSlzcC3BB278Pz6E9ecBH8f5rpL6xVGk
# TujQ3aEVvLJcVWLZB0V9njgs6q5Vx5ns2ZdDN+XTovekgGkslNdRd2/BzpvsFn6l
# 6JG2zUJrwRi6FXK62vOMHnxE+5YrOtIRpe8HSOf6+5wwLvqca/Aavg3lh7QDH2cF
# u0Do8k+rvaJrElG6z2wUDxuXv995RIdCBxsr5cQeKUArDFLN4d4e8NDImGQoaEGd
# b4BO2SkNdvCq1ppkGuOsoMvDuzUvui8aQjTjOaZTYBurVPbzI8TqQ/DXathg
# SIG # End signature block
