Set-Location $PSScriptRoot

Write-Host "`n=== STOP OBSIDIA TERRAIN ===" -ForegroundColor Yellow

# Stop serveur écoutant sur 3018
Get-NetTCPConnection -LocalPort 3018 -ErrorAction SilentlyContinue |
  Where-Object { $_.OwningProcess -and $_.OwningProcess -ne 0 } |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object {
    Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
    Write-Host "[STOPPED PORT 3018] PID $_"
  }

# Stop processus node/python dont la commande pointe vers Branchement terrain
$Terrain = [regex]::Escape((Resolve-Path $PSScriptRoot).Path)

Get-CimInstance Win32_Process |
  Where-Object {
    ($_.Name -match "node|python|npm") -and
    ($_.CommandLine -match $Terrain -or $_.CommandLine -match "MonProjet\\server.kernel.sealed.cjs" -or $_.CommandLine -match "sigma\\run_pipeline.py")
  } |
  ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "[STOPPED TERRAIN PROC] PID $($_.ProcessId) $($_.Name)"
  }

Write-Host "`n=== REMAINING NODE/PYTHON ===" -ForegroundColor Cyan
Get-Process node,python -ErrorAction SilentlyContinue |
  Select-Object Id, ProcessName, StartTime, Path |
  Format-Table -AutoSize

Write-Host "`nSTOP DONE" -ForegroundColor Green
