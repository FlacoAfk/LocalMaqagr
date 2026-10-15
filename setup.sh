#!/usr/bin/env bash
# ============================================
# MaqAgr Local — Bash Setup Script
# ============================================
# Run: chmod +x setup.sh && ./setup.sh
# ============================================

set -euo pipefail

echo ""
echo "============================================"
echo "  MaqAgr Local — Setup Script"
echo "============================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REQUIRED_PNPM_VERSION="11.1.0"

# ── 1. Check Node.js >= 22 ────────────────────────────────────────────────
echo "[1/9] Checking Node.js..."
if ! command -v node &> /dev/null; then
  echo "  ERROR: Node.js not found. Install from https://nodejs.org"
  exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "  ERROR: Node.js >= 22 required. Found: v$NODE_VERSION"
  exit 1
fi
echo "  OK: v$NODE_VERSION"

# ── 2. Check pnpm availability (REQUIRED) ────────────────────────────────
echo "[2/7] Checking pnpm..."
if ! command -v pnpm &> /dev/null; then
  echo "  ERROR: pnpm is REQUIRED but not found."
  echo "  Enable Corepack and activate pnpm@$REQUIRED_PNPM_VERSION."
  exit 1
fi
PNPM_VERSION=$(pnpm --version)
if [ "$PNPM_VERSION" != "$REQUIRED_PNPM_VERSION" ]; then
  echo "  ERROR: pnpm@$REQUIRED_PNPM_VERSION is required. Found: $PNPM_VERSION"
  exit 1
fi
echo "  OK: pnpm $PNPM_VERSION"

# ── 3. Check local PostgreSQL ─────────────────────────────────────────────
echo "[3/7] Checking local PostgreSQL..."
if ! command -v psql &> /dev/null || ! command -v pg_isready &> /dev/null; then
  echo "  ERROR: PostgreSQL client tools (psql and pg_isready) are required."
  echo "  Install PostgreSQL from https://www.postgresql.org/download/"
  exit 1
fi
if ! pg_isready -h 127.0.0.1 -p 5432 -q; then
  echo "  ERROR: PostgreSQL is not accepting local connections on 127.0.0.1:5432."
  echo "  Start your local PostgreSQL server before continuing."
  exit 1
fi
echo "  OK: $(psql --version); server accepts local connections"

# ── 4. Auto-copy .env files ──────────────────────────────────────────────
echo "[4/7] Setting up .env files..."

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

# ── 5. Install dependencies ──────────────────────────────────────────────
echo "[5/7] Installing pinned dependencies with pnpm..."
cd "$SCRIPT_DIR"
pnpm install --frozen-lockfile
echo "  OK: Dependencies installed from lockfiles"

# ── 6. Create uploads directories ────────────────────────────────────────
echo "[6/7] Creating uploads directories..."
UPLOADS_BASE="$SCRIPT_DIR/backend/uploads"
for subdir in tractors implements users; do
  mkdir -p "$UPLOADS_BASE/$subdir"
done
echo "  OK: uploads/ directories created"

echo "[7/7] Database setup..."
echo "  Database/schema were not modified. This setup never runs legacy schema.sql (which drops tables)."
echo "  Configure backend/.env and apply the documented baseline to maqagr_local."

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "To start the application:"
echo "  cd \"$SCRIPT_DIR\""
echo "  pnpm run start:local"
echo ""
echo "Backend:  http://localhost:4000"
echo "Frontend: http://localhost:5173"
echo ""
