<#
.SYNOPSIS
    K9-Claude-Framework installer (Windows PowerShell).

.DESCRIPTION
    Installs the three commands for Claude Code and/or Codex CLI,
    depending on which are detected on the system.

    Claude Code: copies commands to $env:USERPROFILE\.claude\commands\ as .md files.
    Codex CLI:   creates $env:USERPROFILE\.agents\skills\<name>\SKILL.md for each command.

    Detection excludes Codex binaries cached inside .claude\plugins\,
    since those are Claude Code plugin assets, not a standalone Codex install.

    Safe to re-run — each run backs up pre-existing files before overwriting.
#>

$ErrorActionPreference = 'Stop'

# ---- locate repo root and sanity-check inputs ---------------------

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = $ScriptDir
$CommandsSrc = Join-Path $RepoRoot 'commands'
$VersionFile = Join-Path $RepoRoot 'VERSION'

if (-not (Test-Path $CommandsSrc -PathType Container)) {
    Write-Error "$CommandsSrc not found. Run this from the repo root."
    exit 1
}
if (-not (Test-Path $VersionFile -PathType Leaf)) {
    Write-Error "$VersionFile not found. Run this from the repo root."
    exit 1
}

$FrameworkVersion = (Get-Content $VersionFile -Raw).Trim()

# ---- detect installed CLIs ----------------------------------------

$InstallClaude = $false
$InstallCodex  = $false

# Claude Code: ~/.claude/ directory is created on first launch
$ClaudeDir = Join-Path $env:USERPROFILE '.claude'
if (Test-Path $ClaudeDir -PathType Container) {
    $InstallClaude = $true
}

# Codex CLI: ~/.codex/ config directory, OR a codex binary that is NOT
# inside .claude\plugins\ (which is just a Claude Code plugin cache).
$CodexDir = Join-Path $env:USERPROFILE '.codex'
if (Test-Path $CodexDir -PathType Container) {
    $InstallCodex = $true
} else {
    $codexCmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($codexCmd) {
        $codexPath = $codexCmd.Source
        if ($codexPath -notlike "*\.claude\plugins\*") {
            $InstallCodex = $true
        }
    }
}

if (-not $InstallClaude -and -not $InstallCodex) {
    Write-Error ("Neither Claude Code ($ClaudeDir) nor Codex CLI ($CodexDir) detected.`n" +
                 "Install at least one CLI before running this installer.")
    exit 1
}

# ---- detect source (git remote + commit SHA if available) ---------

$SourceInfo = $RepoRoot
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    try {
        Push-Location $RepoRoot
        $null = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -eq 0) {
            $remote = (git remote get-url origin 2>$null) | Out-String
            $sha    = (git rev-parse --short HEAD 2>$null) | Out-String
            $remote = $remote.Trim()
            $sha    = $sha.Trim()
            if ($remote -and $sha) {
                $SourceInfo = "$remote@$sha"
            } elseif ($sha) {
                $SourceInfo = "$RepoRoot@$sha"
            }
        }
    } finally {
        Pop-Location
    }
}

# ---- shared state -------------------------------------------------

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Today     = Get-Date -Format 'yyyy-MM-dd'
$Installed = @()
$BackedUp  = @()

$MarkerContent = @"
framework: K9-Claude-Framework
version: $FrameworkVersion
installed: $Today
source: $SourceInfo
"@

# ---- install for Claude Code --------------------------------------

if ($InstallClaude) {
    $CommandsDst  = Join-Path $ClaudeDir 'commands'
    $MarkerFile   = Join-Path $ClaudeDir '.k9-framework-version'

    if (-not (Test-Path $CommandsDst)) {
        New-Item -ItemType Directory -Path $CommandsDst -Force | Out-Null
    }

    Get-ChildItem -Path $CommandsSrc -Filter '*.md' -File | ForEach-Object {
        $src = $_.FullName
        $dst = Join-Path $CommandsDst $_.Name

        if (Test-Path $dst -PathType Leaf) {
            $backup = "$dst.pre-k9-backup-$Timestamp"
            Copy-Item -Path $dst -Destination $backup
            $script:BackedUp += $backup
        }

        Copy-Item -Path $src -Destination $dst -Force
        $script:Installed += $dst
    }

    $MarkerContent | Set-Content -Path $MarkerFile -Encoding UTF8
}

# ---- install for Codex CLI ----------------------------------------

if ($InstallCodex) {
    $SkillsDir  = Join-Path $env:USERPROFILE '.agents\skills'
    $MarkerFile = Join-Path $CodexDir '.k9-framework-version'

    if (-not (Test-Path $SkillsDir)) {
        New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    }
    # ~/.codex/ may not exist on a fresh Codex install that hasn't been
    # launched yet; create it so the marker write succeeds.
    if (-not (Test-Path $CodexDir)) {
        New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
    }

    Get-ChildItem -Path $CommandsSrc -Filter '*.md' -File | ForEach-Object {
        $src       = $_.FullName
        $skillName = $_.BaseName              # strip .md → init-project, etc.
        $skillDir  = Join-Path $SkillsDir $skillName
        $skillDst  = Join-Path $skillDir 'SKILL.md'

        if (-not (Test-Path $skillDir)) {
            New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        }

        if (Test-Path $skillDst -PathType Leaf) {
            $backup = "$skillDst.pre-k9-backup-$Timestamp"
            Copy-Item -Path $skillDst -Destination $backup
            $script:BackedUp += $backup
        }

        Copy-Item -Path $src -Destination $skillDst -Force
        $script:Installed += $skillDst
    }

    $MarkerContent | Set-Content -Path $MarkerFile -Encoding UTF8
}

# ---- summary ------------------------------------------------------

Write-Host ""
Write-Host "K9-Claude-Framework $FrameworkVersion installed."
Write-Host ""

if ($InstallClaude) { Write-Host "  Claude Code -> $ClaudeDir\commands\" }
if ($InstallCodex)  { Write-Host "  Codex CLI   -> $env:USERPROFILE\.agents\skills\" }

Write-Host ""
Write-Host "Installed:"
foreach ($f in $Installed) { Write-Host "  $f" }

if ($BackedUp.Count -gt 0) {
    Write-Host ""
    Write-Host "Backed up (pre-existing files):"
    foreach ($f in $BackedUp) { Write-Host "  $f" }
}

Write-Host ""
if ($InstallClaude) { Write-Host "Marker written: $ClaudeDir\.k9-framework-version" }
if ($InstallCodex)  { Write-Host "Marker written: $CodexDir\.k9-framework-version" }

Write-Host ""
Write-Host "Next steps:"
if ($InstallClaude) { Write-Host "  Claude Code -- cd into any project and run /init-project." }
if ($InstallCodex)  { Write-Host "  Codex CLI   -- cd into any project and invoke `$init-project (or /skills picker)." }
Write-Host "  Already initialized? Try the check-init command to verify health."
