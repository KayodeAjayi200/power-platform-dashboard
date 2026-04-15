# ⚡ Power Platform Dashboard

> **A complete Power Platform ALM toolkit with a point-and-click GUI — set up entirely by your AI agent. No command line required.**

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-7.4%2B-blue?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green)

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

## 🤖 Setup via your AI agent (recommended — no command line)

**This is the intended setup path.** You give your AI agent the skill file and it installs everything for you.

### GitHub Copilot (in VS Code or copilot.github.com)

1. Open a chat with GitHub Copilot
2. Say:

   > "Read the file at this URL and follow the setup instructions for me:  
   > `https://raw.githubusercontent.com/KayodeAjayi200/power-platform-dashboard/main/AGENT_SKILL.md`"

3. Copilot will download the skill, run the installer, open browser auth prompts, and launch the dashboard.

---

### Claude (claude.ai or Claude Desktop with MCP)

1. Open a new conversation
2. Paste this message:

   > "Please fetch this URL and follow all setup instructions in the file:  
   > `https://raw.githubusercontent.com/KayodeAjayi200/power-platform-dashboard/main/AGENT_SKILL.md`  
   >
   > Run each step using your computer-use / tool-use capability. Ask me before opening any browser for login."

3. Claude will read `AGENT_SKILL.md`, run PowerShell commands via tool use, and walk you through browser-based authentication.

---

### OpenAI Codex / ChatGPT with Code Interpreter

1. Download [`AGENT_SKILL.md`](./AGENT_SKILL.md) from this repo
2. Upload it to a new ChatGPT conversation (paperclip → upload file)
3. Say:

   > "I'm on Windows 11. Read this file and set up everything it describes. Use your code execution tool to run the PowerShell commands. Pause and ask me when you need me to log in via a browser."

---

### Any other AI agent

Just share the raw content of [`AGENT_SKILL.md`](./AGENT_SKILL.md). It is a self-contained, step-by-step instruction set written for AI consumption. Any agent that can run PowerShell commands can complete the setup.

---

## 📋 What the AI will install

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

## 🔧 Manual setup (for developers)

If you prefer to run the installer yourself:

```powershell
# Clone the repo
gh repo clone KayodeAjayi200/power-platform-dashboard "C:\Repositories\Powerapps Stuff"
cd "C:\Repositories\Powerapps Stuff"

# Run the installer (installs all tools, opens browser login prompts)
pwsh -ExecutionPolicy Bypass -File scripts\Install-PPDashboard.ps1

# Launch the dashboard
.\Launch-Dashboard.ps1
```

---

## 🏗 Repository structure

```
power-platform-dashboard/
├── Launch-Dashboard.ps1          ← Double-click to start (no terminal needed)
├── AGENT_SKILL.md                ← Give this to any AI to set up everything
├── README.md
├── .gitignore
├── scripts/
│   ├── PowerPlatformDashboard.ps1   ← Main WinForms app (2500+ lines)
│   ├── Install-PPDashboard.ps1      ← Full toolchain installer
│   └── mcp-config-template.json    ← MCP server configuration template
└── alm/
    ├── .github/                     ← GitHub Actions pipeline templates
    ├── pipelines/                   ← Azure DevOps pipeline templates
    ├── config/                      ← Environment configuration
    └── src/                         ← ALM source files
```

---

## 🤝 Sharing with your team

To give a colleague access:

1. Share the link to this repository
2. Tell them: *"Give the `AGENT_SKILL.md` file to your AI (Copilot, Claude, ChatGPT) and ask it to set everything up"*
3. They'll need to authenticate their own Power Platform, GitHub, and Azure DevOps accounts via browser pop-ups — the AI handles the rest

No one needs to touch the command line.

---

## License

MIT — free to use, modify, and share.
