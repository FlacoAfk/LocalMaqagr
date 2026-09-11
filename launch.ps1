# MaqAgr Local — Launch Script
param([int]$BackendPort = 4000, [int]$FrontendPort = 5173)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n🚀 MaqAgr Local" -ForegroundColor Green
Write-Host "   Backend:  http://localhost:$BackendPort" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:$FrontendPort" -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop`n" -ForegroundColor Yellow

# Start backend in new window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ProjectRoot\backend'; pnpm run start"

# Start frontend in current window
Set-Location "$ProjectRoot\frontend"
pnpm run dev