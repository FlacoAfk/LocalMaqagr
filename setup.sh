#!/usr/bin/env bash
# ============================================
# MaqAgr Local — Bash Setup Script
# ============================================
# Run: chmod +x setup.sh && ./setup.sh
# ============================================

set -e

echo ""
echo "============================================"
echo "  MaqAgr Local — Setup Script"
echo "============================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Check Node.js >= 18 ────────────────────────────────────────────────
echo "[1/9] Checking Node.js..."
if ! command -v node &> /dev/null; then
  echo "  ERROR: Node.js not found. Install from https://nodejs.org"
  exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "  ERROR: Node.js >= 18 required. Found: v$NODE_VERSION"
  exit 1
fi
echo "  OK: v$NODE_VERSION"

# ── 2. Check pnpm availability (REQUIRED) ────────────────────────────────
echo "[2/9] Checking pnpm..."
if ! command -v pnpm &> /dev/null; then
  echo "  ERROR: pnpm is REQUIRED but not found."
  echo "  Install with: npm install -g pnpm"
  exit 1
fi
echo "  OK: pnpm $(pnpm --version)"

# ── 3. Check PostgreSQL ───────────────────────────────────────────────────
echo "[3/9] Checking PostgreSQL..."
if ! command -v psql &> /dev/null; then
  echo "  ERROR: PostgreSQL (psql) not found. Install from https://www.postgresql.org/download/"
  exit 1
fi
echo "  OK: $(psql --version)"

# ── 4. Create database ───────────────────────────────────────────────────
echo "[4/9] Creating database maqagr_local..."
export PGPASSWORD="password"
DB_EXISTS=$(psql -U postgres -h localhost -tc "SELECT 1 FROM pg_database WHERE datname='maqagr_local'" 2>/dev/null | grep -c "1" || true)
if [ "$DB_EXISTS" -eq 0 ]; then
  psql -U postgres -h localhost -c "CREATE DATABASE maqagr_local;" 2>/dev/null || true
  echo "  OK: Database maqagr_local created"
else
  echo "  OK: Database maqagr_local already exists"
fi

# ── 5. Run schema.sql ────────────────────────────────────────────────────
echo "[5/9] Running schema.sql..."
SCHEMA_PATH="$SCRIPT_DIR/backend/database/schema.sql"
if [ -f "$SCHEMA_PATH" ]; then
  psql -U postgres -h localhost -d maqagr_local -f "$SCHEMA_PATH" 2>/dev/null
  echo "  OK: Schema applied"
else
  echo "  WARN: schema.sql not found at $SCHEMA_PATH"
fi

# ── 6. Run migrations ────────────────────────────────────────────────────
echo "[6/9] Running migrations..."
MIGRATIONS_DIR="$SCRIPT_DIR/backend/database/migrations"
if [ -d "$MIGRATIONS_DIR" ]; then
  for f in $(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    echo "  Running $(basename "$f")..."
    psql -U postgres -h localhost -d maqagr_local -f "$f" 2>/dev/null
  done
  echo "  OK: Migrations applied"
else
  echo "  WARN: migrations/ directory not found"
fi

# ── 7. Auto-copy .env files ──────────────────────────────────────────────
echo "[7/9] Setting up .env files..."

# Backend: .env.local.example → .env
if [ -f "$SCRIPT_DIR/backend/.env.local.example" ] && [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
  cp "$SCRIPT_DIR/backend/.env.local.example" "$SCRIPT_DIR/backend/.env"
  echo "  OK: backend/.env created from .env.local.example"
elif [ -f "$SCRIPT_DIR/backend/.env" ]; then
  echo "  OK: backend/.env already exists"
else
  echo "  WARN: backend/.env.local.example not found"
fi

# Frontend: .env.example → .env
if [ -f "$SCRIPT_DIR/frontend/.env.example" ] && [ ! -f "$SCRIPT_DIR/frontend/.env" ]; then
  cp "$SCRIPT_DIR/frontend/.env.example" "$SCRIPT_DIR/frontend/.env"
  echo "  OK: frontend/.env created from .env.example"
elif [ -f "$SCRIPT_DIR/frontend/.env" ]; then
  echo "  OK: frontend/.env already exists"
else
  echo "  WARN: frontend/.env.example not found"
fi

# ── 8. pnpm install ──────────────────────────────────────────────────────
echo "[8/9] Installing dependencies with pnpm..."

echo "  Installing backend dependencies..."
cd "$SCRIPT_DIR/backend"
pnpm install

echo "  Installing frontend dependencies..."
cd "$SCRIPT_DIR/frontend"
pnpm install

echo "  OK: Dependencies installed"

# ── 9. Create uploads directories ────────────────────────────────────────
echo "[9/9] Creating uploads directories..."
UPLOADS_BASE="$SCRIPT_DIR/backend/uploads"
for subdir in tractors implements users; do
  mkdir -p "$UPLOADS_BASE/$subdir"
done
echo "  OK: uploads/ directories created"

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "To start the application:"
echo "  cd app/LocalMaqagr"
echo "  pnpm run start:local"
echo ""
echo "Backend:  http://localhost:4000"
echo "Frontend: http://localhost:5173"
echo ""
