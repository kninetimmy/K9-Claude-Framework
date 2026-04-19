<#
.SYNOPSIS
    K9-Claude-Framework installer (Windows PowerShell).

.DESCRIPTION
    Copies the three commands from .\commands\ into
    $env:USERPROFILE\.claude\commands\, backing up any pre-existing
    versions, and writes a framework marker at
    $env:USERPROFILE\.claude\.k9-framework-version.

    Safe to re-run — each run backs up what's already there before
    overwriting.
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

# ---- locate install target ----------------------------------------

$ClaudeDir   = Join-Path $env:USERPROFILE '.claude'
$CommandsDst = Join-Path $ClaudeDir 'commands'
$MarkerFile  = Join-Path $ClaudeDir '.k9-framework-version'

if (-not (Test-Path $CommandsDst)) {
    New-Item -ItemType Directory -Path $CommandsDst -Force | Out-Null
}

# ---- install each command file ------------------------------------

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Today     = Get-Date -Format 'yyyy-MM-dd'
$Installed = @()
$BackedUp  = @()

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

# ---- write framework marker ---------------------------------------

@"
framework: K9-Claude-Framework
version: $FrameworkVersion
installed: $Today
source: $SourceInfo
"@ | Set-Content -Path $MarkerFile -Encoding UTF8

# ---- summary ------------------------------------------------------

Write-Host ""
Write-Host "K9-Claude-Framework $FrameworkVersion installed."
Write-Host ""
Write-Host "Installed:"
foreach ($f in $Installed) { Write-Host "  $f" }

if ($BackedUp.Count -gt 0) {
    Write-Host ""
    Write-Host "Backed up (pre-existing files):"
    foreach ($f in $BackedUp) { Write-Host "  $f" }
}

Write-Host ""
Write-Host "Marker written: $MarkerFile"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  cd into any project and run /init-project in a Claude Code session."
Write-Host "  Already initialized? Try /check-init to verify health."
