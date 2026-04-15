# Power Platform Dashboard — Agent Skill

> **Give this file to any AI agent (GitHub Copilot, Claude, ChatGPT, etc.).**  
> It tells the agent exactly how to set up and use the Power Platform Dashboard  
> so non-developers get a working environment with zero command-line knowledge.

---

## What this skill enables

This skill lets an AI agent:
- Install all required Power Platform CLI tools on a Windows machine
- Configure MCP servers so the AI can query Dataverse, SharePoint, Azure DevOps, etc.
- Launch a GUI dashboard that lets non-developers manage solutions, deployments, and source control
- Sync Power Platform solutions to GitHub with AI-generated change summaries

---

## 1 · System Requirements

| Requirement | Minimum |
|---|---|
| OS | Windows 10 / 11 (64-bit) |
| PowerShell | 7.4+ (`winget install Microsoft.PowerShell`) |
| .NET | 8.0 SDK (`winget install Microsoft.DotNet.SDK.8`) |
| Node.js | 20+ (`winget install OpenJS.NodeJS.LTS`) |
| Git | Any recent (`winget install Git.Git`) |

---

## 2 · One-command bootstrap (run as the user, not admin)

```powershell
irm https://raw.githubusercontent.com/YOUR_ORG/veldarr-powerplatform/main/scripts/Install-PPDashboard.ps1 | iex
```

Or run `Install-PPDashboard.ps1` from the repo locally.

---

## 3 · Tools installed and why

| Tool | Install command | Purpose |
|---|---|---|
| PAC CLI | `winget install Microsoft.PowerPlatformCLI` | Export/import solutions, manage environments |
| m365 CLI | `npm install -g @pnp/cli-microsoft365` | SharePoint, Teams, Entra ID management |
| PnP.PowerShell | `Install-Module PnP.PowerShell -Scope CurrentUser` | SharePoint deep operations |
| Azure CLI | `winget install Microsoft.AzureCLI` | Azure resources, DevOps auth |
| GitHub CLI | `winget install GitHub.cli` | Repos, PRs, Actions |
| gh-copilot ext | `gh extension install github/gh-copilot` | AI in terminal |

### MCP Servers (registered via `copilot mcp add`)

| Server | Package | What it gives the AI |
|---|---|---|
| dataverse | `Microsoft.PowerPlatform.Dataverse.MCP` (dotnet tool) | Query/update Dataverse tables |
| canvas | `Microsoft.PowerPlatform.Canvas.MCP` (dotnet tool) | Read canvas app structure |
| copilot-studio | `@microsoft/copilot-studio-mcp` (npm) | Copilot Studio agent management |
| sharepoint | `@modelcontextprotocol/server-sharepoint` (npm) | SharePoint sites and files |
| github | `@modelcontextprotocol/server-github` (npm) | GitHub repos, issues, PRs |
| azure-devops | `@tiberriver256/mcp-server-azure-devops` (npm) | ADO pipelines, work items |
| filesystem | `@modelcontextprotocol/server-filesystem` (npm) | Local file access |
| fetch | `@kazuph/mcp-fetch` (npm) | Web scraping |
| playwright | `@playwright/mcp` (npm) | Browser automation |

---

## 4 · Configuration values the user must supply

Ask the user for these — then write them to `~/.copilot/mcp-config.json` and/or the Settings tab in the dashboard:

| Setting | Where to find it | Used by |
|---|---|---|
| **GitHub PAT** | github.com → Settings → Developer settings → Fine-grained tokens | GitHub MCP, gh CLI |
| **Dataverse connection URL** | Power Automate → Connections → Common Data Service → `...` → Details. URL format: `https://make.powerautomate.com/environments/{envId}?apiName=shared_commondataserviceforapps&connectionName={connId}` | Dataverse MCP |
| **Azure DevOps org URL** | `https://dev.azure.com/{orgname}` | ADO MCP, az cli |
| **Copilot Studio MCP URL** | Copilot Studio → Settings → Channels → MCP Client → copy URL | Copilot Studio MCP |
| **AI API key** (optional) | Azure OpenAI portal OR Anthropic console. Leave blank to use GitHub Copilot clipboard mode | AI Assistant tab |

### GitHub PAT permissions required
- Contents (Read/Write)
- Pull requests (Read/Write)  
- Issues (Read/Write)
- Workflows (Read/Write)
- Metadata (Read — auto-granted)

---

## 5 · How to launch the dashboard

```powershell
cd "C:\Repositories\Powerapps Stuff"
.\Launch-Dashboard.ps1
```

Or double-click `Launch-Dashboard.ps1` in Explorer → "Run with PowerShell".

---

## 6 · Dashboard tabs and what each does

| Tab | Non-dev description |
|---|---|
| 🌐 Environments | See and switch between Power Platform environments |
| 📦 Solutions | List, export, import, and sync solutions to GitHub |
| 🗂 SharePoint | Manage SharePoint sites, lists, and pages |
| 🔧 Azure DevOps | View pipelines, work items, repos |
| 🚀 ALM Pipelines | Run deployment pipelines (Dev → Test → Prod) |
| 🔌 MCP Servers | See which AI tools are connected |
| 📤 Deploy | Move/migrate solutions between environments or tenants |
| 🔍 Code Review | Review solution changes, run checkers, create PRs |
| ⚙️ Settings | Configure tokens, URLs, and AI provider without editing JSON |
| 🤖 AI Assistant | Chat with an AI about Power Platform topics |

---

## 7 · Key workflows (what to tell the AI to do)

### Export a solution to GitHub
> "Sync my [SolutionName] solution to GitHub"

The AI should:
1. Switch to the correct environment (top dropdown)
2. Go to Solutions tab — solution list auto-loads
3. Select the solution from the dropdown
4. Set repo path (or create/clone via the UI buttons)
5. Click "📤 Export → Unpack → AI Summary → Commit → Push"

### Deploy to another environment
> "Deploy [SolutionName] from Dev to Test"

The AI should guide the user to the Deploy tab and use the cross-environment migration section.

### Connect to a new environment
> "Switch to my Production environment"

Use the top environment dropdown → select env → click ⚡ Switch.  
Solutions and other data refresh automatically.

---

## 8 · Troubleshooting

| Symptom | Fix |
|---|---|
| "pac not found" | Run `winget install Microsoft.PowerPlatformCLI` then restart terminal |
| "No environments loaded" | Run `pac auth create` and sign in, then click Environments tab |
| Dataverse MCP fails with "Missing apiName" | URL must be the Power Automate connection URL (see §4), NOT the org URL |
| GitHub CLI fails | Run `gh auth login` and complete browser login |
| "Export failed" | Check `pac auth list` — make sure you're authenticated to the right environment |
| Solutions dropdown empty | Check environment is selected at top; click another tab and back to re-trigger auto-load |

---

## 9 · For the AI agent — setup script flow

When a user asks "set up Power Platform tools for me", follow this sequence:

```
1. Check winget, PowerShell 7, Node.js, .NET 8, Git → install missing
2. Install PAC CLI via winget
3. Install m365 CLI via npm  
4. Install PnP.PowerShell via Install-Module
5. Install Azure CLI + GitHub CLI via winget
6. Install gh-copilot extension
7. Install dotnet MCP tools (dataverse, canvas, copilot-studio)
8. Install npm MCP servers
9. Run `copilot mcp add` for each server (use template in mcp-config-template.json)
10. Ask user for PAT, Dataverse URL, ADO org, Copilot Studio URL
11. Write values to ~/.copilot/mcp-config.json
12. Clone or copy dashboard repo to C:\Repositories\Powerapps Stuff\
13. Run .\Launch-Dashboard.ps1 — user is done!
```

---

## 10 · File locations

| File | Purpose |
|---|---|
| `scripts/PowerPlatformDashboard.ps1` | Main dashboard (WinForms GUI) |
| `Launch-Dashboard.ps1` | One-click launcher |
| `scripts/Install-PPDashboard.ps1` | Full toolchain installer |
| `~/.copilot/mcp-config.json` | MCP server registrations |
| `~/.copilot/pp-dashboard-settings.json` | Dashboard settings (AI key, URLs) |
| `alm/` | ALM pipeline templates (ADO + GitHub Actions) |
| `TOOLS-SETUP.md` | Full beginner guide with screenshots |
