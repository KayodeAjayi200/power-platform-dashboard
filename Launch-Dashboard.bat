@echo off
rem ─────────────────────────────────────────────────────────────────────────────
rem  Power Platform Dashboard — double-click this file to open the dashboard.
rem  No typing needed. The window will open automatically.
rem  You can also right-click this file and choose "Pin to taskbar" after
rem  running Create-Shortcut.ps1 once (which puts a proper shortcut on your Desktop).
rem ─────────────────────────────────────────────────────────────────────────────

rem Try PowerShell 7 (pwsh) first — it's faster. Fall back to built-in PowerShell 5.
where pwsh.exe >nul 2>&1
if %errorlevel% == 0 (
    start "" "pwsh.exe" -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0scripts\PowerPlatformDashboard.ps1"
) else (
    start "" "powershell.exe" -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0scripts\PowerPlatformDashboard.ps1"
)
