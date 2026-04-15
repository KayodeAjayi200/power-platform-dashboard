<#
.SYNOPSIS
    Switch the active Dataverse environment used by the Dataverse MCP server.

.DESCRIPTION
    Lists all available Dataverse environments from PAC CLI, lets you pick one
    interactively or by name, updates ~/.copilot/mcp-config.json with the new
    ConnectionUrl, and reminds you to start a new Copilot CLI session.

.PARAMETER EnvironmentName
    Optional. The friendly name of the environment to switch to (partial match supported).
    If omitted, an interactive numbered menu is shown.

.EXAMPLE
    .\Switch-DataverseEnvironment.ps1
    .\Switch-DataverseEnvironment.ps1 -EnvironmentName "Kay's Environment"
    .\Switch-DataverseEnvironment.ps1 -EnvironmentName "Xhub"
#>
[CmdletBinding()]
param(
    [string]$EnvironmentName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$McpConfigPath = Join-Path $env:USERPROFILE '.copilot\mcp-config.json'

# ── 1. Verify prerequisites ───────────────────────────────────────────────────
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Error "PAC CLI not found. Install it with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
    exit 1
}
if (-not (Test-Path $McpConfigPath)) {
    Write-Error "MCP config not found at $McpConfigPath"
    exit 1
}

# ── 2. Get environment list from PAC ─────────────────────────────────────────
Write-Host "`n🔍 Fetching environments from Power Platform..." -ForegroundColor Cyan
$pacOutput = pac env list 2>&1

# Parse lines that look like environment table rows
$envLines = $pacOutput | Where-Object {
    $_ -match '^\s*\S.*https://.*\.dynamics\.com'
}

if (-not $envLines) {
    Write-Error "Could not parse environments from 'pac env list'. Are you logged in? Run: pac auth create --tenant $tenantId"
}

# Build list of objects: Name + Url
$environments = @()
foreach ($line in $envLines) {
    if ($line -match '(https://[^\s]+\.dynamics\.com/?)') {
        $url = $Matches[1]
        if (-not $url.EndsWith('/')) { $url += '/' }
        # Name is everything before the URL on the line, trimmed
        $name = ($line -replace 'https://.*', '').Trim()
        $name = $name -replace '\s{2,}', ' '  # collapse whitespace
        $environments += [PSCustomObject]@{ Name = $name; Url = $url }
    }
}

if ($environments.Count -eq 0) {
    Write-Error "No environments with Dataverse URLs found. Check 'pac env list' output."
}

# ── 3. Select environment ─────────────────────────────────────────────────────
$selected = $null

if ($EnvironmentName) {
    $selected = $environments | Where-Object { $_.Name -like "*$EnvironmentName*" } | Select-Object -First 1
    if (-not $selected) {
        Write-Error "No environment matching '$EnvironmentName'. Run without -EnvironmentName to see all options."
    }
} else {
    Write-Host "`nAvailable Dataverse Environments:" -ForegroundColor Yellow
    Write-Host ("─" * 70) -ForegroundColor DarkGray
    for ($i = 0; $i -lt $environments.Count; $i++) {
        Write-Host ("  [{0,2}]  {1}" -f ($i + 1), $environments[$i].Name) -ForegroundColor White
        Write-Host ("        {0}" -f $environments[$i].Url) -ForegroundColor DarkGray
    }
    Write-Host ("─" * 70) -ForegroundColor DarkGray
    $choice = Read-Host "`nEnter number (1-$($environments.Count))"
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $environments.Count) {
        Write-Error "Invalid selection: $choice"
    }
    $selected = $environments[$idx]
}

Write-Host "`n✅ Selected: $($selected.Name)" -ForegroundColor Green
Write-Host "   URL: $($selected.Url)" -ForegroundColor Cyan

# ── 4. Update mcp-config.json ─────────────────────────────────────────────────
$config = Get-Content $McpConfigPath -Raw | ConvertFrom-Json

$dataverseServer = $config.mcpServers.dataverse
if (-not $dataverseServer) {
    Write-Error "No 'dataverse' server found in $McpConfigPath"
}

$args = $dataverseServer.args
if (-not $args) {
    Write-Error "'dataverse' server has no args array in $McpConfigPath"
}

# Find --ConnectionUrl index and update the next element
$connIdx = [array]::IndexOf($args, '--ConnectionUrl')
if ($connIdx -ge 0 -and $connIdx + 1 -lt $args.Count) {
    $args[$connIdx + 1] = $selected.Url
} else {
    Write-Error "--ConnectionUrl not found in dataverse server args. Please check $McpConfigPath"
}

$config.mcpServers.dataverse.args = $args
$config | ConvertTo-Json -Depth 10 | Set-Content $McpConfigPath -Encoding UTF8

Write-Host "`n💾 Updated $McpConfigPath" -ForegroundColor Green
Write-Host "`n⚠️  IMPORTANT: Start a new Copilot CLI session for the change to take effect." -ForegroundColor Yellow
Write-Host "   The MCP server reads ConnectionUrl at startup only.`n" -ForegroundColor DarkGray
