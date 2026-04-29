# AGENT_SKILL: Power Platform Dashboard Setup

> **Instructions for AI agents.**  
> Users reach this file by pasting the contents of `SETUP_PROMPT.txt` into your chat.  
> Follow every step in order. Run PowerShell commands using your tool-execution capability.  
> **Never blindly reinstall or overwrite something that is already working** — each step includes check-first logic; respect it.  
> Ask the user **only** before opening browser windows for authentication — run everything else automatically.

---

## What you are setting up

A WinForms GUI dashboard that lets non-developers manage Power Platform solutions, GitHub sync, ALM pipelines, disposable environments, canvas app AI tools, and more — all without touching the command line.

---

## Prerequisites check

Run this first to inventory what is already on the machine. **Read the output and note what is missing before proceeding — each install step skips anything already present.**

```powershell
@{
  PowerShell  = $PSVersionTable.PSVersion.ToString()
  Node        = (node --version 2>$null)
  DotNet      = (dotnet --version 2>$null)
  DotNetSDKs  = (dotnet --list-sdks 2>$null)
  Git         = (git --version 2>$null)
  WinGet      = (winget --version 2>$null)
  PAC         = (pac --version 2>$null)
  AzCLI       = (az --version 2>$null | Select-Object -First 1)
  GH          = (gh --version 2>$null | Select-Object -First 1)
  M365        = (m365 --version 2>$null)
  DotNetTools = (dotnet tool list -g 2>$null)
  NpmGlobal   = (npm list -g --depth=0 2>$null)
} | Format-List
```

---

---

## PART A — One-time machine setup

> **Skip this entire section if tools are already installed** (e.g. you are onboarding a second project on a machine that already has the dashboard running). Jump straight to [PART B](#part-b--per-project-setup).

---

## Step 1 — Install core tools

> **Each block checks first — it will only install a tool if it is missing or not working. Existing installations are always preserved.**

```powershell
# PowerShell 7
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Host "✅ PowerShell 7 already installed: $(pwsh --version)"
} else {
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
}

# Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "✅ Node already installed: $(node --version)"
} else {
    winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
}

# .NET 8 SDK
if (dotnet --list-sdks 2>$null | Where-Object { $_ -match '^8\.' }) {
    Write-Host "✅ .NET 8 SDK already installed"
} else {
    winget install --id Microsoft.DotNet.SDK.8 --silent --accept-package-agreements --accept-source-agreements
}

# .NET 10 SDK (required for Canvas App Authoring MCP)
if (dotnet --list-sdks 2>$null | Where-Object { $_ -match '^10\.' }) {
    Write-Host "✅ .NET 10 SDK already installed"
} else {
    winget install --id Microsoft.DotNet.SDK.10 --silent --accept-package-agreements --accept-source-agreements
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "✅ Git already installed: $(git --version)"
} else {
    winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
}

# PAC CLI (Power Platform CLI)
if (Get-Command pac -ErrorAction SilentlyContinue) {
    Write-Host "✅ PAC already installed: $(pac --version)"
} else {
    winget install --id Microsoft.PowerPlatformCLI --silent --accept-package-agreements --accept-source-agreements
}

# Azure CLI
if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Host "✅ Azure CLI already installed"
} else {
    winget install --id Microsoft.AzureCLI --silent --accept-package-agreements --accept-source-agreements
}

# GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "✅ GitHub CLI already installed: $(gh --version | Select-Object -First 1)"
} else {
    winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
}

# m365 CLI (SharePoint & Teams)
if (Get-Command m365 -ErrorAction SilentlyContinue) {
    Write-Host "✅ m365 CLI already installed"
} else {
    npm install -g @pnp/cli-microsoft365
}

# PnP.PowerShell (SharePoint deep operations)
if (Get-Module -ListAvailable -Name PnP.PowerShell) {
    Write-Host "✅ PnP.PowerShell already installed"
} else {
    Install-Module PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
}
```

---

## Step 2 — Install GitHub Copilot extension

```powershell
if (gh extension list 2>$null | Where-Object { $_ -match 'gh-copilot' }) {
    Write-Host "✅ gh-copilot extension already installed"
} else {
    gh extension install github/gh-copilot
}
```

---

## Step 3 — Install .NET MCP tools

> Each tool is checked with `dotnet tool list -g` first. It is only installed if missing — existing installations are never overwritten.

```powershell
$installedDotnetTools = dotnet tool list -g 2>$null

@(
    "Microsoft.PowerPlatform.Dataverse.MCP",
    "microsoft.powerapps.canvasauthoring.mcpserver",
    "microsoft.agents.copilotstudio.mcp"
) | ForEach-Object {
    $tool = $_
    # Match case-insensitively — dotnet tool names can vary in output casing
    if ($installedDotnetTools | Where-Object { $_ -match [regex]::Escape($tool.ToLower()) }) {
        Write-Host "✅ $tool already installed — skipping"
    } else {
        Write-Host "Installing $tool..."
        dotnet tool install -g $tool
    }
}
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

> Checks `npm list -g` first — only installs packages that are not already present.

```powershell
$installedNpm = npm list -g --depth=0 2>$null

@(
    "@modelcontextprotocol/server-github",
    "@tiberriver256/mcp-server-azure-devops",
    "@modelcontextprotocol/server-filesystem",
    "@modelcontextprotocol/server-memory",
    "@modelcontextprotocol/server-sequential-thinking",
    "@playwright/mcp"
) | ForEach-Object {
    $pkg = $_
    if ($installedNpm | Where-Object { $_ -match [regex]::Escape($pkg) }) {
        Write-Host "✅ $pkg already installed — skipping"
    } else {
        Write-Host "Installing $pkg..."
        npm install -g $pkg
    }
}
```

---

---

## PART B — Dashboard setup (once per machine)

> **Do these steps once per machine** to install the dashboard tool itself.  
> The dashboard is a separate tool repo — it does not store your Power Platform solutions.  
> Solution repos are set up independently in [PART C](#part-c--per-solution-setup).

---

## Step 5 — Clone the dashboard repo

> This clones the **dashboard tool** — not your Power Platform solutions.  
> Solutions live in their own separate repos (see PART C).
>
> **Ask the user:** "Where would you like to store the dashboard tool? I'll create the folder if it doesn't exist."  
> Suggest **`C:\Repositories\power-platform-dashboard`** as the default.  
> Store their answer as `$repoPath` and use it for **all remaining steps in PART B**.

```powershell
# Replace with the path the user chose, e.g. "C:\Repositories\power-platform-dashboard"
$repoPath = "C:\Repositories\power-platform-dashboard"

New-Item -ItemType Directory -Force -Path (Split-Path $repoPath)
gh repo clone KayodeAjayi200/power-platform-dashboard $repoPath
```

If `gh` is not yet authenticated (step 7 handles this), clone with HTTPS:
```powershell
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git $repoPath
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
- `SOLUTION_REPO_PATHS` — Ask: *"Do you have any Power Platform solution repos already cloned locally? If so, paste the folder paths (one per line). You can skip this and add them later."* Collect as a list of paths — these are the repos where your solutions are stored, separate from the dashboard tool. Example: `C:\Repositories\my-hr-app`, `C:\Repositories\my-expense-tracker`

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
$repoPath       = $repoPath  # Set in Step 5 — the dashboard tool folder

# All folders the filesystem MCP can read/write.
# Starts with the dashboard tool repo; add solution repo paths here too.
# The user can add more later by running the PART C helper script.
$filesystemPaths = @($repoPath)
# Add any solution repos the user provided, e.g.:
# $filesystemPaths += "C:\Repositories\my-hr-app"
# $filesystemPaths += "C:\Repositories\my-expense-tracker"

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
    # Filesystem MCP — read/write local files across the dashboard and all solution repos.
    # $filesystemPaths is an array; each path becomes a separate positional argument.
    filesystem = @{
      type    = "local"
      command = "npx"
      args    = @("-y", "@modelcontextprotocol/server-filesystem") + $filesystemPaths
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
Write-Host "✅ MCP config written — filesystem MCP covers: $($filesystemPaths -join ', ')"
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
New-Item -ItemType Directory -Force -Path "$skillsBase\powerapps-canvas-accessibility" | Out-Null
Copy-Item "$repoRoot\skills\PowerApps-Canvas-Accessibility-Skill.md" `
          "$skillsBase\powerapps-canvas-accessibility\SKILL.md" -Force
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

## PART C — Per-solution setup

> **Do these steps each time you want to work on a Power Platform solution.**
>
> The dashboard tool (PART B) only needs to be set up once per machine.  
> Each Power Platform solution you build lives in its own **separate GitHub repo**.  
> The dashboard's **📦 Solutions** tab has a "Set Repo" field — you point it at the relevant solution repo whenever you want to sync, deploy, or manage that solution.
>
> **Which scenario applies?** Ask the user:  
> - "Are you starting a brand new solution, or do you already have a solution repo on GitHub?"

---

### Step C1 — Create a new solution repo (new project)

> Skip to Step C2 if the solution repo already exists on GitHub.

**Ask the user:**
- "What should the GitHub repo be called?" (e.g. `my-hr-app`, `expense-tracker`)
- "Where do you want it stored locally?" (suggest `C:\Repositories\<repo-name>`)
- "Should it be public or private?" (default: private)

```powershell
# Replace these with the values the user provided
$solutionRepoName  = "my-hr-app"         # Name for the new GitHub repo
$solutionLocalPath = "C:\Repositories\my-hr-app"  # Local folder to clone into
$visibility        = "private"            # "private" or "public"

# Create the repo on GitHub and clone it locally
gh repo create $solutionRepoName --$visibility --clone --gitignore "VisualStudio"
Move-Item -Path $solutionRepoName -Destination $solutionLocalPath -Force
Set-Location $solutionLocalPath

Write-Host "✅ Repo created and cloned to $solutionLocalPath"
```

---

### Step C2 — Clone an existing solution repo

> Skip to Step C3 if the repo is already cloned locally.

**Ask the user:**
- "What is the GitHub repo URL or `owner/repo` name?" (e.g. `KayodeAjayi200/my-hr-app`)
- "Where do you want to clone it?" (suggest `C:\Repositories\<repo-name>`)

```powershell
# Replace these with the values the user provided
$solutionRepoUrl   = "https://github.com/KayodeAjayi200/my-hr-app"
$solutionLocalPath = "C:\Repositories\my-hr-app"

# Create the parent folder if it doesn't already exist
$parent = Split-Path $solutionLocalPath -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

# Clone the repo into the specified folder
git clone $solutionRepoUrl $solutionLocalPath

Write-Host "✅ Repo cloned to $solutionLocalPath"
```

---

### Step C3 — Add the solution repo to the filesystem MCP

> The filesystem MCP controls which folders the AI can read and write.  
> Adding the solution repo path lets Copilot see both the dashboard and your solution files.

```powershell
# The path where the solution repo was cloned (from Step C1 or C2)
$solutionLocalPath = "C:\Repositories\my-hr-app"  # Update to the actual path

$mcpConfigPath = Join-Path $env:USERPROFILE ".copilot\mcp-config.json"

# Read the existing MCP config file
$mcp = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json

# Get the current list of filesystem paths
# The args array starts with "-y", "@modelcontextprotocol/server-filesystem", then paths
$currentArgs = $mcp.mcpServers.filesystem.args

# Only add the path if it isn't already listed (avoid duplicates)
if ($currentArgs -notcontains $solutionLocalPath) {
    # Append the new solution repo path to the args array
    $mcp.mcpServers.filesystem.args = $currentArgs + @($solutionLocalPath)
    
    # Write the updated config back to disk
    $mcp | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigPath -Encoding UTF8
    Write-Host "✅ Added $solutionLocalPath to filesystem MCP config"
} else {
    Write-Host "ℹ️  $solutionLocalPath is already in the filesystem MCP config — no changes needed"
}
```

> **Restart Copilot CLI** after updating the MCP config so the change takes effect.

---

### Step C4 — Point the dashboard at the solution repo

Tell the user:

1. Open the dashboard → **📦 Solutions** tab
2. In the **"GitHub Repo"** field, paste the local path to the solution repo (e.g. `C:\Repositories\my-hr-app`)
3. Click **Set Repo** — the dashboard will use this path for all sync and export operations
4. The path is saved automatically for that solution — you don't need to re-enter it each time

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `pac` not found after install | Close and reopen the terminal to refresh PATH |
| `winget` fails | Windows Store may be updating — wait 2 min and retry |
| `No environments` in dashboard | Run `pac auth create` and sign in again |
| Dataverse MCP URL error | URL must come from Power Automate connections page (includes `?apiName=...`) — NOT the org URL |
| GitHub push fails | Ensure PAT has `Contents: Read/Write` and `Workflows: Read/Write` scopes |
| Dashboard window doesn't appear | Run `pwsh -File "<your-repo-path>\scripts\PowerPlatformDashboard.ps1"` to see error output |
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
| "What changed in my last solution export?" | Check git diff in the repo folder: `git -C "<your-repo-path>" diff HEAD~1 --stat` |
| "Fix accessibility errors in my canvas app" | Read `skills/PowerApps-Canvas-Accessibility-Skill.md` (what to fix + WCAG standards) AND `skills/Canvas-Authoring-MCP-Skill.md` (how to push fixes via MCP) → verify MCP config → run the full accessibility fix workflow |
| "Help me write a Power Fx formula" | Invoke the `powerapps-canvas` skill (in Skills panel) or read `skills/PowerApps-Canvas-Skill.md` |
| "Build me a canvas app for expense tracking" | Read `skills/Canvas-Authoring-MCP-Skill.md` → verify MCP config → use `/generate-canvas-app` — see Step 3b for setup |
| "Add a filter panel to my canvas app" | Read `skills/Canvas-Authoring-MCP-Skill.md` → verify MCP config → sync → edit YAML → compile to push |
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
| `skills/PowerApps-Canvas-Accessibility-Skill.md` | Canvas App accessibility knowledge — WCAG 2.1 AA standards, accessible property reference (AccessibleLabel, TabIndex, FocusedBorderThickness, Role, Live), labelling patterns, keyboard navigation, screen reader support, forms/errors, live regions, known platform limitations, testing guidance |
| `AGENT_SKILL.md` (this file) | Setting up tools, installing MCP servers, onboarding a new machine |

---

*This skill is part of the [Power Platform Dashboard](https://github.com/KayodeAjayi200/power-platform-dashboard) project.*
