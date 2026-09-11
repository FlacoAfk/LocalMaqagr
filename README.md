# MaqAgr Local — Instalación 100% Offline

Aplicación de gestión agrícola que corre **completamente en local** sin
dependencias de nube (sin Cloudinary, sin Supabase, sin Redis externo).

## Arquitectura

```
┌─────────────────────────────────────────────┐
│  Instalador (.exe)  —  Inno Setup 6         │
│  Bundlea todo: Node + PostgreSQL + App      │
└──────────────────┬──────────────────────────┘
                   │ instala a
                   ▼
C:\Program Files\MaqAgr\          (read-only)
  ├── runtime\node\               Node.js portable v24
  ├── runtime\pgsql\              PostgreSQL 17 portable
  ├── app\backend\                Backend Express + API
  ├── app\frontend-dist\          Frontend React (build)
  ├── scripts\launcher.ps1        Orquestador
  ├── scripts\start-maqagr.bat    Acceso directo
  └── MaqAgr.ico

C:\ProgramData\MaqAgr\            (writable, runtime data)
  ├── pgdata\                     Data dir de PostgreSQL
  ├── uploads\                    Imágenes subidas
  └── logs\                       Logs de PG + Node
```

### Proceso único en puerto 4000

El backend Express sirve **todo** en un solo puerto:

| Ruta              | Qué sirve                         |
|-------------------|-----------------------------------|
| `/`               | Frontend SPA (React)              |
| `/api/*`          | API REST (auth, tractors, etc.)   |
| `/uploads/*`      | Imágenes almacenadas localmente   |
| `/api-docs`       | Documentación Swagger             |
| `/health`         | Health check                      |

### Storage de imágenes

Las imágenes se guardan en el **filesystem local**
(`C:\ProgramData\MaqAgr\uploads\{tractors,implements,users,general}\`).
No se usa Cloudinary ni ningún servicio cloud.

### Base de datos

PostgreSQL 17 portable corre en el **puerto 5435** (para no chocar
con instancias del sistema). La base de datos `maqagr_local` se
crea automáticamente en el primer arranque con el schema completo
+ migraciones estructurales.

## Instalación

1. Ejecutar `MaqAgr-Setup.exe` (requiere permisos de administrador).
2. Seguir el asistente (idioma español disponible).
3. Al finalizar, marcar "Iniciar MaqAgr" si se desea abrir ahora.
4. Un acceso directo se crea en el escritorio.

**Primer arranque**: el launcher inicializa PostgreSQL, crea la base
de datos y aplica el schema. Puede tardar ~30 segundos.

**Arranques posteriores**: inicia PG + backend y abre el navegador
en `http://localhost:4000` en ~5 segundos.

## Uso

- Doble clic en el acceso directo **MaqAgr** del escritorio.
- Se abre una consola que muestra el estado del servidor.
- El navegador se abre automáticamente en `http://localhost:4000`.
- Para detener: cerrar la ventana de consola.

## Datos del sistema

| Parámetro       | Valor                    |
|-----------------|--------------------------|
| Puerto app      | 4000                     |
| Puerto BD       | 5435                     |
| Usuario BD      | postgres                 |
| Password BD     | postgres                 |
| Nombre BD       | maqagr_local             |
| Data dir BD     | C:\ProgramData\MaqAgr\pgdata |
| Uploads dir     | C:\ProgramData\MaqAgr\uploads |

## Desinstalación

Desde "Agregar o quitar programas" → MaqAgr → Desinstalar.
Esto elimina los archivos de `C:\Program Files\MaqAgr` y
`C:\ProgramData\MaqAgr` (incluyendo la base de datos y las imágenes).

## Desarrollo

### Estructura del proyecto

```
MaqAgr-Local/
├── MaqAgr-Installer.iss    Script de Inno Setup
├── MaqAgr.ico              Icono de la app
├── scripts/
│   ├── launcher.ps1        Orquestador (PG + Node + browser)
│   └── start-maqagr.bat    Wrapper del launcher
├── runtime/
│   ├── node/               Node.js portable (no commitear)
│   └── pgsql/              PostgreSQL portable (no commitear)
├── backend/
│   ├── src/
│   │   ├── config/         db.js, storage.js (filesystem), redis.js (disabled)
│   │   ├── routes/         API routes
│   │   ├── middleware/     upload, security, cors, etc.
│   │   └── app.js          Express app (sirve SPA + API + uploads)
│   ├── database/
│   │   ├── 01-create-db.sql          CREATE DATABASE idempotente
│   │   ├── 02-schema-migrations.sql  Schema + migraciones consolidadas
│   │   └── migrations/               Migraciones originales (referencia)
│   ├── .env                Config local (DB_PORT=5435, REDIS_ENABLED=false)
│   └── package.json
├── frontend/
│   ├── dist/               Build de producción (servido por backend)
│   ├── src/
│   └── .env.local          VITE_API_URL=http://localhost:4000
└── build/
    └── MaqAgr-Setup.exe    Instalador compilado
```

### Reconstruir el instalador

```powershell
# 1. Asegurar que runtime/ tiene Node y PG portable
# 2. Asegurar que frontend/dist existe (pnpm run build)
# 3. Compilar con Inno Setup
& "C:\Program Files\Inno Setup 6\ISCC.exe" "MaqAgr-Installer.iss"
```

El `.exe` resultante estará en `build\MaqAgr-Setup.exe`.

- **Node.js** >= 18 (auto-installed via winget if missing)
- **PostgreSQL** (running on localhost:5432, auto-installed via winget if missing)
- **pnpm** (installed via corepack automatically)

## Quick Start

### Windows (PowerShell)

```powershell
cd app\LocalMaqagr
.\setup.ps1
.\launch.ps1
```

The installer will:
1. Check and install Node.js and PostgreSQL if missing
2. Create the `maqagr_local` database and run migrations
3. Set up environment files from templates
4. Install all dependencies (backend, frontend, root)
5. Create upload directories

### Linux / macOS

```bash
cd app/LocalMaqagr
chmod +x setup.sh
./setup.sh
```

## Manual Setup

If you prefer step-by-step control:

1. **Create the database**:
   ```sql
   CREATE DATABASE maqagr_local;
   ```

2. **Run the schema**:
   ```bash
   psql -U postgres -h localhost -d maqagr_local -f backend/database/schema.sql
   ```

3. **Run migrations**:
   ```bash
   psql -U postgres -h localhost -d maqagr_local -f backend/database/migrations/004_add_image_url_columns.sql
   psql -U postgres -h localhost -d maqagr_local -f backend/database/migrations/005_seed_image_urls.sql
   ```

4. **Install dependencies**:
   ```bash
   cd backend && pnpm install
   cd ../frontend && pnpm install
   cd .. && pnpm install
   ```

5. **Create environment files**:
   ```bash
   cp backend/.env.local.example backend/.env
   cp frontend/.env.example frontend/.env
   ```

6. **Start the application**:
   ```bash
   .\launch.ps1
   ```

## Running

```powershell
.\launch.ps1
```

This starts:
- **Backend**: http://localhost:4000 (in a new PowerShell window)
- **Frontend**: http://localhost:5173 (in the current window)

Press `Ctrl+C` to stop the frontend. Close the backend window to stop it.

## Setup Flags

```powershell
.\setup.ps1 -SkipInstall    # Skip Node/PG installation
.\setup.ps1 -SkipDB         # Skip database setup
.\setup.ps1 -SkipDeps       # Skip pnpm install
```

## Architecture

```
LocalMaqagr/
├── backend/          # Express API (local copy of BackMaqagr)
│   ├── src/
│   │   ├── config/
│   │   │   ├── storage.js      # Local filesystem storage (no Cloudinary)
│   │   │   ├── cloudinary.js   # No-op stub
│   │   │   ├── db.js           # PostgreSQL (localhost:5432/maqagr_local)
│   │   │   └── redis.js        # Redis (disabled by default)
│   │   ├── middleware/
│   │   │   └── upload.middleware.js  # Multer diskStorage
│   │   └── controllers/        # File upload via disk reads
│   ├── uploads/                # User-uploaded images
│   │   ├── tractors/
│   │   ├── implements/
│   │   └── users/
│   └── database/
│       ├── schema.sql
│       └── migrations/
├── frontend/         # React + Vite (local copy of MaqAgr)
│   └── .env          # Points to localhost:4000
├── setup.ps1         # Full installer (Windows)
├── setup.sh          # Linux/macOS installer
├── launch.ps1        # Launch script (Windows)
├── package.json      # Orchestrator (concurrently)
└── README.md
```

## Key Differences from Production

| Feature | Production (BackMaqagr) | Local (LocalMaqagr) |
|---------|------------------------|---------------------|
| Image storage | Cloudinary / GCS | Local filesystem (`uploads/`) |
| Database | Supabase (remote) | PostgreSQL (localhost) |
| Redis | Upstash (remote) | Disabled |
| Image URLs | `https://res.cloudinary.com/...` | `/uploads/tractors/...` |
| Frontend env | Vercel | `VITE_API_URL=http://localhost:4000` |

## Configuration

Edit `backend/.env` to customize:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=maqagr_local
DB_USER=postgres
DB_PASS=password
REDIS_ENABLED=false
JWT_SECRET=local-dev-secret
PORT=4000
```

## Notes

- **No code changes to originals**: This is a complete copy. `app/BackMaqagr/` and `app/MaqAgr/` are untouched.
- **ES Modules**: The backend uses `import`/`export` (not CommonJS).
- **Spanish naming**: Database tables and columns keep their original Spanish names.
- **Upload images**: Place images in `backend/uploads/tractors/` or `backend/uploads/implements/` and set `image_url` in the database to `/uploads/tractors/filename.jpg`.