# AGENT_SKILL: Power Platform Dashboard Setup

> **Instructions for AI agents.**  
> This file tells you, the AI, exactly how to set up the Power Platform Dashboard on a user's Windows machine.  
> Follow every step in order. Run PowerShell commands using your tool-execution capability.  
> Ask the user before opening any browser window for authentication.

---

## What you are setting up

A WinForms GUI dashboard that lets non-developers manage Power Platform solutions, GitHub sync, ALM pipelines, disposable environments, canvas app AI tools, and more — all without touching the command line.

---

## Prerequisites check

Run this first to see what is already installed:

```powershell
@{
  PowerShell  = $PSVersionTable.PSVersion.ToString()
  Node        = (node --version 2>$null)
  DotNet      = (dotnet --version 2>$null)
  Git         = (git --version 2>$null)
  WinGet      = (winget --version 2>$null)
  PAC         = (pac --version 2>$null)
  AzCLI       = (az --version 2>$null | Select-Object -First 1)
  GH          = (gh --version 2>$null | Select-Object -First 1)
} | Format-List
```

Install anything missing using the steps below.

---

## Step 1 — Install core tools

Run each block. Skip any that are already installed (check output from prerequisites check).

### PowerShell 7
```powershell
winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
```

### Node.js 20 LTS
```powershell
winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
```

### .NET 8 SDK
```powershell
winget install --id Microsoft.DotNet.SDK.8 --silent --accept-package-agreements --accept-source-agreements
```

### Git
```powershell
winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
```

### PAC CLI (Power Platform CLI)
```powershell
winget install --id Microsoft.PowerPlatformCLI --silent --accept-package-agreements --accept-source-agreements
```

### Azure CLI
```powershell
winget install --id Microsoft.AzureCLI --silent --accept-package-agreements --accept-source-agreements
```

### GitHub CLI
```powershell
winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
```

### m365 CLI (SharePoint & Teams)
```powershell
npm install -g @pnp/cli-microsoft365
```

### PnP.PowerShell (SharePoint deep operations)
```powershell
Install-Module PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
```

---

## Step 2 — Install GitHub Copilot extension

```powershell
gh extension install github/gh-copilot
```

---

## Step 3 — Install .NET MCP tools

```powershell
dotnet tool install -g Microsoft.PowerPlatform.Dataverse.MCP
dotnet tool install -g Microsoft.PowerPlatform.Canvas.MCP
```

If either fails with "already installed", run with `update` instead:
```powershell
dotnet tool update -g Microsoft.PowerPlatform.Dataverse.MCP
dotnet tool update -g Microsoft.PowerPlatform.Canvas.MCP
```

---

## Step 4 — Install npm MCP servers

```powershell
npm install -g @microsoft/copilot-studio-mcp
npm install -g @modelcontextprotocol/server-github
npm install -g @tiberriver256/mcp-server-azure-devops
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @kazuph/mcp-fetch
npm install -g @playwright/mcp
```

---

## Step 5 — Clone the dashboard repo

```powershell
New-Item -ItemType Directory -Force -Path "C:\Repositories"
gh repo clone KayodeAjayi200/power-platform-dashboard "C:\Repositories\Powerapps Stuff"
```

If `gh` is not yet authenticated (step 7 handles this), clone with HTTPS:
```powershell
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git "C:\Repositories\Powerapps Stuff"
```

---

## Step 6 — Write the MCP server configuration

Create the file `~/.copilot/mcp-config.json` with this content.  
**Ask the user for the values marked `ASK_USER` before writing.**

Values to ask the user:
- `GITHUB_PAT` — GitHub Personal Access Token (github.com → Settings → Developer settings → Fine-grained tokens → New token → give: Contents R/W, Pull requests R/W, Issues R/W, Workflows R/W, Metadata Read)
- `ADO_ORG_URL` — Azure DevOps org URL, e.g. `https://dev.azure.com/myorg`
- `ADO_PAT` — Azure DevOps PAT (dev.azure.com → User settings → Personal access tokens)
- `DATAVERSE_CONNECTION_URL` — Power Automate connection URL (Power Automate → My connections → Common Data Service → `...` → Details → copy the full URL including query string)
- `COPILOT_STUDIO_MCP_URL` — from Copilot Studio → Settings → Channels → MCP Client (optional — can be added later)

```powershell
$mcpDir = Join-Path $env:USERPROFILE ".copilot"
New-Item -ItemType Directory -Force -Path $mcpDir | Out-Null

$githubPat      = "PASTE_GITHUB_PAT_HERE"
$adoOrgUrl      = "PASTE_ADO_ORG_URL_HERE"
$adoPat         = "PASTE_ADO_PAT_HERE"
$dataverseUrl   = "PASTE_DATAVERSE_CONNECTION_URL_HERE"
$copilotStudio  = "REPLACE_WITH_YOUR_AGENT_MCP_URL"
$repoPath       = "C:\Repositories\Powerapps Stuff"

$mcp = @{
  mcpServers = @{
    dataverse = @{
      command = "dataverse-mcp"
      args = @()
      env = @{ DATAVERSE_MCP_URL = $dataverseUrl }
    }
    canvas = @{
      command = "canvas-mcp"
      args = @()
    }
    "copilot-studio" = @{
      command = "npx"
      args = @("-y", "@microsoft/copilot-studio-mcp", $copilotStudio)
    }
    github = @{
      command = "npx"
      args = @("-y", "@modelcontextprotocol/server-github")
      env = @{ GITHUB_PERSONAL_ACCESS_TOKEN = $githubPat }
    }
    "azure-devops" = @{
      command = "npx"
      args = @("-y", "@tiberriver256/mcp-server-azure-devops")
      env = @{
        AZURE_DEVOPS_ORG_URL = $adoOrgUrl
        AZURE_DEVOPS_PAT     = $adoPat
      }
    }
    filesystem = @{
      command = "npx"
      args = @("-y", "@modelcontextprotocol/server-filesystem", $repoPath)
    }
    fetch = @{
      command = "npx"
      args = @("-y", "@kazuph/mcp-fetch")
    }
    playwright = @{
      command = "npx"
      args = @("-y", "@playwright/mcp")
    }
  }
} | ConvertTo-Json -Depth 10

$mcp | Set-Content (Join-Path $mcpDir "mcp-config.json") -Encoding UTF8
Write-Host "✅ MCP config written"
```

---

## Step 7 — Authenticate tools (browser-based — tell the user before running)

### Power Platform
Tell the user: *"A browser window will open for Power Platform / Microsoft 365 login."*
```powershell
pac auth create
```

### GitHub CLI
Tell the user: *"A browser window will open for GitHub login."*
```powershell
gh auth login --web
```

### Azure CLI (optional — needed for Azure DevOps pipeline triggers)
Tell the user: *"A browser window will open for Azure login."*
```powershell
az login
```

---

## Step 8 — Verify installation

```powershell
Write-Host "── Tool versions ──"
pac --version
gh --version
az --version | Select-Object -First 1
node --version
dotnet --version

Write-Host "`n── PAC auth ──"
pac auth list

Write-Host "`n── PAC environments ──"
pac env list
```

If `pac env list` returns environments, the setup is complete.

---

## Step 9 — Launch the dashboard

```powershell
Set-Location "C:\Repositories\Powerapps Stuff"
.\Launch-Dashboard.ps1
```

Or tell the user to double-click `Launch-Dashboard.ps1` in File Explorer and choose "Run with PowerShell".

---

## Step 10 — First-time configuration in the dashboard

Tell the user to:

1. Go to the **⚙️ Settings** tab
2. Fill in:
   - GitHub PAT (if not already in MCP config)
   - Dataverse connection URL
   - Azure DevOps org URL
   - AI provider (choose "GitHub Copilot (clipboard)" if no API key — it's free)
3. Click **💾 Save Settings**
4. Go back to **🌐 Environments** tab — environments should load automatically

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `pac` not found after install | Close and reopen the terminal to refresh PATH |
| `winget` fails | Windows Store may be updating — wait 2 min and retry |
| `No environments` in dashboard | Run `pac auth create` and sign in again |
| Dataverse MCP URL error | URL must come from Power Automate connections page (includes `?apiName=...`) — NOT the org URL |
| GitHub push fails | Ensure PAT has `Contents: Read/Write` and `Workflows: Read/Write` scopes |
| Dashboard window doesn't appear | Run `pwsh -File "C:\Repositories\Powerapps Stuff\scripts\PowerPlatformDashboard.ps1"` to see error output |
| `npm install -g` permission error | Run terminal as the current user (not admin) |

---

## What the user can ask you to do once set up

Once everything is installed, the user can ask their AI agent:

| Request | What to do |
|---|---|
| "Sync my SolutionName to GitHub" | Open dashboard → Solutions tab → select solution → set repo → click sync button |
| "Deploy SolutionName to Test" | Open dashboard → Deploy tab → select source env and target env → deploy |
| "Create a test environment and deploy my solution" | Open dashboard → ALM Tools tab → Disposable Environments section |
| "What changed in my last solution export?" | Check git diff in the repo folder: `git -C "C:\Repositories\Powerapps Stuff" diff HEAD~1 --stat` |
| "Add the dashboard tools to a new colleague's machine" | Share this repo URL + tell them to give AGENT_SKILL.md to their AI |

---

*This skill is part of the [Power Platform Dashboard](https://github.com/KayodeAjayi200/power-platform-dashboard) project.*
