Set-Location $PSScriptRoot

New-Item -ItemType Directory -Force ".\MonProjet\allData" | Out-Null
New-Item -ItemType Directory -Force ".\logs" | Out-Null

$env:OBSIDIA_PORT = "3018"
$env:OBSIDIA_URL = "http://localhost:3018/kernel/ragnarok"
$env:PYTHONPATH = $PSScriptRoot

Write-Host "`n=== START OBSIDIA TERRAIN ===" -ForegroundColor Cyan
Write-Host "PORT=$env:OBSIDIA_PORT"
Write-Host "URL=$env:OBSIDIA_URL"

npm.cmd start

