<#
.SYNOPSIS
    Creates a Desktop shortcut for the Power Platform Dashboard so you can
    double-click it to open the app, and optionally pin it to the taskbar.

.DESCRIPTION
    Run this script once after cloning the repo.
    It will place a shortcut called "Power Platform Dashboard" on your Desktop.

    To pin to the taskbar after running this script:
      1. Find the shortcut on your Desktop
      2. Right-click it → Pin to taskbar

    No technical knowledge needed — just run this script and follow the message.
#>

# Work out where this script lives (the repo root folder)
$repoRoot = $PSScriptRoot

# The main dashboard PowerShell script
$dashboardScript = Join-Path $repoRoot "scripts\PowerPlatformDashboard.ps1"

# Decide which PowerShell to use — prefer the newer PS 7 (pwsh) if installed
$psExe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }

# Build the Desktop shortcut (.lnk file)
$shortcutPath = Join-Path $env:USERPROFILE "Desktop\Power Platform Dashboard.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath       = $psExe
$shortcut.Arguments        = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dashboardScript`""
$shortcut.WorkingDirectory = $repoRoot
$shortcut.Description      = "Power Platform Dashboard — manage Power Apps, Dataverse, and SharePoint without typing commands"

# Use the PowerShell icon — it has a recognisable look
$shortcut.IconLocation = "$psExe,0"
$shortcut.Save()

Write-Host ""
Write-Host "✅ Shortcut created on your Desktop: 'Power Platform Dashboard'"
Write-Host ""
Write-Host "👉 To pin it to the taskbar:"
Write-Host "   1. Find 'Power Platform Dashboard' on your Desktop"
Write-Host "   2. Right-click it"
Write-Host "   3. Choose 'Pin to taskbar'"
Write-Host ""
Write-Host "From then on, just click the icon in your taskbar to open the dashboard."
