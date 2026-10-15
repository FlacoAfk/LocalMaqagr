# MaqAgr Local — Launch Script
param(
    [ValidateRange(1, 65535)][int]$BackendPort = 4000,
    [ValidateRange(1, 65535)][int]$FrontendPort = 5173
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n🚀 MaqAgr Local" -ForegroundColor Green
Write-Host "   Backend:  http://localhost:$BackendPort" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:$FrontendPort" -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop`n" -ForegroundColor Yellow

$BackendDir = Join-Path $ProjectRoot "backend"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$previousPort = $env:PORT
$previousVitePort = $env:VITE_PORT
$previousApiProxyTarget = $env:VITE_DEV_API_PROXY_TARGET

try {
    # Child processes inherit these values, so the displayed ports are the ones
    # the backend and Vite actually bind to.
    $env:PORT = [string]$BackendPort
    $env:VITE_PORT = [string]$FrontendPort
    $env:VITE_DEV_API_PROXY_TARGET = "http://127.0.0.1:$BackendPort"

    Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoExit", "-NoProfile", "-Command", "pnpm run start") `
        -WorkingDirectory $BackendDir

    Push-Location $FrontendDir
    try {
        & pnpm run dev
    } finally {
        Pop-Location
    }
} finally {
    if ($null -eq $previousPort) { Remove-Item Env:\PORT -ErrorAction SilentlyContinue }
    else { $env:PORT = $previousPort }

    if ($null -eq $previousVitePort) { Remove-Item Env:\VITE_PORT -ErrorAction SilentlyContinue }
    else { $env:VITE_PORT = $previousVitePort }

    if ($null -eq $previousApiProxyTarget) { Remove-Item Env:\VITE_DEV_API_PROXY_TARGET -ErrorAction SilentlyContinue }
    else { $env:VITE_DEV_API_PROXY_TARGET = $previousApiProxyTarget }
}
