<#
.SYNOPSIS
    Power Platform Dashboard — GUI for managing Power Platform, SharePoint & Azure DevOps
    without typing long commands.

.DESCRIPTION
    A Windows Forms dashboard that wraps PAC CLI, m365 CLI, Azure CLI, and all registered
    MCP servers into a clickable UI. Every action is logged to dashboard-log.json so
    Copilot can see what you've been doing.

.EXAMPLE
    .\PowerPlatformDashboard.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Config ────────────────────────────────────────────────────────────────────
$Script:LogPath        = Join-Path $PSScriptRoot "dashboard-log.json"
$Script:McpConfigPath  = Join-Path $env:USERPROFILE ".copilot\mcp-config.json"
$Script:Environments   = @()
$Script:Solutions      = @()
$Script:LogEntries     = @()
$Script:AiHistory      = [System.Collections.ArrayList]::new()
$Script:AiSettingsPath = Join-Path $env:USERPROFILE ".copilot\pp-dashboard-settings.json"
$Script:DisposableEnvs = [System.Collections.ArrayList]::new()
# Thread-safe queue — runspaces write here, UI timer drains it to OutputBox
$Script:LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

# ── Colour palette (Catppuccin Mocha) ─────────────────────────────────────────
function RGB([int]$r,[int]$g,[int]$b) { [System.Drawing.Color]::FromArgb($r,$g,$b) }
$C = @{
    Base    = (RGB 30 30 46)
    Mantle  = (RGB 24 24 37)
    Surface = (RGB 49 50 68)
    Overlay = (RGB 88 91 112)
    Text    = (RGB 202 211 245)
    Subtext = (RGB 166 173 200)
    Blue    = (RGB 137 180 250)
    Green   = (RGB 166 227 161)
    Peach   = (RGB 250 179 135)
    Red     = (RGB 243 139 168)
    Teal    = (RGB 148 226 213)
    Mauve   = (RGB 203 166 247)
    Sky     = (RGB 137 220 235)
    Panel   = (RGB 36 39 58)
}
$Script:C = $C   # make palette available inside all timer/event closures

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Action, [string]$Result, [string]$Category = "General")
    $entry = [ordered]@{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        category  = $Category
        action    = $Action
        result    = ($Result | Out-String).Trim()
    }
    $Script:LogEntries += $entry
    try { $Script:LogEntries | ConvertTo-Json -Depth 5 | Set-Content $Script:LogPath -Encoding UTF8 }
    catch {}
}

function Run-Cmd {
    param([string]$Label, [scriptblock]$Block, [string]$Cat = "General")
    $Script:OutputBox.SelectionColor = $C.Sky
    $Script:OutputBox.AppendText("`r`n▶ $Label`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
    try {
        $out = & $Block 2>&1 | Out-String
        $Script:OutputBox.AppendText($out.TrimEnd() + "`r`n")
        Write-Log -Action $Label -Result $out -Category $Cat
    } catch {
        $Script:OutputBox.SelectionColor = $C.Red
        $Script:OutputBox.AppendText("ERROR: $($_.Exception.Message)`r`n")
        $Script:OutputBox.SelectionColor = $C.Text
    }
    $Script:OutputBox.ScrollToCaret()
}

function New-Btn {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=160, [int]$H=30,
          [System.Drawing.Color]$Bg = $C.Blue)
    $b = New-Object System.Windows.Forms.Button
    $b.Text       = $Text
    $b.Location   = [System.Drawing.Point]::new($X, $Y)
    $b.Size       = [System.Drawing.Size]::new($W, $H)
    $b.FlatStyle  = [System.Windows.Forms.FlatStyle]::Flat
    $b.BackColor  = $Bg
    $b.ForeColor  = $C.Mantle
    $b.Font       = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $b.FlatAppearance.BorderSize = 0
    $b.Cursor     = [System.Windows.Forms.Cursors]::Hand
    return $b
}

function New-Lbl {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=400, [int]$H=20,
          [System.Drawing.Color]$Fg = $C.Subtext)
    $l = New-Object System.Windows.Forms.Label
    $l.Text      = $Text
    $l.Location  = [System.Drawing.Point]::new($X, $Y)
    $l.Size      = [System.Drawing.Size]::new($W, $H)
    $l.ForeColor = $Fg
    return $l
}

function New-Txt {
    param([string]$Default="", [int]$X=0, [int]$Y=0, [int]$W=250)
    $t = New-Object System.Windows.Forms.TextBox
    $t.Text        = $Default
    $t.Location    = [System.Drawing.Point]::new($X, $Y)
    $t.Size        = [System.Drawing.Size]::new($W, 24)
    $t.BackColor   = $C.Surface
    $t.ForeColor   = $C.Text
    $t.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    return $t
}

function New-Combo {
    param([string[]]$Items, [int]$X, [int]$Y, [int]$W=200)
    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.Location      = [System.Drawing.Point]::new($X, $Y)
    $combo.Size          = [System.Drawing.Size]::new($W, 24)
    $combo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $combo.BackColor     = $C.Surface
    $combo.ForeColor     = $C.Text
    $combo.FlatStyle     = [System.Windows.Forms.FlatStyle]::Flat
    if ($Items) { $combo.Items.AddRange($Items) }
    return $combo
}

function Invoke-AiRequest {
    param([string]$Prompt)
    if (-not (Test-Path $Script:AiSettingsPath)) {
        [System.Windows.Forms.Clipboard]::SetText($Prompt)
        return "(No AI configured — prompt copied to clipboard)"
    }
    $cfg = Get-Content $Script:AiSettingsPath -Raw | ConvertFrom-Json
    $provider = if ($cfg.ai) { $cfg.ai.provider } else { "clipboard" }
    if ($provider -eq "clipboard" -or -not $cfg.ai.key) {
        [System.Windows.Forms.Clipboard]::SetText($Prompt)
        return "(Prompt copied to clipboard — paste into your AI chat)"
    }
    try {
        if ($provider -eq "azure") {
            $uri  = "$($cfg.ai.endpoint.TrimEnd('/'))/openai/deployments/$($cfg.ai.model)/chat/completions?api-version=2024-08-01-preview"
            $body = @{ messages = @(@{role="user";content=$Prompt}); max_tokens=1200 } | ConvertTo-Json -Depth 5
            $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers @{"api-key"=$cfg.ai.key;"Content-Type"="application/json"} -Body $body
            return $resp.choices[0].message.content
        } elseif ($provider -eq "claude") {
            $body = @{ model=$cfg.ai.model; max_tokens=1200; messages=@(@{role="user";content=$Prompt}) } | ConvertTo-Json -Depth 5
            $resp = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post `
                -Headers @{"x-api-key"=$cfg.ai.key;"anthropic-version"="2023-06-01";"Content-Type"="application/json"} `
                -Body $body
            return $resp.content[0].text
        }
    } catch { return "❌ AI error: $($_.Exception.Message)" }
    return "(Unknown AI provider)"
}

function Divider {
    param([string]$Label, [int]$X, [int]$Y, [int]$W=830, [System.Windows.Forms.Control]$Parent)
    $l = New-Lbl "── $Label $('─' * [Math]::Max(1, [int](($W - ($Label.Length * 8)) / 8)))" $X $Y $W 18 $C.Overlay
    $Parent.Controls.Add($l)
}

# ── FORM ──────────────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text            = "⚡ Power Platform Dashboard"
$form.Size            = [System.Drawing.Size]::new(930, 750)
$form.MinimumSize     = [System.Drawing.Size]::new(930, 750)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $C.Base
$form.ForeColor       = $C.Text
$form.Font            = [System.Drawing.Font]::new("Segoe UI", 9)
$form.Icon            = [System.Drawing.SystemIcons]::Application

# Title strip
$titleStrip = New-Object System.Windows.Forms.Panel
$titleStrip.Size      = [System.Drawing.Size]::new(930, 50)
$titleStrip.Location  = [System.Drawing.Point]::new(0, 0)
$titleStrip.BackColor = $C.Panel
$form.Controls.Add($titleStrip)

$titleLbl = New-Lbl "  ⚡ PP Dashboard" 0 12 200 26 $C.Blue
$titleLbl.Font = [System.Drawing.Font]::new("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$titleStrip.Controls.Add($titleLbl)

$titleStrip.Controls.Add((New-Lbl "Env:" 205 15 36 18 $C.Subtext))
$cboTopEnv               = New-Object System.Windows.Forms.ComboBox
$cboTopEnv.Location      = [System.Drawing.Point]::new(240, 11)
$cboTopEnv.Size          = [System.Drawing.Size]::new(360, 28)
$cboTopEnv.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cboTopEnv.BackColor     = $C.Surface
$cboTopEnv.ForeColor     = $C.Text
$cboTopEnv.FlatStyle     = [System.Windows.Forms.FlatStyle]::Flat
$titleStrip.Controls.Add($cboTopEnv)
$btnTopSwitch            = New-Object System.Windows.Forms.Button
$btnTopSwitch.Text       = "⚡ Switch"
$btnTopSwitch.Location   = [System.Drawing.Point]::new(608, 11)
$btnTopSwitch.Size       = [System.Drawing.Size]::new(88, 28)
$btnTopSwitch.BackColor  = $C.Green
$btnTopSwitch.ForeColor  = $C.Base
$btnTopSwitch.FlatStyle  = [System.Windows.Forms.FlatStyle]::Flat
$btnTopSwitch.Font       = [System.Drawing.Font]::new("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$titleStrip.Controls.Add($btnTopSwitch)
$envStatusLbl = New-Lbl "" 702 15 218 20 $C.Subtext
$envStatusLbl.TextAlign = "MiddleRight"
$titleStrip.Controls.Add($envStatusLbl)

# ── TABS ──────────────────────────────────────────────────────────────────────
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = [System.Drawing.Point]::new(8, 58)
$tabs.Size     = [System.Drawing.Size]::new(910, 440)
$tabs.Font     = [System.Drawing.Font]::new("Segoe UI", 9)
$form.Controls.Add($tabs)

function New-Tab([string]$Name) {
    $t = New-Object System.Windows.Forms.TabPage
    $t.Text      = $Name
    $t.BackColor = $C.Panel
    $t.ForeColor = $C.Text
    $t.Padding   = [System.Windows.Forms.Padding]::new(8)
    return $t
}

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 1 — ENVIRONMENTS
# ═══════════════════════════════════════════════════════════════════════════════
$tabEnv = New-Tab "🌍  Environments"
$tabs.TabPages.Add($tabEnv)

$tabEnv.Controls.Add((New-Lbl "Active Environment:" 8 12 160 20 $C.Subtext))
$cboEnv = New-Combo @() 8 34 520
$tabEnv.Controls.Add($cboEnv)

$btnRefreshEnvs = New-Btn "🔄 Refresh" 540 34 110 26
$tabEnv.Controls.Add($btnRefreshEnvs)

$btnSwitchEnv = New-Btn "⚡ Switch" 660 34 120 26 $C.Green
$tabEnv.Controls.Add($btnSwitchEnv)

$btnOpenPPAC = New-Btn "🌐 Admin Centre" 790 34 110 26 $C.Teal
$tabEnv.Controls.Add($btnOpenPPAC)

$lblEnvUrl = New-Lbl "Select an environment above" 8 68 820 20 $C.Sky
$tabEnv.Controls.Add($lblEnvUrl)

Divider "Quick Actions" 8 96 830 $tabEnv
$btnListEnvs    = New-Btn "📋 List Envs"     8  122 140
$btnAuthStatus  = New-Btn "🔑 Auth Status"   158 122 140
$btnLogin       = New-Btn "🔐 PAC Login"     308 122 140 30 $C.Peach
$btnOpenPAPortal= New-Btn "🌐 Power Apps"    458 122 140
$btnOpenPAAdmin = New-Btn "⚙ PAC Auth Mgr"  608 122 155
$tabEnv.Controls.Add($btnListEnvs)
$tabEnv.Controls.Add($btnAuthStatus)
$tabEnv.Controls.Add($btnLogin)
$tabEnv.Controls.Add($btnOpenPAPortal)
$tabEnv.Controls.Add($btnOpenPAAdmin)

Divider "Environment Info" 8 162 830 $tabEnv
$btnWhoAmI    = New-Btn "👤 Who Am I"       8  188 140
$btnListUsers = New-Btn "👥 List Users"     158 188 140
$btnListRoles = New-Btn "🛡 List Roles"     308 188 140
$tabEnv.Controls.Add($btnWhoAmI)
$tabEnv.Controls.Add($btnListUsers)
$tabEnv.Controls.Add($btnListRoles)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 2 — SOLUTIONS & APPS
# ═══════════════════════════════════════════════════════════════════════════════
$tabSol = New-Tab "📦  Solutions"
$tabs.TabPages.Add($tabSol)

Divider "Solutions" 8 8 830 $tabSol
$btnExportSol = New-Btn "⬇ Export"          8   34 120 30 $C.Green
$btnImportSol = New-Btn "⬆ Import .zip"     138 34 130 30 $C.Peach
$tabSol.Controls.Add($btnExportSol)
$tabSol.Controls.Add($btnImportSol)

# Solutions dropdown — populated when List Solutions is clicked
$tabSol.Controls.Add((New-Lbl "Solutions:" 8 72 80 20 $C.Subtext))
$Script:cboSolutions = New-Combo @() 90 69 460
$Script:cboSolutions.Add_SelectedIndexChanged({
    if ($Script:cboSolutions.SelectedIndex -ge 0 -and $Script:Solutions) {
        $sol = $Script:Solutions[$Script:cboSolutions.SelectedIndex]
        $txtSolName.Text = $sol.UniqueName
        $Script:AllComponents.Clear(); $Script:DgComponents.Rows.Clear()
        $Script:OutputBox.SelectionColor = $Script:C.Sky
        $Script:OutputBox.AppendText("💡 Selected: '$($sol.FriendlyName)' [$($sol.UniqueName)] — click 📋 Load Components to inspect`r`n")
        $Script:OutputBox.SelectionColor = $Script:C.Text
    }
})
$tabSol.Controls.Add($Script:cboSolutions)

$tabSol.Controls.Add((New-Lbl "Solution Name (unique):" 8 102 160))
$txtSolName = New-Txt "" 170 99 250
$tabSol.Controls.Add($txtSolName)

$tabSol.Controls.Add((New-Lbl "Export Path:" 8 130 120))
$txtExportPath = New-Txt "$env:USERPROFILE\Desktop" 130 127 280
$tabSol.Controls.Add($txtExportPath)
$btnBrowse = New-Btn "📁" 418 127 40 24
$tabSol.Controls.Add($btnBrowse)

Divider "📋 Solution Components" 8 163 830 $tabSol
$btnLoadComponents = New-Btn "📋 Load Components" 8 186 170 26 $C.Teal
$tabSol.Controls.Add($btnLoadComponents)
$tabSol.Controls.Add((New-Lbl "Filter:" 188 191 42 18 $C.Subtext))
$txtCompFilter = New-Txt "" 230 188 170
$tabSol.Controls.Add($txtCompFilter)
$tabSol.Controls.Add((New-Lbl "Type:" 408 191 42 18 $C.Subtext))
$cboCompType = New-Combo @("All Types","Canvas App","Cloud Flow","Table","Column","View","Web Resource","Plugin","Model-driven App","Copilot","Environment Variable","Other") 450 188 160
$tabSol.Controls.Add($cboCompType)
$btnOpenInPortal = New-Btn "🌐 Open in Portal" 622 186 165 26 $C.Blue
$tabSol.Controls.Add($btnOpenInPortal)

$Script:DgComponents = New-Object System.Windows.Forms.DataGridView
$Script:DgComponents.Location  = [System.Drawing.Point]::new(8, 218)
$Script:DgComponents.Size      = [System.Drawing.Size]::new(888, 70)
$Script:DgComponents.BackgroundColor = $C.Surface
$Script:DgComponents.ForeColor       = $C.Text
$Script:DgComponents.GridColor       = $C.Overlay
$Script:DgComponents.BorderStyle     = [System.Windows.Forms.BorderStyle]::None
$Script:DgComponents.ColumnHeadersDefaultCellStyle.BackColor = $C.Panel
$Script:DgComponents.ColumnHeadersDefaultCellStyle.ForeColor = $C.Text
$Script:DgComponents.ColumnHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::None
$Script:DgComponents.DefaultCellStyle.BackColor            = $C.Surface
$Script:DgComponents.DefaultCellStyle.ForeColor            = $C.Text
$Script:DgComponents.AlternatingRowsDefaultCellStyle.BackColor = $C.Base
$Script:DgComponents.SelectionMode       = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$Script:DgComponents.ReadOnly            = $true
$Script:DgComponents.AllowUserToAddRows  = $false
$Script:DgComponents.RowHeadersVisible   = $false
$Script:DgComponents.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$Script:DgComponents.Font                = [System.Drawing.Font]::new("Segoe UI", 8.5)
$c1 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $c1.Name="Type";        $c1.HeaderText="Type";         $c1.FillWeight=18
$c2 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $c2.Name="DisplayName"; $c2.HeaderText="Display Name"; $c2.FillWeight=40
$c3 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $c3.Name="UniqueName";  $c3.HeaderText="Unique Name";  $c3.FillWeight=36
$c4 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $c4.Name="Root";        $c4.HeaderText="Root";         $c4.FillWeight=6
$null = $Script:DgComponents.Columns.AddRange($c1, $c2, $c3, $c4)
$tabSol.Controls.Add($Script:DgComponents)
$Script:AllComponents = [System.Collections.Generic.List[PSCustomObject]]::new()


Divider "🐙 GitHub Explorer" 8 293 880 $tabSol
$tabSol.Controls.Add((New-Lbl "Repo:" 8 317 42 18 $C.Subtext))
$Script:cboGHRepo   = New-Combo @() 52 314 268
$tabSol.Controls.Add($Script:cboGHRepo)
$tabSol.Controls.Add((New-Lbl "Branch:" 328 317 52 18 $C.Subtext))
$Script:cboGHBranch = New-Combo @("main","master") 382 314 120
$tabSol.Controls.Add($Script:cboGHBranch)
$btnGHRefresh = New-Btn "🔄 Refresh"   510 314 100 26 $C.Teal
$btnGHOpen    = New-Btn "🌐 Open"      618 314 80  26 $C.Blue
$btnGHNewRepo = New-Btn "➕ New Repo"  706 314 106 26 $C.Green
$tabSol.Controls.Add($btnGHRefresh); $tabSol.Controls.Add($btnGHOpen); $tabSol.Controls.Add($btnGHNewRepo)

$Script:DgGHCommits = New-Object System.Windows.Forms.DataGridView
$Script:DgGHCommits.Location  = [System.Drawing.Point]::new(8, 346)
$Script:DgGHCommits.Size      = [System.Drawing.Size]::new(888, 62)
$Script:DgGHCommits.BackgroundColor = $C.Surface
$Script:DgGHCommits.ForeColor       = $C.Text
$Script:DgGHCommits.GridColor       = $C.Overlay
$Script:DgGHCommits.BorderStyle     = [System.Windows.Forms.BorderStyle]::None
$Script:DgGHCommits.ColumnHeadersDefaultCellStyle.BackColor = $C.Panel
$Script:DgGHCommits.ColumnHeadersDefaultCellStyle.ForeColor = $C.Text
$Script:DgGHCommits.ColumnHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::None
$Script:DgGHCommits.DefaultCellStyle.BackColor            = $C.Surface
$Script:DgGHCommits.DefaultCellStyle.ForeColor            = $C.Text
$Script:DgGHCommits.AlternatingRowsDefaultCellStyle.BackColor = $C.Base
$Script:DgGHCommits.SelectionMode       = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$Script:DgGHCommits.ReadOnly            = $true
$Script:DgGHCommits.AllowUserToAddRows  = $false
$Script:DgGHCommits.RowHeadersVisible   = $false
$Script:DgGHCommits.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$Script:DgGHCommits.Font                = [System.Drawing.Font]::new("Segoe UI", 8.5)
$gc1 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $gc1.Name="When";    $gc1.HeaderText="When";    $gc1.FillWeight=14
$gc2 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $gc2.Name="Author";  $gc2.HeaderText="Author";  $gc2.FillWeight=16
$gc3 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $gc3.Name="Message"; $gc3.HeaderText="Commit Message"; $gc3.FillWeight=60
$gc4 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn; $gc4.Name="SHA";     $gc4.HeaderText="SHA";     $gc4.FillWeight=10
$null = $Script:DgGHCommits.Columns.AddRange($gc1,$gc2,$gc3,$gc4)
$tabSol.Controls.Add($Script:DgGHCommits)

$tabSol.Controls.Add((New-Lbl "Ask AI:" 8 416 54 18 $C.Subtext))
$txtGHAiCmd = New-Txt "Summarise recent changes to this solution in plain English" 62 413 644
$tabSol.Controls.Add($txtGHAiCmd)
$btnGHAskAi = New-Btn "🤖 Ask AI" 710 413 104 26 $C.Mauve
$tabSol.Controls.Add($btnGHAskAi)

$btnSolSyncGH            = New-Object System.Windows.Forms.Button
$btnSolSyncGH.Text       = "📤  Export from Environment → Unpack → Push to GitHub  (no local folder needed)"
$btnSolSyncGH.Location   = [System.Drawing.Point]::new(8, 445)
$btnSolSyncGH.Size       = [System.Drawing.Size]::new(888, 36)
$btnSolSyncGH.BackColor  = $C.Mauve
$btnSolSyncGH.ForeColor  = $C.Base
$btnSolSyncGH.FlatStyle  = [System.Windows.Forms.FlatStyle]::Flat
$btnSolSyncGH.Font       = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabSol.Controls.Add($btnSolSyncGH)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 3 — SHAREPOINT
# ═══════════════════════════════════════════════════════════════════════════════
$tabSP = New-Tab "🟠  SharePoint"
$tabs.TabPages.Add($tabSP)

# Row 1 — current Site URL (auto-filled from checklist, or type manually)
$tabSP.Controls.Add((New-Lbl "Site URL:" 8 12 70))
$txtSiteUrl = New-Txt "https://veldarr.sharepoint.com" 82 9 490
$tabSP.Controls.Add($txtSiteUrl)
$btnSPConnect = New-Btn "🔐 Connect" 582 9 120 26 $C.Peach
$tabSP.Controls.Add($btnSPConnect)

Divider "Sites — select one or check multiple" 8 40 830 $tabSP

# Action buttons above the checklist
$btnSPLoadSites   = New-Btn "🔄 Load Sites"      8  64 130
$btnSPSiteInfo    = New-Btn "ℹ Info (selected)"  148 64 150
$btnSPOpenChecked = New-Btn "🌐 Open Checked"    308 64 150 30 $C.Green
$tabSP.Controls.Add($btnSPLoadSites)
$tabSP.Controls.Add($btnSPSiteInfo)
$tabSP.Controls.Add($btnSPOpenChecked)

# CheckedListBox — populated by Load Sites; single-click → fills txtSiteUrl; check multiple for bulk open
$Script:SPSites = @()
$Script:clbSites = New-Object System.Windows.Forms.CheckedListBox
$Script:clbSites.Location  = [System.Drawing.Point]::new(8, 98)
$Script:clbSites.Size      = [System.Drawing.Size]::new(830, 130)
$Script:clbSites.BackColor = $C.Surface
$Script:clbSites.ForeColor = $C.Text
$Script:clbSites.Font      = [System.Drawing.Font]::new("Consolas", 9)
$Script:clbSites.CheckOnClick = $true
$Script:clbSites.add_SelectedIndexChanged({
    $i = $Script:clbSites.SelectedIndex
    if ($i -ge 0 -and $Script:SPSites.Count -gt $i) {
        $txtSiteUrl.Text = $Script:SPSites[$i].Url
    }
})
$tabSP.Controls.Add($Script:clbSites)

Divider "Lists & Libraries" 8 238 830 $tabSP
$btnSPListLists = New-Btn "📋 Lists"      8   264 130
$tabSP.Controls.Add((New-Lbl "List Name:" 148 268 90 20 $C.Subtext))
$txtListName = New-Txt "" 240 264 200
$tabSP.Controls.Add($txtListName)
$btnSPListItems = New-Btn "📄 Get Items"  450 264 130
$tabSP.Controls.Add($btnSPListLists)
$tabSP.Controls.Add($btnSPListItems)

$btnSPListLibs  = New-Btn "📚 Libraries"  8   300 130
$btnSPListFiles = New-Btn "📁 List Files" 148 300 130
$tabSP.Controls.Add($btnSPListLibs)
$tabSP.Controls.Add($btnSPListFiles)

Divider "m365 / Teams" 8 338 830 $tabSP
$btnM365Login    = New-Btn "🔐 m365 Login"  8   364 140 30 $C.Peach
$btnM365Status   = New-Btn "ℹ m365 Status"  158 364 140
$btnListTeams    = New-Btn "👥 Teams"        308 364 130
$btnListChannels = New-Btn "💬 Channels"     448 364 130
$tabSP.Controls.Add($btnM365Login)
$tabSP.Controls.Add($btnM365Status)
$tabSP.Controls.Add($btnListTeams)
$tabSP.Controls.Add($btnListChannels)
$tabSP.Controls.Add((New-Lbl "Team name for channels:" 590 368 200 20 $C.Subtext))
$txtTeamName = New-Txt "" 788 364 100
$tabSP.Controls.Add($txtTeamName)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 4 — AZURE DEVOPS
# ═══════════════════════════════════════════════════════════════════════════════
$tabADO = New-Tab "🔵  Azure DevOps"
$tabs.TabPages.Add($tabADO)

$tabADO.Controls.Add((New-Lbl "Org:" 8 12 35 20 $C.Subtext))
$txtOrg = New-Txt "veldarr" 45 9 160
$tabADO.Controls.Add($txtOrg)
$tabADO.Controls.Add((New-Lbl "Project:" 215 12 60 20 $C.Subtext))
$txtProject = New-Txt "" 278 9 200
$tabADO.Controls.Add($txtProject)
$btnAZLogin    = New-Btn "🔐 az login"  488 9 120 26 $C.Peach
$btnListProjs  = New-Btn "📋 Projects"  618 9 140 26
$tabADO.Controls.Add($btnAZLogin)
$tabADO.Controls.Add($btnListProjs)

Divider "Work Items" 8 44 830 $tabADO
$btnListWI     = New-Btn "📋 List WI"         8   70 130
$btnCreateWI   = New-Btn "➕ Create WI"       148 70 130 30 $C.Green
$btnGetWI      = New-Btn "🔍 Get by ID"       288 70 120
$tabADO.Controls.Add($btnListWI)
$tabADO.Controls.Add($btnCreateWI)
$tabADO.Controls.Add($btnGetWI)

$tabADO.Controls.Add((New-Lbl "Title:" 8 108 50 20 $C.Subtext))
$txtWITitle = New-Txt "" 60 105 310
$tabADO.Controls.Add($txtWITitle)
$cboWIType = New-Combo @("Task","Bug","User Story","Feature","Epic") 380 105 130
$cboWIType.SelectedIndex = 0
$tabADO.Controls.Add($cboWIType)
$tabADO.Controls.Add((New-Lbl "WI ID:" 520 108 50 20 $C.Subtext))
$txtWIId = New-Txt "" 572 105 80
$tabADO.Controls.Add($txtWIId)

Divider "Repos & PRs" 8 140 830 $tabADO
$btnListRepos = New-Btn "📁 Repos"      8   166 120
$btnListPRs   = New-Btn "🔀 PRs"        138 166 120
$btnCreatePR  = New-Btn "➕ Create PR"  268 166 130 30 $C.Green
$tabADO.Controls.Add($btnListRepos)
$tabADO.Controls.Add($btnListPRs)
$tabADO.Controls.Add($btnCreatePR)

$tabADO.Controls.Add((New-Lbl "Repo:" 8 204 45 20 $C.Subtext))
$txtRepo = New-Txt "" 56 201 180
$tabADO.Controls.Add($txtRepo)
$tabADO.Controls.Add((New-Lbl "Src Branch:" 246 204 85 20 $C.Subtext))
$txtSrcBranch = New-Txt "feature/" 334 201 160
$tabADO.Controls.Add($txtSrcBranch)
$tabADO.Controls.Add((New-Lbl "Target:" 504 204 55 20 $C.Subtext))
$txtTargetBranch = New-Txt "main" 562 201 100
$tabADO.Controls.Add($txtTargetBranch)

Divider "Pipelines" 8 235 830 $tabADO
$btnListPipelines = New-Btn "⚙ Pipelines"    8   261 140
$btnRunPipeline   = New-Btn "▶ Run Pipeline"  158 261 150 30 $C.Teal
$btnPipelineRuns  = New-Btn "📋 Recent Runs"  318 261 150
$tabADO.Controls.Add($btnListPipelines)
$tabADO.Controls.Add($btnRunPipeline)
$tabADO.Controls.Add($btnPipelineRuns)
$tabADO.Controls.Add((New-Lbl "Pipeline name:" 478 265 110 20 $C.Subtext))
$txtPipelineName = New-Txt "" 592 261 200
$tabADO.Controls.Add($txtPipelineName)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 5 — MCP SERVERS
# ═══════════════════════════════════════════════════════════════════════════════
$tabMCP = New-Tab "🔌  MCP Servers"
$tabs.TabPages.Add($tabMCP)

$btnMCPList    = New-Btn "📋 List Servers"  8   8 150
$btnMCPRefresh = New-Btn "🔄 Refresh"       168 8 110 30 $C.Teal
$tabMCP.Controls.Add($btnMCPList)
$tabMCP.Controls.Add($btnMCPRefresh)

$tabMCP.Controls.Add((New-Lbl "Server name:" 290 12 100 20 $C.Subtext))
$txtMCPName = New-Txt "" 392 9 180
$tabMCP.Controls.Add($txtMCPName)
$btnMCPRemove = New-Btn "🗑 Remove" 582 9 110 26 $C.Red
$tabMCP.Controls.Add($btnMCPRemove)

$mcpStatusBox = New-Object System.Windows.Forms.RichTextBox
$mcpStatusBox.Location  = [System.Drawing.Point]::new(8, 46)
$mcpStatusBox.Size      = [System.Drawing.Size]::new(884, 350)
$mcpStatusBox.BackColor = $C.Mantle
$mcpStatusBox.ForeColor = $C.Green
$mcpStatusBox.Font      = [System.Drawing.Font]::new("Cascadia Code", 9)
$mcpStatusBox.ReadOnly  = $true
$tabMCP.Controls.Add($mcpStatusBox)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 6 — ADMIN & LICENSE ANALYTICS
# ═══════════════════════════════════════════════════════════════════════════════
$tabAdmin = New-Tab "⚙  Admin & Licences"
$tabs.TabPages.Add($tabAdmin)

Divider "Environment Settings" 8 8 830 $tabAdmin
$btnEnvWho        = New-Btn "👤 Who Am I"          8   34 140
$btnEnvDetails    = New-Btn "📋 Env Details"        158 34 140
$btnGovernance    = New-Btn "🛡 Governance"         308 34 140
$btnEnvCapacity   = New-Btn "📦 Capacity"           458 34 140
$btnOpenPPAdmin2  = New-Btn "🌐 Admin Centre"       608 34 140 30 $C.Teal
$tabAdmin.Controls.Add($btnEnvWho)
$tabAdmin.Controls.Add($btnEnvDetails)
$tabAdmin.Controls.Add($btnGovernance)
$tabAdmin.Controls.Add($btnEnvCapacity)
$tabAdmin.Controls.Add($btnOpenPPAdmin2)

Divider "License Analytics" 8 72 830 $tabAdmin
$btnLicenseSummary   = New-Btn "📊 License Summary"      8   98 180
$btnPowerAppsLic     = New-Btn "📱 Power Apps Users"     198 98 180
$btnPowerAutomateLic = New-Btn "⚡ Power Automate Users" 388 98 190
$btnD365Lic          = New-Btn "🏢 D365 Licences"        588 98 160
$tabAdmin.Controls.Add($btnLicenseSummary)
$tabAdmin.Controls.Add($btnPowerAppsLic)
$tabAdmin.Controls.Add($btnPowerAutomateLic)
$tabAdmin.Controls.Add($btnD365Lic)

Divider "DLP & Governance Policies" 8 135 830 $tabAdmin
$btnDlpList   = New-Btn "🔒 List DLP Policies"   8   161 180
$btnDlpCreate = New-Btn "➕ DLP Policy Wizard"   198 161 180 30 $C.Peach
$btnEnvUsers  = New-Btn "👥 Env User Access"     388 161 180
$btnEnvGroups = New-Btn "🏷 Security Groups"     578 161 170
$tabAdmin.Controls.Add($btnDlpList)
$tabAdmin.Controls.Add($btnDlpCreate)
$tabAdmin.Controls.Add($btnEnvUsers)
$tabAdmin.Controls.Add($btnEnvGroups)

Divider "Usage & Adoption" 8 200 830 $tabAdmin
$btnAppUsage    = New-Btn "📈 App Usage (30d)"      8   226 180
$btnFlowUsage   = New-Btn "⚡ Flow Runs (30d)"      198 226 180
$btnConnUsage   = New-Btn "🔗 Connector Usage"      388 226 160
$btnInventory   = New-Btn "🗂 Full Inventory"       558 226 160 30 $C.Green
$tabAdmin.Controls.Add($btnAppUsage)
$tabAdmin.Controls.Add($btnFlowUsage)
$tabAdmin.Controls.Add($btnConnUsage)
$tabAdmin.Controls.Add($btnInventory)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 7 — DEPLOY / MIGRATE
# ═══════════════════════════════════════════════════════════════════════════════
$tabDeploy = New-Tab "🚀  Deploy"
$tabs.TabPages.Add($tabDeploy)

Divider "Source" 8 8 830 $tabDeploy

$tabDeploy.Controls.Add((New-Lbl "Source Env:" 8 34 90))
$Script:cboSrcEnv = New-Combo @() 100 31 380
$btnLoadSrcSols = New-Btn "🔄 Load Solutions" 492 31 160 26 $C.Teal
$tabDeploy.Controls.Add($Script:cboSrcEnv)
$tabDeploy.Controls.Add($btnLoadSrcSols)

$tabDeploy.Controls.Add((New-Lbl "Solution:" 8 62 90))
$Script:cboDeploySol = New-Combo @() 100 59 380
$tabDeploy.Controls.Add($Script:cboDeploySol)

$radManaged   = New-Object System.Windows.Forms.RadioButton
$radUnmanaged = New-Object System.Windows.Forms.RadioButton
foreach ($r in @($radManaged, $radUnmanaged)) {
    $r.ForeColor = $C.Text; $r.BackColor = [System.Drawing.Color]::Transparent
    $r.Font      = [System.Drawing.Font]::new("Segoe UI", 9)
    $tabDeploy.Controls.Add($r)
}
$radManaged.Text     = "Managed";   $radManaged.Location   = [System.Drawing.Point]::new(492, 62); $radManaged.Size = [System.Drawing.Size]::new(100, 24)
$radUnmanaged.Text   = "Unmanaged"; $radUnmanaged.Location = [System.Drawing.Point]::new(600, 62); $radUnmanaged.Size = [System.Drawing.Size]::new(110, 24)
$radUnmanaged.Checked = $true

Divider "Target" 8 92 830 $tabDeploy

$tabDeploy.Controls.Add((New-Lbl "Target Env:" 8 118 90))
$Script:cboTgtEnv = New-Combo @() 100 115 380
$tabDeploy.Controls.Add($Script:cboTgtEnv)
$tabDeploy.Controls.Add((New-Lbl "(or type URL below for cross-tenant)" 492 119 340 18 $C.Subtext))

$tabDeploy.Controls.Add((New-Lbl "Target URL:" 8 146 90))
$txtDeployTargetUrl = New-Txt "" 100 143 560
$tabDeploy.Controls.Add($txtDeployTargetUrl)

# Cross-tenant auth section
$chkCrossTenant = New-Object System.Windows.Forms.CheckBox
$chkCrossTenant.Text      = "Different tenant (requires separate login)"
$chkCrossTenant.Location  = [System.Drawing.Point]::new(8, 174)
$chkCrossTenant.Size      = [System.Drawing.Size]::new(350, 22)
$chkCrossTenant.ForeColor = $C.Peach
$chkCrossTenant.BackColor = [System.Drawing.Color]::Transparent
$chkCrossTenant.Font      = [System.Drawing.Font]::new("Segoe UI", 9)
$tabDeploy.Controls.Add($chkCrossTenant)

$tabDeploy.Controls.Add((New-Lbl "Target Tenant ID:" 8 202 130))
$txtDeployTenantId = New-Txt "" 142 199 300
$btnAuthTarget     = New-Btn "🔐 Auth to Target" 454 199 170 26 $C.Peach
$tabDeploy.Controls.Add($txtDeployTenantId)
$tabDeploy.Controls.Add($btnAuthTarget)

Divider "Options" 8 232 830 $tabDeploy

$chkOverwrite = New-Object System.Windows.Forms.CheckBox
$chkPublish   = New-Object System.Windows.Forms.CheckBox
$chkOverwrite.Text = "Overwrite existing"; $chkPublish.Text = "Publish after import"
foreach ($cb in @($chkOverwrite, $chkPublish)) {
    $cb.ForeColor = $C.Text; $cb.BackColor = [System.Drawing.Color]::Transparent
    $cb.Font      = [System.Drawing.Font]::new("Segoe UI", 9)
    $tabDeploy.Controls.Add($cb)
}
$chkOverwrite.Location = [System.Drawing.Point]::new(8,   258); $chkOverwrite.Size = [System.Drawing.Size]::new(200, 22); $chkOverwrite.Checked = $true
$chkPublish.Location   = [System.Drawing.Point]::new(220, 258); $chkPublish.Size   = [System.Drawing.Size]::new(200, 22); $chkPublish.Checked   = $true

$tabDeploy.Controls.Add((New-Lbl "Export path (temp):" 8 290 140))
$txtDeployTmp = New-Txt (Join-Path $env:TEMP "pp_deploy") 152 287 360
$tabDeploy.Controls.Add($txtDeployTmp)

# Big deploy button
$btnDeploy = New-Object System.Windows.Forms.Button
$btnDeploy.Text      = "🚀  Deploy Solution"
$btnDeploy.Location  = [System.Drawing.Point]::new(8, 325)
$btnDeploy.Size      = [System.Drawing.Size]::new(890, 50)
$btnDeploy.BackColor = $C.Blue
$btnDeploy.ForeColor = $C.Base
$btnDeploy.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDeploy.Font      = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$tabDeploy.Controls.Add($btnDeploy)

$Script:DeploySolutions = @()

# ── Source Control section (below deploy button) ───────────────────────────
Divider "Source Control (Export → Git → Pipeline)" 8 385 830 $tabDeploy

$tabDeploy.Controls.Add((New-Lbl "Repo path:" 8 411 80))
$txtRepoPath = New-Txt (Join-Path "C:\Repositories" "Powerapps Stuff\alm") 92 408 440
$tabDeploy.Controls.Add($txtRepoPath)

$btnGitStatus   = New-Btn "📋 Git Status"       542 408 130
$btnGitPull     = New-Btn "⬇ Pull"              682 408 90  26 $C.Teal
$tabDeploy.Controls.Add($btnGitStatus)
$tabDeploy.Controls.Add($btnGitPull)

$tabDeploy.Controls.Add((New-Lbl "Branch:" 8 440 60))
$txtGitBranch = New-Txt "feature/sol-export" 72 437 260
$tabDeploy.Controls.Add($txtGitBranch)
$btnUnpackCommit = New-Btn "📦 Export+Unpack+Commit" 342 437 220 26 $C.Mauve
$btnGitPush      = New-Btn "⬆ Push & PR"            572 437 130 26 $C.Green
$tabDeploy.Controls.Add($btnUnpackCommit)
$tabDeploy.Controls.Add($btnGitPush)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB — ALM: CANVAS AI + DISPOSABLE ENVIRONMENTS
# ═══════════════════════════════════════════════════════════════════════════════
$tabALM = New-Tab "🧪  ALM Tools"
$tabs.TabPages.Add($tabALM)

# ── Canvas AI Tools ────────────────────────────────────────────────────────────
Divider "🎨 Canvas App AI — Rename Controls & Add Comments" 8 8 830 $tabALM
$tabALM.Controls.Add((New-Lbl ".msapp file:" 8 34 80))
$txtCanvasMsapp = New-Txt "" 92 31 380
$tabALM.Controls.Add($txtCanvasMsapp)
$btnBrowseMsapp = New-Btn "📁" 480 31 38 24
$tabALM.Controls.Add($btnBrowseMsapp)
$tabALM.Controls.Add((New-Lbl "Unpack to:" 528 34 70))
$txtCanvasUnpackDir = New-Txt (Join-Path $env:TEMP "canvas-unpack") 600 31 248
$tabALM.Controls.Add($txtCanvasUnpackDir)

$btnCanvasUnpack  = New-Btn "📦 Unpack"              8   63 120 28 $C.Teal
$btnCanvasRename  = New-Btn "🤖 AI Rename Controls"  138 63 200 28 $C.Mauve
$btnCanvasComment = New-Btn "💬 AI Add Comments"      348 63 180 28 $C.Blue
$btnCanvasRepack  = New-Btn "✅ Apply & Repack"       538 63 180 28 $C.Green
$tabALM.Controls.Add($btnCanvasUnpack)
$tabALM.Controls.Add($btnCanvasRename)
$tabALM.Controls.Add($btnCanvasComment)
$tabALM.Controls.Add($btnCanvasRepack)
$tabALM.Controls.Add((New-Lbl "💡 Unpacks your .msapp, sends YAML to AI for rename suggestions and/or code comments, then repacks." 8 97 880 18 $C.Overlay))

# ── Disposable Environments ─────────────────────────────────────────────────────
Divider "🧪 Disposable Environments — Create · Deploy · Destroy" 8 118 830 $tabALM
$tabALM.Controls.Add((New-Lbl "Env name:" 8 144 70))
$txtDisposableEnvName = New-Txt "sandbox-$(Get-Date -Format 'MMdd-HHmm')" 82 141 240
$tabALM.Controls.Add($txtDisposableEnvName)
$tabALM.Controls.Add((New-Lbl "Region:" 332 144 55))
$cboDisposableRegion = New-Combo @("unitedkingdom","unitedstates","europe","asia","australia","canada") 390 141 160
$cboDisposableRegion.SelectedIndex = 0
$tabALM.Controls.Add($cboDisposableRegion)
$tabALM.Controls.Add((New-Lbl "Type:" 558 144 45))
$cboDisposableType = New-Combo @("Sandbox","Trial","Developer") 606 141 140
$cboDisposableType.SelectedIndex = 0
$tabALM.Controls.Add($cboDisposableType)

$tabALM.Controls.Add((New-Lbl "Solution:" 8 174 70))
$cboDisposableSol = New-Combo @() 82 171 340
$tabALM.Controls.Add($cboDisposableSol)
$radDisposableManaged   = New-Object System.Windows.Forms.RadioButton
$radDisposableUnmanaged = New-Object System.Windows.Forms.RadioButton
foreach ($r in @($radDisposableManaged,$radDisposableUnmanaged)) {
    $r.ForeColor = $C.Text; $r.BackColor = [System.Drawing.Color]::Transparent
    $r.Font = [System.Drawing.Font]::new("Segoe UI", 9); $tabALM.Controls.Add($r)
}
$radDisposableManaged.Text     = "Managed";   $radDisposableManaged.Location   = [System.Drawing.Point]::new(432, 173); $radDisposableManaged.Size = [System.Drawing.Size]::new(100,22); $radDisposableManaged.Checked = $true
$radDisposableUnmanaged.Text   = "Unmanaged"; $radDisposableUnmanaged.Location = [System.Drawing.Point]::new(540, 173); $radDisposableUnmanaged.Size = [System.Drawing.Size]::new(110,22)

$tabALM.Controls.Add((New-Lbl "Env vars JSON:" 8 204 100))
$txtDisposableEnvVars = New-Txt (Join-Path $PSScriptRoot "..\config\env-variables.json") 112 201 450
$tabALM.Controls.Add($txtDisposableEnvVars)
$btnBrowseEnvVars = New-Btn "📁" 570 201 38 24
$tabALM.Controls.Add($btnBrowseEnvVars)
$tabALM.Controls.Add((New-Lbl "optional JSON: [{schemaName:'var_Key',value:'val'}]" 618 205 310 18 $C.Overlay))

$btnDisposableCreate          = New-Object System.Windows.Forms.Button
$btnDisposableCreate.Text     = "🧪  Create Environment · Apply Variables · Deploy Solution  (AI-powered)"
$btnDisposableCreate.Location = [System.Drawing.Point]::new(8, 233)
$btnDisposableCreate.Size     = [System.Drawing.Size]::new(890, 44)
$btnDisposableCreate.BackColor= $C.Green
$btnDisposableCreate.ForeColor= $C.Base
$btnDisposableCreate.FlatStyle= [System.Windows.Forms.FlatStyle]::Flat
$btnDisposableCreate.Font     = [System.Drawing.Font]::new("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$tabALM.Controls.Add($btnDisposableCreate)

$btnListDisposable = New-Btn "🔄 List My Envs"     8   287 160 28 $C.Teal
$btnDeleteDisposable = New-Btn "🗑 Delete Selected" 178 287 160 28 $C.Red
$tabALM.Controls.Add($btnListDisposable)
$tabALM.Controls.Add($btnDeleteDisposable)
$tabALM.Controls.Add((New-Lbl "💡 Environments created here are tracked below. Delete them when done to avoid licence waste." 348 291 560 18 $C.Overlay))

$lstDisposableEnvs = New-Object System.Windows.Forms.ListBox
$lstDisposableEnvs.Location  = [System.Drawing.Point]::new(8, 318)
$lstDisposableEnvs.Size      = [System.Drawing.Size]::new(890, 95)
$lstDisposableEnvs.BackColor = $C.Surface
$lstDisposableEnvs.ForeColor = $C.Text
$lstDisposableEnvs.SelectionMode = "MultiExtended"
$tabALM.Controls.Add($lstDisposableEnvs)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 8 — CODE REVIEW
# ═══════════════════════════════════════════════════════════════════════════════
$tabReview = New-Tab "🔍  Code Review"
$tabs.TabPages.Add($tabReview)

$tabReview.Controls.Add((New-Lbl "Repo path:" 8 12 80))
$txtReviewRepo = New-Txt (Join-Path "C:\Repositories" "Powerapps Stuff\alm") 90 9 400
$tabReview.Controls.Add($txtReviewRepo)
$tabReview.Controls.Add((New-Lbl "Compare:" 500 12 65))
$txtReviewBase   = New-Txt "main"   568 9 80
$tabReview.Controls.Add($txtReviewBase)
$tabReview.Controls.Add((New-Lbl "↔" 652 12 20 20 $C.Subtext))
$txtReviewHead   = New-Txt "HEAD"   672 9 100
$tabReview.Controls.Add($txtReviewHead)

Divider "Git Review" 8 40 830 $tabReview
$btnReviewDiff    = New-Btn "📄 Diff"           8   66 110
$btnReviewLog     = New-Btn "📋 Log"            128 66 110
$btnReviewChanged = New-Btn "🗂 Changed Files"   248 66 150
$btnReviewBlame   = New-Btn "👤 Blame"           408 66 110
$btnReviewStats   = New-Btn "📊 Diff Stats"      528 66 120
$tabReview.Controls.Add($btnReviewDiff)
$tabReview.Controls.Add($btnReviewLog)
$tabReview.Controls.Add($btnReviewChanged)
$tabReview.Controls.Add($btnReviewBlame)
$tabReview.Controls.Add($btnReviewStats)

Divider "PAC Solution Checker" 8 100 830 $tabReview
$tabReview.Controls.Add((New-Lbl "Solution zip/folder:" 8 126 150))
$txtCheckerPath = New-Txt "" 162 123 400
$btnBrowseChecker = New-Btn "📁" 570 123 40 24
$tabReview.Controls.Add($txtCheckerPath)
$tabReview.Controls.Add($btnBrowseChecker)
$tabReview.Controls.Add((New-Lbl "Ruleset:" 620 126 60))
$cboRuleset = New-Combo @("AppSource","Solution","PowerAppsRecommendations") 682 123 170
$cboRuleset.SelectedIndex = 1
$tabReview.Controls.Add($cboRuleset)
$btnRunChecker = New-Btn "🔍 Run Solution Checker" 8 157 220 30 $C.Teal
$btnOpenCheckerReport = New-Btn "📊 Open Report" 238 157 160 30 $C.Green
$tabReview.Controls.Add($btnRunChecker)
$tabReview.Controls.Add($btnOpenCheckerReport)

Divider "GitHub PR" 8 200 830 $tabReview
$tabReview.Controls.Add((New-Lbl "PR Title:" 8 226 70))
$txtPRTitle = New-Txt "chore: export solution" 82 223 380
$tabReview.Controls.Add($txtPRTitle)
$tabReview.Controls.Add((New-Lbl "Base branch:" 472 226 90))
$txtPRBase  = New-Txt "main" 564 223 100
$tabReview.Controls.Add($txtPRBase)
$tabReview.Controls.Add((New-Lbl "PR Body:" 8 254 70))
$txtPRBody = New-Txt "Auto-generated by Power Platform Dashboard" 82 251 580
$tabReview.Controls.Add($txtPRBody)
$btnCreatePR = New-Btn "🐙 Create GitHub PR" 8 285 200 30 $C.Blue
$btnOpenPRs  = New-Btn "📋 List Open PRs"   218 285 180
$btnOpenADOPR = New-Btn "🔵 Create ADO PR" 408 285 180 30 $C.Sky
$tabReview.Controls.Add($btnCreatePR)
$tabReview.Controls.Add($btnOpenPRs)
$tabReview.Controls.Add($btnOpenADOPR)

Divider "Copilot Review (AI)" 8 325 830 $tabReview
$btnAIReview = New-Btn "🤖 Ask Copilot to Review Diff" 8 351 260 30 $C.Mauve
$tabReview.Controls.Add($btnAIReview)
$tabReview.Controls.Add((New-Lbl "Opens diff in Copilot CLI with review prompt" 280 355 450 18 $C.Subtext))

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 9 — SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════
$tabSettings = New-Tab "⚙️  Settings"
$tabs.TabPages.Add($tabSettings)

Divider "GitHub" 8 8 890 $tabSettings
$tabSettings.Controls.Add((New-Lbl "Personal Access Token:" 8 32 162))
$txtGhPAT = New-Txt "" 174 29 420
$txtGhPAT.UseSystemPasswordChar = $true
$tabSettings.Controls.Add($txtGhPAT)
$chkShowPAT           = New-Object System.Windows.Forms.CheckBox
$chkShowPAT.Text      = "Show"
$chkShowPAT.Location  = [System.Drawing.Point]::new(602, 31)
$chkShowPAT.Size      = [System.Drawing.Size]::new(60, 22)
$chkShowPAT.ForeColor = $C.Subtext
$chkShowPAT.BackColor = $C.Panel
$tabSettings.Controls.Add($chkShowPAT)
$btnTestGh = New-Btn "🔗 Test GitHub" 672 29 118 24 $C.Teal
$tabSettings.Controls.Add($btnTestGh)

Divider "Dataverse MCP Connection" 8 60 890 $tabSettings
$tabSettings.Controls.Add((New-Lbl "Connection URL:" 8 84 120))
$txtDvUrl = New-Txt "" 132 81 560
$tabSettings.Controls.Add($txtDvUrl)
$btnDetectDv = New-Btn "🔍 Auto-detect" 700 81 180 24 $C.Teal
$tabSettings.Controls.Add($btnDetectDv)
$tabSettings.Controls.Add((New-Lbl "💡 Format: https://make.powerautomate.com/environments/{id}?apiName=shared_commondataserviceforapps&connectionName={connId}" 8 108 880 18 $C.Overlay))

Divider "Copilot Studio Agent MCP" 8 130 890 $tabSettings
$tabSettings.Controls.Add((New-Lbl "Agent MCP URL:" 8 154 115))
$txtCsMcpUrl = New-Txt "" 126 151 565
$tabSettings.Controls.Add($txtCsMcpUrl)
$lnkOpenStudio           = New-Object System.Windows.Forms.LinkLabel
$lnkOpenStudio.Text      = "Open Studio ↗"
$lnkOpenStudio.Location  = [System.Drawing.Point]::new(700, 154)
$lnkOpenStudio.Size      = [System.Drawing.Size]::new(120, 20)
$lnkOpenStudio.LinkColor = $C.Blue
$lnkOpenStudio.BackColor = $C.Panel
$tabSettings.Controls.Add($lnkOpenStudio)
$tabSettings.Controls.Add((New-Lbl "💡 Studio → Your Agent → Settings → Channels → MCP Client → copy the endpoint URL" 8 178 880 18 $C.Overlay))

Divider "Azure DevOps" 8 200 890 $tabSettings
$tabSettings.Controls.Add((New-Lbl "Organisation URL:" 8 224 130))
$txtAdoOrgCfg = New-Txt "https://dev.azure.com/veldarr" 142 221 400
$tabSettings.Controls.Add($txtAdoOrgCfg)

Divider "AI Assistant (for the AI Chat tab)" 8 252 890 $tabSettings
$tabSettings.Controls.Add((New-Lbl "Provider:" 8 276 65))
$cboAiProv = New-Combo @("GitHub Copilot (clipboard)","Azure OpenAI","Anthropic Claude") 76 273 230
$cboAiProv.SelectedIndex = 0
$tabSettings.Controls.Add($cboAiProv)
$tabSettings.Controls.Add((New-Lbl "API Endpoint / Base URL:" 8 304 180))
$txtAiEp = New-Txt "https://YOUR-RESOURCE.openai.azure.com/" 192 301 490
$tabSettings.Controls.Add($txtAiEp)
$tabSettings.Controls.Add((New-Lbl "Deployment / Model:" 8 330 140))
$txtAiDeploy = New-Txt "gpt-4o" 152 327 220
$tabSettings.Controls.Add($txtAiDeploy)
$tabSettings.Controls.Add((New-Lbl "API Key:" 8 356 65))
$txtAiApiKey = New-Txt "" 76 353 480
$txtAiApiKey.UseSystemPasswordChar = $true
$tabSettings.Controls.Add($txtAiApiKey)
$chkShowAiKey           = New-Object System.Windows.Forms.CheckBox
$chkShowAiKey.Text      = "Show"
$chkShowAiKey.Location  = [System.Drawing.Point]::new(564, 355)
$chkShowAiKey.Size      = [System.Drawing.Size]::new(60, 22)
$chkShowAiKey.ForeColor = $C.Subtext
$chkShowAiKey.BackColor = $C.Panel
$tabSettings.Controls.Add($chkShowAiKey)

$btnSaveCfg          = New-Object System.Windows.Forms.Button
$btnSaveCfg.Text     = "💾  Save All Settings"
$btnSaveCfg.Location = [System.Drawing.Point]::new(8, 388)
$btnSaveCfg.Size     = [System.Drawing.Size]::new(890, 38)
$btnSaveCfg.BackColor = $C.Green
$btnSaveCfg.ForeColor = $C.Base
$btnSaveCfg.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSaveCfg.Font     = [System.Drawing.Font]::new("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$tabSettings.Controls.Add($btnSaveCfg)
$lblCfgStatus = New-Lbl "" 8 430 880 18 $C.Green
$tabSettings.Controls.Add($lblCfgStatus)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 10 — AI ASSISTANT
# ═══════════════════════════════════════════════════════════════════════════════
$tabAI = New-Tab "🤖  AI Assistant"
$tabs.TabPages.Add($tabAI)

# Quick-prompt buttons
$btnQp1 = New-Btn "❓ What can you do?"  8   8 158 24 $C.Overlay
$btnQp2 = New-Btn "🚀 How to deploy?"   176  8 138 24 $C.Overlay
$btnQp3 = New-Btn "🌍 My environments"  324  8 138 24 $C.Overlay
$btnQp4 = New-Btn "💡 Explain error"    472  8 128 24 $C.Overlay
$btnQp5 = New-Btn "🔍 Best practices"   610  8 150 24 $C.Overlay
$tabAI.Controls.Add($btnQp1); $tabAI.Controls.Add($btnQp2); $tabAI.Controls.Add($btnQp3)
$tabAI.Controls.Add($btnQp4); $tabAI.Controls.Add($btnQp5)

# Chat history
$Script:AiChat          = New-Object System.Windows.Forms.RichTextBox
$Script:AiChat.Location = [System.Drawing.Point]::new(8, 38)
$Script:AiChat.Size     = [System.Drawing.Size]::new(888, 268)
$Script:AiChat.BackColor  = $C.Mantle
$Script:AiChat.ForeColor  = $C.Text
$Script:AiChat.Font       = [System.Drawing.Font]::new("Segoe UI", 9)
$Script:AiChat.ReadOnly   = $true
$Script:AiChat.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$tabAI.Controls.Add($Script:AiChat)

# Message input
$Script:AiMsgBox             = New-Object System.Windows.Forms.TextBox
$Script:AiMsgBox.Location    = [System.Drawing.Point]::new(8, 314)
$Script:AiMsgBox.Size        = [System.Drawing.Size]::new(728, 64)
$Script:AiMsgBox.Multiline   = $true
$Script:AiMsgBox.BackColor   = $C.Surface
$Script:AiMsgBox.ForeColor   = $C.Text
$Script:AiMsgBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$Script:AiMsgBox.AcceptsReturn = $true
$tabAI.Controls.Add($Script:AiMsgBox)

$btnAiSend  = New-Btn "➤  Send"  746 314 150 32 $C.Blue
$btnAiClear = New-Btn "🗑 Clear"  746 350 150 28 $C.Red
$tabAI.Controls.Add($btnAiSend)
$tabAI.Controls.Add($btnAiClear)
$tabAI.Controls.Add((New-Lbl "Ctrl+Enter to send  •  Configure AI in ⚙️ Settings tab" 8 384 700 18 $C.Overlay))

$outputHeader           = New-Object System.Windows.Forms.Panel
$outputHeader.Location  = [System.Drawing.Point]::new(8, 500)
$outputHeader.Size      = [System.Drawing.Size]::new(910, 26)
$outputHeader.BackColor = $C.Panel
$form.Controls.Add($outputHeader)

$outputHeader.Controls.Add((New-Lbl "  Output" 0 4 100 20 $C.Subtext))
$btnClearOutput = New-Btn "🗑 Clear"           780 2 60 22 $C.Red
$btnCopyLog     = New-Btn "📋 Copy Log (for Copilot)" 620 2 156 22 $C.Mauve
$outputHeader.Controls.Add($btnClearOutput)
$outputHeader.Controls.Add($btnCopyLog)

$Script:OutputBox = New-Object System.Windows.Forms.RichTextBox
$Script:OutputBox.Location   = [System.Drawing.Point]::new(8, 528)
$Script:OutputBox.Size       = [System.Drawing.Size]::new(910, 185)
$Script:OutputBox.BackColor  = $C.Mantle
$Script:OutputBox.ForeColor  = $C.Text
$Script:OutputBox.Font       = [System.Drawing.Font]::new("Cascadia Code", 9)
$Script:OutputBox.ReadOnly   = $true
$Script:OutputBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$form.Controls.Add($Script:OutputBox)

# ── EVENT WIRING ──────────────────────────────────────────────────────────────

# ---- Shared helper: get current env URL -----
function Get-CurEnvUrl {
    if ($cboEnv.SelectedIndex -ge 0) { return $Script:Environments[$cboEnv.SelectedIndex].Url }
    return ""
}

function Get-OrgUrl { return "https://dev.azure.com/$($txtOrg.Text.Trim())" }

# ---- Load environments ----
function Load-Environments {
    Run-Cmd "pac env list" { pac env list } "Environments"
    $raw = pac env list 2>&1
    $Script:Environments = @()
    $cboEnv.Items.Clear()
    $cboTopEnv.Items.Clear()
    foreach ($line in $raw) {
        if ($line -match '(https://[^\s]+\.dynamics\.com/?)') {
            $url = $Matches[1]; if (-not $url.EndsWith('/')) { $url += '/' }
            $name = ($line -replace 'https://.*','').Trim() -replace '\s{2,}',' '
            $Script:Environments += [PSCustomObject]@{ Name=$name; Url=$url }
            $null = $cboEnv.Items.Add($name)
            $null = $cboTopEnv.Items.Add($name)
        }
    }
    if ($cboEnv.Items.Count -gt 0) {
        $cboEnv.SelectedIndex    = 0
        $cboTopEnv.SelectedIndex = 0
    }
    Refresh-DeployEnvDropdowns
}

$cboEnv.add_SelectedIndexChanged({
    if ($cboEnv.SelectedIndex -ge 0) {
        $e = $Script:Environments[$cboEnv.SelectedIndex]
        $lblEnvUrl.Text    = "URL: $($e.Url)"
        $envStatusLbl.Text = $e.Name
        if ($cboTopEnv.SelectedIndex -ne $cboEnv.SelectedIndex) {
            $cboTopEnv.SelectedIndex = $cboEnv.SelectedIndex
        }
    }
})

$cboTopEnv.add_SelectedIndexChanged({
    if ($cboTopEnv.SelectedIndex -ge 0 -and $cboTopEnv.SelectedIndex -ne $cboEnv.SelectedIndex) {
        $cboEnv.SelectedIndex = $cboTopEnv.SelectedIndex
    }
    # Refresh env-dependent data silently
    if ($Script:Environments.Count -gt 0) {
        $Script:Solutions = @()
        $Script:cboSolutions.Items.Clear()
        Load-Solutions
        Refresh-DeployEnvDropdowns
    }
})

$btnRefreshEnvs.add_Click({ Load-Environments })

$btnSwitchEnv.add_Click({
    if ($cboEnv.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Select an environment first."); return }
    $e = $Script:Environments[$cboEnv.SelectedIndex]
    Run-Cmd "Switch-DataverseEnvironment '$($e.Name)'" {
        & "$PSScriptRoot\Switch-DataverseEnvironment.ps1" -EnvironmentName $e.Name
    } "Environments"
    [System.Windows.Forms.MessageBox]::Show(
        "Switched to:`n$($e.Name)`n$($e.Url)`n`nStart a new Copilot CLI session to apply.",
        "Switched!", [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)
})

$btnOpenPPAC.add_Click({
    Start-Process "https://admin.powerplatform.microsoft.com"
    Write-Log "Open Power Platform Admin Centre" "" "Environments"
})

$btnListEnvs.add_Click({   Run-Cmd "pac env list"   { pac env list }   "Environments" })
$btnAuthStatus.add_Click({ Run-Cmd "pac auth list"   { pac auth list }  "Auth" })
$btnLogin.add_Click({
    $Script:OutputBox.AppendText("`r`n▶ pac auth create (browser will open...)`r`n")
    Start-Process pwsh -ArgumentList "-NoProfile -Command `"pac auth create`""
    Write-Log "pac auth create" "Browser opened" "Auth"
})
$btnOpenPAPortal.add_Click({
    Start-Process "https://make.powerapps.com"
    Write-Log "Open Power Apps Portal" "" "Environments"
})
$btnOpenPAAdmin.add_Click({
    Start-Process "https://admin.powerplatform.microsoft.com/environments"
    Write-Log "Open PP Admin Environments" "" "Environments"
})
$btnWhoAmI.add_Click({    Run-Cmd "pac org who"        { pac org who }        "Environments" })
$btnListUsers.add_Click({ Run-Cmd "pac admin list (environments/users)" { pac admin list } "Environments" })
$btnListRoles.add_Click({ Run-Cmd "pac admin list-roles" { pac admin list-roles } "Environments" })

# ---- Solutions ----
function Load-Solutions {
    $envUrl = Get-CurEnvUrl
    $envArg = if ($envUrl) { @("--environment", $envUrl) } else { @() }
    $raw = pac solution list @envArg 2>&1
    $Script:Solutions = @()
    $Script:cboSolutions.Items.Clear()
    $cboDisposableSol.Items.Clear()
    foreach ($line in $raw) {
        if ($line -match '^(\S+)\s+(.+?)\s{2,}([\d\.]+)\s+(True|False)\s*$') {
            $sol = [PSCustomObject]@{
                UniqueName   = $Matches[1].Trim()
                FriendlyName = $Matches[2].Trim()
                Version      = $Matches[3].Trim()
                Managed      = $Matches[4].Trim()
            }
            $Script:Solutions += $sol
            $null = $Script:cboSolutions.Items.Add("$($sol.FriendlyName)  [$($sol.UniqueName)]  v$($sol.Version)")
            $null = $cboDisposableSol.Items.Add($sol.FriendlyName)
        }
    }
    if ($Script:cboSolutions.Items.Count -gt 0) {
        $Script:cboSolutions.SelectedIndex = 0
        $cboDisposableSol.SelectedIndex    = 0
        $Script:OutputBox.SelectionColor = $C.Green
        $Script:OutputBox.AppendText("▸ $($Script:Solutions.Count) solutions loaded.`r`n")
        $Script:OutputBox.SelectionColor = $C.Text
    }
}
$btnBrowse.add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.SelectedPath = $txtExportPath.Text
    if ($d.ShowDialog() -eq "OK") { $txtExportPath.Text = $d.SelectedPath }
})
$btnExportSol.add_Click({
    if (-not $txtSolName.Text.Trim()) { [System.Windows.Forms.MessageBox]::Show("Enter solution name."); return }
    $n = $txtSolName.Text.Trim(); $p = $txtExportPath.Text.Trim()
    Run-Cmd "pac solution export --name `"$n`" --path `"$p`"" {
        pac solution export --name $n --path $p
    } "Solutions"
})
$btnImportSol.add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Filter = "Zip (*.zip)|*.zip"
    if ($d.ShowDialog() -eq "OK") {
        $fp = $d.FileName
        Run-Cmd "pac solution import --path `"$fp`"" { pac solution import --path $fp } "Solutions"
    }
})
# ---- Solution component browser ----
$filterComp = {
    $ft = $txtCompFilter.Text.ToLower()
    $tp = $cboCompType.SelectedItem
    $Script:DgComponents.Rows.Clear()
    foreach ($comp in $Script:AllComponents) {
        $tm = ($tp -eq "All Types" -or $comp.Type -eq $tp)
        $tx = ($ft -eq "" -or $comp.DisplayName.ToLower() -like "*$ft*" -or $comp.UniqueName.ToLower() -like "*$ft*")
        if ($tm -and $tx) { $null = $Script:DgComponents.Rows.Add($comp.Type, $comp.DisplayName, $comp.UniqueName, $comp.Root) }
    }
}
$txtCompFilter.add_TextChanged($filterComp)
$cboCompType.add_SelectedIndexChanged($filterComp)

$btnOpenInPortal.add_Click({
    $idx = $cboTopEnv.SelectedIndex
    $url = if ($idx -ge 0 -and $Script:Environments.Count -gt $idx -and $Script:Environments[$idx].Id) {
        "https://make.powerapps.com/environments/$($Script:Environments[$idx].Id)/solutions"
    } else { "https://make.powerapps.com" }
    Start-Process $url
})

$Script:CompTypeMap = @{
    '1'='Table'; '2'='Column'; '3'='Relationship'; '9'='Entity Relationship';
    '10'='Intersect Entity'; '14'='Duplicate Rule'; '16'='System Form'; '24'='Connection Role';
    '26'='Canvas App'; '29'='Cloud Flow'; '33'='View'; '44'='Chart'; '59'='Site Map';
    '60'='Form'; '61'='View'; '62'='Chart'; '66'='Connection Role';
    '70'='Field Permission'; '71'='Field Security Profile';
    '80'='Web Resource'; '90'='Plugin Assembly'; '91'='SDK Step'; '92'='SDK Step Image';
    '95'='Service Endpoint'; '154'='Business Process Flow';
    '300'='Model-driven App'; '371'='Page'; '380'='Flow Machine';
    '400'='AI Builder Model'; '430'='Copilot'; '431'='Copilot Subcomponent';
    '10028'='Connection Reference'; '10029'='Connector';
    '10057'='Environment Variable'; '10058'='Env Variable Value';
}

$btnLoadComponents.add_Click({
    $solName = $txtSolName.Text.Trim()
    if (-not $solName -and $Script:cboSolutions.SelectedIndex -ge 0 -and $Script:Solutions) {
        $solName = $Script:Solutions[$Script:cboSolutions.SelectedIndex].UniqueName
    }
    if (-not $solName) { [System.Windows.Forms.MessageBox]::Show("Select a solution first (click 'List Solutions' then pick one)."); return }

    $btnLoadComponents.Enabled = $false; $btnLoadComponents.Text = "⏳ Loading..."
    $Script:AllComponents.Clear(); $Script:DgComponents.Rows.Clear()
    $Script:OutputBox.AppendText("`r`n📋 Loading components for '$solName'...`r`n")

    $logQ   = $Script:LogQueue
    $typeMap = $Script:CompTypeMap
    $rs = [runspacefactory]::CreateRunspace(); $rs.ApartmentState="STA"; $rs.ThreadOptions="ReuseThread"; $rs.Open()
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($solName, $logQ, $typeMap)
        $logQ.Enqueue("⚙️ pac solution list-component --solution-name '$solName'")
        $raw = pac solution list-component --solution-name $solName 2>&1 | Out-String

        $components = [System.Collections.Generic.List[hashtable]]::new()
        $lines = ($raw -split "`r?`n") | Where-Object { $_.Trim() -ne "" }
        $pastHeader = $false

        foreach ($line in $lines) {
            if ($line -match '^[\s\-─=]+$') { $pastHeader = $true; continue }
            if (-not $pastHeader) { continue }
            # Format: TypeNum  ObjectGuid  RootBehavior  SchemaName
            if ($line -match '^\s*(\d+)\s+([0-9a-fA-F-]{36})\s+(\d*)\s*(.*)$') {
                $tn = $matches[1].Trim(); $root = $matches[3].Trim(); $name = $matches[4].Trim()
                $tp = if ($typeMap.ContainsKey($tn)) { $typeMap[$tn] } else { "Type $tn" }
                $components.Add(@{Type=$tp; DisplayName=$name; UniqueName=$name; Root=$root})
            } elseif ($line -match '^\s*(\d+)\s+(.+)$') {
                $tn = $matches[1].Trim(); $name = $matches[2].Trim()
                $tp = if ($typeMap.ContainsKey($tn)) { $typeMap[$tn] } else { "Type $tn" }
                $components.Add(@{Type=$tp; DisplayName=$name; UniqueName=$name; Root=""})
            }
        }
        $logQ.Enqueue("  ✅ $($components.Count) components parsed")
        return @{ Components=$components; RawOutput=$raw; Count=$components.Count }
    }).AddParameters(@{solName=$solName; logQ=$logQ; typeMap=$typeMap})

    $handle = $ps.BeginInvoke()
    $timer  = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $res = try { $ps.EndInvoke($handle) } catch { @{Components=@(); RawOutput=$_.Exception.Message; Count=0} }
            $ps.Dispose(); $rs.Dispose()
            $btnLoadComponents.Enabled = $true; $btnLoadComponents.Text = "📋 Load Components"
            if ($res.Count -gt 0) {
                foreach ($c in $res.Components) {
                    $null = $Script:AllComponents.Add([PSCustomObject]$c)
                    $null = $Script:DgComponents.Rows.Add($c.Type, $c.DisplayName, $c.UniqueName, $c.Root)
                }
                $Script:OutputBox.SelectionColor = $Script:C.Green
                $Script:OutputBox.AppendText("✅ $($res.Count) components loaded — use filter/type dropdown to narrow down`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
            } else {
                $Script:OutputBox.SelectionColor = $Script:C.Peach
                $Script:OutputBox.AppendText("⚠ Could not parse component list. Is the solution name correct?`r`nRaw output:`r`n$($res.RawOutput)`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
            }
        }
    }); $timer.Start()
})

# ---- SharePoint ----
$btnSPConnect.add_Click({
    $url = $txtSiteUrl.Text.Trim()
    Run-Cmd "Connect-PnPOnline -Url `"$url`" -Interactive" {
        Import-Module PnP.PowerShell -ErrorAction SilentlyContinue
        Connect-PnPOnline -Url $url -Interactive
    } "SharePoint"
})

$btnSPLoadSites.add_Click({
    $Script:OutputBox.AppendText("`r`n▶ Loading SharePoint sites (may take a moment)...`r`n")
    $raw = m365 spo site list --output json 2>&1 | Out-String
    try {
        $sites = $raw | ConvertFrom-Json
        $Script:SPSites = $sites
        $Script:clbSites.Items.Clear()
        foreach ($s in $sites) {
            $label = "$($s.Title.PadRight(45)) $($s.Url)"
            $null = $Script:clbSites.Items.Add($label)
        }
        $Script:OutputBox.SelectionColor = $C.Green
        $Script:OutputBox.AppendText("✅ $($sites.Count) sites loaded. Click to select, check multiple to open.`r`n")
        $Script:OutputBox.SelectionColor = $C.Text
        Write-Log "Load SP Sites" "$($sites.Count) sites" "SharePoint"
    } catch {
        $Script:OutputBox.SelectionColor = $C.Red
        $Script:OutputBox.AppendText("❌ Could not parse sites. Are you logged in with m365?`r`n$raw`r`n")
        $Script:OutputBox.SelectionColor = $C.Text
    }
})

$btnSPSiteInfo.add_Click({
    $url = $txtSiteUrl.Text.Trim()
    if (-not $url) { [System.Windows.Forms.MessageBox]::Show("Select or type a site URL first."); return }
    Run-Cmd "m365 spo site get --url `"$url`"" { m365 spo site get --url $url } "SharePoint"
})

$btnSPOpenChecked.add_Click({
    $checked = $Script:clbSites.CheckedIndices
    if ($checked.Count -eq 0 -and -not $txtSiteUrl.Text.Trim()) {
        [System.Windows.Forms.MessageBox]::Show("Check at least one site, or type a URL above.")
        return
    }
    if ($checked.Count -gt 0) {
        foreach ($i in $checked) { Start-Process $Script:SPSites[$i].Url }
        Write-Log "Open checked SP sites" "$($checked.Count) sites" "SharePoint"
    } else {
        Start-Process $txtSiteUrl.Text.Trim()
    }
})
$btnSPListLists.add_Click({
    $url = $txtSiteUrl.Text.Trim()
    Run-Cmd "m365 spo list list --webUrl `"$url`"" { m365 spo list list --webUrl $url } "SharePoint"
})
$btnSPListItems.add_Click({
    $url = $txtSiteUrl.Text.Trim(); $list = $txtListName.Text.Trim()
    if (-not $list) { [System.Windows.Forms.MessageBox]::Show("Enter a list name."); return }
    Run-Cmd "m365 spo listitem list --listTitle `"$list`" --webUrl `"$url`"" {
        m365 spo listitem list --listTitle $list --webUrl $url
    } "SharePoint"
})
$btnSPListLibs.add_Click({
    $url = $txtSiteUrl.Text.Trim()
    Run-Cmd "Get-PnPList (libraries)" {
        Import-Module PnP.PowerShell -ErrorAction SilentlyContinue
        Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 } | Select-Object Title, ItemCount, LastItemModifiedDate
    } "SharePoint"
})
$btnSPListFiles.add_Click({
    $url = $txtSiteUrl.Text.Trim()
    Run-Cmd "m365 spo file list --webUrl `"$url`"" { m365 spo file list --webUrl $url } "SharePoint"
})
$btnM365Login.add_Click({
    $Script:OutputBox.AppendText("`r`n▶ m365 login (browser will open...)`r`n")
    Start-Process pwsh -ArgumentList "-NoProfile -Command `"m365 login`""
    Write-Log "m365 login" "Browser opened" "Auth"
})
$btnM365Status.add_Click({ Run-Cmd "m365 status" { m365 status } "Auth" })
$btnListTeams.add_Click({  Run-Cmd "m365 teams team list" { m365 teams team list } "Teams" })
$btnListChannels.add_Click({
    $team = $txtTeamName.Text.Trim()
    if (-not $team) { [System.Windows.Forms.MessageBox]::Show("Enter a team name."); return }
    Run-Cmd "m365 teams channel list --teamName `"$team`"" { m365 teams channel list --teamName $team } "Teams"
})

# ---- Azure DevOps ----
$btnAZLogin.add_Click({
    $Script:OutputBox.SelectionColor = $C.Peach
    $Script:OutputBox.AppendText("`r`n▶ az login — browser opening, complete sign-in then buttons will re-enable...`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
    $btnAZLogin.Enabled = $false
    $btnAZLogin.Text    = "⏳ Signing in..."
    $btnListProjs.Enabled = $false

    # Run az login in background runspace so UI stays responsive
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $null = $ps.AddScript("az login 2>&1 | Out-String")
    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 800
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) | Out-String } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $Script:OutputBox.SelectionColor = $Script:C.Green
            $Script:OutputBox.AppendText("✅ az login complete:`r`n$result`r`n")
            $Script:OutputBox.SelectionColor = $Script:C.Text
            $Script:OutputBox.AppendText("You can now use Azure DevOps buttons.`r`n")
            $btnAZLogin.Enabled   = $true
            $btnAZLogin.Text      = "🔐 az login"
            $btnListProjs.Enabled = $true
            Write-Log "az login" $result "Auth"
        }
    })
    $timer.Start()
})
$btnListProjs.add_Click({
    $org = Get-OrgUrl
    Run-Cmd "az devops project list --org $org" { az devops project list --organization $org -o table } "AzureDevOps"
})
$btnListWI.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    Run-Cmd "az boards work-item list" {
        az boards query --wiql "SELECT [Id],[Title],[State],[AssignedTo] FROM WorkItems WHERE [System.TeamProject]='$proj' ORDER BY [System.ChangedDate] DESC" --project $proj --org $org -o table
    } "AzureDevOps"
})
$btnCreateWI.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim(); $title = $txtWITitle.Text.Trim()
    if (-not $proj)  { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    if (-not $title) { [System.Windows.Forms.MessageBox]::Show("Enter a work item title."); return }
    $type = $cboWIType.SelectedItem
    Run-Cmd "az boards work-item create --title `"$title`" --type $type" {
        az boards work-item create --title $title --type $type --project $proj --org $org
    } "AzureDevOps"
})
$btnGetWI.add_Click({
    $id = $txtWIId.Text.Trim()
    if (-not $id) { [System.Windows.Forms.MessageBox]::Show("Enter a work item ID."); return }
    Run-Cmd "az boards work-item show --id $id" { az boards work-item show --id $id } "AzureDevOps"
})
$btnListRepos.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    Run-Cmd "az repos list --project $proj" { az repos list --project $proj --org $org -o table } "AzureDevOps"
})
$btnListPRs.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    Run-Cmd "az repos pr list --project $proj" { az repos pr list --project $proj --org $org -o table } "AzureDevOps"
})
$btnCreatePR.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim()
    $repo = $txtRepo.Text.Trim(); $src = $txtSrcBranch.Text.Trim(); $tgt = $txtTargetBranch.Text.Trim()
    $title = $txtWITitle.Text.Trim()
    if (-not $proj -or -not $repo) { [System.Windows.Forms.MessageBox]::Show("Enter project and repo name."); return }
    Run-Cmd "az repos pr create ($src → $tgt)" {
        az repos pr create --repository $repo --source-branch $src --target-branch $tgt `
            --title $(if($title){"$title"}else{"PR: $src → $tgt"}) --project $proj --org $org
    } "AzureDevOps"
})
$btnListPipelines.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    Run-Cmd "az pipelines list --project $proj" { az pipelines list --project $proj --org $org -o table } "AzureDevOps"
})
$btnRunPipeline.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim(); $name = $txtPipelineName.Text.Trim()
    if (-not $proj -or -not $name) { [System.Windows.Forms.MessageBox]::Show("Enter project and pipeline name."); return }
    Run-Cmd "az pipelines run --name `"$name`"" {
        az pipelines run --name $name --project $proj --org $org
    } "AzureDevOps"
})
$btnPipelineRuns.add_Click({
    $org = Get-OrgUrl; $proj = $txtProject.Text.Trim(); $name = $txtPipelineName.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Enter a project name."); return }
    Run-Cmd "az pipelines runs list --project $proj" {
        $args_ = @("--project", $proj, "--org", $org, "-o", "table")
        if ($name) { $args_ += @("--pipeline-name", $name) }
        az pipelines runs list @args_
    } "AzureDevOps"
})

# ---- MCP ----
function Refresh-MCP {
    $raw = copilot mcp list 2>&1 | Out-String
    $mcpStatusBox.Text = $raw
    Write-Log "copilot mcp list" $raw "MCP"
}
$btnMCPList.add_Click({    Refresh-MCP })
$btnMCPRefresh.add_Click({ Refresh-MCP })
$btnMCPRemove.add_Click({
    $name = $txtMCPName.Text.Trim()
    if (-not $name) { [System.Windows.Forms.MessageBox]::Show("Enter server name to remove."); return }
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Remove MCP server '$name'?", "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -eq "Yes") {
        Run-Cmd "copilot mcp remove $name" { copilot mcp remove $name } "MCP"
        Refresh-MCP
    }
})

# ---- Output ----
$btnClearOutput.add_Click({ $Script:OutputBox.Clear() })
$btnCopyLog.add_Click({
    $summary = $Script:LogEntries | Select-Object -Last 20 | ForEach-Object {
        "[$($_.timestamp)] [$($_.category)] $($_.action)"
    }
    $text = "=== Dashboard Actions (last 20) ===`n" + ($summary -join "`n")
    [System.Windows.Forms.Clipboard]::SetText($text)
    $Script:OutputBox.SelectionColor = $C.Mauve
    $Script:OutputBox.AppendText("`r`n[Log copied! Paste into Copilot chat so I can see what you've done.]`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
})

# ---- Admin & Licence Analytics ----

$btnEnvWho.add_Click({        Run-Cmd "pac org who"          { pac org who }              "Admin" })
$btnEnvDetails.add_Click({    Run-Cmd "pac env who (details)" {
    $envUrl = Get-CurEnvUrl
    $envArg = if ($envUrl) { @("--environment", $envUrl) } else { @() }
    pac admin show @envArg
} "Admin" })
$btnGovernance.add_Click({    Run-Cmd "pac admin show-governance-config" {
    pac admin show-governance-config
} "Admin" })
$btnEnvCapacity.add_Click({   Run-Cmd "pac admin show-capacity" {
    pac admin show-capacity
} "Admin" })
$btnOpenPPAdmin2.add_Click({
    Start-Process "https://admin.powerplatform.microsoft.com/environments"
    Write-Log "Open PP Admin Centre" "" "Admin"
})

$btnLicenseSummary.add_Click({
    Run-Cmd "m365 tenant report getm365activationsuserdetail" {
        $raw = az rest --method get --url "https://graph.microsoft.com/v1.0/subscribedSkus" 2>&1 | Out-String
        try {
            $skus = ($raw | ConvertFrom-Json).value
            $skus | Select-Object skuPartNumber,
                @{N="Assigned";E={$_.prepaidUnits.enabled}},
                @{N="Used";E={$_.consumedUnits}},
                @{N="Available";E={$_.prepaidUnits.enabled - $_.consumedUnits}} |
                Sort-Object skuPartNumber | Format-Table -AutoSize
        } catch { "Run 'az login' first, then retry.`n$raw" }
    } "Admin"
})

$btnPowerAppsLic.add_Click({
    Run-Cmd "Graph: Power Apps licensed users" {
        $url = "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,assignedLicenses&`$top=100"
        $raw = az rest --method get --url $url 2>&1 | Out-String
        try {
            $users = ($raw | ConvertFrom-Json).value
            # Power Apps Per User SKU IDs (approximate — includes D365/PP bundles)
            $paParts = @("POWERAPPS_PER_USER","POWER_APPS_PER_APP","POWERAPPS_DEV","D365_ENTERPRISE")
            $skuRaw  = az rest --method get --url "https://graph.microsoft.com/v1.0/subscribedSkus" 2>&1 | Out-String
            $skuMap  = @{}
            try { ($skuRaw | ConvertFrom-Json).value | ForEach-Object { $skuMap[$_.skuId] = $_.skuPartNumber } } catch {}
            $pa = $users | Where-Object {
                $_.assignedLicenses | Where-Object {
                    $id = $skuMap[$_.skuId]
                    $paParts | Where-Object { $id -like "*$_*" }
                }
            } | Select-Object displayName, userPrincipalName
            if ($pa) { $pa | Format-Table -AutoSize } else { "No Power Apps licensed users found (or az login needed)." }
        } catch { "Run 'az login' first, then retry.`n$raw" }
    } "Admin"
})

$btnPowerAutomateLic.add_Click({
    Run-Cmd "Graph: Power Automate licensed users" {
        $url = "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,assignedLicenses&`$top=100"
        $raw = az rest --method get --url $url 2>&1 | Out-String
        try {
            $users = ($raw | ConvertFrom-Json).value
            $skuRaw = az rest --method get --url "https://graph.microsoft.com/v1.0/subscribedSkus" 2>&1 | Out-String
            $skuMap = @{}
            try { ($skuRaw | ConvertFrom-Json).value | ForEach-Object { $skuMap[$_.skuId] = $_.skuPartNumber } } catch {}
            $pa = $users | Where-Object {
                $_.assignedLicenses | Where-Object {
                    $id = $skuMap[$_.skuId]
                    $id -like "*FLOW*" -or $id -like "*POWER_AUTOMATE*"
                }
            } | Select-Object displayName, userPrincipalName
            if ($pa) { $pa | Format-Table -AutoSize } else { "No Power Automate licensed users found (or az login needed)." }
        } catch { "Run 'az login' first, then retry.`n$raw" }
    } "Admin"
})

$btnD365Lic.add_Click({
    Run-Cmd "Graph: D365 licensed users" {
        $url = "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,assignedLicenses&`$top=100"
        $raw = az rest --method get --url $url 2>&1 | Out-String
        try {
            $users = ($raw | ConvertFrom-Json).value
            $skuRaw = az rest --method get --url "https://graph.microsoft.com/v1.0/subscribedSkus" 2>&1 | Out-String
            $skuMap = @{}
            try { ($skuRaw | ConvertFrom-Json).value | ForEach-Object { $skuMap[$_.skuId] = $_.skuPartNumber } } catch {}
            $d365 = $users | Where-Object {
                $_.assignedLicenses | Where-Object { $skuMap[$_.skuId] -like "D365*" }
            } | Select-Object displayName, userPrincipalName
            if ($d365) { $d365 | Format-Table -AutoSize } else { "No D365 licensed users found (or az login needed)." }
        } catch { "Run 'az login' first, then retry.`n$raw" }
    } "Admin"
})

$btnDlpList.add_Click({       Run-Cmd "pac dlp policy list" { pac dlp policy list }  "Admin" })
$btnDlpCreate.add_Click({
    Start-Process "https://admin.powerplatform.microsoft.com/policies/data-policies"
    Write-Log "Open DLP Policy Wizard" "" "Admin"
})
$btnEnvUsers.add_Click({      Run-Cmd "pac admin list-environment-users" {
    $envUrl = Get-CurEnvUrl
    $envArg = if ($envUrl) { @("--environment", $envUrl) } else { @() }
    pac admin list-environment-users @envArg
} "Admin" })
$btnEnvGroups.add_Click({     Run-Cmd "pac admin list-security-groups" {
    $envUrl = Get-CurEnvUrl
    $envArg = if ($envUrl) { @("--environment", $envUrl) } else { @() }
    pac admin list-security-roles @envArg
} "Admin" })

$btnAppUsage.add_Click({
    Run-Cmd "Graph: App usage report (30d)" {
        $raw = az rest --method get --url "https://graph.microsoft.com/v1.0/reports/getM365AppUserDetail(period='D30')" 2>&1 | Out-String
        $Script:OutputBox.AppendText($raw)
    } "Admin"
})
$btnFlowUsage.add_Click({     Run-Cmd "pac flow list (all)" { pac flow list } "Admin" })
$btnConnUsage.add_Click({     Run-Cmd "pac connector list" { pac connector list } "Admin" })
$btnInventory.add_Click({
    Run-Cmd "Full PP Inventory (env + solutions + apps)" {
        "=== ENVIRONMENTS ==="
        pac env list
        "=== SOLUTIONS ==="
        pac solution list
        "=== CANVAS APPS ==="
        pac canvas list
        "=== CLOUD FLOWS ==="
        pac flow list
    } "Admin"
})

# ---- Deploy / Migrate ----

# Populate source & target env dropdowns whenever environments are loaded
function Refresh-DeployEnvDropdowns {
    $Script:cboSrcEnv.Items.Clear()
    $Script:cboTgtEnv.Items.Clear()
    foreach ($e in $Script:Environments) {
        $null = $Script:cboSrcEnv.Items.Add($e.Name)
        $null = $Script:cboTgtEnv.Items.Add($e.Name)
    }
    if ($Script:cboSrcEnv.Items.Count -gt 0) { $Script:cboSrcEnv.SelectedIndex = 0; $Script:cboTgtEnv.SelectedIndex = 0 }
}

# When target env combo changes, fill the URL textbox
$Script:cboTgtEnv.add_SelectedIndexChanged({
    $i = $Script:cboTgtEnv.SelectedIndex
    if ($i -ge 0 -and $Script:Environments.Count -gt $i) {
        $txtDeployTargetUrl.Text = $Script:Environments[$i].Url
    }
})

# Load solutions from selected source environment
$btnLoadSrcSols.add_Click({
    $i = $Script:cboSrcEnv.SelectedIndex
    if ($i -lt 0 -or $Script:Environments.Count -le $i) { [System.Windows.Forms.MessageBox]::Show("Select a source environment."); return }
    $srcUrl = $Script:Environments[$i].Url
    $Script:OutputBox.AppendText("`r`n▶ Loading solutions from: $srcUrl`r`n")
    $raw = pac solution list --environment $srcUrl 2>&1
    $Script:DeploySolutions = @()
    $Script:cboDeploySol.Items.Clear()
    foreach ($line in $raw) {
        if ($line -match '^(\S+)\s+(.+?)\s{2,}([\d\.]+)\s+(True|False)\s*$') {
            $sol = [PSCustomObject]@{ UniqueName = $Matches[1].Trim(); FriendlyName = $Matches[2].Trim(); Version = $Matches[3].Trim() }
            $Script:DeploySolutions += $sol
            $null = $Script:cboDeploySol.Items.Add("$($sol.FriendlyName)  [$($sol.UniqueName)]  v$($sol.Version)")
        }
    }
    if ($Script:cboDeploySol.Items.Count -gt 0) { $Script:cboDeploySol.SelectedIndex = 0 }
    $Script:OutputBox.SelectionColor = $C.Green
    $Script:OutputBox.AppendText("✅ $($Script:DeploySolutions.Count) solutions loaded.`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
})

# Auth to target tenant (cross-tenant deploy)
$btnAuthTarget.add_Click({
    $targetUrl    = $txtDeployTargetUrl.Text.Trim()
    $targetTenant = $txtDeployTenantId.Text.Trim()
    if (-not $targetUrl) { [System.Windows.Forms.MessageBox]::Show("Enter the Target URL first."); return }
    $Script:OutputBox.AppendText("`r`n▶ Authenticating to target environment (browser will open)...`r`n")
    $btnAuthTarget.Enabled = $false; $btnAuthTarget.Text = "⏳ Authenticating..."
    $args = if ($targetTenant) { @("auth", "create", "--environment", $targetUrl, "--tenant", $targetTenant) } `
            else               { @("auth", "create", "--environment", $targetUrl) }
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript("pac $($args -join ' ') 2>&1 | Out-String")
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 800
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) | Out-String } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $Script:OutputBox.SelectionColor = $Script:C.Green
            $Script:OutputBox.AppendText("✅ Auth complete:`r`n$result`r`n")
            $Script:OutputBox.SelectionColor = $Script:C.Text
            $btnAuthTarget.Enabled = $true; $btnAuthTarget.Text = "🔐 Auth to Target"
        }
    }); $timer.Start()
})

# 🚀 Main deploy button
$btnDeploy.add_Click({
    $solIdx = $Script:cboDeploySol.SelectedIndex
    if ($solIdx -lt 0 -or $Script:DeploySolutions.Count -le $solIdx) {
        [System.Windows.Forms.MessageBox]::Show("Load solutions from source first, then select one.")
        return
    }
    $srcIdx    = $Script:cboSrcEnv.SelectedIndex
    $srcUrl    = $Script:Environments[$srcIdx].Url
    $sol       = $Script:DeploySolutions[$solIdx]
    $targetUrl = $txtDeployTargetUrl.Text.Trim()
    if (-not $targetUrl) { [System.Windows.Forms.MessageBox]::Show("Enter or select a Target URL."); return }

    $tmpDir = $txtDeployTmp.Text.Trim()
    if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }
    $zipPath = Join-Path $tmpDir "$($sol.UniqueName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

    $isManaged  = $radManaged.Checked
    $overwrite  = $chkOverwrite.Checked
    $publish    = $chkPublish.Checked

    $btnDeploy.Enabled = $false; $btnDeploy.Text = "⏳ Deploying..."
    $Script:OutputBox.AppendText("`r`n🚀 Deploying '$($sol.FriendlyName)' [$($sol.UniqueName)]`r`n")
    $Script:OutputBox.AppendText("   Source : $srcUrl`r`n   Target : $targetUrl`r`n   Managed: $isManaged`r`n")
    $logQ = $Script:LogQueue

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($srcUrl, $solName, $zipPath, $isManaged, $targetUrl, $overwrite, $publish, $logQ)
        $logQ.Enqueue("  📤 Step 1/2 — Exporting '$solName' as $(if($isManaged){'managed'}else{'unmanaged'}) from source...")
        $exportArgs = @("solution", "export", "--path", $zipPath, "--name", $solName, "--environment", $srcUrl)
        if ($isManaged) { $exportArgs += "--managed" }
        $exportResult = pac @exportArgs 2>&1 | Out-String
        if (-not (Test-Path $zipPath)) {
            $logQ.Enqueue("  ❌ Export failed")
            return "❌ Export failed:`r`n$exportResult"
        }
        $kb = [Math]::Round((Get-Item $zipPath).Length / 1KB)
        $logQ.Enqueue("  ✅ Exported — ${kb} KB")
        $logQ.Enqueue("  📦 Step 2/2 — Importing into target environment (may take several minutes)...")
        $importArgs = @("solution", "import", "--path", $zipPath, "--environment", $targetUrl)
        if ($overwrite) { $importArgs += "--force-overwrite" }
        if ($publish)   { $importArgs += "--publish-changes" }
        $importResult = pac @importArgs 2>&1 | Out-String
        if ($importResult -match "succeeded|Import successful") {
            $logQ.Enqueue("  ✅ Import succeeded")
        } elseif ($importResult -match "error|failed") {
            $logQ.Enqueue("  ❌ Import reported errors — check output below")
        } else {
            $logQ.Enqueue("  ✅ Import complete")
        }
        return "EXPORT:`r`n$exportResult`r`nIMPORT:`r`n$importResult"
    }).AddParameters(@{
        srcUrl=$srcUrl; solName=$sol.UniqueName; zipPath=$zipPath
        isManaged=$isManaged; targetUrl=$targetUrl; overwrite=$overwrite; publish=$publish; logQ=$logQ
    })
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) | Out-String } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $btnDeploy.Enabled = $true; $btnDeploy.Text = "🚀  Deploy Solution"
            if ($result -match "❌|Export failed") {
                $Script:OutputBox.SelectionColor = $Script:C.Red
                $Script:OutputBox.AppendText("❌ Deploy FAILED — see details above`r`n")
            } else {
                $Script:OutputBox.SelectionColor = $Script:C.Green
                $Script:OutputBox.AppendText("✅ Deploy COMPLETE — '$($sol.UniqueName)' → $targetUrl`r`n")
            }
            $Script:OutputBox.SelectionColor = $Script:C.Text
            Write-Log "Deploy $($sol.UniqueName)" $result "Deploy"
        }
    }); $timer.Start()
})

# ---- Source Control handlers ----
$btnGitStatus.add_Click({
    $repo = $txtRepoPath.Text.Trim()
    Run-Cmd "git status" {
        Set-Location $repo
        git status
        git log --oneline -5
    } "SourceControl"
})

$btnGitPull.add_Click({
    $repo = $txtRepoPath.Text.Trim()
    Run-Cmd "git pull" { Set-Location $repo; git pull } "SourceControl"
})

$btnUnpackCommit.add_Click({
    $solIdx = $Script:cboDeploySol.SelectedIndex
    if ($solIdx -lt 0 -or $Script:DeploySolutions.Count -le $solIdx) {
        [System.Windows.Forms.MessageBox]::Show("Load solutions from source and select one first.")
        return
    }
    $sol     = $Script:DeploySolutions[$solIdx]
    $srcIdx  = $Script:cboSrcEnv.SelectedIndex
    $srcUrl  = $Script:Environments[$srcIdx].Url
    $repo    = $txtRepoPath.Text.Trim()
    $branch  = $txtGitBranch.Text.Trim()
    $zipPath = Join-Path $env:TEMP "$($sol.UniqueName)_export.zip"
    $srcDir  = Join-Path $repo "src\$($sol.UniqueName)"

    $btnUnpackCommit.Enabled = $false; $btnUnpackCommit.Text = "⏳ Working..."
    $Script:OutputBox.AppendText("`r`n▶ Export → Unpack → Commit '$($sol.UniqueName)'`r`n")
    $logQ = $Script:LogQueue

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($srcUrl,$solName,$zipPath,$srcDir,$repo,$branch,$logQ)
        Set-Location $repo
        $logQ.Enqueue("  🌿 Step 1/4 — Switching to branch '$branch'...")
        git fetch origin 2>&1 | Out-Null
        $branches = git branch --list $branch
        if (-not $branches) { git checkout -b $branch 2>&1 | Out-Null } else { git checkout $branch 2>&1 | Out-Null }
        $logQ.Enqueue("  ✅ On branch '$branch'")
        $logQ.Enqueue("  📤 Step 2/4 — Exporting '$solName' from environment...")
        $export = pac solution export --path $zipPath --name $solName --environment $srcUrl 2>&1 | Out-String
        if (-not (Test-Path $zipPath)) {
            $logQ.Enqueue("  ❌ Export failed")
            return "❌ Export failed:`r`n$export"
        }
        $kb = [Math]::Round((Get-Item $zipPath).Length / 1KB)
        $logQ.Enqueue("  ✅ Exported — ${kb} KB")
        $logQ.Enqueue("  📦 Step 3/4 — Unpacking YAML files to $srcDir...")
        if (Test-Path $srcDir) { Remove-Item $srcDir -Recurse -Force }
        $unpack = pac solution unpack --zipfile $zipPath --folder $srcDir --packagetype Unmanaged 2>&1 | Out-String
        $fileCount = (Get-ChildItem $srcDir -Recurse -File -ErrorAction SilentlyContinue).Count
        $logQ.Enqueue("  ✅ Unpacked — $fileCount files")
        $logQ.Enqueue("  💾 Step 4/4 — Staging and committing changes...")
        git add "src/$solName/" 2>&1 | Out-Null
        $diff = git diff --staged --stat
        if ($diff) {
            git commit -m "chore: export $solName from dev [dashboard]" 2>&1 | Out-Null
            $logQ.Enqueue("  ✅ Committed — push when ready")
            return "✅ Exported, unpacked and committed:`r`n$diff"
        } else {
            $logQ.Enqueue("  ℹ No changes since last export")
            return "ℹ No changes to commit — solution unchanged since last export."
        }
    }).AddParameters(@{srcUrl=$srcUrl;solName=$sol.UniqueName;zipPath=$zipPath;srcDir=$srcDir;repo=$repo;branch=$branch;logQ=$logQ})
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) | Out-String } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $btnUnpackCommit.Enabled = $true; $btnUnpackCommit.Text = "📦 Export+Unpack+Commit"
            if ($result -match "❌") {
                $Script:OutputBox.SelectionColor = $Script:C.Red
                $Script:OutputBox.AppendText("❌ Export/Unpack/Commit FAILED — see details above`r`n")
            } elseif ($result -match "ℹ No changes") {
                $Script:OutputBox.SelectionColor = $Script:C.Sky
                $Script:OutputBox.AppendText("ℹ No changes to commit — '$($sol.UniqueName)' is up to date`r`n")
            } else {
                $Script:OutputBox.SelectionColor = $Script:C.Green
                $Script:OutputBox.AppendText("✅ Export+Unpack+Commit COMPLETE — '$($sol.UniqueName)'`r`n")
            }
            $Script:OutputBox.SelectionColor = $Script:C.Text
            Write-Log "Export+Unpack+Commit $($sol.UniqueName)" $result "SourceControl"
        }
    }); $timer.Start()
})

$btnTopSwitch.add_Click({
    $idx = $cboTopEnv.SelectedIndex
    if ($idx -lt 0 -or $Script:Environments.Count -le $idx) {
        [System.Windows.Forms.MessageBox]::Show("Load environments first (Environments tab → Load).")
        return
    }
    $env = $Script:Environments[$idx]
    Run-Cmd "pac env select $($env.Url)" {
        pac env select --environment $env.Url 2>&1
    } "Environments"
    $envStatusLbl.Text = "✅ $($env.Name)"
})

# ---- GitHub Explorer handlers ----
function Refresh-GHRepos {
    $Script:OutputBox.AppendText("`r`n🐙 Fetching GitHub repos...`r`n")
    $raw = gh repo list --limit 100 --json nameWithOwner,url,defaultBranchRef 2>&1 | Out-String
    try {
        $repos = $raw | ConvertFrom-Json
        $Script:GHRepos = $repos
        $Script:cboGHRepo.Items.Clear()
        foreach ($r in $repos) { $Script:cboGHRepo.Items.Add($r.nameWithOwner) | Out-Null }
        if ($Script:cboGHRepo.Items.Count -gt 0) { $Script:cboGHRepo.SelectedIndex = 0 }
        $Script:OutputBox.SelectionColor = $Script:C.Green
        $Script:OutputBox.AppendText("✅ $($repos.Count) repos loaded`r`n")
        $Script:OutputBox.SelectionColor = $Script:C.Text
    } catch {
        $Script:OutputBox.SelectionColor = $Script:C.Red
        $Script:OutputBox.AppendText("❌ Could not list repos — run 'gh auth login' first`r`n")
        $Script:OutputBox.SelectionColor = $Script:C.Text
    }
}

function Refresh-GHBranches {
    $idx = $Script:cboGHRepo.SelectedIndex
    if ($idx -lt 0 -or -not $Script:GHRepos) { return }
    $repo = $Script:GHRepos[$idx].nameWithOwner
    $raw  = gh api "repos/$repo/branches" 2>&1 | Out-String
    try {
        $branches = $raw | ConvertFrom-Json
        $Script:cboGHBranch.Items.Clear()
        foreach ($b in $branches) { $Script:cboGHBranch.Items.Add($b.name) | Out-Null }
        if ($Script:cboGHBranch.Items.Count -gt 0) { $Script:cboGHBranch.SelectedIndex = 0 }
    } catch { }
}

function Refresh-GHCommits {
    $idx = $Script:cboGHRepo.SelectedIndex
    if ($idx -lt 0 -or -not $Script:GHRepos) { return }
    $repo   = $Script:GHRepos[$idx].nameWithOwner
    $branch = if ($Script:cboGHBranch.SelectedItem) { $Script:cboGHBranch.SelectedItem } else { "main" }
    $solName = $txtSolName.Text.Trim()
    $path   = if ($solName) { "&path=solutions/$solName" } else { "" }
    $raw    = gh api "repos/$repo/commits?sha=$branch&per_page=10$path" 2>&1 | Out-String
    $Script:DgGHCommits.Rows.Clear()
    try {
        $commits = $raw | ConvertFrom-Json
        $Script:GHLastCommits = $commits
        foreach ($c in $commits) {
            $when   = try { ([datetime]$c.commit.author.date).ToString("MM/dd HH:mm") } catch { "" }
            $author = $c.commit.author.name
            $msg    = $c.commit.message -replace "`n.*",""   # first line only
            $sha    = $c.sha.Substring(0,7)
            $null   = $Script:DgGHCommits.Rows.Add($when, $author, $msg, $sha)
        }
    } catch { }
}

$Script:cboGHRepo.add_SelectedIndexChanged({ Refresh-GHBranches; Refresh-GHCommits })
$Script:cboGHBranch.add_SelectedIndexChanged({ Refresh-GHCommits })

$btnGHRefresh.add_Click({ Refresh-GHRepos })

$btnGHOpen.add_Click({
    $idx = $Script:cboGHRepo.SelectedIndex
    $url = if ($idx -ge 0 -and $Script:GHRepos) { $Script:GHRepos[$idx].url } else { "https://github.com" }
    Start-Process $url
})

$btnGHNewRepo.add_Click({
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("New GitHub repo name:","Create Repo","veldarr-powerplatform")
    if (-not $name) { return }
    $vis = [System.Windows.Forms.MessageBox]::Show("Make repo private?","Visibility",[System.Windows.Forms.MessageBoxButtons]::YesNo)
    $flag = if ($vis -eq "Yes") { "--private" } else { "--public" }
    gh repo create $name $flag 2>&1 | Out-Null
    $Script:OutputBox.SelectionColor = $Script:C.Green
    $Script:OutputBox.AppendText("✅ Created GitHub repo: $name`r`n")
    $Script:OutputBox.SelectionColor = $Script:C.Text
    Refresh-GHRepos
})

$btnGHAskAi.add_Click({
    $idx = $Script:cboGHRepo.SelectedIndex
    if ($idx -lt 0 -or -not $Script:GHRepos) { [System.Windows.Forms.MessageBox]::Show("Click 🔄 Refresh to load repos first."); return }
    $repo    = $Script:GHRepos[$idx].nameWithOwner
    $branch  = if ($Script:cboGHBranch.SelectedItem) { $Script:cboGHBranch.SelectedItem } else { "main" }
    $solName = $txtSolName.Text.Trim()
    $cmd     = $txtGHAiCmd.Text.Trim()

    $Script:OutputBox.AppendText("`r`n🤖 Gathering context from GitHub for AI...`r`n")

    # Get diff of last commit
    $commits = $Script:GHLastCommits
    $context = ""
    if ($commits -and $commits.Count -gt 0) {
        $sha  = $commits[0].sha
        $diff = gh api "repos/$repo/commits/$sha" 2>&1 | Out-String
        try {
            $d = $diff | ConvertFrom-Json
            $files = $d.files | ForEach-Object { "  $($_.status): $($_.filename) (+$($_.additions)/-$($_.deletions))" }
            $context = "Latest commit on $branch by $($d.commit.author.name):`r`n$($d.commit.message)`r`n`r`nFiles changed:`r`n$($files -join "`r`n")"
        } catch { $context = $diff.Substring(0,[Math]::Min(3000,$diff.Length)) }
    }

    $prompt = "$cmd`r`n`r`nGitHub repo: $repo  Branch: $branch  Solution: $solName`r`n`r`n$context"
    $aiResult = Invoke-AiRequest $prompt
    $Script:OutputBox.SelectionColor = $Script:C.Mauve
    $Script:OutputBox.AppendText("🤖 AI:`r`n$aiResult`r`n")
    $Script:OutputBox.SelectionColor = $Script:C.Text
})

$btnSolSyncGH.add_Click({
    $solIdx = $Script:cboSolutions.SelectedIndex
    if ($solIdx -lt 0 -or -not $Script:Solutions) {
        [System.Windows.Forms.MessageBox]::Show("Select a solution first (use 'List Solutions' at the top)."); return
    }
    $ghIdx = $Script:cboGHRepo.SelectedIndex
    if ($ghIdx -lt 0 -or -not $Script:GHRepos) {
        [System.Windows.Forms.MessageBox]::Show("Click 🔄 Refresh to pick a GitHub repo first."); return
    }
    $sol     = $Script:Solutions[$solIdx]
    $repoNWO = $Script:GHRepos[$ghIdx].nameWithOwner   # "owner/repo"
    $branch  = if ($Script:cboGHBranch.SelectedItem) { $Script:cboGHBranch.SelectedItem } else { "main" }
    $envUrl  = if ($Script:Environments.Count -gt 0 -and $cboTopEnv.SelectedIndex -ge 0) { $Script:Environments[$cboTopEnv.SelectedIndex].Url } else { "" }
    if (-not $envUrl) { [System.Windows.Forms.MessageBox]::Show("No environment selected — use the top switcher."); return }

    $btnSolSyncGH.Enabled = $false; $btnSolSyncGH.Text = "⏳ Working..."
    $Script:OutputBox.AppendText("`r`n📤 Pushing '$($sol.UniqueName)' → $repoNWO ($branch)`r`n")

    $logQ = $Script:LogQueue
    $rs = [runspacefactory]::CreateRunspace(); $rs.ApartmentState="STA"; $rs.ThreadOptions="ReuseThread"; $rs.Open()
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($envUrl, $solName, $repoNWO, $branch, $logQ)
        $tmpBase  = Join-Path $env:TEMP "ppdash_$solName"
        $zipPath  = "$tmpBase.zip"
        $unpackDir = "$tmpBase`_src"
        $cloneDir  = "$tmpBase`_clone"

        try {
            $logQ.Enqueue("  📤 Step 1/4 — Exporting '$solName' from environment...")
            $export = pac solution export --path $zipPath --name $solName --environment $envUrl 2>&1 | Out-String
            if (-not (Test-Path $zipPath)) { return "❌ Export failed: $export" }
            $logQ.Enqueue("  ✅ Exported — $(([System.IO.FileInfo]$zipPath).Length / 1KB -as [int]) KB")

            $logQ.Enqueue("  📦 Step 2/4 — Unpacking solution files...")
            if (Test-Path $unpackDir) { Remove-Item $unpackDir -Recurse -Force }
            pac solution unpack --zipfile $zipPath --folder $unpackDir --packagetype Unmanaged 2>&1 | Out-Null
            $fileCount = (Get-ChildItem $unpackDir -Recurse -File -ErrorAction SilentlyContinue).Count
            $logQ.Enqueue("  ✅ Unpacked — $fileCount files")

            $logQ.Enqueue("  ⬇ Step 3/4 — Cloning $repoNWO to temp folder...")
            if (Test-Path $cloneDir) { Remove-Item $cloneDir -Recurse -Force }
            gh repo clone $repoNWO $cloneDir -- --depth 1 --branch $branch 2>&1 | Out-Null
            if (-not (Test-Path $cloneDir)) { return "❌ Clone failed — check gh auth and repo name" }

            # Copy unpacked files into solutions/<solName>/
            $dest = Join-Path $cloneDir "solutions\$solName"
            if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
            Copy-Item $unpackDir $dest -Recurse -Force

            # Diff check
            $diffStat = git -C $cloneDir diff --stat HEAD 2>&1 | Out-String
            $diffFull = git -C $cloneDir diff HEAD 2>&1 | Out-String

            $logQ.Enqueue("  ⬆ Step 4/4 — Committing and pushing to $repoNWO/$branch...")
            git -C $cloneDir add "solutions/$solName/" 2>&1 | Out-Null
            $status = git -C $cloneDir status --short 2>&1 | Out-String
            if (-not $status.Trim()) {
                $logQ.Enqueue("  ℹ No changes — solution unchanged since last push")
                return [PSCustomObject]@{ SolName=$solName; Stat="No changes"; Full=""; NoChange=$true }
            }
            git -C $cloneDir commit -m "sync: $solName from env [pp-dashboard]" 2>&1 | Out-Null
            git -C $cloneDir push origin $branch 2>&1 | Out-Null
            $logQ.Enqueue("  ✅ Pushed to $repoNWO/$branch")

            return [PSCustomObject]@{ SolName=$solName; Stat=$diffStat; Full=$diffFull; NoChange=$false }
        } catch {
            return "❌ Error: $($_.Exception.Message)"
        } finally {
            Remove-Item $zipPath    -Force -ErrorAction SilentlyContinue
            Remove-Item $unpackDir  -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $cloneDir   -Recurse -Force -ErrorAction SilentlyContinue
        }
    }).AddParameters(@{envUrl=$envUrl; solName=$sol.UniqueName; repoNWO=$repoNWO; branch=$branch; logQ=$logQ})

    $handle = $ps.BeginInvoke()
    $timer  = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $btnSolSyncGH.Enabled = $true; $btnSolSyncGH.Text = "📤  Export from Environment → Unpack → Push to GitHub  (no local folder needed)"
            if ($result -is [string]) {
                $Script:OutputBox.SelectionColor = $Script:C.Red
                $Script:OutputBox.AppendText("❌ Push FAILED: $result`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
                return
            }
            if ($result.NoChange) {
                $Script:OutputBox.SelectionColor = $Script:C.Sky
                $Script:OutputBox.AppendText("ℹ No changes — '$($result.SolName)' is already up to date in GitHub`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
                return
            }
            $Script:OutputBox.SelectionColor = $Script:C.Green
            $Script:OutputBox.AppendText("✅ '$($result.SolName)' pushed to GitHub!`r`n")
            $Script:OutputBox.SelectionColor = $Script:C.Sky
            $Script:OutputBox.AppendText("📊 Changes:`r`n$($result.Stat)`r`n")
            $Script:OutputBox.SelectionColor = $Script:C.Text
            Refresh-GHCommits
            # AI summary
            $aiCfg = if (Test-Path $Script:AiSettingsPath) { Get-Content $Script:AiSettingsPath -Raw | ConvertFrom-Json } else { $null }
            if ($null -ne $aiCfg -and $aiCfg.ai.provider -ne "clipboard") {
                $prompt = "Summarize these Power Platform solution changes in plain English for a non-developer. What components changed and why might it matter?`r`n`r`n$($result.Stat)`r`n`r`n$($result.Full.Substring(0,[Math]::Min(3000,$result.Full.Length)))"
                $aiResult = Invoke-AiRequest $prompt
                $Script:OutputBox.SelectionColor = $Script:C.Mauve
                $Script:OutputBox.AppendText("🤖 AI Summary:`r`n$aiResult`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
            } else {
                $clip = "Power Platform solution '$($result.SolName)' was just pushed to GitHub. Changes:`r`n$($result.Stat)`r`n`r`nPlease summarise what changed in plain English."
                [System.Windows.Forms.Clipboard]::SetText($clip)
                $Script:OutputBox.SelectionColor = $Script:C.Teal
                $Script:OutputBox.AppendText("📋 Summary prompt copied to clipboard — paste into your AI chat`r`n")
                $Script:OutputBox.SelectionColor = $Script:C.Text
            }
        }
    }); $timer.Start()
})

$btnGitPush.add_Click({
    $repo   = $txtRepoPath.Text.Trim()
    $branch = $txtGitBranch.Text.Trim()
    Run-Cmd "git push origin $branch" {
        Set-Location $repo
        git push origin $branch --set-upstream 2>&1
        "Push complete. Open a PR in GitHub or Azure DevOps to merge to main."
    } "SourceControl"
})

# ── ALM Tools handlers ─────────────────────────────────────────────────────────
$btnBrowseMsapp.add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Canvas App (*.msapp)|*.msapp"; $dlg.Title = "Select .msapp file"
    if ($dlg.ShowDialog() -eq "OK") { $txtCanvasMsapp.Text = $dlg.FileName }
})

$btnBrowseEnvVars.add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "JSON files (*.json)|*.json"; $dlg.Title = "Select env-variables.json"
    if ($dlg.ShowDialog() -eq "OK") { $txtDisposableEnvVars.Text = $dlg.FileName }
})

$btnCanvasUnpack.add_Click({
    $msapp  = $txtCanvasMsapp.Text.Trim()
    $outDir = $txtCanvasUnpackDir.Text.Trim()
    if (-not $msapp) { [System.Windows.Forms.MessageBox]::Show("Select a .msapp file first."); return }
    Run-Cmd "pac canvas unpack" {
        if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
        pac canvas unpack --msapp $msapp --sources $outDir 2>&1
    } "CanvasAI"
})

$btnCanvasRename.add_Click({
    $outDir = $txtCanvasUnpackDir.Text.Trim()
    if (-not (Test-Path $outDir)) { [System.Windows.Forms.MessageBox]::Show("Unpack the .msapp first."); return }
    # Gather control names from YAML files
    $yamls = Get-ChildItem $outDir -Recurse -Filter "*.yaml" | Where-Object { $_.Name -ne "ControlTemplates.yaml" }
    $controlList = @()
    foreach ($y in $yamls) {
        $lines = Get-Content $y.FullName | Where-Object { $_ -match '^\s*- Control:' }
        $controlList += $lines | ForEach-Object { ($_ -replace '.*Control:\s*','').Trim() }
    }
    $prompt = "You are a Power Apps naming expert. The following are auto-generated control names in a Canvas app. For each name, suggest a better, descriptive camelCase name based on context clues. Return ONLY a JSON array: [{`"old`":`"Label1`",`"new`":`"lblCustomerName`"},...].`n`nControls:`n$($controlList -join ', ')"
    $Script:OutputBox.AppendText("`r`n🤖 Asking AI to suggest control renames...`r`n")
    $Script:_CanvasRenameResult = $null
    $rs = [runspacefactory]::CreateRunspace(); $rs.Open()
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({ param($p,$s) Invoke-AiRequest $p }).AddParameters(@{p=$prompt;s=$Script:AiSettingsPath})
    # Fallback: run synchronously since Invoke-AiRequest is in main scope
    $aiResult = Invoke-AiRequest $prompt
    $Script:OutputBox.SelectionColor = $C.Mauve
    $Script:OutputBox.AppendText("🤖 Rename suggestions:`r`n$aiResult`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
    $Script:OutputBox.AppendText("💡 Review the suggestions above, then click '✅ Apply & Repack' — or edit the YAML files in $outDir manually.`r`n")
    $Script:_CanvasRenameJson = $aiResult
    $ps.Dispose(); $rs.Dispose()
})

$btnCanvasComment.add_Click({
    $outDir = $txtCanvasUnpackDir.Text.Trim()
    if (-not (Test-Path $outDir)) { [System.Windows.Forms.MessageBox]::Show("Unpack the .msapp first."); return }
    $yamls = Get-ChildItem $outDir -Recurse -Filter "*.yaml" | Select-Object -First 3
    $sample = ($yamls | ForEach-Object { "--- $($_.Name) ---`n$(Get-Content $_.FullName -Raw | Select-Object -First 40)" }) -join "`n"
    $prompt = "You are a Power Apps expert. Review the following Canvas app YAML and write developer comments (as YAML comments using #) explaining what each control group does. Return the improved YAML with # comments added.`n`n$sample"
    $Script:OutputBox.AppendText("`r`n🤖 Asking AI to generate comments...`r`n")
    $aiResult = Invoke-AiRequest $prompt
    $Script:OutputBox.SelectionColor = $C.Blue
    $Script:OutputBox.AppendText("🤖 Commented YAML (first 3 files):`r`n$aiResult`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
    $Script:OutputBox.AppendText("💡 Manually apply the comments to the YAML files in $outDir, then click '✅ Apply & Repack'.`r`n")
})

$btnCanvasRepack.add_Click({
    $msapp  = $txtCanvasMsapp.Text.Trim()
    $outDir = $txtCanvasUnpackDir.Text.Trim()
    if (-not (Test-Path $outDir)) { [System.Windows.Forms.MessageBox]::Show("Nothing to repack — unpack first."); return }
    $backupPath = $msapp -replace '\.msapp$', "_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').msapp"
    Copy-Item $msapp $backupPath -ErrorAction SilentlyContinue
    Run-Cmd "pac canvas pack" {
        pac canvas pack --msapp $msapp --sources $outDir 2>&1
        "✅ Repacked to $msapp (backup saved as $backupPath)"
    } "CanvasAI"
})

# ── Disposable Environments handlers ───────────────────────────────────────────
$form.add_Shown({ if ($Script:Solutions) { foreach ($s in $Script:Solutions) { $null = $cboDisposableSol.Items.Add($s.FriendlyName) }; if ($cboDisposableSol.Items.Count) { $cboDisposableSol.SelectedIndex = 0 } } })

$btnListDisposable.add_Click({
    Run-Cmd "pac admin list" { pac admin list 2>&1 | Where-Object { $_ -match 'Sandbox|Trial|Developer' } } "DisposableEnv"
})

$btnDeleteDisposable.add_Click({
    if ($lstDisposableEnvs.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select environment(s) to delete from the list below."); return
    }
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Delete $($lstDisposableEnvs.SelectedItems.Count) environment(s)?`r`nThis CANNOT be undone.",
        "Confirm Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne "Yes") { return }
    foreach ($item in @($lstDisposableEnvs.SelectedItems)) {
        $env = $Script:DisposableEnvs | Where-Object { "$($_.Name)  [$($_.Url)]" -eq $item }
        if ($env) {
            Run-Cmd "pac admin delete $($env.Url)" {
                pac admin delete --environment $env.Url 2>&1
            } "DisposableEnv"
            $Script:DisposableEnvs.Remove($env)
            $lstDisposableEnvs.Items.Remove($item)
        }
    }
})

$btnDisposableCreate.add_Click({
    $envName = $txtDisposableEnvName.Text.Trim()
    $region  = $cboDisposableRegion.SelectedItem
    $type    = $cboDisposableType.SelectedItem
    $solIdx  = $cboDisposableSol.SelectedIndex
    $managed = $radDisposableManaged.Checked
    $evJson  = $txtDisposableEnvVars.Text.Trim()

    if (-not $envName) { [System.Windows.Forms.MessageBox]::Show("Enter an environment name."); return }

    $btnDisposableCreate.Enabled = $false; $btnDisposableCreate.Text = "⏳ Creating environment..."
    $Script:OutputBox.AppendText("`r`n🧪 Creating disposable environment '$envName'...`r`n")

    $solUniqueName = if ($solIdx -ge 0 -and $Script:Solutions.Count -gt $solIdx) { $Script:Solutions[$solIdx].UniqueName } else { "" }
    $managedStr    = if ($managed) { "true" } else { "false" }
    $logQ          = $Script:LogQueue

    $rs = [runspacefactory]::CreateRunspace(); $rs.Open()
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($envName,$region,$type,$solUniqueName,$managed,$evJson,$aiPath,$logQ)
        $logQ.Enqueue("  ⚙️ Step 1/3 — Calling pac admin create for '$envName' ($type, $region)...")
        $create = pac admin create --name $envName --type $type --region $region --currency USD --language 1033 2>&1 | Out-String
        $urlMatch = [regex]::Match($create, 'https://[a-z0-9]+\.crm\d*\.dynamics\.com/?')
        if (-not $urlMatch.Success) { return "❌ Could not create env:`r`n$create" }
        $newUrl = $urlMatch.Value; if (-not $newUrl.EndsWith('/')) { $newUrl += '/' }
        $logQ.Enqueue("  ✅ Environment created: $newUrl")
        if ($evJson -and (Test-Path $evJson)) {
            $vars = Get-Content $evJson -Raw | ConvertFrom-Json
            $logQ.Enqueue("  🔧 Step 2/3 — Applying $($vars.Count) environment variable(s)...")
            foreach ($v in $vars) { $logQ.Enqueue("    → $($v.schemaName)"); pac env update-setting --name $v.schemaName --value $v.value --environment $newUrl 2>&1 | Out-Null }
            $logQ.Enqueue("  ✅ Env vars applied")
        } else { $logQ.Enqueue("  ⏭ Step 2/3 — No env vars file, skipping") }
        if ($solUniqueName) {
            $logQ.Enqueue("  📦 Step 3/3 — Exporting '$solUniqueName' then importing as $(if($managed -eq 'true'){'managed'}else{'unmanaged'})...")
            $zipPath = Join-Path $env:TEMP "${solUniqueName}_disposable.zip"
            pac solution export --name $solUniqueName --path $zipPath 2>&1 | Out-Null
            if (Test-Path $zipPath) {
                $logQ.Enqueue("  ⬆ Importing into new environment...")
                pac solution import --path $zipPath --environment $newUrl --managed:$($managed -eq 'true') --async false 2>&1 | Out-Null
                $logQ.Enqueue("  ✅ Solution deployed")
                Remove-Item $zipPath -Force
            } else { $logQ.Enqueue("  ⚠ Export failed — solution not deployed") }
        } else { $logQ.Enqueue("  ⏭ Step 3/3 — No solution selected, skipping") }
        $summaryPrompt = "A new Power Platform environment called '$envName' ($type, $region) was just created. Solution '$solUniqueName' was deployed as $(if($managed -eq 'true'){'managed'}else{'unmanaged'}). Write 2 plain-English sentences for a non-developer explaining what this environment is for."
        return [PSCustomObject]@{ Url=$newUrl; Name=$envName; AiPrompt=$summaryPrompt }
    }).AddParameters(@{envName=$envName;region=$region;type=$type;solUniqueName=$solUniqueName;managed=$managedStr;evJson=$evJson;aiPath=$Script:AiSettingsPath;logQ=$logQ})

    $handle = $ps.BeginInvoke()
    $timer  = New-Object System.Windows.Forms.Timer; $timer.Interval = 2000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $res = try { $ps.EndInvoke($handle) } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $btnDisposableCreate.Enabled = $true
            $btnDisposableCreate.Text    = "🧪  Create Environment · Apply Variables · Deploy Solution  (AI-powered)"
            if ($res -is [string]) {
                $Script:OutputBox.SelectionColor = $Script:C.Red; $Script:OutputBox.AppendText("❌ Env creation FAILED: $res`r`n"); $Script:OutputBox.SelectionColor = $Script:C.Text; return
            }
            $Script:OutputBox.SelectionColor = $Script:C.Green
            $Script:OutputBox.AppendText("✅ Environment ready: $($res.Url)`r`n")
            if ($res.EnvVars) { $Script:OutputBox.AppendText("🔧 $($res.EnvVars)`r`n") }
            if ($res.Deploy)  { $Script:OutputBox.AppendText("📦 Deploy: $($res.Deploy)`r`n") }
            $Script:OutputBox.SelectionColor = $Script:C.Text
            # Track in list
            $entry = [PSCustomObject]@{ Name=$res.Name; Url=$res.Url }
            $null  = $Script:DisposableEnvs.Add($entry)
            $lstDisposableEnvs.Items.Add("$($res.Name)  [$($res.Url)]") | Out-Null
            # AI summary
            $aiSummary = Invoke-AiRequest $res.AiPrompt
            $Script:OutputBox.SelectionColor = $Script:C.Mauve
            $Script:OutputBox.AppendText("🤖 $aiSummary`r`n")
            $Script:OutputBox.SelectionColor = $Script:C.Text
            # Update top env combo
            Load-Environments
        }
    }); $timer.Start()
})

# ---- Code Review handlers ----
function Get-ReviewRepo { $txtReviewRepo.Text.Trim() }
function Get-ReviewBase { $txtReviewBase.Text.Trim() }
function Get-ReviewHead { $txtReviewHead.Text.Trim() }

$btnReviewDiff.add_Click({
    $repo = Get-ReviewRepo; $base = Get-ReviewBase; $head = Get-ReviewHead
    Run-Cmd "git diff $base..$head" {
        Set-Location $repo
        git diff $base..$head
    } "CodeReview"
})

$btnReviewLog.add_Click({
    $repo = Get-ReviewRepo; $base = Get-ReviewBase; $head = Get-ReviewHead
    Run-Cmd "git log $base..$head" {
        Set-Location $repo
        git log --oneline --graph --decorate $base..$head
    } "CodeReview"
})

$btnReviewChanged.add_Click({
    $repo = Get-ReviewRepo; $base = Get-ReviewBase; $head = Get-ReviewHead
    Run-Cmd "git diff --name-status $base..$head" {
        Set-Location $repo
        git diff --name-status $base..$head
    } "CodeReview"
})

$btnReviewBlame.add_Click({
    $repo = Get-ReviewRepo
    Run-Cmd "git shortlog" {
        Set-Location $repo
        git shortlog -sn --all
    } "CodeReview"
})

$btnReviewStats.add_Click({
    $repo = Get-ReviewRepo; $base = Get-ReviewBase; $head = Get-ReviewHead
    Run-Cmd "git diff --stat $base..$head" {
        Set-Location $repo
        git diff --stat $base..$head
        "`r`n--- Insertions / Deletions summary ---"
        git diff --shortstat $base..$head
    } "CodeReview"
})

$btnBrowseChecker.add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Solution files (*.zip)|*.zip|All files (*.*)|*.*"
    $dlg.Title  = "Select solution zip"
    if ($dlg.ShowDialog() -eq "OK") { $txtCheckerPath.Text = $dlg.FileName }
})

$Script:CheckerReportPath = ""
$btnRunChecker.add_Click({
    $path = $txtCheckerPath.Text.Trim()
    if (-not $path) { [System.Windows.Forms.MessageBox]::Show("Select a solution zip first."); return }
    $ruleset = $cboRuleset.SelectedItem.ToString()
    $outDir  = Join-Path $env:TEMP "pac_checker_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $Script:CheckerReportPath = $outDir
    $btnRunChecker.Enabled = $false; $btnRunChecker.Text = "⏳ Running..."
    $Script:OutputBox.AppendText("`r`n▶ Running Solution Checker (ruleset: $ruleset)...`r`n")
    $logQ = $Script:LogQueue

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript({
        param($path, $ruleset, $outDir, $logQ)
        $logQ.Enqueue("  🔍 Uploading to Solution Checker service (this usually takes 2–10 minutes)...")
        $result = pac solution check --path $path --ruleset $ruleset --outputDirectory $outDir 2>&1 | Out-String
        $issueCount = ([regex]::Matches($result, 'Critical|High|Medium|Low')).Count
        if ($result -match "error|critical" -and $result -notmatch "0 error") {
            $logQ.Enqueue("  ❌ Checker found issues — see report below")
        } elseif ($result -match "warning") {
            $logQ.Enqueue("  ⚠ Checker complete — warnings found ($issueCount issue mentions)")
        } else {
            $logQ.Enqueue("  ✅ Checker complete — no critical issues")
        }
        $logQ.Enqueue("  📊 Report saved to: $outDir")
        $result
    }).AddParameters(@{path=$path; ruleset=$ruleset; outDir=$outDir; logQ=$logQ})
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $result = try { $ps.EndInvoke($handle) | Out-String } catch { $_.Exception.Message }
            $ps.Dispose(); $rs.Dispose()
            $btnRunChecker.Enabled = $true; $btnRunChecker.Text = "🔍 Run Solution Checker"
            if ($result -match "error|critical" -and $result -notmatch "0 error") {
                $Script:OutputBox.SelectionColor = $Script:C.Red
                $Script:OutputBox.AppendText("❌ Solution Checker found critical issues — review report at: $outDir`r`n")
            } elseif ($result -match "warning") {
                $Script:OutputBox.SelectionColor = $Script:C.Peach
                $Script:OutputBox.AppendText("⚠ Solution Checker complete — warnings found. Report: $outDir`r`n")
            } else {
                $Script:OutputBox.SelectionColor = $Script:C.Green
                $Script:OutputBox.AppendText("✅ Solution Checker PASSED — Report saved to: $outDir`r`n")
            }
            $Script:OutputBox.SelectionColor = $Script:C.Text
            Write-Log "Solution Checker" $result "CodeReview"
        }
    }); $timer.Start()
})

$btnOpenCheckerReport.add_Click({
    if ($Script:CheckerReportPath -and (Test-Path $Script:CheckerReportPath)) {
        Start-Process explorer.exe $Script:CheckerReportPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("Run the checker first to generate a report.")
    }
})

$btnCreatePR.add_Click({
    $repo  = Get-ReviewRepo
    $title = $txtPRTitle.Text.Trim()
    $body  = $txtPRBody.Text.Trim()
    $base  = $txtPRBase.Text.Trim()
    if (-not $title) { [System.Windows.Forms.MessageBox]::Show("Enter a PR title."); return }
    Run-Cmd "gh pr create" {
        Set-Location $repo
        gh pr create --title $title --body $body --base $base 2>&1
    } "CodeReview"
})

$btnOpenPRs.add_Click({
    $repo = Get-ReviewRepo
    Run-Cmd "gh pr list" {
        Set-Location $repo
        gh pr list 2>&1
    } "CodeReview"
})

$btnOpenADOPR.add_Click({
    $repo   = Get-ReviewRepo
    $title  = $txtPRTitle.Text.Trim()
    $org    = "https://dev.azure.com/veldarr"
    $proj   = $txtProject.Text.Trim()
    $base   = $txtPRBase.Text.Trim()
    if (-not $proj) { [System.Windows.Forms.MessageBox]::Show("Fill in the Project field on the Azure DevOps tab."); return }
    Run-Cmd "az repos pr create" {
        Set-Location $repo
        az repos pr create --org $org --project $proj --title $title --target-branch $base --auto-complete false --squash false 2>&1
    } "CodeReview"
})

$btnAIReview.add_Click({
    $repo = Get-ReviewRepo; $base = Get-ReviewBase; $head = Get-ReviewHead
    # Write diff to temp file and open Copilot CLI with review prompt
    $diffFile = Join-Path $env:TEMP "review_diff_$(Get-Date -Format 'yyyyMMdd_HHmmss').patch"
    Set-Location $repo
    git diff $base..$head | Out-File -FilePath $diffFile -Encoding UTF8
    $prompt = "Please review this Power Platform solution diff for bugs, best practice violations, unused variables, hardcoded values, missing error handling, and security issues. Be concise and specific about line numbers.`n`n$(Get-Content $diffFile -Raw)"
    Set-Clipboard -Value $prompt
    $Script:OutputBox.SelectionColor = $C.Mauve
    $Script:OutputBox.AppendText("`r`n✅ Review prompt copied to clipboard ($diffFile)`r`nPaste it into Copilot CLI or any AI chat for a full review.`r`n")
    $Script:OutputBox.SelectionColor = $C.Text
    Write-Log "AI Review prompt" "Copied to clipboard" "CodeReview"
})

# ── SETTINGS event handlers ───────────────────────────────────────────────────

function Load-Settings {
    try {
        $cfg = Get-Content $Script:McpConfigPath -Raw | ConvertFrom-Json
        $pat = $cfg.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN
        $txtGhPAT.Text = if ($pat -and $pat -ne "REPLACE_WITH_YOUR_PAT") { $pat } else { "" }
        $dvArgs = [string[]]$cfg.mcpServers.dataverse.args
        $dvIdx  = [Array]::IndexOf($dvArgs, "--ConnectionUrl")
        $txtDvUrl.Text = if ($dvIdx -ge 0) { $dvArgs[$dvIdx+1] } else { "" }
        $csArgs = [string[]]$cfg.mcpServers.'copilot-studio'.args
        $csIdx  = [Array]::IndexOf($csArgs, "--remote-server-url")
        $csVal  = if ($csIdx -ge 0) { $csArgs[$csIdx+1] } else { "" }
        $txtCsMcpUrl.Text = if ($csVal -and $csVal -ne "REPLACE_WITH_YOUR_AGENT_MCP_URL") { $csVal } else { "" }
        $adoOrg = $cfg.mcpServers.'azure-devops'.env.AZURE_DEVOPS_ORG_URL
        if ($adoOrg) { $txtAdoOrgCfg.Text = $adoOrg }
    } catch {}
    if (Test-Path $Script:AiSettingsPath) {
        try {
            $s = Get-Content $Script:AiSettingsPath -Raw | ConvertFrom-Json
            if ($s.ai) {
                $cboAiProv.SelectedIndex = if ($s.ai.provider -like "*Anthropic*") { 2 } elseif ($s.ai.provider -like "*Azure*") { 1 } else { 0 }
                $txtAiEp.Text     = $s.ai.endpoint
                $txtAiDeploy.Text = $s.ai.model
                $txtAiApiKey.Text = $s.ai.key
            }
        } catch {}
    }
}

$chkShowPAT.add_CheckedChanged({   $txtGhPAT.UseSystemPasswordChar    = -not $chkShowPAT.Checked })
$chkShowAiKey.add_CheckedChanged({ $txtAiApiKey.UseSystemPasswordChar = -not $chkShowAiKey.Checked })
$lnkOpenStudio.add_LinkClicked({ Start-Process "https://copilotstudio.microsoft.com" })

$btnTestGh.add_Click({
    $pat = $txtGhPAT.Text.Trim()
    if (-not $pat) { [System.Windows.Forms.MessageBox]::Show("Enter your GitHub PAT first."); return }
    Run-Cmd "Test GitHub PAT" {
        $r = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers @{ Authorization="token $pat"; "User-Agent"="PowerPlatformDashboard" } -ErrorAction Stop
        "✅ Authenticated as: $($r.login)  ($($r.name))"
    } "Settings"
})

$btnDetectDv.add_Click({
    Run-Cmd "Detect Dataverse connection" {
        $raw = pac connection list 2>&1
        $connId = ""; $apiName = "shared_commondataserviceforapps"
        foreach ($line in $raw) {
            if ($line -match '(shared[_-]commondataserviceforapps\S*)' -and $line -match 'Connected') {
                $apiName = "shared_commondataserviceforapps"
                if ($line -match '^(\S+)\s') { $connId = $Matches[1] }
                break
            }
        }
        if ($connId) {
            $envId = "ef77d261-f915-e0fb-95f4-1cbc09edb6ab"
            $url = "https://make.powerautomate.com/environments/$envId`?apiName=$apiName&connectionName=$connId"
            $txtDvUrl.Text = $url
            "✅ Detected: $url"
        } else {
            "ℹ️ No connected Dataverse connection found — using known working URL."
            $txtDvUrl.Text = "https://make.powerautomate.com/environments/ef77d261-f915-e0fb-95f4-1cbc09edb6ab?apiName=shared_commondataserviceforapps&connectionName=shared-commondataser-ed948043-b01e-4d3c-9460-7afac3791ff1"
        }
    } "Settings"
})

$btnSaveCfg.add_Click({
    try {
        $cfg = Get-Content $Script:McpConfigPath -Raw | ConvertFrom-Json
        $pat = $txtGhPAT.Text.Trim()
        if ($pat) { $cfg.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $pat }
        $dvUrl = $txtDvUrl.Text.Trim()
        if ($dvUrl) {
            $dvList = [System.Collections.Generic.List[string]]::new()
            [string[]]$cfg.mcpServers.dataverse.args | ForEach-Object { $dvList.Add($_) }
            $idx = $dvList.IndexOf("--ConnectionUrl")
            if ($idx -ge 0) { $dvList[$idx+1] = $dvUrl } else { $dvList.Add("--ConnectionUrl"); $dvList.Add($dvUrl) }
            $cfg.mcpServers.dataverse.args = $dvList.ToArray()
        }
        $csUrl = $txtCsMcpUrl.Text.Trim()
        if ($csUrl) {
            $csList = [System.Collections.Generic.List[string]]::new()
            [string[]]$cfg.mcpServers.'copilot-studio'.args | ForEach-Object { $csList.Add($_) }
            $idx = $csList.IndexOf("--remote-server-url")
            if ($idx -ge 0) { $csList[$idx+1] = $csUrl }
            $cfg.mcpServers.'copilot-studio'.args = $csList.ToArray()
        }
        $adoUrl = $txtAdoOrgCfg.Text.Trim()
        if ($adoUrl) { $cfg.mcpServers.'azure-devops'.env.AZURE_DEVOPS_ORG_URL = $adoUrl }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $Script:McpConfigPath -Encoding UTF8
        $provider = switch ($cboAiProv.SelectedItem.ToString()) { "Azure OpenAI" {"azure"} "Anthropic Claude" {"claude"} default {"clipboard"} }
        @{ ai = @{ provider=$provider; endpoint=$txtAiEp.Text.Trim(); model=$txtAiDeploy.Text.Trim(); key=$txtAiApiKey.Text.Trim() } } | ConvertTo-Json -Depth 5 | Set-Content $Script:AiSettingsPath -Encoding UTF8
        $lblCfgStatus.Text      = "✅ Saved! Restart Copilot CLI to apply MCP changes."
        $lblCfgStatus.ForeColor = $C.Green
        Write-Log "Save Settings" "OK" "Settings"
    } catch {
        $lblCfgStatus.Text      = "❌ $($_.Exception.Message)"
        $lblCfgStatus.ForeColor = $C.Red
    }
})

$tabs.add_SelectedIndexChanged({
    if ($tabs.SelectedTab -eq $tabSettings) { Load-Settings }
    if ($tabs.SelectedTab -eq $tabSol -and $Script:Solutions.Count -eq 0) { Load-Solutions }
    if ($tabs.SelectedTab -eq $tabAI -and $Script:AiChat.TextLength -eq 0) {
        $Script:AiChat.SelectionColor = $C.Teal
        $Script:AiChat.AppendText("👋 Hi! I'm your Power Platform AI assistant.`r`n")
        $Script:AiChat.SelectionColor = $C.Subtext
        $Script:AiChat.AppendText("Ask me anything, or click a quick-prompt button above.`r`n")
        $Script:AiChat.AppendText("Configure your AI API key in ⚙️ Settings first.`r`n`r`n")
        $Script:AiChat.SelectionColor = $C.Text
    }
})

# ── AI ASSISTANT event handlers ───────────────────────────────────────────────

function Send-AiMessage {
    $msg = $Script:AiMsgBox.Text.Trim()
    if (-not $msg) { return }
    $Script:AiChat.SelectionColor = $C.Blue
    $Script:AiChat.AppendText("You: $msg`r`n")
    $Script:AiChat.SelectionColor = $C.Overlay
    $Script:AiChat.AppendText("─────────────────────────────────────────────`r`n")
    $Script:AiMsgBox.Clear()
    $null = $Script:AiHistory.Add(@{role="user"; content=$msg})
    $btnAiSend.Enabled = $false; $btnAiSend.Text = "⏳ …"

    $histJson  = $Script:AiHistory | ConvertTo-Json -Depth 5 -Compress
    $envCtx    = $envStatusLbl.Text
    $aiSetPath = $Script:AiSettingsPath
    $userMsg   = $msg

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    $rs.SessionStateProxy.SetVariable("HistJson",   $histJson)
    $rs.SessionStateProxy.SetVariable("EnvCtx",     $envCtx)
    $rs.SessionStateProxy.SetVariable("AiSetPath",  $aiSetPath)
    $ps = [powershell]::Create().AddScript({
        $cfg = @{Provider="clipboard"; Endpoint=""; Model=""; Key=""}
        if (Test-Path $AiSetPath) {
            try {
                $s = Get-Content $AiSetPath -Raw | ConvertFrom-Json
                if ($s.ai) { $cfg = @{Provider=$s.ai.provider; Endpoint=$s.ai.endpoint; Model=$s.ai.model; Key=$s.ai.key} }
            } catch {}
        }
        if ($cfg.Provider -like "*Copilot*" -or $cfg.Provider -eq "clipboard") {
            $fullPrompt = "You are a helpful Power Platform assistant. Context: $EnvCtx`r`n`r`nConversation so far:`r`n$(($HistJson | ConvertFrom-Json | ForEach-Object {"$($_.role): $($_.content)"}) -join "`r`n")`r`n`r`nThis is your clipboard prompt — paste it into your AI of choice."
            return "📋 Prompt copied to clipboard! Paste into Copilot, ChatGPT, or any AI chat.`r`n`r`n(You already have GitHub Copilot CLI — just paste here in the chat for a full response.)"
        }
        if (-not $cfg.Key) {
            return "⚠️ No AI API key configured. Go to ⚙️ Settings tab → AI Assistant section. Add an Azure OpenAI or Anthropic Claude key and Save.`r`n`r`n💡 You also have GitHub Copilot — select 'GitHub Copilot (clipboard)' as the provider to copy prompts and paste into this chat!"
        }
        $sys = "You are a helpful Power Platform assistant embedded in the Power Platform Dashboard app. Help users (including non-developers) with Power Apps, Power Automate, Dataverse, SharePoint, and Azure DevOps. Be concise and friendly. Guide users to the right tab and button in this dashboard when they ask to do things. The dashboard has tabs: Environments, Solutions, SharePoint, Azure DevOps, ALM Pipelines, MCP Servers, Deploy, Code Review, Settings, AI Assistant. Current context: $EnvCtx"
        $history = try { $HistJson | ConvertFrom-Json } catch { @() }
        $msgs = [System.Collections.ArrayList]::new()
        $null = $msgs.Add(@{role="system"; content=$sys})
        foreach ($h in $history) { $null = $msgs.Add(@{role=[string]$h.role; content=[string]$h.content}) }
        try {
            if ($cfg.Provider -like "*Azure*") {
                $uri  = "$($cfg.Endpoint.TrimEnd('/'))/openai/deployments/$($cfg.Model)/chat/completions?api-version=2024-08-01-preview"
                $body = @{messages=$msgs.ToArray(); max_tokens=800; temperature=0.7} | ConvertTo-Json -Depth 10
                $r = Invoke-RestMethod -Uri $uri -Method Post -Headers @{"api-key"=$cfg.Key; "Content-Type"="application/json"} -Body $body
                $r.choices[0].message.content
            } else {
                $nonSys = $msgs | Where-Object { $_.role -ne "system" }
                $body = @{model="claude-3-5-sonnet-20241022"; max_tokens=1024; system=$sys; messages=@($nonSys)} | ConvertTo-Json -Depth 10
                $r = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post -Headers @{"x-api-key"=$cfg.Key; "anthropic-version"="2023-06-01"; "Content-Type"="application/json"} -Body $body
                $r.content[0].text
            }
        } catch { "❌ API error: $($_.Exception.Message)" }
    })
    $ps.Runspace = $rs
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $reply = try { ($ps.EndInvoke($handle) | Out-String).Trim() } catch { "❌ $($_.Exception.Message)" }
            $ps.Dispose(); $rs.Dispose()
            $null = $Script:AiHistory.Add(@{role="assistant"; content=$reply})
            $Script:AiChat.SelectionColor = $Script:C.Green
            $Script:AiChat.AppendText("Assistant: $reply`r`n")
            $Script:AiChat.SelectionColor = $Script:C.Overlay
            $Script:AiChat.AppendText("─────────────────────────────────────────────`r`n`r`n")
            $Script:AiChat.SelectionColor = $Script:C.Text
            $Script:AiChat.ScrollToCaret()
            $btnAiSend.Enabled = $true; $btnAiSend.Text = "➤  Send"
        }
    }); $timer.Start()
}

$btnAiSend.add_Click({ Send-AiMessage })
$Script:AiMsgBox.add_KeyDown({
    param($s, $e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $e.SuppressKeyPress = $true; Send-AiMessage
    }
})
$btnAiClear.add_Click({
    $Script:AiHistory.Clear()
    $Script:AiChat.Clear()
    $Script:AiChat.SelectionColor = $C.Subtext
    $Script:AiChat.AppendText("Chat cleared. Start a new conversation.`r`n`r`n")
    $Script:AiChat.SelectionColor = $C.Text
})
$btnQp1.add_Click({ $Script:AiMsgBox.Text = "What can you help me with? Give me a quick overview of all your capabilities."; Send-AiMessage })
$btnQp2.add_Click({ $Script:AiMsgBox.Text = "How do I deploy a Power Apps solution to another environment step by step?"; Send-AiMessage })
$btnQp3.add_Click({
    if ($Script:Environments.Count -gt 0) {
        $envList = ($Script:Environments | ForEach-Object { "  • $($_.Name): $($_.Url)" }) -join "`n"
        $Script:AiMsgBox.Text = "Here are my Power Platform environments:`n$envList`nWhich one should I use for development vs production and what are the best practices?"
    } else {
        $Script:AiMsgBox.Text = "I haven't loaded my environments yet. What are the recommended Power Platform environment strategies (dev/test/prod)?"
    }
    Send-AiMessage
})
$btnQp4.add_Click({ $Script:AiMsgBox.Text = "I'm getting an error. The error message is: [paste your error here]. What does it mean and how do I fix it?" })
$btnQp5.add_Click({ $Script:AiMsgBox.Text = "What are the most important Power Platform ALM and solution best practices I should follow?"; Send-AiMessage })


$form.add_Load({
    $Script:OutputBox.AppendText("⚡ Power Platform Dashboard ready.`r`n")
    $Script:OutputBox.AppendText("Log file: $Script:LogPath`r`n")
    Load-Environments
    Load-Solutions
    Refresh-MCP
    Load-Settings

    # Global log-stream drain timer — reads from $Script:LogQueue every 300ms
    $Script:DrainTimer = New-Object System.Windows.Forms.Timer
    $Script:DrainTimer.Interval = 300
    $Script:DrainTimer.add_Tick({
        $msg = $null
        while ($Script:LogQueue.TryDequeue([ref]$msg)) {
            $col = if     ($msg -match '^  ✅|^✅') { [System.Drawing.Color]::FromArgb(166,227,161) }
                   elseif ($msg -match '^  ❌|^❌') { [System.Drawing.Color]::FromArgb(243,139,168) }
                   elseif ($msg -match '^  ⚠|^⚠')  { [System.Drawing.Color]::FromArgb(250,179,135) }
                   elseif ($msg -match '^  🤖|^🤖') { [System.Drawing.Color]::FromArgb(203,166,247) }
                   elseif ($msg -match '📦|📤|📊|⚙️|🔧|⬆') { [System.Drawing.Color]::FromArgb(137,220,235) }
                   else   { [System.Drawing.Color]::FromArgb(202,211,245) }
            $Script:OutputBox.SelectionColor = $col
            $Script:OutputBox.AppendText("$msg`r`n")
            $Script:OutputBox.SelectionColor = [System.Drawing.Color]::FromArgb(202,211,245)
            $Script:OutputBox.ScrollToCaret()
        }
    })
    $Script:DrainTimer.Start()
})

[System.Windows.Forms.Application]::Run($form)
