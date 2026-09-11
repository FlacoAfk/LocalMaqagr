# MaqAgr Local — Full Installer
# Usage: .\setup.ps1 (or right-click → Run with PowerShell)
# Flags: -SkipInstall (skip Node/pnpm install), -SkipDeps (skip pnpm install)

param(
    [switch]$SkipInstall,
    [switch]$SkipDeps
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Helpers ──
function Write-Step  { param([string]$msg) Write-Host "`n═══ $msg ═══" -ForegroundColor Cyan }
function Write-OK    { param([string]$msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn  { param([string]$msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  ✗ $msg" -ForegroundColor Red }

function Refresh-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   MaqAgr Local — Full Installer          ║" -ForegroundColor Green
Write-Host "║   Agricultural Machinery Platform        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green

# ═══════════════════════════════════════════════
# PHASE 1: Check Prerequisites
# ═══════════════════════════════════════════════
Write-Step "Phase 1/4: Checking Prerequisites"

# ── Node.js ──
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeVersion = (node --version) -replace 'v',''
    Write-OK "Node.js v$nodeVersion"
    if ([version]$nodeVersion -lt [version]"18.0.0") {
        Write-Warn "Node.js 18+ recommended. Current: v$nodeVersion"
    }
} else {
    if ($SkipInstall) {
        Write-Fail "Node.js not found. Install from https://nodejs.org"
        exit 1
    }
    Write-Warn "Node.js not found. Installing via winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        Refresh-Path
        $node = Get-Command node -ErrorAction SilentlyContinue
        if ($node) { Write-OK "Node.js installed: $(node --version)" }
        else { Write-Fail "Node.js install failed. Install manually from https://nodejs.org"; exit 1 }
    } else {
        Write-Fail "winget not available. Install Node.js from https://nodejs.org"
        exit 1
    }
}

# ── pnpm via corepack ──
$pnpmHome = Join-Path $env:LOCALAPPDATA "pnpm"
if (-not $env:PNPM_HOME) { $env:PNPM_HOME = $pnpmHome }
if ($env:PATH -notlike "*$pnpmHome*") { $env:PATH = "$pnpmHome;$env:PATH" }

try {
    corepack enable 2>$null
    $pnpmVersion = pnpm --version 2>$null
    if ($pnpmVersion) {
        Write-OK "pnpm v$pnpmVersion"
    } else {
        Write-Warn "Installing pnpm via corepack..."
        corepack prepare pnpm@latest --activate 2>$null
        $pnpmVersion = pnpm --version 2>$null
        if ($pnpmVersion) {
            Write-OK "pnpm v$pnpmVersion installed"
        } else {
            Write-Fail "pnpm install failed. Try: npm install -g pnpm"
            exit 1
        }
    }
} catch {
    Write-Fail "Failed to setup pnpm: $_"
    exit 1
}

# ═══════════════════════════════════════════════
# PHASE 2: Environment Files
# ═══════════════════════════════════════════════
Write-Step "Phase 2/4: Environment Configuration"

$backendEnv = Join-Path $ProjectRoot "backend\.env"
$backendEnvExample = Join-Path $ProjectRoot "backend\.env.local.example"
if (-not (Test-Path $backendEnv) -and (Test-Path $backendEnvExample)) {
    Copy-Item $backendEnvExample $backendEnv
    Write-OK "backend/.env created from template"
} elseif (Test-Path $backendEnv) {
    Write-OK "backend/.env already exists"
} else {
    Write-Warn "No .env template found — create backend/.env manually"
}

$frontendEnv = Join-Path $ProjectRoot "frontend\.env"
$frontendEnvExample = Join-Path $ProjectRoot "frontend\.env.example"
if (-not (Test-Path $frontendEnv) -and (Test-Path $frontendEnvExample)) {
    Copy-Item $frontendEnvExample $frontendEnv
    Write-OK "frontend/.env created from template"
} elseif (Test-Path $frontendEnv) {
    Write-OK "frontend/.env already exists"
} else {
    Write-Warn "No .env template found — create frontend/.env manually"
}

# ═══════════════════════════════════════════════
# PHASE 3: Install Dependencies
# ═══════════════════════════════════════════════
Write-Step "Phase 3/4: Installing Dependencies"

if (-not $SkipDeps) {
    Write-Warn "Installing backend dependencies..."
    Push-Location (Join-Path $ProjectRoot "backend")
    pnpm install
    if ($?) { Write-OK "Backend dependencies installed" }
    else { Write-Fail "Backend install failed" }
    Pop-Location

    Write-Warn "Installing frontend dependencies..."
    Push-Location (Join-Path $ProjectRoot "frontend")
    pnpm install
    if ($?) { Write-OK "Frontend dependencies installed" }
    else { Write-Fail "Frontend install failed" }
    Pop-Location

    Write-Warn "Installing root dependencies..."
    Push-Location $ProjectRoot
    pnpm install
    if ($?) { Write-OK "Root dependencies installed" }
    else { Write-Fail "Root install failed" }
    Pop-Location
} else {
    Write-Warn "Dependency installation skipped"
}

# ═══════════════════════════════════════════════
# PHASE 4: Final Setup
# ═══════════════════════════════════════════════
Write-Step "Phase 4/4: Final Setup"

$uploadsDir = Join-Path $ProjectRoot "backend\uploads"
@("tractors", "implements", "users") | ForEach-Object {
    $dir = Join-Path $uploadsDir $_
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $dir ".gitkeep") -Force | Out-Null
    }
}
Write-OK "Upload directories ready"

# ═══════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════
Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Setup Complete!                      ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║   To start the application:              ║" -ForegroundColor Green
Write-Host "║                                          ║" -ForegroundColor Green
Write-Host "║   .\launch.ps1                           ║" -ForegroundColor Green
Write-Host "║                                          ║" -ForegroundColor Green
Write-Host "║   Backend:  http://localhost:4000         ║" -ForegroundColor Green
Write-Host "║   Frontend: http://localhost:5173         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green
