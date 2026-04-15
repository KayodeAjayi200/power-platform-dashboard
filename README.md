# ⚡ Power Platform Dashboard

> **A complete Power Platform ALM toolkit with a point-and-click GUI — set up entirely by your AI agent. No command line required.**

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-7.4%2B-blue?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ Setup — 2 steps only

### Step 1 — Clone this repo

```
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git "C:\Repositories\Powerapps Stuff"
```

> **No git?** Ask your AI: *"Clone https://github.com/KayodeAjayi200/power-platform-dashboard into C:\Repositories\Powerapps Stuff"*

---

### Step 2 — Paste this into your AI agent

Open [`SETUP_PROMPT.txt`](./SETUP_PROMPT.txt) from the cloned folder and paste its full contents into any AI agent chat. Or copy from here:

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

**Done.** Your AI installs all tools, configures MCP servers, handles browser-based authentication, and launches the dashboard. No command line needed.

---

### Works with any AI agent

| AI Agent | How |
|---|---|
| **GitHub Copilot** (VS Code / github.com) | Copilot Chat → paste prompt |
| **Claude** (claude.ai or Claude Desktop) | New conversation → paste prompt |
| **ChatGPT / OpenAI Codex** | New conversation → upload `SETUP_PROMPT.txt` → *"follow these"* |
| **Cursor / Windsurf / Cline** | Agent panel → paste prompt |
| **Any agent with PowerShell tool use** | Paste prompt — it's agent-agnostic |

---

## What is this?

A **WinForms desktop dashboard** that wraps the entire Power Platform developer toolchain into a point-and-click interface. Designed for teams where some members are not comfortable with the command line.

| What you can do | How |
|---|---|
| Manage Power Platform environments | Environment switcher, always visible at the top |
| Export & unpack solutions | One click — zipped & YAML side-by-side |
| Sync solutions to GitHub with AI summaries | Select repo → click sync → AI explains what changed |
| Deploy between environments (including cross-tenant) | Visual source→target picker with managed/unmanaged toggle |
| Create disposable environments for testing | Name it, pick a region, deploy a solution — it creates everything |
| Rename canvas app controls with AI | Unpack `.msapp` → AI suggests camelCase names → repack |
| Run ALM pipelines (Azure DevOps & GitHub Actions) | Click-to-trigger with live log streaming |
| Query Dataverse, SharePoint, GitHub via AI (MCP) | Built-in AI Assistant tab with 9 connected tools |
| Code review Power Platform changes | Diff view with AI-generated review comments |

---

## 🤝 Sharing with your team

To give a colleague access:

1. Send them the link: **https://github.com/KayodeAjayi200/power-platform-dashboard**
2. Tell them: *"Clone the repo then paste `SETUP_PROMPT.txt` into your AI agent"*
3. They authenticate their own accounts via browser pop-ups — the AI handles the rest

No one needs to touch the command line.

---

## 🔧 Manual setup (developers only)

```powershell
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git "C:\Repositories\Powerapps Stuff"
cd "C:\Repositories\Powerapps Stuff"
pwsh -ExecutionPolicy Bypass -File scripts\Install-PPDashboard.ps1
.\Launch-Dashboard.ps1
```

---

| Tool | Purpose |
|---|---|
| **PAC CLI** | Export, import, and manage Power Platform solutions |
| **m365 CLI** | SharePoint, Teams, Entra ID management |
| **PnP.PowerShell** | Deep SharePoint operations |
| **Azure CLI** | Azure resources and DevOps auth |
| **GitHub CLI** | Repos, pull requests, GitHub Actions |
| **gh-copilot extension** | AI in the terminal |

### MCP servers (give your AI real-time access to your data)

| Server | What it lets your AI do |
|---|---|
| `dataverse` | Query and update Dataverse tables directly |
| `canvas` | Read canvas app structure and controls |
| `copilot-studio` | Manage Copilot Studio agents |
| `sharepoint` | Browse and edit SharePoint sites |
| `github` | Read repos, issues, PRs |
| `azure-devops` | Trigger pipelines, view work items |
| `filesystem` | Read local files |
| `fetch` | Browse the web |
| `playwright` | Browser automation |

---

## 🖥 Dashboard tabs

| Tab | What it does |
|---|---|
| 🌐 **Environments** | See all environments; switch with the top dropdown |
| 📦 **Solutions** | List, export, import; GitHub sync with AI diff summary |
| 🗂 **SharePoint** | Site/list/page management |
| 🔧 **Azure DevOps** | Pipelines and work items |
| 🚀 **ALM Pipelines** | Promote Dev → Test → Prod |
| 🔌 **MCP Servers** | See and refresh AI tool connections |
| 📤 **Deploy** | Cross-environment and cross-tenant deployment |
| 🔍 **Code Review** | Diff + AI review comments |
| 🧪 **ALM Tools** | Canvas AI rename/comment; disposable env creation |
| ⚙️ **Settings** | Configure tokens, URLs, AI provider (no JSON editing) |
| 🤖 **AI Assistant** | Chat with AI using Dataverse/SharePoint/GitHub context |

---

## 📦 Credentials you'll need

The AI agent will ask you for these during setup — you don't need to type any commands, just supply the values when prompted:

| Credential | Where to find it |
|---|---|
| **GitHub Personal Access Token** | github.com → Settings → Developer settings → Fine-grained tokens |
| **Dataverse connection URL** | Power Automate → My connections → Common Data Service → `...` → Details |
| **Azure DevOps org URL** | `https://dev.azure.com/YOUR_ORG` |
| **Copilot Studio MCP URL** *(optional)* | Copilot Studio → Settings → Channels → MCP Client |
| **AI API key** *(optional)* | Azure OpenAI or Anthropic — leave blank to use GitHub Copilot (free) |

> **Security note:** Credentials are stored only in `~/.copilot/pp-dashboard-settings.json` and `~/.copilot/mcp-config.json` on your local machine. They are never committed to this repository.

---

## 🏗 Repository structure

```
power-platform-dashboard/
├── SETUP_PROMPT.txt              ← ★ Paste this into any AI to set up everything
├── AGENT_SKILL.md                ← Step-by-step instructions the AI follows
├── Launch-Dashboard.ps1          ← Double-click to start (no terminal needed)
├── README.md
├── .gitignore
├── scripts/
│   ├── PowerPlatformDashboard.ps1   ← Main WinForms app (~2500 lines)
│   ├── Install-PPDashboard.ps1      ← Full toolchain installer
│   └── mcp-config-template.json    ← MCP server config template
└── alm/
    ├── .github/                     ← GitHub Actions pipeline templates
    ├── pipelines/                   ← Azure DevOps pipeline templates
    ├── config/                      ← Environment configuration
    └── src/                         ← ALM source files
```

---

## 📦 Credentials the AI will ask you for

Your AI agent will pause and ask you for these during setup. You just paste or type the values — no commands needed:

| Credential | Where to find it |
|---|---|
| **GitHub Personal Access Token** | github.com → Settings → Developer settings → Fine-grained tokens → New token (scopes: Contents, Pull requests, Issues, Workflows) |
| **Dataverse connection URL** | Power Automate → My connections → Common Data Service → `···` → Details (copy the full URL with `?apiName=...`) |
| **Azure DevOps org URL** | `https://dev.azure.com/YOUR_ORG_NAME` |
| **Copilot Studio MCP URL** *(optional)* | Copilot Studio → Settings → Channels → MCP Client |
| **AI API key** *(optional)* | Azure OpenAI or Anthropic — skip this to use GitHub Copilot for free |

> Credentials are stored only in `~/.copilot/` on your local machine. They are **never** committed to this repo.

---

## 🤝 Sharing with your team

Send a colleague:
1. The repo link: **https://github.com/KayodeAjayi200/power-platform-dashboard**
2. The message: *"Clone it, then paste `SETUP_PROMPT.txt` into your AI agent"*

That's the entire handoff. Their AI handles the rest.

---

## 🔧 Developer / manual install

```powershell
git clone https://github.com/KayodeAjayi200/power-platform-dashboard.git "C:\Repositories\Powerapps Stuff"
cd "C:\Repositories\Powerapps Stuff"
pwsh -ExecutionPolicy Bypass -File scripts\Install-PPDashboard.ps1
.\Launch-Dashboard.ps1
```

---

## License

MIT — free to use, modify, and share.
