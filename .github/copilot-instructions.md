# GitHub Copilot Instructions — Power Platform Dashboard

This repository contains the **Power Platform Dashboard** — a WinForms PowerShell GUI that lets non-developers manage Power Platform solutions, GitHub sync, ALM pipelines, disposable environments, and canvas app AI tools.

---

## Repository layout

| Path | What it is |
|---|---|
| `scripts/PowerPlatformDashboard.ps1` | Main dashboard (~2800 lines, 11 WinForms tabs) |
| `Launch-Dashboard.bat` | Double-click to open the dashboard (no terminal needed) |
| `Create-Shortcut.ps1` | Run once to create a pinnable Desktop shortcut |
| `Launch-Dashboard.ps1` | PowerShell launcher (right-click → Run with PowerShell) |
| `AGENT_SKILL.md` | Full setup guide for AI agents — read this to onboard a new machine |
| `SETUP_PROMPT.txt` | One-paste onboarding text for users to give to their AI |
| `TOOLS-SETUP.md` | Manual setup reference for humans |
| `skills/` | Detailed agent skill reference files (see below) |
| `alm/.github/workflows/` | GitHub Actions workflows for ALM export/deploy |
| `.mcp.json` | MCP server configuration for this repo |

---

## Agent Skills — always read before working on related topics

These files are your reference when the user asks about the corresponding area.
Read the relevant skill file before writing any code or formulas.

| Skill file | When to read it |
|---|---|
| [`AGENT_SKILL.md`](../AGENT_SKILL.md) | Setting up tools, installing MCP servers, onboarding a new machine, configuring the dashboard |
| [`skills/PowerApps-Canvas-Skill.md`](../skills/PowerApps-Canvas-Skill.md) | Any question about Canvas App controls, Power Fx formulas, components, galleries, forms, collections, AI Builder components |
| [`skills/PowerApps-Canvas-Design-Skill.md`](../skills/PowerApps-Canvas-Design-Skill.md) | Any question about Canvas App UI/UX design — containers, responsive layouts, Fluent UI controls, themes, gallery card designs, filter panels, navigation menus, micro-interactions |

---

## Tech stack

- **Language:** PowerShell 5.1 (WinForms GUI) + Power Fx (canvas apps)
- **UI framework:** `System.Windows.Forms` (.NET 4.x via PowerShell 5.1)
- **CLI tools used:** `pac` (Power Platform CLI), `gh` (GitHub CLI), `git`, `az` (Azure CLI), `m365` (PnP CLI)
- **MCP servers:** Dataverse MCP, Canvas MCP, Canvas Authoring MCP (for AI code gen), Copilot Studio MCP, GitHub MCP, Azure DevOps MCP, Filesystem MCP
- **Color palette:** Power Apps Fluent light theme — keys: `Base`, `Mantle`, `Surface`, `Overlay`, `Text`, `Subtext`, `Blue`, `Green`, `Peach`, `Red`, `Teal`, `Mauve`, `Sky`, `Panel`, `Console`

---

## Key conventions

- **UTF-8 BOM required** — always save PowerShell files with BOM:
  ```powershell
  [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $true))
  ```
- **Comment everything for non-technical readers** — every function, section, and non-obvious line must have a plain-English comment explaining *what* it does and *why*. Assume the reader has never written code. Example:
  ```powershell
  # Ask Power Platform for a list of all environments the user has access to
  $envs = pac env list --output json | ConvertFrom-Json
  ```
- **Canvas app layout** — ALWAYS use Horizontal and Vertical Containers for every screen. Never use absolute X/Y positions. See `skills/PowerApps-Canvas-Design-Skill.md` for the full rule and patterns.
- **Script-scope variables for timers** — WinForms timer variables in click handlers must be stored as `$Script:TimerName` (not local `$timer`) to prevent PowerShell garbage-collecting them
- **No `pac solution list-component`** — that command does not exist. Use export+zip+solution.xml parsing instead
- **Color palette** — `$Script:C` hashtable; valid keys: `Base`, `Mantle`, `Surface`, `Overlay`, `Text`, `Subtext`, `Blue`, `Green`, `Peach`, `Red`, `Teal`, `Mauve`, `Sky`, `Panel`, `Console`; no "Yellow"; `Console` is for text inside the dark output box
- **Form dimensions** — Form: 930×810 (resizable, min 800×650); Tab panel: Location(8,62), Size(910,511), Anchor all 4 sides; OutputBox: y=608, h=165, Anchor Bottom+Left+Right

---

## Dashboard tabs (quick reference)

| Tab | Purpose |
|---|---|
| 🌐 Environments | List/select Power Platform environments |
| 📦 Solutions | List solutions, sync to GitHub (export → unpack → push) |
| 🚀 Deploy | Deploy solutions between environments |
| 🔧 ALM Tools | Disposable environments, ALM pipelines |
| 🎨 Canvas | Canvas app operations via Canvas MCP |
| 🤖 Copilot Studio | Copilot Studio agent operations |
| 📊 Dataverse | Table and data operations via Dataverse MCP |
| 🔗 SharePoint | SharePoint/m365 operations |
| 📋 Power Automate | Flow management |
| ⚙️ Settings | GitHub PAT, Dataverse URL, ADO config, AI provider |
| 📝 Output | Live log of all operations |

---

## Common user requests and how to handle them

| User says | What to do |
|---|---|
| "Sync my solution to GitHub" | Solutions tab → select solution → set repo → Export→Unpack→Push button |
| "Deploy to Test" | Deploy tab → select envs → deploy |
| "Create a test environment" | ALM Tools tab → Disposable Environments |
| "Build a canvas app form" | Read `skills/PowerApps-Canvas-Skill.md` first, then write Power Fx |
| "Design a canvas app screen / layout" | Read `skills/PowerApps-Canvas-Design-Skill.md` first — use containers, never absolute X/Y |
| "Generate a canvas app for me" | Read `skills/PowerApps-Canvas-Skill.md` → install canvas plugin via Step 3b in `AGENT_SKILL.md` → run `/generate-canvas-app` and describe what the user wants |
| "Edit my canvas app" | Read `skills/PowerApps-Canvas-Skill.md` → run `/edit-canvas-app` → describe the change; ensure coauthoring is on in Power Apps Studio |
| "Add a new MCP server" | Update `.mcp.json` + update `AGENT_SKILL.md` Step 4 |
| "Set up on a new machine" | Follow `AGENT_SKILL.md` steps 1–11 in order |

---

## GitHub repo

**URL:** https://github.com/KayodeAjayi200/power-platform-dashboard  
**Default branch:** master  
**Owner:** KayodeAjayi200 (org: Veldarr)
