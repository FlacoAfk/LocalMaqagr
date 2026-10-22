@echo off
setlocal
cd /d "%~dp0"
if errorlevel 1 goto directory_failed
title MaqAgr Local - Installer
color 0A
mode con: cols=70 lines=40

echo.
echo   ╔═══════════════════════════════════════════════════════════╗
echo   ║                                                           ║
echo   ║          MAQ AGR LOCAL - INSTALADOR                      ║
echo   ║          Plataforma de Maquinaria Agricola               ║
echo   ║                                                           ║
echo   ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Este instalador prepara todo para ejecutar la plataforma
echo   de calculo de potencia de maquinaria agricola.
echo.
echo   Requisitos: Windows 10/11, Node.js 22 o superior y Corepack
echo   PostgreSQL local y herramientas psql y pg_isready en PATH.
echo   Configure manualmente backend/.env con sus credenciales locales.
echo   Cree maqagr_local y aplique el baseline documentado antes de iniciar.
echo.
echo   ═══════════════════════════════════════════════════════════
echo.

:: ── Step 1: Check/Install Node.js ──
echo   [1/6] Verificando Node.js...
where node >nul 2>&1
if not errorlevel 1 goto check_node_version
echo   Node.js no encontrado. Instalando...
where winget >nul 2>&1
if errorlevel 1 goto node_failed
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
if errorlevel 1 goto node_failed
set "PATH=%PATH%;C:\Program Files\nodejs"
where node >nul 2>&1
if errorlevel 1 goto node_failed

:check_node_version
node -e "process.exit(Number(process.versions.node.split('.')[0]) >= 22 ? 0 : 1)"
if errorlevel 1 goto node_failed
echo   [OK] Node.js 22 o superior encontrado
echo.

:: ── Step 2: Enable pnpm ──
echo   [2/6] Configurando pnpm...
where corepack >nul 2>&1
if errorlevel 1 goto corepack_failed
call corepack enable
if errorlevel 1 goto corepack_failed
call corepack prepare pnpm@11.1.0 --activate
if errorlevel 1 goto corepack_failed
node -e "try { const actual = require('child_process').execSync('corepack pnpm --version', { encoding: 'utf8' }).trim(); if (actual !== '11.1.0') { console.error('pnpm esperado: 11.1.0; encontrado: ' + actual); process.exit(1); } } catch (error) { console.error(error.message); process.exit(1); }"
if errorlevel 1 goto corepack_failed
echo   [OK] pnpm 11.1.0 listo
echo.

:: Check server readiness only; credentials and schema remain manual prerequisites.
echo   [3/6] Verificando PostgreSQL local...
where psql >nul 2>&1
if errorlevel 1 goto postgres_tools_failed
where pg_isready >nul 2>&1
if errorlevel 1 goto postgres_tools_failed
pg_isready -h 127.0.0.1 -p 5432 -q
if errorlevel 1 goto postgres_failed
echo   [OK] PostgreSQL acepta conexiones en 127.0.0.1:5432.
echo   No se verificaron credenciales, base de datos ni esquema.
echo.

:: ── Step 3: Create .env files ──
echo   [4/6] Configurando entorno...
if not exist "backend\.env" (
    if exist "backend\.env.local.example" (
        copy "backend\.env.local.example" "backend\.env" >nul
        if errorlevel 1 goto environment_failed
        echo   [OK] backend/.env creado
    )
)
if not exist "frontend\.env" (
    if exist "frontend\.env.example" (
        copy "frontend\.env.example" "frontend\.env" >nul
        if errorlevel 1 goto environment_failed
        echo   [OK] frontend/.env creado
    )
)
echo.

:: ── Step 4: Install dependencies ──
echo   [5/6] Instalando dependencias (puede tardar 2-3 minutos)...
echo.

echo   Instalando herramientas, backend y frontend desde la raiz...
call corepack pnpm install --frozen-lockfile
if errorlevel 1 goto install_failed
echo   [OK] Dependencias instaladas
echo.

:: ── Step 5: Create upload dirs ──
echo   [6/6] Preparando directorios...
if not exist "backend\uploads\tractors" (
    mkdir "backend\uploads\tractors"
    if errorlevel 1 goto directory_failed
)
if not exist "backend\uploads\implements" (
    mkdir "backend\uploads\implements"
    if errorlevel 1 goto directory_failed
)
if not exist "backend\uploads\users" (
    mkdir "backend\uploads\users"
    if errorlevel 1 goto directory_failed
)
echo   [OK] Directorios listos
echo.

:: ── Done ──
echo   AVISO: Las credenciales de backend/.env y el baseline de maqagr_local
echo   son requisitos manuales. Este instalador no modifica la base de datos.
echo   La disponibilidad del servidor no garantiza que la aplicacion pueda conectarse.
echo.
echo   ═══════════════════════════════════════════════════════════
echo.
echo   ╔═══════════════════════════════════════════════════════════╗
echo   ║              INSTALACION COMPLETADA                      ║
echo   ╠═══════════════════════════════════════════════════════════╣
echo   ║                                                           ║
echo   ║   Iniciando servidores...                                 ║
echo   ║                                                           ║
echo   ║   Backend:  http://localhost:24688                          ║
echo   ║   Frontend: http://localhost:5173                          ║
echo   ║                                                           ║
echo   ║   Abra su navegador en: http://localhost:5173              ║
echo   ║                                                           ║
echo   ║   Para detener: cierre esta ventana                       ║
echo   ║                                                           ║
echo   ╚═══════════════════════════════════════════════════════════╝
echo.

:: Start backend in new window
start "MaqAgr Backend" cmd /k "cd backend && corepack pnpm run start"
if errorlevel 1 goto startup_failed

:: Wait for backend to start
timeout /t 4 /nobreak >nul
if errorlevel 1 goto startup_failed

:: Start frontend in current window
echo   Frontend iniciando... espere unos segundos
echo.
cd /d "%~dp0frontend"
if errorlevel 1 goto directory_failed
call corepack pnpm run dev
if errorlevel 1 goto startup_failed
exit /b 0

:node_failed
echo   ERROR: Se requiere Node.js 22 o superior.
echo   Instale o actualice Node.js desde https://nodejs.org y abra una nueva ventana.
goto failed

:corepack_failed
echo   ERROR: No se pudo configurar Corepack con pnpm 11.1.0.
echo   Instale Corepack si falta: npm install -g corepack
echo   Si enable falla por permisos, habilite Corepack desde una consola de administrador.
echo   Revise tambien su conexion y los errores anteriores.
goto failed

:environment_failed
echo   ERROR: No se pudo crear un archivo de entorno.
echo   Revise los permisos de escritura y los archivos de ejemplo.
goto failed

:postgres_tools_failed
echo   ERROR: Se requieren psql y pg_isready en PATH.
echo   Instale PostgreSQL desde https://www.postgresql.org/download/windows/
echo   Agregue su directorio bin a PATH y abra una nueva ventana.
goto failed

:postgres_failed
echo   ERROR: PostgreSQL no acepta conexiones en 127.0.0.1:5432.
echo   Inicie el servidor PostgreSQL local y revise su puerto antes de continuar.
echo   No se iniciaran los servidores de la aplicacion.
goto failed

:install_failed
echo   ERROR: La instalacion de dependencias fallo. No se iniciaran los servidores.
echo   Revise los errores anteriores, la conexion y los lockfiles del proyecto.
echo   No se intentara una instalacion sin --frozen-lockfile.
goto failed

:directory_failed
echo   ERROR: No se pudo acceder o preparar un directorio del proyecto.
echo   Revise la ubicacion del instalador y los permisos de escritura.
goto failed

:startup_failed
echo   ERROR: No se pudieron iniciar o mantener los servidores.
echo   Revise los errores anteriores y cierre cualquier ventana de servidor abierta.

:failed
echo.
echo   Corrija el problema y vuelva a ejecutar este instalador.
pause
exit /b 1
