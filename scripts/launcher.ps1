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

$pgPort = 25435
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
$env:PGCONNECT_TIMEOUT = '5'

# --- Step 1: Initialize PostgreSQL (first run only) ---
if (-not (Test-Path (Join-Path $pgDataDir 'PG_VERSION'))) {
    Write-Host "[MaqAgr] First run: initializing database..." -ForegroundColor Cyan
    $pwFile = Join-Path $logsDir '.pgpass_init'
    Set-Content -Path $pwFile -Value $pgPass -NoNewline
    $initOutput = & "$pgBin\initdb.exe" -D $pgDataDir -U $pgUser --auth-local=md5 --auth-host=md5 --pwfile=$pwFile 2>&1
    $initExitCode = $LASTEXITCODE
    Remove-Item -LiteralPath $pwFile -Force -ErrorAction SilentlyContinue
    $initOutput | Out-Host
    if ($initExitCode -ne 0) {
        Write-Host "[MaqAgr] ERROR: initdb failed (exit $initExitCode)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
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
        $pidText = Get-Content -LiteralPath $pidFile -First 1 -ErrorAction SilentlyContinue
        if (-not [int]::TryParse(([string]$pidText).Trim(), [ref]$recordedPid) -or $recordedPid -le 0) {
            Write-Host "[MaqAgr] ERROR: Cannot verify database lock. Preserve it and inspect $pidFile." -ForegroundColor Red
            exit 1
        }
        $pidAlive = $false
        if ($recordedPid -gt 0) { try { $null = Get-Process -Id $recordedPid -ErrorAction Stop; $pidAlive = $true } catch {} }
        if (-not $pidAlive) {
            Write-Host "[MaqAgr] Cleaning up stale lock file..." -ForegroundColor DarkYellow
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        } else {
            # A live PID may belong to another process, or PostgreSQL may still
            # be recovering. Never terminate it or remove its active lock.
            Write-Host "[MaqAgr] ERROR: Database lock belongs to live PID $recordedPid. Wait for recovery or inspect the database log." -ForegroundColor Red
            exit 1
        }
    }

    Write-Host "[MaqAgr] Starting database on port $pgPort..." -ForegroundColor Cyan
    $pgLog = Join-Path $logsDir 'postgresql.log'
    # Start postgres.exe DIRECTLY instead of pg_ctl. On machines with existing
    # system PostgreSQL installations, pg_ctl's internal process management
    # triggers a DLL conflict (0xC0000142 / STATUS_DLL_INIT_FAILED) that hangs
    # indefinitely. postgres.exe started via Start-Process avoids this entirely.
    $pgExe = Join-Path $pgBin 'postgres.exe'
    $pgProc = Start-Process -FilePath $pgExe -ArgumentList "-D `"$pgDataDir`" -p $pgPort -h 127.0.0.1" -RedirectStandardError $pgLog -NoNewWindow -PassThru
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
    Start-Sleep -Seconds 1
}
Write-Host ""
if (-not $pgQueryReady) {
    Write-Host "[MaqAgr] ERROR: Database is not accepting queries after 60 seconds" -ForegroundColor Red
    Write-Host "[MaqAgr] Check log at: $pgLog" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
# Readiness alone does not prove this is our portable cluster: another service
# may occupy the port. Refuse to alter any database outside the expected path.
$connectedDataDir = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d postgres -w -tAc "SHOW data_directory" 2>$null
if ($LASTEXITCODE -ne 0 -or -not [string]::Equals(($connectedDataDir -join '').Trim().Replace('/', '\').TrimEnd('\'), $pgDataDir.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "[MaqAgr] ERROR: Port $pgPort does not belong to the expected database at $pgDataDir." -ForegroundColor Red
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
if ($LASTEXITCODE -ne 0 -or -not [int]::TryParse(($tableCount -join '').Trim(), [ref]$tableCountNum)) {
    Write-Host "[MaqAgr] ERROR: Could not inspect database schema." -ForegroundColor Red
    exit 1
}
if ($tableCountNum -gt 0) {
    # A failed older (nontransactional) dump can leave a few tables behind.
    # Do not interpret those as a completed import or overwrite user data.
    $coreTables = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name IN ('role','users','terrain','tractor','implement','query','power_loss','recommendation','query_history')" 2>$null
    if ($LASTEXITCODE -ne 0 -or ($coreTables -join '').Trim() -ne '9') {
        Write-Host "[MaqAgr] ERROR: Incomplete database schema. Back up $pgDataDir and restore a complete database; no data has been deleted." -ForegroundColor Red
        exit 1
    }
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
    # The dump has no transaction wrapper; a failed import must roll back.
    # The fallback baseline already includes BEGIN/COMMIT.
    $transactionArgs = if ($schemaFile -eq $supabaseDump) { @('--single-transaction') } else { @() }
    $schemaOutput = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -v ON_ERROR_STOP=1 @transactionArgs -f $schemaFile 2>&1
    if ($LASTEXITCODE -ne 0) {
        $schemaOutput | Out-Host
        Write-Host "[MaqAgr] ERROR: Failed to apply schema (exit $LASTEXITCODE)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    } else {
        $schemaErrores = @($schemaOutput | Where-Object { "$_" -match 'ERROR|FATAL' })
        if ($schemaErrores.Count -gt 0) { $schemaErrores | Out-Host }
        Write-Host "[MaqAgr] Schema applied." -ForegroundColor DarkGray
    }
}

# Apply the data-preserving baseline once to legacy installs and full dumps.
# The dump does not contain every structural migration. Mark completion only
# after the transactional baseline succeeds; retries are idempotent.
$markerExists = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -tAc "SELECT to_regclass('public.maqagr_schema_migrations') IS NOT NULL" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host '[MaqAgr] ERROR: Cannot inspect schema migration state.' -ForegroundColor Red; exit 1 }
$baselineApplied = ''
if (($markerExists -join '').Trim() -eq 't') {
    $baselineApplied = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -tAc "SELECT version FROM public.maqagr_schema_migrations WHERE version='baseline-008'" 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host '[MaqAgr] ERROR: Cannot read schema migration state.' -ForegroundColor Red; exit 1 }
}
if (($baselineApplied -join '').Trim() -ne 'baseline-008') {
    $baselineOutput = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -v ON_ERROR_STOP=1 -f (Join-Path $backendDir 'database\02-schema-migrations.sql') -c "BEGIN; CREATE TABLE IF NOT EXISTS public.maqagr_schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now()); INSERT INTO public.maqagr_schema_migrations(version) VALUES ('baseline-008') ON CONFLICT DO NOTHING; COMMIT;" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $baselineOutput | Out-Host
        Write-Host '[MaqAgr] ERROR: Baseline migration failed. Startup aborted.' -ForegroundColor Red; exit 1
    } else {
        $baselineErrores = @($baselineOutput | Where-Object { "$_" -match 'ERROR|FATAL' })
        if ($baselineErrores.Count -gt 0) { $baselineErrores | Out-Host }
        Write-Host "[MaqAgr] Baseline verified." -ForegroundColor DarkGray
    }
}
# Idempotent forward migrations apply on every launch, including legacy DBs.
$migrationOutput = & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $pgPort -U $pgUser -d $dbName -w -v ON_ERROR_STOP=1 --single-transaction -f (Join-Path $backendDir 'database\migrations\009_add_ficha_pdf.sql') -f (Join-Path $backendDir 'database\migrations\010_add_prioridad.sql') -f (Join-Path $backendDir 'database\migrations\011_add_mfwd_traction_type.sql') 2>&1
if ($LASTEXITCODE -ne 0) {
    $migrationOutput | Out-Host
    Write-Host '[MaqAgr] ERROR: Schema upgrade failed. Startup aborted.' -ForegroundColor Red; exit 1
} else {
    # psql escribe los NOTICE idempotentes por stderr y PowerShell 5.1 los
    # pinta como RemoteException; con exit 0 se ocultan y solo se muestran
    # errores reales.
    $migrationErrores = @($migrationOutput | Where-Object { "$_" -match 'ERROR|FATAL' })
    if ($migrationErrores.Count -gt 0) { $migrationErrores | Out-Host }
    Write-Host "[MaqAgr] Schema up to date." -ForegroundColor DarkGray
}
Remove-Item Env:\PGPASSWORD
Remove-Item Env:\PGCLIENTENCODING
Remove-Item Env:\PGCONNECT_TIMEOUT

# --- Step 4: Set environment for backend ---
$env:PORT          = '24688'
$env:HOST          = '127.0.0.1'
$env:TRUST_PROXY_HOPS = '0'
$env:DB_HOST       = '127.0.0.1'
$env:DB_PORT       = "$pgPort"
$env:DB_NAME       = $dbName
$env:DB_USER       = $pgUser
$env:DB_PASS       = $pgPass
$env:DB_SSL        = 'false'
$env:REDIS_ENABLED = 'false'
# Keep signing keys across restarts without exposing them in shared ProgramData.
# CreateNew prevents concurrent launches from overwriting an existing key.
try {
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable.' }
    $secretDir = Join-Path $env:LOCALAPPDATA 'MaqAgr'
    New-Item -ItemType Directory -Force -Path $secretDir -ErrorAction Stop | Out-Null
    $secretFile = Join-Path $secretDir 'jwt-secret'
    if (-not (Test-Path -LiteralPath $secretFile)) {
        $secretBytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($secretBytes) } finally { $rng.Dispose() }
        $secretText = [Convert]::ToBase64String($secretBytes)
        try {
            $secretStream = [System.IO.File]::Open($secretFile, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                $secretEncoded = [System.Text.Encoding]::UTF8.GetBytes($secretText)
                $secretStream.Write($secretEncoded, 0, $secretEncoded.Length)
            } finally { $secretStream.Dispose() }
        } catch [System.IO.IOException] {
            if (-not (Test-Path -LiteralPath $secretFile)) { throw }
        }
    }
    $secretText = (Get-Content -LiteralPath $secretFile -Raw -ErrorAction Stop).Trim()
    if ([Convert]::FromBase64String($secretText).Length -ne 32) { throw 'Invalid persisted signing key.' }
    $env:JWT_SECRET = $secretText
} catch {
    Write-Host "[MaqAgr] ERROR: Cannot load persistent signing key: $_" -ForegroundColor Red
    exit 1
}
$env:JWT_EXPIRES_IN = '24h'
$env:NODE_ENV      = 'production'
$env:UPLOAD_DIR    = $uploadsDir
$env:LOG_DIR       = $logsDir
$env:FRONTEND_DIST = $frontendDist

# --- Step 4a: Unpack node_modules payload (first run or upgrade) ---
# The installer ships server dependencies as ONE archive (vendor/node_modules.zip)
# instead of ~24k loose files: some machines deterministically lose random
# folders during a mass extraction. We unpack it once and record the zip's
# size+mtime in the marker, so an upgraded payload re-extracts automatically.
$nmRoot = Join-Path $backendDir 'node_modules'
$nmPayload = Join-Path $backendDir 'vendor\node_modules.zip'
$nmMarker = Join-Path $nmRoot '.maqagr-node-modules-ok'
$nmFingerprint = if (Test-Path $nmPayload) {
    $z = Get-Item $nmPayload
    "$($z.Length):$($z.LastWriteTimeUtc.Ticks)"
} else { '' }
$nmPrevious = ''
if (Test-Path $nmMarker) { $nmPrevious = (Get-Content -LiteralPath $nmMarker -Raw -ErrorAction SilentlyContinue) }
if ($nmFingerprint -and ($nmPrevious -ne $nmFingerprint)) {
    Write-Host "[MaqAgr] Preparing server modules (this can take a few minutes)..." -ForegroundColor Cyan
    # Keep the node_modules root (it carries the users-modify permission);
    # clear only its contents. Mirror an empty directory with robocopy /MIR:
    # it deletes everything inside node_modules, including long paths
    # (>260 chars) that Remove-Item cannot handle under PS 5.1.
    if (Test-Path $nmRoot) {
        $emptyDir = Join-Path ([System.IO.Path]::GetTempPath()) ('maqagr-empty-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $emptyDir | Out-Null
        robocopy $emptyDir $nmRoot /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
        Remove-Item $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $extracted = $false
    $extractError = ''
    # 1) tar.exe (bsdtar, bundled with Windows 10+): fast and overwrites.
    $tarExe = Join-Path $env:SystemRoot 'System32\tar.exe'
    if (Test-Path $tarExe) {
        & $tarExe -xf $nmPayload -C $backendDir
        if ($LASTEXITCODE -eq 0) { $extracted = $true } else { $extractError = "tar exit $LASTEXITCODE" }
    } else { $extractError = 'tar.exe ausente' }
    # 2) .NET ZipFile: fast, but cannot overwrite (the clear step above matters).
    if (-not $extracted) {
        Write-Host "[MaqAgr] Aviso: tar fallo ($extractError); probando .NET ZipFile..." -ForegroundColor DarkYellow
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            [System.IO.Compression.ZipFile]::ExtractToDirectory($nmPayload, $backendDir)
            $extracted = $true
        } catch { $extractError = $_.Exception.Message }
    }
    # 3) Expand-Archive: slow but ubiquitous.
    if (-not $extracted) {
        Write-Host "[MaqAgr] Aviso: .NET ZipFile fallo ($extractError); probando Expand-Archive..." -ForegroundColor DarkYellow
        try {
            Expand-Archive -Path $nmPayload -DestinationPath $backendDir -Force
            $extracted = $true
        } catch { $extractError = $_.Exception.Message }
    }
    if (-not $extracted) {
        Write-Host "[MaqAgr] ERROR: no se pudieron descomprimir los modulos del servidor ($extractError)." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    New-Item -ItemType File -Path $nmMarker -Force | Out-Null
    Set-Content -LiteralPath $nmMarker -Value $nmFingerprint -NoNewline
    Write-Host "[MaqAgr] Server modules ready." -ForegroundColor Green
}

# --- Step 4b: Pre-flight de módulos críticos ---
# Una instalación interrumpida (antivirus, política de seguridad, cierre del
# instalador) deja node_modules incompleto y node muere con un
# ERR_MODULE_NOT_FOUND que no le dice nada al usuario. Verificamos antes.
$criticalModules = @('ip-address', 'express-rate-limit', 'sharp', 'detect-libc')
$missingModules = @()
foreach ($mod in $criticalModules) {
    if (-not (Test-Path (Join-Path $backendDir "node_modules\$mod\package.json"))) {
        $missingModules += $mod
    }
}
# --- Step 4c: Autorreparacion desde la copia de respaldo del instalador ---
# Algunas maquinas pierden deterministicamente una carpeta de node_modules
# durante la extraccion (observado con ip-address). El instalador trae un zip
# de respaldo de los modulos JS criticos; si falta alguno, se restaura solo.
if ($missingModules.Count -gt 0) {
    $vendorZip = Join-Path $backendDir 'vendor\modulos-criticos.zip'
    if (Test-Path $vendorZip) {
        Write-Host "[MaqAgr] Faltan modulos; restaurando desde la copia de respaldo del instalador..." -ForegroundColor Cyan
        $restoreTmp = Join-Path ([System.IO.Path]::GetTempPath()) ('maqagr-restore-' + [guid]::NewGuid().ToString('N'))
        try {
            Expand-Archive -Path $vendorZip -DestinationPath $restoreTmp -Force
            foreach ($mod in $missingModules) {
                $srcDir = Join-Path $restoreTmp $mod
                if (Test-Path $srcDir) {
                    Copy-Item -Path $srcDir -Destination (Join-Path $backendDir "node_modules\$mod") -Recurse -Force
                    Write-Host "[MaqAgr] restaurado: $mod" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "[MaqAgr] Aviso: la autorreparacion no pudo completarse ($($_.Exception.Message))" -ForegroundColor DarkYellow
        } finally {
            Remove-Item $restoreTmp -Recurse -Force -ErrorAction SilentlyContinue
        }
        # Re-verificar tras la restauracion
        $missingModules = @()
        foreach ($mod in $criticalModules) {
            if (-not (Test-Path (Join-Path $backendDir "node_modules\$mod\package.json"))) { $missingModules += $mod }
        }
    }
}

if ($missingModules.Count -gt 0) {
    Write-Host "[MaqAgr] ERROR: La instalacion quedo incompleta." -ForegroundColor Red
    Write-Host "[MaqAgr] Faltan modulos: $($missingModules -join ', ')." -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "[MaqAgr] Para repararla:" -ForegroundColor Yellow
    Write-Host "  1) Configuracion > Aplicaciones > MaqAgr > Desinstalar" -ForegroundColor Yellow
    Write-Host "  2) Si la carpeta queda, borra: C:\Program Files\MaqAgr" -ForegroundColor Yellow
    Write-Host "  3) Ejecuta MaqAgr-Setup.exe como administrador (descargalo de nuevo" -ForegroundColor Yellow
    Write-Host "     de la pagina de releases del proyecto)" -ForegroundColor Yellow
    Read-Host "Presiona Enter para salir"
    exit 1
}

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
        $r = Invoke-WebRequest -Uri 'http://localhost:24688/health' -UseBasicParsing -TimeoutSec 2
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
}

if ($ready) {
    Write-Host "[MaqAgr] Ready! Opening http://localhost:24688" -ForegroundColor Green
} else {
    Write-Host "[MaqAgr] Backend is still starting, opening browser..." -ForegroundColor Yellow
}
Start-Process 'http://localhost:24688'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MaqAgr is running at http://localhost:24688" -ForegroundColor White
Write-Host "  Close this window to stop the application." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Keep console alive until backend exits ---
$nodeProc.WaitForExit()

# --- Cleanup: stop only the PostgreSQL process started by this launcher ---
if ($pgProc) {
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
}
Pop-Location
Write-Host "[MaqAgr] Stopped." -ForegroundColor Gray
