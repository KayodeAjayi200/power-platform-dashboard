# ⚡ Power Platform Dashboard

> **A complete Power Platform ALM toolkit with a point-and-click GUI — set up entirely by your AI agent. No command line required.**

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-7.4%2B-blue?logo=powershell)
![Power Platform](https://img.shields.io/badge/Power%20Platform-742774?logo=microsoftpowerplatform&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ Setup — 2 steps

### Step 1 — Clone this repo

```
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git
```

> Clone it anywhere you like — your Desktop, Documents, wherever is convenient.  
> **No git?** Ask your AI: *"Clone https://github.com/KayodeAjayi200/power-platform-dashboard to my computer"*

---

### Step 2 — Paste this into your AI agent

Open [`SETUP_PROMPT.txt`](./SETUP_PROMPT.txt) from the cloned folder, **fill in your folder path** where indicated, then paste it into any AI agent (Copilot, Claude, ChatGPT, Cursor, etc.):

```
I've cloned the Power Platform Dashboard repository to "C:\Repositories\Powerapps Stuff".

Please read the file at this path:
  C:\Repositories\Powerapps Stuff\AGENT_SKILL.md

Then follow every setup step in that file using your tool-execution capability.

Rules:
- Run all install commands automatically — do not ask me to run them
- Tell me what you are doing at each step
- Pause and ask me ONLY when a browser login window is needed
- After everything is installed and configured, launch the dashboard for me

I am on Windows 11. Let's go.
```

**Done.** Your AI installs all tools, configures MCP servers, handles browser authentication, and launches the dashboard. No command line needed.

---

### Works with any AI agent

| Agent | How |
|---|---|
| **GitHub Copilot** (VS Code / github.com / Copilot app) | Copilot Chat → paste prompt |
| **Claude** (claude.ai / Claude Desktop) | New conversation → paste prompt |
| **ChatGPT / OpenAI Codex** | New conversation → upload `SETUP_PROMPT.txt` → *"follow these"* |
| **Cursor / Windsurf / Cline** | Agent panel → paste prompt |
| **Any agent with PowerShell tool use** | Paste prompt — it's agent-agnostic |

---

## What it does

A **WinForms desktop dashboard** wrapping the entire Power Platform developer toolchain into a point-and-click interface. Built for teams where not everyone is comfortable with the command line. Designed to look and feel like Power Apps Studio — light theme, purple header, responsive layout that adjusts to any window size.

| Feature | How it works |
|---|---|
| Manage environments | Environment switcher always visible at the top |
| Export & unpack solutions | One click — zip and YAML side-by-side |
| Sync solutions to GitHub with AI summaries | Select repo → click sync → AI explains what changed |
| Deploy between environments | Visual source→target picker with managed/unmanaged toggle |
| Create disposable test environments | Name it, pick a region, deploy a solution — fully automated |
| **Build canvas apps by describing what you want** | Tell your AI "build me a canvas app for expense tracking" — it generates the whole app and opens it in Power Apps Studio |
| **Edit canvas apps in plain English** | Tell your AI "add a filter for pending items" — it updates your live app automatically |
| Rename canvas app controls with AI | Unpack `.msapp` → AI suggests camelCase names → repack |
| Run ALM pipelines (Azure DevOps & GitHub Actions) | Click-to-trigger with live log streaming |
| Query Dataverse, SharePoint, GitHub via AI | MCP-powered AI assistant with 9 connected live tools |

---

## 🖥 Dashboard tabs

| Tab | What it does |
|---|---|
| 🌐 **Environments** | List all environments; switch with top dropdown |
| 📦 **Solutions** | Export, import, sync to GitHub with AI diff summary |
| 🚀 **Deploy** | Deploy solutions between environments (cross-tenant supported) |
| 🔧 **ALM Tools** | Disposable environments, canvas AI rename, ALM pipelines |
| 🎨 **Canvas** | Canvas app operations via Canvas MCP |
| 🤖 **Copilot Studio** | Manage Copilot Studio agents |
| 📊 **Dataverse** | Query and edit Dataverse tables |
| 🔗 **SharePoint** | SharePoint site and list management |
| 📋 **Power Automate** | Flow listing and management |
| ⚙️ **Settings** | GitHub PAT, Dataverse URL, ADO config, AI provider |
| 📝 **Output** | Live log of all operations |

---

## 🤖 Build canvas apps by describing what you want

Once set up, you can create and edit Power Apps canvas apps just by telling your AI what you need — no coding required.

**Examples of what you can say:**

> *"Build me a canvas app for tracking expenses with an approval workflow"*
> 
> *"Create an employee directory app with a photo grid and a search bar"*
>
> *"Add a new screen to my app that shows a chart of this month's sales"*
>
> *"Make the home screen use cards instead of a plain list"*

Your AI generates the entire app, opens it in Power Apps Studio, and keeps refining it as you give more instructions. You can keep chatting until it looks exactly how you want.

> **One-time setup:** Your AI handles this automatically during initial setup (Step 3b in `AGENT_SKILL.md`). It needs .NET 10 and coauthoring enabled in Power Apps Studio — your AI will guide you through both.

---

## 🧠 AI Agent Skills

This repo ships with **agent skill files** — structured reference docs that tell AI agents exactly what to know for each domain. They work with any agent that supports skill/context files.

### Built-in skills (in `skills/`)

| Skill | Description |
|---|---|
| [`skills/PowerApps-Canvas-Skill.md`](./skills/PowerApps-Canvas-Skill.md) | All ~60 canvas controls, 150+ Power Fx functions, components, common patterns |
| [`skills/PowerApps-Canvas-Design-Skill.md`](./skills/PowerApps-Canvas-Design-Skill.md) | UI/UX design — containers, responsive layouts, Fluent UI, gallery designs, filter panels, nav menus |
| [`skills/PowerApps-Delegation-Skill.md`](./skills/PowerApps-Delegation-Skill.md) | Delegation warnings, Filter/Search formulas on large data sources, data correctness at scale |
| [`skills/Canvas-Authoring-MCP-Skill.md`](./skills/Canvas-Authoring-MCP-Skill.md) | Connecting the Canvas Authoring MCP to the right app — extracting IDs from Studio URL, updating config, resolving 404 errors |

### Installing skills into the Copilot app

If you use the **GitHub Copilot desktop app**, just tell your AI agent:

> *"Install the agent skills from this repo into my Copilot app"*

Your AI will copy the skill files to the right place automatically. Then open the Skills panel and click 🔄 Refresh — the skills will appear under **personal-agents**.

### For VS Code / GitHub Copilot coding agent

The repo includes [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) which GitHub Copilot reads automatically in every session. It routes Copilot to the correct skill file for each topic.

---

## 🔌 MCP servers (AI gets live access to your data)

| Server | What your AI can do |
|---|---|
| `dataverse` | Query and update Dataverse tables directly |
| `canvas` | Read canvas app structure and controls |
| `canvas-authoring` | Edit a live canvas app via Power Apps Studio co-authoring |
| `copilot-studio` | Manage Copilot Studio agents |
| `github` | Read repos, issues, PRs |
| `azure-devops` | Trigger pipelines, view work items |
| `filesystem` | Read local files |
| `fetch` | Browse the web |
| `playwright` | Browser automation |

---

## 📦 Credentials you'll need

Your AI agent pauses and asks for these during setup — just paste the values when prompted:

| Credential | Where to find it |
|---|---|
| **GitHub Personal Access Token** | github.com → Settings → Developer settings → Fine-grained tokens → New token (scopes: Contents R/W, Pull requests R/W, Issues R/W, Workflows R/W) |
| **Dataverse connection URL** | Power Automate → My connections → Common Data Service → `···` → Details → copy the full URL (includes `?apiName=...`) |
| **Azure DevOps org URL** | `https://dev.azure.com/YOUR_ORG_NAME` |
| **Copilot Studio MCP URL** *(optional)* | Copilot Studio → Settings → Channels → MCP Client |
| **AI API key** *(optional)* | Azure OpenAI or Anthropic — leave blank to use GitHub Copilot for free |

> 🔒 Credentials are stored only in `~/.copilot/` on your local machine. They are **never** committed to this repo.

---

## 🏗 Repository structure

```
power-platform-dashboard/
├── SETUP_PROMPT.txt                  ← ★ Paste into any AI to set up everything
├── AGENT_SKILL.md                    ← Full setup instructions the AI follows
├── Launch-Dashboard.bat              ← Double-click to open the dashboard
├── Create-Shortcut.ps1               ← Run once to get a taskbar-pinnable Desktop icon
├── Launch-Dashboard.ps1              ← PowerShell launcher (right-click → Run with PowerShell)
├── TOOLS-SETUP.md                    ← Manual setup reference for developers
├── .mcp.json                         ← MCP server config (used by VS Code Copilot)
├── .github/
│   ├── copilot-instructions.md       ← Copilot reads this automatically every session
│   └── workflows/
│       └── copilot-setup-steps.yml   ← Pre-installs all tools in Copilot cloud agent
├── skills/
│   ├── PowerApps-Canvas-Skill.md         ← Power Fx + controls reference (agent skill)
│   ├── PowerApps-Canvas-Design-Skill.md  ← UI/UX design, containers, Fluent UI (agent skill)
│   ├── PowerApps-Delegation-Skill.md     ← Delegation warnings + large data sources (agent skill)
│   └── Canvas-Authoring-MCP-Skill.md    ← Canvas Authoring MCP connection guide (agent skill)
├── scripts/
│   ├── PowerPlatformDashboard.ps1   ← Main WinForms dashboard (~2800 lines)
│   ├── Install-PPDashboard.ps1      ← Full toolchain installer script
│   └── mcp-config-template.json    ← MCP server config template
└── alm/
    ├── .github/workflows/           ← GitHub Actions pipeline templates
    ├── pipelines/                   ← Azure DevOps pipeline templates
    └── config/                      ← Per-environment configuration (dev/test/prod)
```

---

## 🤝 Sharing with your team

1. Send the repo link: **https://github.com/KayodeAjayi200/power-platform-dashboard**
2. Say: *"Clone it, then paste `SETUP_PROMPT.txt` into your AI agent"*

Each person authenticates their own accounts via browser pop-ups — the AI does everything else.

---

## 🔧 Manual install (developers)

```powershell
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git "C:\Repositories\Powerapps Stuff"
cd "C:\Repositories\Powerapps Stuff"
pwsh -ExecutionPolicy Bypass -File scripts\Install-PPDashboard.ps1
.\Create-Shortcut.ps1   # puts a pinnable icon on your Desktop
```

Then double-click **"Power Platform Dashboard"** on your Desktop, or double-click `Launch-Dashboard.bat`.

For a full manual walkthrough see [`TOOLS-SETUP.md`](./TOOLS-SETUP.md).

---

## 🛠 Toolchain

| Tool | Purpose |
|---|---|
| **PAC CLI** | Export, import, and manage Power Platform solutions |
| **m365 CLI** | SharePoint, Teams, Entra ID operations |
| **PnP.PowerShell** | Deep SharePoint operations |
| **Azure CLI** | Azure resources and DevOps authentication |
| **GitHub CLI** | Repos, pull requests, GitHub Actions |
| **gh-copilot extension** | AI in the terminal |

---

## License

MIT — free to use, modify, and share.
