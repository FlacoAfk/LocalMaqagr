@echo off
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
echo   Requisitos: Windows 10/11 (se instala Node.js automaticamente)
echo.
echo   ═══════════════════════════════════════════════════════════
echo.

:: ── Step 1: Check/Install Node.js ──
echo   [1/5] Verificando Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo   Node.js no encontrado. Instalando...
    where winget >nul 2>&1
    if %errorlevel% equ 0 (
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        set PATH=%PATH%;C:\Program Files\nodejs
    ) else (
        echo.
        echo   ERROR: Node.js no encontrado y winget no disponible.
        echo   Instale Node.js desde: https://nodejs.org
        echo   Despues vuelva a ejecutar este instalador.
        echo.
        pause
        exit /b 1
    )
)
for /f "tokens=1 delims=." %%a in ('node --version') do set NODE_VER=%%a
echo   [OK] Node.js encontrado
echo.

:: ── Step 2: Enable pnpm ──
echo   [2/5] Configurando pnpm...
call corepack enable 2>nul
where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    call corepack prepare pnpm@latest --activate 2>nul
)
where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    call npm install -g pnpm 2>nul
)
echo   [OK] pnpm listo
echo.

:: ── Step 3: Create .env files ──
echo   [3/5] Configurando entorno...
if not exist "backend\.env" (
    if exist "backend\.env.local.example" (
        copy "backend\.env.local.example" "backend\.env" >nul
        echo   [OK] backend/.env creado
    )
)
if not exist "frontend\.env" (
    if exist "frontend\.env.example" (
        copy "frontend\.env.example" "frontend\.env" >nul
        echo   [OK] frontend/.env creado
    )
)
echo.

:: ── Step 4: Install dependencies ──
echo   [4/5] Instalando dependencias (puede tardar 2-3 minutos)...
echo.

echo   Instalando backend...
cd backend
call pnpm install --frozen-lockfile 2>nul
if %errorlevel% neq 0 (
    call pnpm install 2>nul
)
cd ..
echo   [OK] Backend listo

echo   Instalando frontend...
cd frontend
call pnpm install --frozen-lockfile 2>nul
if %errorlevel% neq 0 (
    call pnpm install 2>nul
)
cd ..
echo   [OK] Frontend listo

echo   Instalando herramientas...
call pnpm install 2>nul
echo   [OK] Todo listo
echo.

:: ── Step 5: Create upload dirs ──
echo   [5/5] Preparando directorios...
if not exist "backend\uploads\tractors" mkdir "backend\uploads\tractors"
if not exist "backend\uploads\implements" mkdir "backend\uploads\implements"
if not exist "backend\uploads\users" mkdir "backend\uploads\users"
echo   [OK] Directorios listos
echo.

:: ── Done ──
echo   ═══════════════════════════════════════════════════════════
echo.
echo   ╔═══════════════════════════════════════════════════════════╗
echo   ║              INSTALACION COMPLETADA                      ║
echo   ╠═══════════════════════════════════════════════════════════╣
echo   ║                                                           ║
echo   ║   Iniciando servidores...                                 ║
echo   ║                                                           ║
echo   ║   Backend:  http://localhost:4000                          ║
echo   ║   Frontend: http://localhost:5173                          ║
echo   ║                                                           ║
echo   ║   Abra su navegador en: http://localhost:5173              ║
echo   ║                                                           ║
echo   ║   Para detener: cierre esta ventana                       ║
echo   ║                                                           ║
echo   ╚═══════════════════════════════════════════════════════════╝
echo.

:: Start backend in new window
start "MaqAgr Backend" cmd /k "cd backend && pnpm run start"

:: Wait for backend to start
timeout /t 4 /nobreak >nul

:: Start frontend in current window
echo   Frontend iniciando... espere unos segundos
echo.
cd frontend
call pnpm run dev
