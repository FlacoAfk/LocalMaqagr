# MaqAgr Local — Development Setup
# Usage: .\setup.ps1 (or right-click → Run with PowerShell)
# Flags: -SkipInstall (skip Node installation), -SkipDeps (skip dependency install)

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
Write-Host "║   MaqAgr Local — Development Setup       ║" -ForegroundColor Green
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

$nodeVersion = (node --version) -replace 'v',''
if ([version]$nodeVersion -lt [version]"22.0.0") {
    Write-Fail "Node.js 22+ is required by the frontend. Current: v$nodeVersion"
    exit 1
}

# ── PostgreSQL client ──
if (-not (Get-Command psql -ErrorAction SilentlyContinue) -or -not (Get-Command pg_isready -ErrorAction SilentlyContinue)) {
    Write-Fail "PostgreSQL client tools (psql and pg_isready) not found. Install PostgreSQL and ensure its bin directory is on PATH."
    exit 1
}
& pg_isready -h 127.0.0.1 -p 5432 -q
if ($LASTEXITCODE -ne 0) {
    Write-Fail "PostgreSQL is not accepting local connections on 127.0.0.1:5432. Start your local database before setup."
    exit 1
}
Write-OK "PostgreSQL client found and local server is accepting connections"

# ── pnpm via corepack ──
$requiredPnpmVersion = "11.1.0"
$pnpmHome = Join-Path $env:LOCALAPPDATA "pnpm"
if (-not $env:PNPM_HOME) { $env:PNPM_HOME = $pnpmHome }
if ($env:PATH -notlike "*$pnpmHome*") { $env:PATH = "$pnpmHome;$env:PATH" }

try {
    if (-not (Get-Command corepack -ErrorAction SilentlyContinue)) {
        throw "Corepack was not found. Install Corepack, then activate pnpm@$requiredPnpmVersion."
    }
    & corepack enable
    if ($LASTEXITCODE -ne 0) { throw "corepack enable exited with $LASTEXITCODE" }
    $pnpmVersion = pnpm --version 2>$null
    if ($pnpmVersion -eq $requiredPnpmVersion) {
        Write-OK "pnpm v$pnpmVersion"
    } else {
        Write-Warn "Activating pinned pnpm@$requiredPnpmVersion via Corepack..."
        & corepack prepare "pnpm@$requiredPnpmVersion" --activate
        if ($LASTEXITCODE -ne 0) { throw "Corepack could not activate pnpm@$requiredPnpmVersion" }
        $pnpmVersion = pnpm --version 2>$null
        if ($pnpmVersion -ne $requiredPnpmVersion) {
            throw "Expected pnpm $requiredPnpmVersion but found '$pnpmVersion'"
        }
        Write-OK "pnpm v$pnpmVersion activated"
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
    Write-Warn "Installing pinned root, backend, and frontend dependencies..."
    Push-Location $ProjectRoot
    try {
        & pnpm install --frozen-lockfile
        if ($LASTEXITCODE -ne 0) {
            throw "pnpm install --frozen-lockfile failed with exit code $LASTEXITCODE"
        }
        Write-OK "All dependencies installed from lockfiles"
    } catch {
        Write-Fail $_
        exit 1
    } finally {
        Pop-Location
    }
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
Write-Warn "Configure backend/.env for your local PostgreSQL credentials, create maqagr_local, and apply the database baseline before launching."

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
Write-Host "║   Backend:  http://localhost:24688         ║" -ForegroundColor Green
Write-Host "║   Frontend: http://localhost:5173         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green
