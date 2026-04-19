---
name: canvas-authoring-mcp
description: Canvas Authoring MCP connection guide — how to point the MCP at the right Power Apps canvas app, extract App ID and Environment ID from the Studio URL, update mcp-config.json, restart the MCP server, and resolve 404 connection errors. Use this skill before any Canvas Authoring MCP tool call.
license: MIT
metadata:
  author: KayodeAjayi200
  version: "1.0.0"
  organization: Veldarr
  date: April 2026
  abstract: Step-by-step guide for AI agents to connect the Canvas Authoring MCP server to the correct Power Apps canvas app. Covers extracting App ID and Environment ID from the Studio URL, reading and updating mcp-config.json, restarting the MCP server, verifying co-authoring is active, and resolving HTTP 404 connection errors across both powerapps-canvas and canvas-authoring MCP entries.
---

# AGENT SKILL: Canvas Authoring MCP — Connecting to the Right App

> **Reference for AI agents working with the Canvas Authoring MCP server.**
> Read this skill whenever a user asks you to edit, fix, or build controls in a Canvas App
> via the Canvas Authoring MCP, or whenever you get a 404 / connection error from the MCP.

---

## What is the Canvas Authoring MCP?

The Canvas Authoring MCP server lets an AI agent read and write a live Canvas App that is
open in Power Apps Studio — without the user having to manually edit YAML files.

It connects to Power Apps Studio's **co-authoring** session. That session is tied to a
specific App ID **and** a specific Environment ID. If either of those IDs is wrong in the
MCP config, every call returns HTTP 404 and nothing works.

---

## The #1 rule — always verify the App ID and Environment ID before touching the MCP

**Before calling any canvas authoring tool, always check that the configured App ID and
Environment ID match the app the user wants to edit.**

The user may have multiple apps across multiple environments. The MCP config file holds
only ONE app ID at a time. If the user has worked on different apps in different sessions,
the config is almost certainly pointing at the wrong app.

---

## Step 1 — Get the correct App ID and Environment ID

There are two ways the user can give you the IDs:

### Option A — from the Power Apps Studio URL (most reliable)

Ask the user to copy the URL from their browser while the app is open in Studio.
The URL looks like this:

```
https://make.powerapps.com/e/{ENVIRONMENT_ID}/canvas/?action=edit&app-id=%2Fproviders%2FMicrosoft.PowerApps%2Fapps%2F{APP_ID}&solution-id=...
```

Parse it like this:

- **Environment ID** — the GUID immediately after `/e/` in the URL
  Example: `https://make.powerapps.com/e/25146b4f-3532-efb4-8ce7-a181452f88ae/canvas/...`
  → Environment ID = `25146b4f-3532-efb4-8ce7-a181452f88ae`

- **App ID** — the GUID at the very end of `app-id=%2Fproviders%2FMicrosoft.PowerApps%2Fapps%2F`
  Example: `app-id=%2Fproviders%2FMicrosoft.PowerApps%2Fapps%2F58aa6a76-ecd1-4560-a451-b99c6582e783`
  → App ID = `58aa6a76-ecd1-4560-a451-b99c6582e783`

> `%2F` is just URL-encoding for `/`. Strip it — the App ID is always the last GUID.

### Option B — from the PAC CLI

If the user knows the app name, you can look up the App ID programmatically:

```powershell
# List all canvas apps in the current environment and find the one by name.
# Replace "My App Name" with the actual app name.
pac canvas list | Select-String "My App Name"
```

The output includes the App ID (a GUID) in the second column.

To get the current environment ID:
```powershell
# The selected environment shows a ">" marker in the first column.
pac env list
```

---

## Step 2 — Check what is currently configured

Run this to see what App ID and Environment ID the MCP is currently using:

```powershell
$config = Get-Content "$env:USERPROFILE\.copilot\mcp-config.json" -Raw | ConvertFrom-Json

Write-Host "powerapps-canvas MCP:"
Write-Host "  App ID:  $($config.mcpServers.'powerapps-canvas'.env.CANVAS_APP_ID)"
Write-Host "  Env ID:  $($config.mcpServers.'powerapps-canvas'.env.CANVAS_ENVIRONMENT_ID)"

Write-Host "`ncanvas-authoring MCP:"
Write-Host "  App ID:  $($config.mcpServers.'canvas-authoring'.env.CANVAS_APP_ID)"
Write-Host "  Env ID:  $($config.mcpServers.'canvas-authoring'.env.CANVAS_ENVIRONMENT_ID)"
```

Compare the output to the IDs you got from the Studio URL.
If either is different — update the config (Step 3).

---

## Step 3 — Update the config to point at the right app

Run this, replacing the two ID values with the correct ones from Step 1:

```powershell
$mcpPath = "$env:USERPROFILE\.copilot\mcp-config.json"
$config  = Get-Content $mcpPath -Raw | ConvertFrom-Json

# ✏️  Replace these two values with what you got from the Studio URL:
$newAppId = "PASTE-APP-ID-HERE"
$newEnvId = "PASTE-ENVIRONMENT-ID-HERE"

# Update both MCP server entries — they must always match each other
$config.mcpServers.'powerapps-canvas'.env.CANVAS_APP_ID         = $newAppId
$config.mcpServers.'powerapps-canvas'.env.CANVAS_ENVIRONMENT_ID = $newEnvId
$config.mcpServers.'canvas-authoring'.env.CANVAS_APP_ID         = $newAppId
$config.mcpServers.'canvas-authoring'.env.CANVAS_ENVIRONMENT_ID = $newEnvId

# Save — UTF8 without BOM is fine for JSON
$config | ConvertTo-Json -Depth 10 | Set-Content $mcpPath -Encoding UTF8
Write-Host "✅  Config updated — App: $newAppId | Env: $newEnvId"
```

---

## Step 4 — Restart the MCP server

The MCP server reads its config at startup. You must restart it after any config change.

Tell the user to do one of the following:

**Option A — Restart Copilot CLI completely**
1. Close the Copilot CLI window
2. Reopen it from the Desktop shortcut or Start menu
3. Come back to the same session

**Option B — Reload individual MCP servers (faster)**
1. Click the MCP plug icon (🔌) in the Copilot sidebar
2. Find `powerapps-canvas` and `canvas-authoring` in the list
3. Click the restart/reload button (↺) next to each one

---

## Step 5 — Verify the Studio session is ready

Before trying to sync, confirm the user has done all of this in Power Apps Studio:

| Requirement | How to check |
|---|---|
| App is open in Studio | User should have the Studio browser tab open |
| Co-authoring is ON | Settings → Updates → Co-authoring → toggle is blue |
| App has not timed out | If Studio was idle for 30+ minutes, refresh the page and re-enable co-authoring |
| Correct app is open | The app name in the Studio header must match the one you looked up in Step 1 |

> ⚠️ Co-authoring must be **ON** before you restart the MCP server. If you turn it on
> after restarting, restart the MCP server again.

---

## Step 6 — Test the connection

After restarting, try to sync the canvas. This call reads the live YAML from Studio:

```
canvas-authoring-sync_canvas  directoryPath: "C:\path\to\working\directory"
```

**If it succeeds:** you get YAML files in the target directory. You are connected.

**If it returns 404:** go through the checklist below.

---

## Troubleshooting — 404 / connection errors

Work through this list in order. Most issues are caused by a mismatch at one of these steps.

| Symptom | Most likely cause | Fix |
|---|---|---|
| HTTP 404 on every MCP call | App ID or Env ID is wrong | Re-check Step 1 — confirm against Studio URL |
| 404 even after updating config | MCP server not restarted yet | Restart the MCP server (Step 4) |
| 404 after restart | Co-authoring is OFF | Enable co-authoring in Studio, then restart MCP again |
| 404 after enabling co-authoring | Studio session timed out | Refresh the Studio page, re-enable co-authoring, restart MCP |
| `dnx` not found error | .NET 10 SDK not installed | Run `dotnet --version` — must be 10.0+; install via `AGENT_SKILL.md` Step 1 |
| Config file not found | Copilot CLI not initialised | Run Copilot CLI at least once to create `~\.copilot\mcp-config.json` |
| Changes not appearing in Studio | Sync ran before co-authoring was on | Turn co-authoring on, then re-sync |
| Two different apps need editing | Config holds only ONE app at a time | Update config to the target app each time; restart MCP between switches |

---

## How the two MCP entries relate to each other

The MCP config has two canvas-related server entries. They serve the same purpose from
different access paths. **Both must always have the same App ID and Environment ID.**

| Entry key | Command used | Accessed via |
|---|---|---|
| `powerapps-canvas` | `CanvasAuthoringMcpServer` | `powerapps-canvas-*` tools |
| `canvas-authoring` | `dnx Microsoft.PowerApps.CanvasAuthoring.McpServer` | `canvas-authoring-*` tools |

If one is updated without the other, half your tool calls will connect and half will 404.
The update script in Step 3 always updates both — always use it.

---

## Quick-reference: tools available once connected

| Tool | What it does |
|---|---|
| `canvas-authoring-sync_canvas` | Pull live YAML from Studio into a local directory |
| `canvas-authoring-compile_canvas` | Validate YAML for errors without pushing |
| `canvas-authoring-list_controls` | List every control on every screen |
| `canvas-authoring-describe_control` | Get the properties and schema for a specific control type |
| `canvas-authoring-list_data_sources` | List data sources connected to the app |
| `canvas-authoring-get_data_source_schema` | Get column types for a data source |
| `canvas-authoring-list_apis` | List available connectors |

After syncing, edit the YAML files locally and push changes back to Studio by syncing again
(the MCP server auto-merges edits made on both sides during a co-authoring session).

---

## Workflow summary — every time you need to edit a canvas app

```
1. Ask user for Studio URL  →  extract App ID + Env ID
2. Check mcp-config.json   →  compare IDs
3. If different:  update config (Step 3 script)  →  restart MCP (Step 4)
4. Confirm Studio has co-authoring ON and the correct app is open
5. Run canvas-authoring-sync_canvas  →  confirm you get YAML files back
6. Read / edit YAML  →  sync again to push changes to Studio
```

---

## Real-world debugging log — what went wrong and how it was fixed

> This section records the actual problems encountered when building and using this skill.
> It is here so future agents don't repeat the same mistakes.

---

### Problem 1 — Canvas MCP returned HTTP 404 on every call

**What happened:**
The first attempt to run `canvas-authoring-sync_canvas` returned HTTP 404. The tool appeared to connect but immediately failed.

**Root cause:**
`mcp-config.json` contained placeholder App ID and Environment ID values from a previous session — they belonged to a completely different app. The MCP server validates these IDs against the active Studio co-authoring session and rejects any mismatch with a 404.

The config had:
```
CANVAS_APP_ID:         "25be9404-7270-405a-90df-659d500dd1ad"   ← wrong app
CANVAS_ENVIRONMENT_ID: "ef77d261-f915-e0fb-95f4-1cbc09edb6ab"  ← wrong environment
```

The user's actual app (visible in the Studio URL) was:
```
CANVAS_APP_ID:         "58aa6a76-ecd1-4560-a451-b99c6582e783"
CANVAS_ENVIRONMENT_ID: "25146b4f-3532-efb4-8ce7-a181452f88ae"
```

**Fix:**
1. Asked the user for the full Power Apps Studio URL from their browser
2. Parsed App ID and Environment ID directly from the URL (see Step 1 of this skill)
3. Updated both `powerapps-canvas` and `canvas-authoring` entries in `mcp-config.json`
4. Told the user to restart Copilot CLI

**Lesson learned:**
Never assume the config is correct. Always check it against the Studio URL at the start of every canvas session. If the user has worked on multiple apps across sessions, the config is almost certainly stale.

---

*This skill is part of the [Power Platform Dashboard](https://github.com/KayodeAjayi200/power-platform-dashboard) project.*
