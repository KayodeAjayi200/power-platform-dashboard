<#
.SYNOPSIS
    One-click installer for the Power Platform Dashboard toolchain.
    Run this on any new Windows machine to get everything set up.

.EXAMPLE
    .\Install-PPDashboard.ps1
#>

$ErrorActionPreference = "Continue"

function Step([string]$msg) {
    Write-Host "`n━━ $msg" -ForegroundColor Cyan
}

function Ok([string]$msg)   { Write-Host "  ✅ $msg" -ForegroundColor Green }
function Warn([string]$msg) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
function Err([string]$msg)  { Write-Host "  ❌ $msg" -ForegroundColor Red }

function Need([string]$cmd) { return -not (Get-Command $cmd -ErrorAction SilentlyContinue) }

Write-Host @"

  ⚡ Power Platform Dashboard — Installer
  ────────────────────────────────────────
  This installs all CLI tools, MCP servers, and the dashboard GUI.
  It will NOT affect your existing apps or files.

"@ -ForegroundColor Magenta

# ── 1. Core CLI tools ──────────────────────────────────────────────────────────
Step "Installing core CLI tools..."

$wingetPkgs = @(
    @{ id="Microsoft.PowerPlatformCLI"; name="PAC CLI"       }
    @{ id="Microsoft.AzureCLI";         name="Azure CLI"      }
    @{ id="GitHub.cli";                 name="GitHub CLI"     }
)
foreach ($pkg in $wingetPkgs) {
    if (winget list --id $pkg.id --accept-source-agreements 2>&1 | Select-String $pkg.id) {
        Ok "$($pkg.name) already installed"
    } else {
        Write-Host "  Installing $($pkg.name)..." -NoNewline
        winget install --id $pkg.id --silent --accept-package-agreements --accept-source-agreements | Out-Null
        Ok "$($pkg.name) installed"
    }
}

# m365 CLI
if (Need "m365") {
    Write-Host "  Installing m365 CLI..." -NoNewline
    npm install -g @pnp/cli-microsoft365 --silent 2>&1 | Out-Null
    Ok "m365 CLI installed"
} else { Ok "m365 CLI already installed" }

# PnP.PowerShell
if (-not (Get-Module -ListAvailable PnP.PowerShell)) {
    Write-Host "  Installing PnP.PowerShell..." -NoNewline
    Install-Module PnP.PowerShell -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue | Out-Null
    Ok "PnP.PowerShell installed"
} else { Ok "PnP.PowerShell already installed" }

# ── 2. GitHub CLI extensions ───────────────────────────────────────────────────
Step "Installing GitHub CLI extensions..."
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh extension install github/gh-copilot 2>&1 | Out-Null
    Ok "gh-copilot extension installed"
} else { Warn "gh CLI not found — skipping extensions (restart and re-run after gh installs)" }

# ── 3. .NET MCP tools ──────────────────────────────────────────────────────────
Step "Installing .NET MCP servers..."
$dotnetTools = @(
    @{ pkg="Microsoft.PowerPlatform.Dataverse.MCP"; cmd="dataverse-mcp" }
    @{ pkg="Microsoft.PowerPlatform.Canvas.MCP";    cmd="canvas-mcp"    }
)
foreach ($t in $dotnetTools) {
    $installed = dotnet tool list -g 2>&1 | Select-String $t.pkg
    if (-not $installed) {
        dotnet tool install -g $t.pkg 2>&1 | Out-Null
        Ok "$($t.pkg) installed"
    } else { Ok "$($t.pkg) already installed" }
}

# ── 4. npm MCP servers ─────────────────────────────────────────────────────────
Step "Installing npm MCP servers..."
$npmPkgs = @(
    "@microsoft/copilot-studio-mcp"
    "@modelcontextprotocol/server-github"
    "@tiberriver256/mcp-server-azure-devops"
    "@modelcontextprotocol/server-filesystem"
    "@kazuph/mcp-fetch"
    "@playwright/mcp"
)
foreach ($pkg in $npmPkgs) {
    npm install -g $pkg --silent 2>&1 | Out-Null
    Ok "$pkg installed"
}

# ── 5. MCP config ──────────────────────────────────────────────────────────────
Step "Setting up MCP config..."
$mcpPath = Join-Path $env:USERPROFILE ".copilot\mcp-config.json"
if (-not (Test-Path $mcpPath)) {
    $mcpDir = Split-Path $mcpPath
    if (-not (Test-Path $mcpDir)) { New-Item -ItemType Directory $mcpDir | Out-Null }
    $template = Join-Path $PSScriptRoot "mcp-config-template.json"
    if (Test-Path $template) {
        Copy-Item $template $mcpPath
        Ok "MCP config created from template"
    } else {
        Warn "mcp-config-template.json not found — MCP config not created"
    }
} else { Ok "MCP config already exists at $mcpPath" }

# ── 6. PAC auth ────────────────────────────────────────────────────────────────
Step "Power Platform authentication..."
$authList = pac auth list 2>&1
if ($authList -match "No profiles") {
    Write-Host "  Opening browser for Power Platform login..." -ForegroundColor Yellow
    pac auth create
} else { Ok "Already authenticated to Power Platform" }

# ── 7. GitHub auth ─────────────────────────────────────────────────────────────
Step "GitHub authentication..."
$ghStatus = gh auth status 2>&1
if ($ghStatus -match "not logged in") {
    Write-Host "  Opening browser for GitHub login..." -ForegroundColor Yellow
    gh auth login
} else { Ok "Already authenticated to GitHub" }

# ── Done ───────────────────────────────────────────────────────────────────────
Write-Host @"

  ✅  All done! Launch the dashboard with:

      .\Launch-Dashboard.ps1

  Or open the Settings tab to configure your GitHub PAT,
  Dataverse connection URL, and AI provider.

  📖 Full guide:    https://github.com/KayodeAjayi200/power-platform-dashboard
  🤖 Agent skill:   https://raw.githubusercontent.com/KayodeAjayi200/power-platform-dashboard/main/AGENT_SKILL.md

"@ -ForegroundColor Green
