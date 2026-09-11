#!/usr/bin/env bash
#
# init-local-db.sh — Bash mirror of init-local-db.ps1
# Provisions a local PostgreSQL database for the MaqAgr backend.
#
# Usage:
#   ./init-local-db.sh -b /path/to/pgsql/bin [-H localhost] [-p 5432] \
#                      [-U postgres] [-P postgres] [-d maqagr_local]
#
set -euo pipefail

PgBin=""
PgHost="localhost"
PgPort="5432"
DbUser="postgres"
DbPass="postgres"
DbName="maqagr_local"

while getopts "b:H:p:U:P:d:h" opt; do
    case "$opt" in
        b) PgBin="$OPTARG" ;;
        H) PgHost="$OPTARG" ;;
        p) PgPort="$OPTARG" ;;
        U) DbUser="$OPTARG" ;;
        P) DbPass="$OPTARG" ;;
        d) DbName="$OPTARG" ;;
        h)
            echo "Usage: $0 -b <pg_bin_dir> [-H host] [-p port] [-U user] [-P pass] [-d dbname]"
            exit 0
            ;;
        *) exit 1 ;;
    esac
done

if [ -z "$PgBin" ]; then
    echo "ERROR: -b (PgBin) is required." >&2
    exit 1
fi

PSQL="$PgBin/psql"
if [ ! -x "$PSQL" ] && [ ! -f "$PSQL" ]; then
    echo "ERROR: psql not found at: $PSQL" >&2
    exit 1
fi

# Resolve artifact paths (scripts/ -> ../database/)
ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DatabaseDir="$(cd "$ScriptDir/../database" && pwd)"
CreateDbSql="$DatabaseDir/01-create-db.sql"
SchemaSql="$DatabaseDir/02-schema-migrations.sql"

for f in "$CreateDbSql" "$SchemaSql"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: SQL artifact not found: $f" >&2
        exit 1
    fi
done

export PGPASSWORD="$DbPass"

PSQL_BASE=(-h "$PgHost" -p "$PgPort" -U "$DbUser" -v ON_ERROR_STOP=1)

echo "==> Provisioning database '$DbName' on ${PgHost}:${PgPort}"

echo "==> [1/2] Creating database '$DbName' (if not exists)..."
"$PSQL" "${PSQL_BASE[@]}" -d postgres -v "dbname=$DbName" -f "$CreateDbSql"
echo "[== OK ==] Database '$DbName' is ready."

echo "==> [2/2] Applying schema + structural migrations..."
"$PSQL" "${PSQL_BASE[@]}" -d "$DbName" -f "$SchemaSql"
echo "[== OK ==] Schema and migrations applied to '$DbName'."

echo "==> Verifying tables in '$DbName'..."
"$PSQL" "${PSQL_BASE[@]}" -d "$DbName" -c "\dt"

echo ""
echo "[== OK ==] Local database provisioning complete."
