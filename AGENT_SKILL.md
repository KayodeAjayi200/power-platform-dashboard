# AGENT_SKILL: Power Platform Dashboard Setup

> **Instructions for AI agents.**  
> Users reach this file by pasting the contents of `SETUP_PROMPT.txt` into your chat.  
> Follow every step in order. Run PowerShell commands using your tool-execution capability.  
> Ask the user **only** before opening browser windows for authentication — run everything else automatically.

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

### .NET 10 SDK (required for Canvas App Authoring MCP)
```powershell
winget install --id Microsoft.DotNet.SDK.10 --silent --accept-package-agreements --accept-source-agreements
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
dotnet tool install -g microsoft.powerapps.canvasauthoring.mcpserver
dotnet tool install -g microsoft.agents.copilotstudio.mcp
```

If any fail with "already installed", run with `update` instead:
```powershell
dotnet tool update -g Microsoft.PowerPlatform.Dataverse.MCP
dotnet tool update -g microsoft.powerapps.canvasauthoring.mcpserver
dotnet tool update -g microsoft.agents.copilotstudio.mcp
```

> **Note:** These install three tools:
> - `Microsoft.PowerPlatform.Dataverse.MCP` → command: `Microsoft.PowerPlatform.Dataverse.MCP`
> - `microsoft.powerapps.canvasauthoring.mcpserver` → command: `CanvasAuthoringMcpServer`
> - `microsoft.agents.copilotstudio.mcp` → command: `Microsoft.Agents.CopilotStudio.Mcp`

---

## Step 3b — Enable AI canvas app generation (build apps from descriptions)

> This lets the user describe a canvas app in plain English and have the AI build it for them. The AI generates the app, validates it, and opens it live in Power Apps Studio — no manual drag-and-drop required.
>
> **Official docs:** https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/create-canvas-external-tools

Run both commands **inside GitHub Copilot CLI** (or Claude Code):

```
/plugin marketplace add microsoft/power-platform-skills
/plugin install canvas-apps@power-platform-skills
```

After installing, configure the MCP server before first use:

1. Open your canvas app in Power Apps Studio.
2. Enable coauthoring: **Settings → Updates → Coauthoring** (toggle on).
3. Copy the full browser URL of your open app.
4. In Copilot CLI or Claude Code, run:
   ```
   /configure-canvas-mcp
   ```
5. Paste the Power Apps Studio URL when prompted.

**Available commands after setup:**

| Command | What it does |
|---|---|
| `/generate-canvas-app` | Create a new canvas app from a description |
| `/edit-canvas-app` | Edit an existing app via the coauthoring session |
| `/configure-canvas-mcp` | Re-configure the MCP server connection |

---

## Step 4 — Install Node.js MCP packages

```powershell
npm install -g @modelcontextprotocol/server-github
npm install -g @tiberriver256/mcp-server-azure-devops
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-memory
npm install -g @modelcontextprotocol/server-sequential-thinking
npm install -g @playwright/mcp
npm install -g @pnp/cli-microsoft365
```

> **Note:** Copilot Studio MCP is now a .NET tool installed in Step 3 — no npm package needed.

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
- `TENANT_ID` — Your Microsoft/Entra tenant ID (Azure Portal → Entra ID → Overview → Tenant ID)
- `COPILOT_STUDIO_MCP_URL` — from Copilot Studio → Settings → Channels → MCP Client (optional — can be added later)
- `CANVAS_APP_ID` — App ID from the Power Apps Studio URL (after `/apps/` in the URL) — set this after opening your canvas app in Studio (optional — use `/configure-canvas-mcp` later)
- `CANVAS_ENVIRONMENT_ID` — Environment ID from the Power Apps Studio URL (after `/e/`) — same as above (optional)

```powershell
$mcpDir = Join-Path $env:USERPROFILE ".copilot"
New-Item -ItemType Directory -Force -Path $mcpDir | Out-Null

$githubPat      = "PASTE_GITHUB_PAT_HERE"
$adoOrgUrl      = "PASTE_ADO_ORG_URL_HERE"
$adoPat         = "PASTE_ADO_PAT_HERE"
$dataverseUrl   = "PASTE_DATAVERSE_CONNECTION_URL_HERE"
$tenantId       = "PASTE_TENANT_ID_HERE"
$copilotStudio  = "REPLACE_WITH_YOUR_AGENT_MCP_URL"
$canvasAppId    = "PASTE_CANVAS_APP_ID_HERE"
$canvasEnvId    = "PASTE_CANVAS_ENVIRONMENT_ID_HERE"
$repoPath       = "C:\Repositories\Powerapps Stuff"

$mcp = @{
  mcpServers = @{
    # Dataverse MCP — reads and writes Dataverse tables
    dataverse = @{
      type    = "local"
      command = "Microsoft.PowerPlatform.Dataverse.MCP"
      args    = @(
        "--ConnectionUrl", $dataverseUrl,
        "--TenantId",      $tenantId,
        "--MCPServerName", "DataverseMCPServer",
        "--BackendProtocol", "HTTP"
      )
    }
    # Canvas App Authoring MCP — primary entry point (uses installed global tool)
    "powerapps-canvas" = @{
      command = "CanvasAuthoringMcpServer"
      args    = @()
      env     = @{
        CANVAS_APP_ID           = $canvasAppId
        CANVAS_ENVIRONMENT_ID   = $canvasEnvId
        CANVAS_CLUSTER_CATEGORY = "prod"
      }
    }
    # Canvas App Authoring MCP — secondary entry (uses dnx for latest prerelease)
    "canvas-authoring" = @{
      type    = "stdio"
      command = "dnx"
      args    = @(
        "Microsoft.PowerApps.CanvasAuthoring.McpServer",
        "--yes", "--prerelease",
        "--source", "https://api.nuget.org/v3/index.json"
      )
      env     = @{
        CANVAS_APP_ID           = $canvasAppId
        CANVAS_ENVIRONMENT_ID   = $canvasEnvId
        CANVAS_CLUSTER_CATEGORY = "prod"
      }
    }
    # Copilot Studio MCP — manage Copilot Studio agents
    "copilot-studio" = @{
      type    = "local"
      command = "Microsoft.Agents.CopilotStudio.Mcp"
      args    = @(
        "--remote-server-url", $copilotStudio,
        "--tenant-id",         $tenantId,
        "--scopes",            "https://api.powerplatform.com/.default"
      )
    }
    # GitHub MCP — read repos, issues, PRs
    github = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@modelcontextprotocol/server-github")
      env     = @{ GITHUB_PERSONAL_ACCESS_TOKEN = $githubPat }
    }
    # Azure DevOps MCP — pipelines, work items, repos
    "azure-devops" = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@tiberriver256/mcp-server-azure-devops")
      env     = @{
        AZURE_DEVOPS_ORG_URL  = $adoOrgUrl
        AZURE_DEVOPS_AUTH_METHOD = "pat"
        AZURE_DEVOPS_PAT      = $adoPat
      }
    }
    # Filesystem MCP — read/write local repo files
    filesystem = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@modelcontextprotocol/server-filesystem", $repoPath)
    }
    # Memory MCP — persistent knowledge graph across sessions
    memory = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@modelcontextprotocol/server-memory")
    }
    # Sequential Thinking MCP — structured reasoning for complex tasks
    "sequential-thinking" = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@modelcontextprotocol/server-sequential-thinking")
    }
    # Playwright MCP — browser automation
    playwright = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@playwright/mcp")
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

## Step 9 — Install agent skills (Copilot app users only)

> Skip this step if the user is not using the GitHub Copilot desktop app.

Install the skills so they appear in the Skills panel (Skills → personal-agents):

```powershell
# Detect where this repo lives — works no matter where the user cloned it
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
# Fallback: if the above doesn't resolve, use the current directory
if (-not (Test-Path "$repoRoot\AGENT_SKILL.md")) { $repoRoot = $PWD.Path }

$skillsBase = "$env:USERPROFILE\.agents\skills"
New-Item -ItemType Directory -Force -Path "$skillsBase\powerapps-canvas" | Out-Null
New-Item -ItemType Directory -Force -Path "$skillsBase\powerapps-canvas-design" | Out-Null
New-Item -ItemType Directory -Force -Path "$skillsBase\power-platform-dashboard" | Out-Null

Copy-Item "$repoRoot\skills\PowerApps-Canvas-Skill.md" `
          "$skillsBase\powerapps-canvas\SKILL.md" -Force
Copy-Item "$repoRoot\skills\PowerApps-Canvas-Design-Skill.md" `
          "$skillsBase\powerapps-canvas-design\SKILL.md" -Force
New-Item -ItemType Directory -Force -Path "$skillsBase\powerapps-delegation" | Out-Null
Copy-Item "$repoRoot\skills\PowerApps-Delegation-Skill.md" `
          "$skillsBase\powerapps-delegation\SKILL.md" -Force
New-Item -ItemType Directory -Force -Path "$skillsBase\canvas-authoring-mcp" | Out-Null
Copy-Item "$repoRoot\skills\Canvas-Authoring-MCP-Skill.md" `
          "$skillsBase\canvas-authoring-mcp\SKILL.md" -Force
Copy-Item "$repoRoot\AGENT_SKILL.md" `
          "$skillsBase\power-platform-dashboard\SKILL.md" -Force

Write-Host "✅ Skills installed from $repoRoot — refresh the Skills panel in the Copilot app"
```

Tell the user to click the 🔄 icon in the Skills panel to see **powerapps-canvas** and **power-platform-dashboard** appear.

---

## Step 10 — Create desktop shortcut (one-time setup)

Run this to create a proper desktop shortcut that can be double-clicked or pinned to the taskbar:

```powershell
Set-Location $repoRoot
.\Create-Shortcut.ps1
```

This puts **"Power Platform Dashboard"** on the user's Desktop. Tell them:
- **To open it**: double-click the icon on the Desktop
- **To pin to taskbar**: right-click the desktop icon → "Pin to taskbar"
- **Alternative**: double-click `Launch-Dashboard.bat` in the repo folder any time

---

## Step 10b — Launch the dashboard (for testing)

```powershell
# Navigate to wherever the user cloned the repo, then launch
Set-Location $repoRoot
.\Launch-Dashboard.bat
```

Or tell the user to double-click `Launch-Dashboard.bat` in their repo folder.

---

## Step 11 — First-time configuration in the dashboard

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
| Solutions tab shows nothing | Select an environment first on the Environments tab |
| Export→Unpack→Push stuck | Operation has a 5-minute timeout; check Output tab for error details |
| Skills not showing in Copilot app | Click 🔄 in Skills panel; verify files exist in `~\.agents\skills\` |
| Canvas MCP not responding | Run `dotnet --version` — must be **10.0+**; re-run `/configure-canvas-mcp` with fresh Studio URL |
| Canvas MCP returns 404 | App ID or Environment ID in `mcp-config.json` does not match the open app — read `skills/Canvas-Authoring-MCP-Skill.md` and follow Steps 1–4 |
| Canvas MCP connects to wrong app | User switched to a different app — update config with new IDs from the Studio URL; restart MCP server |
| `/plugin install` command not found | Command only works inside GitHub Copilot CLI or Claude Code — not in a regular terminal |
| Changes not appearing in Studio | Ensure coauthoring is enabled (Settings → Updates → Coauthoring) and Studio session is still active |

---

## What the user can ask you to do once set up

Once everything is installed, the user can ask their AI agent:

| Request | What to do |
|---|---|
| "Sync my SolutionName to GitHub" | Open dashboard → Solutions tab → select solution → set repo → click sync button |
| "Deploy SolutionName to Test" | Open dashboard → Deploy tab → select source env and target env → deploy |
| "Create a test environment and deploy my solution" | Open dashboard → ALM Tools tab → Disposable Environments section |
| "What changed in my last solution export?" | Check git diff in the repo folder: `git -C "C:\Repositories\Powerapps Stuff" diff HEAD~1 --stat` |
| "Help me write a Power Fx formula" | Invoke the `powerapps-canvas` skill (in Skills panel) or read `skills/PowerApps-Canvas-Skill.md` |
| "Build me a canvas app for expense tracking" | Use `/generate-canvas-app` in Copilot CLI — see Step 3b for setup |
| "Add a filter panel to my canvas app" | Use `/edit-canvas-app` in Copilot CLI; describe the change in natural language |
| "Add the dashboard tools to a new colleague's machine" | Share this repo URL + tell them to give `AGENT_SKILL.md` to their AI |

---

## Agent skills reference

This repo includes reference skill files for common Power Platform topics:

| File | When to use it |
|---|---|
| `skills/PowerApps-Canvas-Skill.md` | Writing or debugging Canvas App controls, Power Fx formulas, components |
| `skills/PowerApps-Canvas-Design-Skill.md` | UI/UX design — containers, responsive layouts, Fluent UI, gallery cards, filter panels, navigation |
| `skills/PowerApps-Delegation-Skill.md` | Delegation warnings, Filter/Search formulas on large data sources, data correctness at scale |
| `skills/Canvas-Authoring-MCP-Skill.md` | Connecting the Canvas Authoring MCP to the right app — resolving 404s, updating App ID / Environment ID, verifying co-authoring |
| `AGENT_SKILL.md` (this file) | Setting up tools, installing MCP servers, onboarding a new machine |

---

*This skill is part of the [Power Platform Dashboard](https://github.com/KayodeAjayi200/power-platform-dashboard) project.*
