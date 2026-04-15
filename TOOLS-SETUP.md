# 🚀 Power Platform, SharePoint & Copilot Developer Tools — Complete Setup Guide

> **Who is this for?** Complete beginners who want to set up every developer tool available for Power Apps, Power Platform, Dataverse, SharePoint, Microsoft Copilot Studio, and Azure DevOps on Windows. This guide covers CLI tools, MCP (Model Context Protocol) servers for AI assistants, PowerShell modules, and utility scripts.

---

## 📋 Table of Contents

1. [What Are These Tools?](#1-what-are-these-tools)
2. [Prerequisites — Install These First](#2-prerequisites--install-these-first)
3. [CLI Tools](#3-cli-tools)
   - [PAC CLI — Power Platform CLI](#31-pac-cli--power-platform-cli)
   - [m365 CLI — CLI for Microsoft 365](#32-m365-cli--cli-for-microsoft-365)
   - [PnP PowerShell](#33-pnp-powershell)
   - [Azure CLI + Azure DevOps Extension](#34-azure-cli--azure-devops-extension)
   - [VSTeam PowerShell Module](#35-vsteam-powershell-module)
4. [MCP Servers (for AI Assistants like Claude & GitHub Copilot)](#4-mcp-servers)
   - [Dataverse MCP Server](#41-dataverse-mcp-server)
   - [Power Apps Canvas Authoring MCP Server](#42-power-apps-canvas-authoring-mcp-server)
   - [Copilot Studio MCP Proxy](#43-copilot-studio-mcp-proxy)
   - [Azure DevOps MCP Server](#44-azure-devops-mcp-server)
   - [Memory MCP Server](#45-memory-mcp-server)
   - [Sequential Thinking MCP Server](#46-sequential-thinking-mcp-server)
   - [Filesystem MCP Server](#47-filesystem-mcp-server)
   - [Playwright MCP Server](#48-playwright-mcp-server)
   - [GitHub MCP Server](#49-github-mcp-server)
5. [How to Authenticate / Log In](#5-how-to-authenticate--log-in)
6. [Configuring MCP Servers with AI Tools](#6-configuring-mcp-servers-with-ai-tools)
   - [GitHub Copilot CLI App Configuration](#61-github-copilot-cli-app-configuration) ⭐ **Already done for this workspace!**
   - [Claude Desktop Configuration](#62-claude-desktop-configuration)
   - [VS Code GitHub Copilot Configuration](#63-vs-code-github-copilot-configuration)
7. [Switching Dataverse Environments](#7-switching-dataverse-environments)
8. [Dashboard GUI](#8-dashboard-gui)
9. [Quick Reference — All Commands](#9-quick-reference--all-commands)
10. [Updating All Tools](#10-updating-all-tools)
11. [Troubleshooting](#11-troubleshooting)
12. [Security: How to Authenticate Safely](#12-security-how-to-authenticate-safely)
13. [Deploy / Migrate Solutions](#13-deploy--migrate-solutions-tab-7--deploy) ⭐ **New!**
14. [ALM Pipelines Structure](#14-alm-pipelines-structure) ⭐ **New!**
15. [Code Review](#15-code-review-tab-8--code-review) ⭐ **New!**
16. [Copilot Studio Integration](#16-copilot-studio-integration) ⭐ **New!**

---

## 1. What Are These Tools?

| Tool | Type | What It Does |
|---|---|---|
| **PAC CLI** | CLI | Official Microsoft tool to manage Power Platform environments, solutions, canvas apps, PCF controls, plugins, Dataverse |
| **m365 CLI** | CLI | Community (PnP) tool to manage SharePoint, Power Apps, Power Automate, Teams, and all of Microsoft 365 |
| **PnP PowerShell** | PowerShell Module | 750+ PowerShell commands specifically for SharePoint Online, Entra ID, Teams |
| **Azure CLI** | CLI | Official Microsoft CLI for all Azure services; `azure-devops` extension adds full Azure DevOps support |
| **VSTeam** | PowerShell Module | Community PowerShell module for Azure DevOps & TFS — work items, pipelines, repos, releases |
| **Dataverse MCP** | MCP Server | Lets AI assistants (Claude, Copilot) read/write your Dataverse database using natural language |
| **PowerApps Canvas MCP** | MCP Server | Lets AI assistants author, validate, and build Power Apps canvas apps from code |
| **Copilot Studio MCP** | MCP Server | Lets AI assistants call and use your published Copilot Studio agents as tools |
| **Azure DevOps MCP** | MCP Server | Lets AI assistants manage work items, PRs, pipelines, repos, and branches in Azure DevOps |
| **Memory MCP** | MCP Server | Gives the AI a persistent knowledge graph — it remembers entities, relationships, facts across sessions |
| **Sequential Thinking MCP** | MCP Server | Enables structured step-by-step reasoning for complex multi-step tasks |
| **Filesystem MCP** | MCP Server | Gives the AI read/write access to your local workspace files |
| **Playwright MCP** | MCP Server | Gives the AI a real browser — automate Power Apps, take screenshots, test web flows |
| **GitHub MCP** | MCP Server | Create/read/update GitHub issues, PRs, files, branches using natural language |

### What is MCP?
MCP (Model Context Protocol) is an open standard that lets AI assistants like Claude Desktop or VS Code GitHub Copilot connect to external tools and data sources. Think of it like giving your AI assistant superpowers — instead of just answering questions, it can actually query your database, create records, and build apps.

---

## 2. Prerequisites — Install These First

Before installing anything else, you need these on your machine.

### 2.1 .NET SDK 10.0 (Required for all dotnet tools)

1. Open PowerShell as Administrator (search "PowerShell", right-click → Run as Administrator)
2. Run:
   ```powershell
   winget install Microsoft.DotNet.SDK.10
   ```
3. Close and reopen PowerShell
4. Verify:
   ```powershell
   dotnet --version
   # Should show: 10.x.x
   ```

### 2.2 Node.js LTS (Required for m365 CLI)

1. Go to https://nodejs.org and download the **LTS** version
2. Run the installer, accept all defaults
3. Verify in PowerShell:
   ```powershell
   node --version
   npm --version
   # Should show version numbers
   ```

### 2.3 PowerShell 7+ (Required for PnP PowerShell)

1. Run in any PowerShell window:
   ```powershell
   winget install Microsoft.PowerShell
   ```
2. Always use **PowerShell 7** (pwsh) for the commands in this guide, not the old blue Windows PowerShell 5.

### 2.4 Add NuGet Package Source (Required for dotnet tools)

Run this once — it tells .NET where to download packages from:
```powershell
dotnet nuget add source https://api.nuget.org/v3/index.json --name nuget.org
```

---

## 3. CLI Tools

### 3.1 PAC CLI — Power Platform CLI

**What it does:** The official Microsoft command-line tool for everything Power Platform. Create and manage environments, export/import solutions, build PCF controls, deploy plugins, work with Dataverse, and more.

#### Install
```powershell
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```

#### Verify Installation
```powershell
pac
# Should show version and list of commands
```

#### Key Commands

```powershell
# --- Authentication ---
pac auth create                              # Opens browser to sign in to your tenant
pac auth list                                # See all saved login profiles
pac auth select --index 1                   # Switch between multiple logins

# --- Environments ---
pac env list                                 # List all your Power Platform environments
pac env select --environment "Dev"          # Set default environment

# --- Solutions ---
pac solution list                            # List solutions in current environment
pac solution export --name MySolution --path ./output  # Export a solution
pac solution import --path ./MySolution.zip            # Import a solution

# --- Canvas Apps (Power Apps) ---
pac canvas pack --sources ./src --msapp ./output.msapp  # Build a canvas app
pac canvas unpack --msapp ./MyApp.msapp --sources ./src  # Unpack for editing

# --- PCF Controls ---
pac pcf init --namespace MyNamespace --name MyControl --template field  # Create PCF project
pac pcf push                                 # Deploy PCF to environment

# --- Plugins ---
pac plugin init                              # Create a plugin project

# --- More ---
pac help                                     # Full help
```

---

### 3.2 m365 CLI — CLI for Microsoft 365

**What it does:** A community-built (PnP) cross-platform CLI covering SharePoint Online (376 commands!), Power Apps, Power Automate, Teams, OneDrive, Entra ID, and more. Works on any OS and any shell.

#### Install
```powershell
npm install -g @pnp/cli-microsoft365
```

#### Verify Installation
```powershell
m365 version
# Should show: "v11.x.x"
```

#### First-Time Setup
```powershell
m365 setup          # Interactive wizard to configure your Entra app registration
m365 login          # Opens browser or device code flow to sign in
m365 status         # Check if you're logged in
```

#### Key Commands

```powershell
# --- SharePoint (spo = SharePoint Online) ---
m365 spo site list                                          # List all sites
m365 spo site get --url https://contoso.sharepoint.com/sites/mysite
m365 spo list list --webUrl https://contoso.sharepoint.com/sites/mysite
m365 spo listitem add --listTitle "Tasks" --webUrl https://... --Title "My Task"

# --- Power Apps (pa) ---
m365 pa app list                             # List all canvas apps
m365 pa app export --name "MyApp"           # Export a Power App
m365 pa solution list                        # List solutions

# --- Power Platform (pp) ---
m365 pp environment list                     # List environments
m365 pp dataverse table list --environment "Dev"  # List Dataverse tables

# --- Power Automate (flow) ---
m365 flow list                               # List all flows
m365 flow run list --name "My Flow ID"      # List flow runs

# --- Help ---
m365 spo --help                              # Help for SharePoint commands
m365 pa --help                               # Help for Power Apps commands
m365 --help                                  # Full command list
```

---

### 3.3 PnP PowerShell

**What it does:** A PowerShell module with 750+ cmdlets specifically for SharePoint Online. Great for automation scripts, bulk operations, and managing SharePoint sites, lists, permissions, and content.

#### Install
```powershell
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
```

#### Verify Installation
```powershell
Get-Module -ListAvailable PnP.PowerShell
```

#### How to Use

```powershell
# Import the module (do this at the start of each session or script)
Import-Module PnP.PowerShell

# Connect to SharePoint
Connect-PnPOnline -Url "https://yourcompany.sharepoint.com/sites/yoursite" -Interactive
# This opens a browser window for you to sign in — no username/password needed in code!

# --- Sites ---
Get-PnPSite                                  # Info about current site
Get-PnPSubWeb                                # List subsites

# --- Lists & Items ---
Get-PnPList                                  # List all lists and libraries
Get-PnPListItem -List "Documents"           # Get items from a list
Add-PnPListItem -List "Tasks" -Values @{"Title"="My Task"; "Priority"="High"}
Set-PnPListItem -List "Tasks" -Identity 5 -Values @{"Title"="Updated Task"}
Remove-PnPListItem -List "Tasks" -Identity 5

# --- Files ---
Add-PnPFile -Path "C:\myfile.docx" -Folder "Shared Documents"
Get-PnPFile -Url "/sites/mysite/Shared Documents/myfile.docx" -AsFile

# --- Permissions ---
Get-PnPSiteCollectionAdmin                   # List site collection admins
Add-PnPSiteCollectionAdmin -Owners "user@company.com"

# --- Disconnect when done ---
Disconnect-PnPOnline
```

---

### 3.4 Azure CLI + Azure DevOps Extension

**What it does:** The official Microsoft CLI for Azure. The `azure-devops` extension adds commands for managing work items, repos, pipelines, pull requests, boards, and more from the terminal.

#### Install

Azure CLI is already installed on this machine. If you ever need to install it fresh:
```powershell
winget install Microsoft.AzureCLI
```

Install the Azure DevOps extension:
```powershell
az extension add --name azure-devops
```

#### How to Use

```powershell
# Log in to Azure
az login
# A browser window opens — sign in with your Microsoft account

# Configure your default org and project (saves you typing it every time)
az devops configure --defaults organization=https://dev.azure.com/veldarr project=MyProject

# --- Work Items ---
az boards work-item show --id 123
az boards work-item create --title "New Bug" --type Bug --project MyProject
az boards work-item update --id 123 --state "In Progress"

# --- Repos & PRs ---
az repos list --project MyProject
az repos pr list --project MyProject
az repos pr create --title "My PR" --source-branch feature/my-feature --target-branch main

# --- Pipelines ---
az pipelines list --project MyProject
az pipelines run --name "My Pipeline"
az pipelines build list --project MyProject --result succeeded

# --- Boards ---
az boards iteration list --project MyProject
az boards area list --project MyProject
```

---

### 3.5 VSTeam PowerShell Module

**What it does:** A community PowerShell module with 100+ cmdlets for Azure DevOps and TFS. Great for PowerShell-based automation scripts.

#### Install
```powershell
Install-Module -Name VSTeam -Scope CurrentUser -Force -SkipPublisherCheck
```

#### Verify Installation
```powershell
Get-Module -ListAvailable VSTeam
```

#### How to Use

```powershell
Import-Module VSTeam

# Connect — use a Personal Access Token (PAT) from Azure DevOps
# Go to: https://dev.azure.com/veldarr → User Settings → Personal Access Tokens
Set-VSTeamAccount -Account "veldarr" -PersonalAccessToken "YOUR_PAT_HERE"

# --- Projects ---
Get-VSTeamProject

# --- Work Items ---
Get-VSTeamWorkItem -Id 123
Add-VSTeamWorkItem -Title "New Task" -WorkItemType "Task" -ProjectName "MyProject"

# --- Builds & Pipelines ---
Get-VSTeamBuild -ProjectName "MyProject"
Add-VSTeamBuild -ProjectName "MyProject" -BuildDefinitionName "MyPipeline"

# --- Repos ---
Get-VSTeamGitRepository -ProjectName "MyProject"

# --- Releases ---
Get-VSTeamRelease -ProjectName "MyProject"
```

---

## 4. MCP Servers

MCP Servers connect AI tools (Claude Desktop, VS Code GitHub Copilot) to your Power Platform data and services. Once configured, you can ask your AI assistant things like *"List the tables in Dataverse"* or *"Create a new Power Apps canvas app"* and it will actually do it.

### 4.1 Dataverse MCP Server

**What it does:** Lets AI assistants query and modify your Dataverse database. Ask questions like "List all contacts", "Create 10 sample records", "Show me the Account table schema."

#### Install
```powershell
dotnet tool install --global --add-source https://api.nuget.org/v3/index.json Microsoft.PowerPlatform.Dataverse.MCP
```

#### Before You Configure It — Get Your Connection URL

1. Go to **Power Automate**: https://make.powerautomate.com
2. Switch to the environment you want to connect to (top right dropdown)
3. In the left menu, click **Connections**
4. Click **+ New connection**
5. Search for **Microsoft Dataverse** and click on the green one
6. Sign in with your Microsoft account
7. Once the connection is created, click on it to open it
8. **Copy the full URL from your browser address bar** — this is your Connection URL

Also get your **Tenant ID**:
1. Go to: https://make.powerapps.com
2. Click the ⚙️ gear icon (top right)
3. Click **Session details**
4. Copy the **Tenant ID**

#### Configuration — see [Section 6](#6-configuring-mcp-servers-with-ai-tools)

---

### 4.2 Power Apps Canvas Authoring MCP Server

**What it does:** Lets AI coding assistants (GitHub Copilot, Claude Code) build, validate and edit Power Apps canvas apps. The AI can browse available controls, check properties, discover connectors/APIs, and validate `.pa.yaml` files.

#### Install
```powershell
dotnet tool install --global --prerelease --add-source https://api.nuget.org/v3/index.json Microsoft.PowerApps.CanvasAuthoring.McpServer
```

#### Verify
```powershell
CanvasAuthoringMcpServer --help
```

#### Configuration — see [Section 6](#6-configuring-mcp-servers-with-ai-tools)

> **Note:** This server uses Azure Identity SDK for authentication — credentials are handled securely through Microsoft's official OAuth flow, never stored in plain text.

---

### 4.3 Copilot Studio MCP Proxy

**What it does:** Turns any of your **published Copilot Studio agents** into MCP tools. This means your AI assistant (Claude, Copilot) can call your Copilot Studio bots as tools — like asking "Use my HR bot to answer leave policy questions."

#### Install
```powershell
dotnet tool install --global --add-source https://api.nuget.org/v3/index.json Microsoft.Agents.CopilotStudio.Mcp
```

#### Verify
```powershell
Microsoft.Agents.CopilotStudio.Mcp --help
```

#### Before You Configure It — Get Your Agent URL

1. Go to **Copilot Studio**: https://copilotstudio.microsoft.com
2. Open the agent you want to expose as an MCP server
3. Make sure the agent is **Published** (top right button)
4. Click **Channels** in the left menu
5. Find **MCP Client (Preview)** under "Other channels"
6. Click it and copy the **Connection string URL**

The URL looks like:
```
https://{ENV_ID}.{ENV_ID_LAST_NUMBER}.environment.api.powerplatform.com/copilotstudio/dataverse-backed/authenticated/bots/{AGENT_NAME}/adapter/modelcontextprotocol?api-version=2022-03-01-preview
```

#### Configuration — see [Section 6](#6-configuring-mcp-servers-with-ai-tools)

---

### 4.4 Azure DevOps MCP Server

**What it does:** Connects AI assistants to Azure DevOps so you can manage work items, PRs, pipelines, branches, and repositories using natural language. Ask things like *"Create a bug for the login page crash"* or *"Show me open PRs in the main repo."*

- **Author:** Community (tiberriver256)
- **Package:** `@tiberriver256/mcp-server-azure-devops` (npm)
- **Auth:** Uses Azure CLI login (`az login`) — no PAT required if already logged in

#### Install
```powershell
npm install -g @tiberriver256/mcp-server-azure-devops
```

#### Verify
```powershell
npx @tiberriver256/mcp-server-azure-devops --version
```

#### What it can do

| Capability | Examples |
|---|---|
| Work Items | Create, update, query, comment on work items |
| Repositories | List repos, get file contents, create branches |
| Pull Requests | Create, list, approve, complete PRs |
| Pipelines | List, trigger, and monitor pipeline runs |
| Boards | List backlogs, sprints, iterations |
| Organizations | List projects and teams |

#### Configuration — see [Section 6](#6-configuring-mcp-servers-with-ai-tools)

---

### 4.5 Memory MCP Server

**What it does:** Gives the AI a persistent knowledge graph — it can remember entities, relationships, and facts across sessions. Ask it to remember your environment URLs, project names, team structures, and it will recall them next time.

- **Package:** `@modelcontextprotocol/server-memory`
- **Auth:** None required

#### Install & Register
```powershell
npm install -g @modelcontextprotocol/server-memory
copilot mcp add memory -- npx -y @modelcontextprotocol/server-memory
```

---

### 4.6 Sequential Thinking MCP Server

**What it does:** Enables step-by-step structured reasoning. Particularly useful when asking the AI to plan complex multi-step processes (like migrating a solution across environments or designing a data model).

- **Package:** `@modelcontextprotocol/server-sequential-thinking`
- **Auth:** None required

#### Install & Register
```powershell
npm install -g @modelcontextprotocol/server-sequential-thinking
copilot mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
```

---

### 4.7 Filesystem MCP Server

**What it does:** Gives the AI structured access to read, write, and search files in your workspace. Useful for reading solution files, searching exported data, or managing config files without leaving the AI chat.

- **Package:** `@modelcontextprotocol/server-filesystem`
- **Auth:** None — you specify which directories are allowed

#### Install & Register
```powershell
npm install -g @modelcontextprotocol/server-filesystem
copilot mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "C:\Repositories\Powerapps Stuff"
```

---

### 4.8 Playwright MCP Server

**What it does:** Gives the AI a real browser it can control. Use it to automate web tasks, test your Power Apps in a browser, fill forms, take screenshots, and navigate the Power Platform portals programmatically.

- **Package:** `@playwright/mcp`
- **Auth:** None required (uses your local browser)

#### Install & Register
```powershell
npm install -g @playwright/mcp
copilot mcp add playwright -- npx -y @playwright/mcp
```

#### Example uses
- "Open make.powerapps.com and take a screenshot of my environment"
- "Navigate to the Dataverse table editor and show me the Contact table"
- "Test my canvas app by clicking through the login flow"

---

### 4.9 GitHub MCP Server

**What it does:** Connects the AI to GitHub repositories — create/read/update issues, pull requests, files, branches, and search code across your repos.

- **Package:** `@modelcontextprotocol/server-github`
- **Auth:** GitHub Personal Access Token (PAT)

#### Get a GitHub PAT
1. Go to: https://github.com/settings/tokens/new
2. Select scopes: `repo`, `read:org`, `read:user`
3. Click **Generate token** and copy it

#### Install & Register
```powershell
npm install -g @modelcontextprotocol/server-github
copilot mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_PAT_HERE -- npx -y @modelcontextprotocol/server-github
```

> ⚠️ Replace `YOUR_PAT_HERE` with your actual token. The token is stored encrypted in the MCP config.

---

## 5. How to Authenticate / Log In

### ⚠️ NEVER put your password in a config file or script

All Microsoft tools use **OAuth browser-based login** — meaning they open your browser and Microsoft handles the login securely. Your password never touches the tool's code or config files.

### How each tool logs in:

| Tool | How to Log In | Command |
|---|---|---|
| **PAC CLI** | Opens browser window | `pac auth create` |
| **m365 CLI** | Device code (browser) | `m365 login` |
| **PnP PowerShell** | Browser popup | `Connect-PnPOnline -Url "..." -Interactive` |
| **Dataverse MCP** | OAuth via Power Automate connection (set up once in browser) | Configured in MCP config file |
| **Canvas MCP** | Azure Identity SDK (browser/cached token) | Automatic on first use |
| **Copilot Studio MCP** | MSAL OAuth (browser popup on first use) | Automatic on first use |

### Can I give Copilot my credentials to log in for me?

**Short answer: No — and that's a good thing.**

Microsoft uses **OAuth 2.0 device code flow** and **interactive browser login**. This means:
- You log in once in a browser window
- A secure token is stored locally on your machine in the credential store (encrypted)
- The tools use that token automatically afterwards
- You never need to re-enter your password (tokens auto-refresh)

**This is the most secure approach** — your password never leaves Microsoft's servers.

### Practical Login Sequence (do this once):

```powershell
# 1. PAC CLI — Opens browser
pac auth create
# Select "Sign in" in the browser, done.

# 2. m365 CLI — Device code or browser
m365 login
# Follow the instructions shown in terminal

# 3. PnP PowerShell — Browser popup
Connect-PnPOnline -Url "https://YOURCOMPANY.sharepoint.com" -Interactive
# Browser window opens, sign in, done.
```

Tokens are cached — you usually only need to do this once per machine.

---

## 6. Configuring MCP Servers with AI Tools

### 6.1 GitHub Copilot CLI App Configuration

> ⭐ **Already configured for this workspace!** The two config files below were created automatically. This section explains what they do and how to set them up from scratch.

The GitHub Copilot CLI desktop app reads MCP server configuration from two places:

| File | Scope | What it's for |
|---|---|---|
| `~/.copilot/mcp-config.json` | User-wide | Servers available in every workspace |
| `.mcp.json` (in project folder) | Workspace | Servers specific to this project, with input prompts for sensitive values |

#### What's already configured

**User-level** (`C:\Users\<you>\.copilot\mcp-config.json`):
```json
{
  "mcpServers": {
    "powerapps-canvas": {
      "command": "CanvasAuthoringMcpServer",
      "args": []
    }
  }
}
```
This makes the Canvas Authoring MCP available in every project.

**Workspace-level** (`C:\Repositories\Powerapps Stuff\.mcp.json`):
```json
{
  "servers": {
    "powerapps-canvas": { "type": "stdio", "command": "CanvasAuthoringMcpServer", "args": [] },
    "dataverse": {
      "type": "stdio",
      "command": "Microsoft.PowerPlatform.Dataverse.MCP",
      "args": ["--ConnectionUrl", "${input:dataverseConnectionUrl}", "--TenantId", "${input:tenantId}", "..."]
    },
    "copilot-studio": {
      "type": "stdio",
      "command": "Microsoft.Agents.CopilotStudio.Mcp",
      "args": ["--remote-server-url", "${input:copilotStudioAgentUrl}", "..."]
    }
  },
  "inputs": [
    { "id": "tenantId", "description": "Your Tenant ID", "type": "promptString" },
    { "id": "dataverseConnectionUrl", "description": "Power Automate connection URL", "type": "promptString" },
    { "id": "copilotStudioAgentUrl", "description": "Copilot Studio agent MCP URL", "type": "promptString" }
  ]
}
```
The `${input:...}` placeholders mean the app will **prompt you to type the values** when you first use the server — no secrets stored in the file.

#### How to activate in the Copilot CLI app

1. Click the **MCP Servers** tab in the left panel
2. Click the 🔄 **refresh** button
3. You should see `powerapps-canvas`, `dataverse`, and `copilot-studio` listed
4. Before using `dataverse` or `copilot-studio`, the app will prompt you for your Tenant ID and connection URLs

#### To set up from scratch (for a new machine)

1. Create `C:\Users\<you>\.copilot\mcp-config.json` with the user-level content above
2. Create `.mcp.json` in your project folder with the workspace-level content above
3. Refresh the MCP Servers tab

---

### 6.2 Claude Desktop Configuration

1. Install Claude Desktop from: https://claude.ai/download
2. Open the config file:
   - Press `Win + R`, type `%APPDATA%\Claude`, press Enter
   - Open `claude_desktop_config.json` in Notepad or VS Code
   - If the file doesn't exist, create it

3. Paste this configuration (replace the placeholder values):

```json
{
  "mcpServers": {

    "Dataverse MCP Server": {
      "command": "Microsoft.PowerPlatform.Dataverse.MCP",
      "args": [
        "--ConnectionUrl", "PASTE_YOUR_POWER_AUTOMATE_CONNECTION_URL_HERE",
        "--MCPServerName", "DataverseMCPServer",
        "--TenantId", "PASTE_YOUR_TENANT_ID_HERE",
        "--EnableHttpLogging", "true",
        "--EnableMsalLogging", "false",
        "--Debug", "false",
        "--BackendProtocol", "HTTP"
      ]
    },

    "PowerApps Canvas MCP": {
      "command": "CanvasAuthoringMcpServer",
      "args": []
    },

    "Copilot Studio Agent": {
      "command": "Microsoft.Agents.CopilotStudio.Mcp",
      "args": [
        "--remote-server-url", "PASTE_YOUR_AGENT_URL_HERE",
        "--scopes", "https://api.powerplatform.com/.default"
      ]
    }

  }
}
```

4. Save the file
5. **Fully exit** Claude Desktop (check system tray, right-click → Quit)
6. Reopen Claude Desktop
7. You should see the MCP servers listed when you click the 🔧 tools icon

---

### 6.3 VS Code GitHub Copilot Configuration

#### Option A: User-level settings (applies to all projects)

1. Open VS Code Settings: `Ctrl+,`
2. Search for `mcp`
3. Click **Edit in settings.json**
4. Add inside the `"mcp"` key:

```json
{
  "mcp": {
    "servers": {

      "Dataverse MCP Server": {
        "type": "stdio",
        "command": "Microsoft.PowerPlatform.Dataverse.MCP",
        "args": [
          "--ConnectionUrl", "PASTE_YOUR_POWER_AUTOMATE_CONNECTION_URL_HERE",
          "--MCPServerName", "DataverseMCPServer",
          "--TenantId", "PASTE_YOUR_TENANT_ID_HERE",
          "--EnableHttpLogging", "true",
          "--EnableMsalLogging", "false",
          "--Debug", "false",
          "--BackendProtocol", "HTTP"
        ]
      },

      "PowerApps Canvas MCP": {
        "type": "stdio",
        "command": "CanvasAuthoringMcpServer",
        "args": []
      },

      "Copilot Studio Agent": {
        "type": "stdio",
        "command": "Microsoft.Agents.CopilotStudio.Mcp",
        "args": [
          "--remote-server-url", "PASTE_YOUR_AGENT_URL_HERE",
          "--scopes", "https://api.powerplatform.com/.default"
        ]
      }

    }
  }
}
```

#### Option B: Workspace-level (per-project, recommended for teams)

1. Press `Ctrl+Shift+P`
2. Type `MCP: Open Workspace Folder MCP Configuration`
3. This creates `.vscode/mcp.json` in your project
4. Paste the same `"servers": { ... }` block from Option A (without the outer `"mcp"` wrapper)

#### Using MCP in VS Code

1. Open GitHub Copilot: `Ctrl+Alt+I`
2. Switch from **Ask** mode to **Agent** mode (dropdown at the bottom of the chat)
3. Click the 🔧 tools icon to see available MCP servers
4. Make sure the Power Platform servers are checked
5. Click **OK** and start chatting!

---

## 7. Switching Dataverse Environments

When you work with multiple Power Platform environments (dev, test, production, client environments), you can switch which one the Dataverse MCP server connects to without editing config files manually.

### The Environment Switcher Script

A PowerShell script is included at `scripts/Switch-DataverseEnvironment.ps1`. It:
1. Calls `pac env list` to fetch all your Dataverse environments
2. Shows an interactive numbered menu (or accepts `-EnvironmentName` for scripting)
3. Updates `~/.copilot/mcp-config.json` with the new `ConnectionUrl`
4. Reminds you to start a new Copilot CLI session

### How to Use It

**Interactive (pick from menu):**
```powershell
cd "C:\Repositories\Powerapps Stuff"
.\scripts\Switch-DataverseEnvironment.ps1
```

**By name (for scripting):**
```powershell
.\scripts\Switch-DataverseEnvironment.ps1 -EnvironmentName "Kay's Environment"
.\scripts\Switch-DataverseEnvironment.ps1 -EnvironmentName "Xhub"
.\scripts\Switch-DataverseEnvironment.ps1 -EnvironmentName "CoE"
```

**After switching:**
- Start a new session in the Copilot CLI app (the MCP server reads the URL only at startup)
- The new session will connect to the updated environment

### Your Available Environments

Run `pac env list` to see all your environments and their URLs. Use the URL from that output when configuring the Dataverse MCP server.

> **Example format:** `https://orgXXXXXXXX.crm11.dynamics.com/`

---

## 8. Dashboard GUI

A Windows Forms GUI is included so you can manage Power Platform, SharePoint, and Azure DevOps **without typing long commands**.

### Launch it

Choose one of these options — they all do the same thing:

**Option 1 — Desktop shortcut (recommended, one-time setup):**
```powershell
cd "C:\Repositories\Powerapps Stuff"
.\Create-Shortcut.ps1
```
This creates **"Power Platform Dashboard"** on your Desktop. Double-click it any time. To pin to the taskbar: right-click the Desktop icon → "Pin to taskbar".

**Option 2 — Double-click the batch file:**
Open the repo folder in Explorer and double-click `Launch-Dashboard.bat`. No PowerShell window needed.

**Option 3 — PowerShell direct:**
```powershell
cd "C:\Repositories\Powerapps Stuff"
.\Launch-Dashboard.ps1
```

### Dashboard appearance

- **Theme:** Power Apps Fluent light theme — purple header bar, white/light content areas, dark console output
- **Responsive:** The window is resizable (minimum 800 × 650 pixels). Tabs and the output panel grow with the window.
- **Font:** Segoe UI throughout; Cascadia Code in the output console

### What's in each tab

| Tab | What you can do |
|---|---|
| **🌐 Environments** | List/switch Power Platform environments, open Admin Centre, check auth, view users and roles |
| **📦 Solutions** | Export, import, list, and sync solutions to GitHub with an AI-written summary of what changed |
| **🚀 Deploy** | Deploy solutions between environments — including cross-tenant |
| **🔧 ALM Tools** | Create disposable test environments, run Azure DevOps and GitHub Actions ALM pipelines |
| **🎨 Canvas** | Canvas app operations via Canvas MCP — list, open, and edit canvas apps |
| **🤖 Copilot Studio** | Manage and test Copilot Studio agents |
| **📊 Dataverse** | Query and update Dataverse tables using the Dataverse MCP |
| **🔗 SharePoint** | SharePoint site and list management via m365 CLI |
| **📋 Power Automate** | List and manage Power Automate flows |
| **⚙️ Settings** | GitHub PAT, Dataverse URL, Azure DevOps config, AI provider (Azure OpenAI or Claude) |
| **📝 Output** | Live log of every action — copy it to paste into Copilot for AI-assisted follow-up |

### How Copilot sees your actions

Every button click is logged to:
```
scripts\dashboard-log.json
```

There's a **📋 Copy Log (for Copilot)** button in the output panel. Click it, then paste into the Copilot CLI chat — I can see everything you did in the UI and continue from there.

---

## 9. Quick Reference — All Commands

### What's Installed on This Machine

| Tool | Version | Command | Installed Via |
|---|---|---|---|
| PAC CLI | 2.6.4 | `pac` | `dotnet tool` |
| m365 CLI | 11.6.0 | `m365` | `npm` |
| PnP.PowerShell | 3.1.0 | `Connect-PnPOnline` | `Install-Module` |
| Dataverse MCP | 0.2.310025 | `Microsoft.PowerPlatform.Dataverse.MCP` | `dotnet tool` |
| PowerApps Canvas MCP | 1.0.3382.38-preview | `CanvasAuthoringMcpServer` | `dotnet tool` |
| Copilot Studio MCP | 1.0.1 | `Microsoft.Agents.CopilotStudio.Mcp` | `dotnet tool` |
| Azure CLI | (system) | `az` | winget |
| Azure DevOps ext | 1.0.2 | `az devops` | `az extension add` |
| VSTeam | 7.15.2 | `Set-VSTeamAccount` | `Install-Module` |
| Azure DevOps MCP | latest | via `npx` | `npm` |
| Memory MCP | latest | via `npx` | `npm` |
| Sequential Thinking MCP | latest | via `npx` | `npm` |
| Filesystem MCP | latest | via `npx` | `npm` |
| Playwright MCP | latest | via `npx` | `npm` |
| GitHub MCP | latest | via `npx` | `npm` |

### Common Tasks Cheat Sheet

```powershell
# ===================== AUTHENTICATION =====================
pac auth create                                 # Log in to Power Platform
m365 login                                      # Log in to Microsoft 365
Connect-PnPOnline -Url "https://..." -Interactive  # Log in to SharePoint
az login                                        # Log in to Azure / Azure DevOps

# ===================== ENVIRONMENTS =====================
pac env list                                    # List all PP environments (pac)
m365 pp environment list                        # List all PP environments (m365)

# ===================== SOLUTIONS =====================
pac solution list                               # List solutions in PP
pac solution export --name "MySolution" --path ./out  # Export a solution
pac solution import --path ./MySolution.zip     # Import a solution

# ===================== SHAREPOINT =====================
m365 spo site list                              # List all SharePoint sites
m365 spo list list --webUrl "https://..."       # List lists in a site
m365 spo listitem list --listTitle "Tasks" --webUrl "https://..."
Get-PnPList                                     # List all lists (PnP)
Get-PnPListItem -List "Documents"              # Get items from list

# ===================== AZURE DEVOPS =====================
az devops configure --defaults organization=https://dev.azure.com/veldarr
az boards work-item show --id 123              # Get work item
az boards work-item create --title "Bug" --type Bug
az repos pr list                               # List pull requests
az pipelines run --name "My Pipeline"          # Trigger pipeline
Set-VSTeamAccount -Account veldarr -PersonalAccessToken "YOUR_PAT"
Get-VSTeamWorkItem -Id 123                     # Get work item (PowerShell)
Get-VSTeamBuild -ProjectName "MyProject"       # List builds

# ===================== POWER APPS =====================
m365 pa app list                                # List all canvas apps
pac canvas unpack --msapp ./App.msapp --sources ./src  # Unpack app for editing
pac canvas pack --sources ./src --msapp ./App.msapp    # Repack app

# ===================== DATAVERSE =====================
m365 pp dataverse table list                    # List Dataverse tables
pac env list                                    # List environments with Dataverse

# ===================== POWER AUTOMATE =====================
m365 flow list                                  # List all cloud flows
m365 flow run list --name "flow-id"            # List runs of a flow
m365 flow export --id "flow-id" --path ./flow.zip  # Export a flow
```

---

## 10. Updating All Tools

Run these periodically to keep everything current:

```powershell
# Update PAC CLI
dotnet tool update --global Microsoft.PowerApps.CLI.Tool

# Update Dataverse MCP
dotnet tool update --global Microsoft.PowerPlatform.Dataverse.MCP

# Update PowerApps Canvas MCP (include --prerelease while in preview)
dotnet tool update --global --prerelease Microsoft.PowerApps.CanvasAuthoring.McpServer

# Update Copilot Studio MCP
dotnet tool update --global Microsoft.Agents.CopilotStudio.Mcp

# Update m365 CLI
npm install -g @pnp/cli-microsoft365@latest

# Update Azure DevOps MCP
npm install -g @tiberriver256/mcp-server-azure-devops@latest

# Update PnP PowerShell
Update-Module -Name PnP.PowerShell -Scope CurrentUser -Force

# Update VSTeam
Update-Module -Name VSTeam -Scope CurrentUser -Force -SkipPublisherCheck

# Update Azure CLI and extensions
az upgrade
az extension update --name azure-devops

# See all installed dotnet tools and their versions
dotnet tool list -g
```

---

## 11. Troubleshooting

### "pac is not recognized"
```powershell
# Add dotnet tools to your PATH
$env:PATH += ";$env:USERPROFILE\.dotnet\tools"
# To make permanent, add to your PowerShell profile:
Add-Content $PROFILE "`$env:PATH += `";$env:USERPROFILE\.dotnet\tools`""
```

### "m365: Cannot find module"
```powershell
# Reinstall m365 CLI
npm uninstall -g @pnp/cli-microsoft365
npm install -g @pnp/cli-microsoft365
```

### MCP Server not showing in Claude/VS Code
1. Verify the tool runs: `Microsoft.PowerPlatform.Dataverse.MCP --help`
2. Check your JSON has no syntax errors (paste it at https://jsonlint.com)
3. Fully exit Claude (system tray → right-click → Quit), then reopen
4. In VS Code: `Ctrl+Shift+P` → `MCP: List Servers` to see status
5. Check Claude logs: `%APPDATA%\Claude\logs`

### Dataverse MCP authentication errors
- Ensure the Power Automate connection is created and uses the same account
- Make sure the Dataverse environment has been provisioned
- Try `--enable-msal-logging true` in the args for detailed auth logs

### Copilot Studio MCP not connecting
- **Make sure your agent is Published** in Copilot Studio (this is required!)
- Verify the URL you copied from the MCP Client channel is complete
- Try adding `"--debug", "true"` to the args temporarily

### PnP PowerShell — Execution Policy error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 12. Security: How to Authenticate Safely

### Why you should NEVER put passwords in config files

Config files like `claude_desktop_config.json` or `settings.json` are plain text files that can accidentally be committed to Git or shared. **Never put your Microsoft 365 password, client secrets, or API keys in these files.**

### The Secure Way — OAuth Device Code / Interactive Flow

All tools in this guide use **OAuth 2.0** — the industry-standard secure authentication protocol:

```
You run a command → Tool opens browser or shows a code → 
You sign in on Microsoft's website → Microsoft gives the tool a token → 
Token is stored encrypted on your machine → Tool uses it automatically
```

**Your password never touches these tools. Only Microsoft sees it.**

### Token Storage Locations (for your reference)

| Tool | Token Location |
|---|---|
| PAC CLI | Windows Credential Manager |
| m365 CLI | `%APPDATA%\m365cli\tokens.json` (encrypted) |
| PnP PowerShell | Windows Credential Manager / in-memory per session |
| MCP Servers | Via MSAL cache in `%LOCALAPPDATA%\.IdentityService` |

### If You're Automating (CI/CD, Scripts)

Use **Service Principals** instead of personal accounts:
1. Register an app in **Entra ID** (Azure Active Directory)
2. Give it the required permissions (SharePoint, Dataverse, etc.)
3. Use **Client ID + Certificate** (never a client secret in plain text!)

```powershell
# PAC CLI with Service Principal
pac auth create --applicationId "YOUR_APP_ID" --tenant "YOUR_TENANT_ID" --clientSecret "SECRET"
# For prod: use --certificateThumbprint instead of --clientSecret

# m365 CLI with Service Principal
m365 login --authType secret --clientId "YOUR_APP_ID" --clientSecret "SECRET" --tenant "YOUR_TENANT_ID"

# PnP PowerShell with Certificate (most secure)
Connect-PnPOnline -Url "https://..." -ClientId "YOUR_APP_ID" -Tenant "YOUR_TENANT_ID" -CertificatePath "./cert.pfx"
```

---

## 🔗 Key Links

| Resource | URL |
|---|---|
| Power Apps | https://make.powerapps.com |
| Power Automate | https://make.powerautomate.com |
| Power Platform Admin Center | https://aka.ms/ppac |
| Copilot Studio | https://copilotstudio.microsoft.com |
| Azure DevOps | https://dev.azure.com/veldarr |
| PAC CLI Docs | https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction |
| m365 CLI Docs | https://pnp.github.io/cli-microsoft365/ |
| PnP PowerShell Docs | https://pnp.github.io/powershell/ |
| Azure CLI Docs | https://learn.microsoft.com/en-us/cli/azure/ |
| VSTeam Docs | https://github.com/MethodsAndPractices/vsteam |
| Azure DevOps MCP | https://github.com/tiberriver256/mcp-server-azure-devops |
| Dataverse MCP Labs | https://github.com/microsoft/Dataverse-MCP |
| Power Platform MCP Samples | https://aka.ms/pp-mcp |
| Copilot Studio MCP Proxy NuGet | https://www.nuget.org/packages/Microsoft.Agents.CopilotStudio.Mcp |
| Canvas Authoring MCP NuGet | https://www.nuget.org/packages/Microsoft.PowerApps.CanvasAuthoring.McpServer |

---

## 13. Deploy / Migrate Solutions (Tab 7 — Deploy)

The dashboard's **🚀 Deploy** tab lets you move solutions between environments — including cross-tenant.

### Same-tenant deploy (basic)
1. **Refresh Envs** to load all your environments  
2. Pick **Source env** and **Target env** from the dropdowns  
3. Click **🔄 Load Solutions** to show solutions in the source  
4. Tick **Managed** or **Unmanaged**, tick **Overwrite** / **Publish** as needed  
5. Press **🚀 Deploy** — it exports a zip then imports it  

### Cross-tenant deploy
If your target is in a different tenant:
1. Fill in **Target Tenant ID** (e.g. `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)  
2. Press **🔐 Auth to Target** — this runs `pac auth create` for the target tenant  
3. Then run the normal deploy steps above  

### Source Control section
| Button | What it does |
|---|---|
| `📁 git status` | Shows uncommitted changes in the repo |
| `⬇ git pull` | Pulls latest from `origin` |
| `📦 Export+Unpack+Commit` | Exports solution → unpacks → `git add .` → `git commit` |
| `⬆ Push & PR` | `git push` then opens PR instructions in output |

---

## 14. ALM Pipelines Structure

The `alm/` folder contains everything needed for automated deployments.

```
alm/
├── src/                          ← Unpacked solution source (versioned)
├── config/
│   ├── dev.json                  ← Connection references for Dev
│   ├── test.json                 ← Connection references for Test
│   └── prod.json                 ← Connection references for Prod
├── pipelines/                    ← Azure DevOps YAML pipelines
│   ├── export-solution.yml       ← Dev export trigger
│   ├── build-solution.yml        ← Pack + test on PR
│   └── deploy-solution.yml       ← Test → Prod with approval gates
└── .github/
    └── workflows/
        ├── export-solution.yml   ← GitHub Actions export
        └── build-deploy.yml      ← GitHub Actions build + deploy
```

### Variables to replace in pipelines
| Placeholder | What to put there |
|---|---|
| `PowerPlatformSPN` | Azure DevOps service connection name |
| `DevEnvironmentUrl` | e.g. `https://orgXXXX.crm11.dynamics.com/` |
| `TestEnvironmentUrl` | Your Test environment URL |
| `ProdEnvironmentUrl` | Your Prod environment URL |
| `PP_CLIENT_ID` | Entra app registration client ID |
| `PP_CLIENT_SECRET` | Client secret (store as GitHub secret) |
| `PP_TENANT_ID` | `36d68e61-4fcf-41b8-bc84-f5bbba006d88` |

### Setting up the service principal
```powershell
# Create an app registration and grant Power Platform System Admin
az ad app create --display-name "PP-ALM-SPN"
az ad sp create --id <appId>
# In Power Platform Admin Center → Environment → Add member → <appId> as System Administrator
```

---

## 15. Code Review (Tab 8 — 🔍 Code Review)

The **Code Review** tab gives you git review, PAC Solution Checker, and PR creation — all from the dashboard.

### Git Review section
| Field | Description |
|---|---|
| Repo path | Full path to your local git repo |
| Compare | `main` ↔ `HEAD` by default; change to any branch/commit |

| Button | What it does |
|---|---|
| `📄 Diff` | Full diff between the two refs |
| `📋 Log` | Commit log between the two refs |
| `🗂 Changed Files` | File list with status (A/M/D) |
| `👤 Blame` | Commit contribution summary |
| `📊 Diff Stats` | Insertions/deletions summary |

### PAC Solution Checker
Microsoft's static analysis tool that checks your solution against AppSource, default Solution, or PowerApps Recommendations rulesets.

1. Click **📁** to browse to your exported `.zip`  
2. Choose a ruleset  
3. Press **🔍 Run Solution Checker**  
4. Press **📊 Open Report** to see the HTML report in Explorer  

> Solution Checker requires `pac` to be authenticated. Run `pac auth create` first.

### PR Creation
| Button | What it does |
|---|---|
| `🐙 Create GitHub PR` | Runs `gh pr create` (needs GitHub CLI: `winget install GitHub.cli`) |
| `📋 List Open PRs` | `gh pr list` in your repo |
| `🔵 Create ADO PR` | `az repos pr create` for Azure DevOps |

#### Install GitHub CLI
```powershell
winget install GitHub.cli
gh auth login          # sign in once
```

### AI Code Review (Copilot)
Press **🤖 Ask Copilot to Review Diff** to:
1. Generate a `git diff` patch file  
2. Build a detailed review prompt  
3. Copy it to your clipboard  

Paste into this Copilot CLI chat (or any AI) for a full Power Platform–aware code review.

---

## 16. Copilot Studio Integration

### Direction A — Use a Copilot Studio agent AS a tool in this CLI

Your Copilot Studio agent can expose its skills to this Copilot CLI via the MCP protocol.

**Steps:**
1. Open [Copilot Studio](https://copilotstudio.microsoft.com) → your agent  
2. Go to **Settings → Channels → Add channel → MCP Client**  
3. Enable the channel and copy the **Endpoint URL** (looks like `https://....api.powerplatform.com/...`)  
4. Update `~/.copilot/mcp-config.json` — replace `REPLACE_WITH_YOUR_AGENT_MCP_URL`:

```json
"copilot-studio": {
  "type": "local",
  "command": "Microsoft.Agents.CopilotStudio.Mcp",
  "args": [
    "--remote-server-url", "https://your-agent-url-here",
    "--tenant-id", "36d68e61-4fcf-41b8-bc84-f5bbba006d88",
    "--scopes", "https://api.powerplatform.com/.default"
  ]
}
```

5. Restart Copilot CLI — your agent's actions are now tools here.

### Direction B — Expose our MCP servers TO a Copilot Studio agent

Your Studio agent can call the Dataverse/Canvas MCP servers as tools, but they need to be publicly hosted (they run locally now).

**Option 1 — Azure Container App (recommended):**
```bash
az containerapp up --name dataverse-mcp --resource-group rg-copilot \
  --image mcr.microsoft.com/... --ingress external --target-port 3000
```

**Option 2 — ngrok (dev/testing only):**
```powershell
winget install ngrok
ngrok http 3000   # exposes localhost:3000 publicly
```

Then in Copilot Studio → **Agent → Tools → Add a tool → New tool → Model Context Protocol** → paste the public URL.

---
