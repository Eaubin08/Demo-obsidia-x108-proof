Set-Location $PSScriptRoot

Write-Host "`n=== OBSIDIA TERRAIN DEP CHECK ===" -ForegroundColor Cyan

Write-Host "`n--- Commands ---" -ForegroundColor Yellow
Get-Command node,npm.cmd,python,pip,git,sqlcmd,sqllocaldb,elan,lean,lake -ErrorAction SilentlyContinue |
  Select-Object Name, Source |
  Format-Table -AutoSize

Write-Host "`n--- Versions ---" -ForegroundColor Yellow
node --version
npm.cmd --version
python --version
python -m pip --version
git --version
elan --version
lean --version
lake --version

Write-Host "`n--- SQL Services ---" -ForegroundColor Yellow
Get-Service |
  Where-Object { $_.Name -match "SQL|MSSQL" -or $_.DisplayName -match "SQL Server" } |
  Select-Object Name, DisplayName, Status, StartType |
  Format-Table -AutoSize

Write-Host "`n--- SQL Connection OK targets ---" -ForegroundColor Yellow
sqlcmd -S ".\SQLEXPRESS" -E -Q "SELECT @@SERVERNAME AS server_name, DB_NAME() AS db_name;"
sqlcmd -S "(LocalDB)\MSSQLLocalDB" -E -Q "SELECT @@SERVERNAME AS server_name, DB_NAME() AS db_name;"

Write-Host "`n--- Node Package ---" -ForegroundColor Yellow
npm.cmd list --depth=0

Write-Host "`n--- Important files ---" -ForegroundColor Yellow
$Files = @(
  ".\package.json",
  ".\package-lock.json",
  ".\requirements.terrain.txt",
  ".\MonProjet\server.kernel.sealed.cjs",
  ".\sigma\contracts.py",
  ".\sigma\aggregation.py",
  ".\sigma\guard.py",
  ".\sigma\run_pipeline.py",
  ".\audit_merkle.py",
  ".\merkle_seal.json"
)

foreach ($f in $Files) {
  if (Test-Path $f) {
    Write-Host "[OK] $f" -ForegroundColor Green
  } else {
    Write-Host "[MISSING] $f" -ForegroundColor Red
  }
}
