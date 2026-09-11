# ============================================================
# MaqAgr Local Launcher
# Starts PostgreSQL portable + Node backend (single process)
# ============================================================
# IMPORTANT: Do NOT use $ErrorActionPreference = 'Stop' here.
# Native executables (pg_ctl, initdb, psql) write warnings to stderr
# which PowerShell would treat as fatal errors. We handle errors
# explicitly via $LASTEXITCODE checks instead.
$ErrorActionPreference = 'Continue'

# --- Paths ---
$appDir     = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dataDir    = Join-Path $env:PROGRAMDATA 'MaqAgr'
$pgDataDir  = Join-Path $dataDir 'pgdata'
$uploadsDir = Join-Path $dataDir 'uploads'
$logsDir    = Join-Path $dataDir 'logs'

$nodeDir      = Join-Path $appDir 'runtime\node'
$pgDir        = Join-Path $appDir 'runtime\pgsql'
$pgBin        = Join-Path $pgDir 'bin'
$pgLib        = Join-Path $pgDir 'lib'
$backendDir   = Join-Path $appDir 'app\backend'
$frontendDist = Join-Path $appDir 'app\frontend-dist'

$pgPort = 5435
$pgUser = 'postgres'
$pgPass = 'postgres'
$dbName = 'maqagr_local'

# --- Create writable directories ---
New-Item -ItemType Directory -Force -Path $dataDir    | Out-Null
New-Item -ItemType Directory -Force -Path $uploadsDir | Out-Null
New-Item -ItemType Directory -Force -Path $logsDir    | Out-Null
foreach ($sub in 'tractors','implements','users','general') {
    New-Item -ItemType Directory -Force -Path (Join-Path $uploadsDir $sub) | Out-Null
}

# --- Put PG bin+lib FIRST in PATH (avoid DLL conflicts) ---
$env:PATH = "$pgBin;$pgLib;$nodeDir;$env:PATH"

# --- Password for every psql invocation (startup probe, DB checks, schema) ---
# psql is always called with -w so it never hangs waiting for a prompt.
$env:PGPASSWORD = $pgPass
$env:PGCLIENTENCODING = 'UTF8'

# --- Step 1: Initialize PostgreSQL (first run only) ---
if (-not (Test-Path (Join-Path $pgDataDir 'PG_VERSION'))) {
    Write-Host "[MaqAgr] First run: initializing database..." -ForegroundColor Cyan
    $pwFile = Join-Path $dataDir '.pgpass_init'
    Set-Content -Path $pwFile -Value $pgPass -NoNewline
    $initOutput = & "$pgBin\initdb.exe" -D $pgDataDir -U $pgUser --auth-local=md5 --auth-host=md5 --pwfile=$pwFile 2>&1
    $initOutput | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[MaqAgr] ERROR: initdb failed (exit $LASTEXITCODE)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Remove-Item $pwFile -Force -ErrorAction SilentlyContinue
}

# --- Step 2: Start PostgreSQL ---
# Check if PG is already running using pg_isready (lightweight TCP probe).
# Do NOT use pg_ctl status — it can hang on machines with system PG installations.
$null = & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p $pgPort 2>&1
$pgRunning = ($LASTEXITCODE -eq 0)

if ($pgRunning) {
    Write-Host "[MaqAgr] Database is already running." -ForegroundColor DarkGray
} else {
    # Handle a leftover postmaster.pid WITHOUT dead-lettering a healthy PID.
    # Only treat the lock as stale if the PID recorded in line 1 is dead or absent.
    $pidFile = Join-Path $pgDataDir 'postmaster.pid'
    if (Test-Path $pidFile) {
        $recordedPid = 0
        [int]::TryParse(((Get-Content $pidFile -First 1 -ErrorAction SilentlyContinue) -as [string]).Trim(), [ref]$recordedPid) | Out-Null
        $pidAlive = $false
        if ($recordedPid -gt 0) { try { $null = Get-Process -Id $recordedPid -ErrorAction Stop; $pidAlive = $true } catch {} }
        if (-not $pidAlive) {
            Write-Host "[MaqAgr] Cleaning up stale lock file..." -ForegroundColor DarkYellow
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        } else {
            # PID exists but pg_isready says not running → unclean shutdown.
            # Kill the stale process and clean the lock file.
            Write-Host "[MaqAgr] Cleaning up stale instance (unclean shutdown)..." -ForegroundColor DarkYellow
            try { Stop-Process -Id $recordedPid -Force -ErrorAction SilentlyContinue } catch {}
            Start-Sleep -Seconds 1
            if (Test-Path $pidFile) { Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }
        }
    }

    Write-Host "[MaqAgr] Starting database on port $pgPort..." -ForegroundColor Cyan
    $pgLog = Join-Path $logsDir 'postgresql.log'
    # Start postgres.exe DIRECTLY instead of pg_ctl. On machines with existing
    # system PostgreSQL installations, pg_ctl's internal process management
    # triggers a DLL conflict (0xC0000142 / STATUS_DLL_INIT_FAILED) that hangs
    # indefinitely. postgres.exe started via Start-Process avoids this entirely.
    $pgExe = Join-Path $pgBin 'postgres.exe'
    $pgProc = Start-Process -FilePath $pgExe -ArgumentList "-D", $pgDataDir, "-p", "$pgPort" -RedirectStandardError $pgLog -NoNewWindow -PassThru
    if (-not $pgProc) {
        Write-Host "[MaqAgr] ERROR: Failed to launch postgres.exe" -ForegroundColor Red
        Write-Host "[MaqAgr] Check log at: $pgLog" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    # Poll with pg_isready (lightweight TCP probe, no DLL conflict)
    $pgReady = $false
    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 1
        $null = & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p $pgPort 2>&1
        if ($LASTEXITCODE -eq 0) { $pgReady = $true; break }
        Write-Host "." -NoNewline
    }
    Write-Host ""
    if (-not $pgReady) {
        Write-Host "[MaqAgr] ERROR: Database did not become ready in 30 seconds" -ForegroundColor Red
        Write-Host "[MaqAgr] Check log at: $pgLog" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# --- Step 2b: Wait until PostgreSQL accepts QUERIES, not just connections ---
# pg_isready can report "accepting connections" while crash recovery (WAL replay
# after an unclean shutdown) is still running. Any query in that window fails
# with FATAL: el sistema de bases de datos está iniciándose. The only reliable
# readiness signal is a successful query, so keep polling with psql SELECT 1.
# This gate runs in BOTH cases (fresh start and already-running) so a database
# that is mid-recovery when the launcher starts is never touched too early.
$pgQueryReady = $false
for ($i = 1; $i -le 60; $i++) {
    $null = & "$pgBin\psql.exe" -h 127.0.0.1 -p $pgPort -U $pgUser -d postgres -w -tAc "SELECT 1" 2>$null
    if ($LASTEXITCODE -eq 0) { $pgQueryReady = $true; break }
    Write-Host "." -NoNewline
}
Write-Host ""
if (-not $pgQueryReady) {
    Write-Host "[MaqAgr] ERROR: Database is not accepting queries after 60 seconds" -ForegroundColor Red
    Write-Host "[MaqAgr] Check log at: $pgLog" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Step 3: Create database + apply schema (first run only) ---
# Check if database exists (retry loop: right after startup a backend can
# still be settling even when SELECT 1 already succeeded).
$dbExistsText = ''
for ($i = 1; $i -le 5; $i++) {
    $dbExists = & "$pgBin\psql.exe" -h 127.0.0.1 -p $pgPort -U $pgUser -d postgres -w -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $dbExistsText = if ($dbExists) { ($dbExists -join "`n").Trim() } else { '' }
        break
    }
    Start-Sleep -Seconds 2
}
if ($dbExistsText -ne '1') {
    Write-Host "[MaqAgr] Creating database '$dbName'..." -ForegroundColor Cyan
    $createOutput = & "$pgBin\psql.exe" -h 127.0.0.1 -p $pgPort -U $pgUser -d postgres -w -v ON_ERROR_STOP=1 -v dbname=$dbName -f (Join-Path $backendDir 'database\01-create-db.sql') 2>&1
    $createOutput | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[MaqAgr] ERROR: Failed to create database (exit $LASTEXITCODE)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
# Check if the database already has tables (skip schema import on subsequent runs)
$tableCount = & "$pgBin\psql.exe" -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" 2>$null
$tableCountNum = 0
[int]::TryParse(($tableCount -join '').Trim(), [ref]$tableCountNum) | Out-Null
if ($tableCountNum -gt 0) {
    Write-Host "[MaqAgr] Database already initialized ($tableCountNum tables). Skipping schema import." -ForegroundColor DarkGray
} else {
    Write-Host "[MaqAgr] Applying database schema..." -ForegroundColor Cyan
    # If 03-supabase-data.sql exists, use it (full schema + data from Supabase).
    # Otherwise, fall back to 02-schema-migrations.sql (empty schema only).
    $supabaseDump = Join-Path $backendDir 'database\03-supabase-data.sql'
    $schemaFile = Join-Path $backendDir 'database\02-schema-migrations.sql'
    if (Test-Path $supabaseDump) {
        Write-Host "[MaqAgr] Loading Supabase data (schema + seed data)..." -ForegroundColor DarkCyan
        $schemaFile = $supabaseDump
    }
    $schemaOutput = & "$pgBin\psql.exe" -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -v ON_ERROR_STOP=1 -f $schemaFile 2>&1
    $schemaOutput | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[MaqAgr] ERROR: Failed to apply schema (exit $LASTEXITCODE)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Remove-Item Env:\PGPASSWORD
Remove-Item Env:\PGCLIENTENCODING

# --- Step 4: Set environment for backend ---
$env:PORT          = '4000'
$env:DB_HOST       = '127.0.0.1'
$env:DB_PORT       = "$pgPort"
$env:DB_NAME       = $dbName
$env:DB_USER       = $pgUser
$env:DB_PASS       = $pgPass
$env:DB_SSL        = 'false'
$env:REDIS_ENABLED = 'false'
$env:JWT_SECRET    = "maqagr-local-jwt-$(Get-Random)"
$env:JWT_EXPIRES_IN = '24h'
$env:NODE_ENV      = 'production'
$env:UPLOAD_DIR    = $uploadsDir
$env:LOG_DIR       = $logsDir
$env:FRONTEND_DIST = $frontendDist

# --- Step 5: Start backend ---
Write-Host "[MaqAgr] Starting application server..." -ForegroundColor Green
$nodeExe = Join-Path $nodeDir 'node.exe'
Push-Location $backendDir
$nodeProc = Start-Process -FilePath $nodeExe -ArgumentList 'src/app.js' -PassThru -NoNewWindow

# --- Step 6: Wait for backend + open browser ---
$ready = $false
for ($i = 1; $i -le 15; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-WebRequest -Uri 'http://localhost:4000/health' -UseBasicParsing -TimeoutSec 2
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
}

if ($ready) {
    Write-Host "[MaqAgr] Ready! Opening http://localhost:4000" -ForegroundColor Green
} else {
    Write-Host "[MaqAgr] Backend is still starting, opening browser..." -ForegroundColor Yellow
}
Start-Process 'http://localhost:4000'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MaqAgr is running at http://localhost:4000" -ForegroundColor White
Write-Host "  Close this window to stop the application." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Keep console alive until backend exits ---
$nodeProc.WaitForExit()

# --- Cleanup: stop PostgreSQL ---
Write-Host "[MaqAgr] Stopping database..." -ForegroundColor Yellow
# Try graceful shutdown via pg_ctl, but don't hang if it fails
try {
    $stopJob = Start-Job -ScriptBlock {
        param($pgBin, $pgDataDir)
        & "$pgBin\pg_ctl.exe" -D $pgDataDir -m fast stop 2>&1
    } -ArgumentList $pgBin, $pgDataDir
    Wait-Job $stopJob -Timeout 10 | Out-Null
    Stop-Job $stopJob -ErrorAction SilentlyContinue
    Remove-Job $stopJob -Force -ErrorAction SilentlyContinue
} catch {}
# Force-kill if still running
if ($pgProc -and -not $pgProc.HasExited) {
    try { Stop-Process -Id $pgProc.Id -Force -ErrorAction SilentlyContinue } catch {}
}
Pop-Location
Write-Host "[MaqAgr] Stopped." -ForegroundColor Gray
