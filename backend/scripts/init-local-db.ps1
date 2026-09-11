<#
.SYNOPSIS
  Provisions a local PostgreSQL database for the MaqAgr backend.

.DESCRIPTION
  Creates the application database (if missing) and applies the
  consolidated schema + structural migrations. Designed to be invoked
  by the Inno installer with a bundled portable PostgreSQL, or run
  manually for local development.

  Idempotent: re-running will not fail if objects already exist and
  will not destroy existing data.

.PARAMETER PgBin
  Path to the PostgreSQL 'bin' folder (contains psql.exe).
.PARAMETER PgHost
  PostgreSQL host. Default: localhost
.PARAMETER PgPort
  PostgreSQL port. Default: 5432
.PARAMETER DbUser
  PostgreSQL superuser. Default: postgres
.PARAMETER DbPass
  Password for DbUser. Default: postgres
.PARAMETER DbName
  Application database name. Default: maqagr_local

.EXAMPLE
  .\init-local-db.ps1 -PgBin "C:\PG\pgsql\bin" -PgPort 55432
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$PgBin,

    [string]$PgHost = 'localhost',
    [int]   $PgPort = 5432,
    [string]$DbUser = 'postgres',
    [string]$DbPass = 'postgres',
    [string]$DbName = 'maqagr_local'
)

# 'Continue' (not 'Stop'): psql emits NOTICE messages on stderr for
# idempotent skips (IF NOT EXISTS). Under 'Stop', PowerShell 5.1 treats
# native-command stderr as terminating errors when output is captured,
# which would abort the script on harmless NOTICES. We rely on explicit
# $LASTEXITCODE checks + throw for real failures instead.
$ErrorActionPreference = 'Continue'

# --- Resolve artifact paths (scripts/ -> ../database/) ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DatabaseDir = Join-Path $ScriptDir '..\database'
if (-not (Test-Path -LiteralPath $DatabaseDir)) {
    throw "Database directory not found: $DatabaseDir"
}
$DatabaseDir = (Resolve-Path -LiteralPath $DatabaseDir).Path
$CreateDbSql = Join-Path $DatabaseDir '01-create-db.sql'
$SchemaSql   = Join-Path $DatabaseDir '02-schema-migrations.sql'

# --- Validate prerequisites ---
$Psql = Join-Path $PgBin 'psql.exe'
if (-not (Test-Path -LiteralPath $Psql)) {
    throw "psql.exe not found at: $Psql"
}
if (-not (Test-Path -LiteralPath $CreateDbSql)) {
    throw "Create-DB script not found: $CreateDbSql"
}
if (-not (Test-Path -LiteralPath $SchemaSql)) {
    throw "Schema-migrations script not found: $SchemaSql"
}

# --- Set PGPASSWORD so psql authenticates without prompting ---
$env:PGPASSWORD = $DbPass

$psqlBase = @('-h', $PgHost, '-p', $PgPort, '-U', $DbUser, '-v', 'ON_ERROR_STOP=1')

Write-Host "==> Provisioning database '$DbName' on ${PgHost}:$PgPort" -ForegroundColor Cyan

# --- Step 1: Create the database (against the maintenance 'postgres' DB) ---
Write-Host "==> [1/2] Creating database '$DbName' (if not exists)..." -ForegroundColor Cyan
$createArgs = $psqlBase + @('-d', 'postgres', '-v', "dbname=$DbName", '-f', $CreateDbSql)
& $Psql @createArgs
if ($LASTEXITCODE -ne 0) {
    throw "Database creation failed (psql exit code $LASTEXITCODE)."
}
Write-Host "[== OK ==] Database '$DbName' is ready." -ForegroundColor Green

# --- Step 2: Apply schema + migrations (against the application DB) ---
Write-Host "==> [2/2] Applying schema + structural migrations..." -ForegroundColor Cyan
$schemaArgs = $psqlBase + @('-d', $DbName, '-f', $SchemaSql)
& $Psql @schemaArgs
if ($LASTEXITCODE -ne 0) {
    throw "Schema/migrations failed (psql exit code $LASTEXITCODE)."
}
Write-Host "[== OK ==] Schema and migrations applied to '$DbName'." -ForegroundColor Green

# --- Verify: list tables ---
Write-Host "==> Verifying tables in '$DbName'..." -ForegroundColor Cyan
$verifyArgs = $psqlBase + @('-d', $DbName, '-c', "\dt")
& $Psql @verifyArgs
if ($LASTEXITCODE -ne 0) {
    throw "Table verification failed (psql exit code $LASTEXITCODE)."
}

Write-Host ""
Write-Host "[== OK ==] Local database provisioning complete." -ForegroundColor Green
