@echo off
title MaqAgr
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0launcher.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] MaqAgr fallo al iniciar. Revise los logs en:
    echo   C:\ProgramData\MaqAgr\logs\
    echo.
    pause
)
