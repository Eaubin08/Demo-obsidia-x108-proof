Set-Location $PSScriptRoot

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Out = ".\audit_terrain\dependency_check_$Stamp"
New-Item -ItemType Directory -Force $Out | Out-Null

$Errors = 0
$Warnings = 0

function OK($msg) {
  Write-Host "[OK] $msg" -ForegroundColor Green
  "[OK] $msg" | Add-Content "$Out\SUMMARY.txt"
}

function WARN($msg) {
  $script:Warnings++
  Write-Host "[WARN] $msg" -ForegroundColor Yellow
  "[WARN] $msg" | Add-Content "$Out\SUMMARY.txt"
}

function FAIL($msg) {
  $script:Errors++
  Write-Host "[FAIL] $msg" -ForegroundColor Red
  "[FAIL] $msg" | Add-Content "$Out\SUMMARY.txt"
}

Write-Host "`n=== OBSIDIA TERRAIN — FULL DEPENDENCY CHECK ===" -ForegroundColor Cyan
"=== OBSIDIA TERRAIN — FULL DEPENDENCY CHECK ===" | Set-Content "$Out\SUMMARY.txt"

# ------------------------------------------------------------
# 1. Dossiers vitaux dans le pack
# ------------------------------------------------------------

Write-Host "`n=== DOSSIERS VITAUX ===" -ForegroundColor Yellow

# Ensure runtime dirs
New-Item -ItemType Directory -Force ".\MonProjet\allData" | Out-Null
New-Item -ItemType Directory -Force ".\logs" | Out-Null

$RequiredDirs = @(
  ".\sigma",
  ".\sigma\domains",
  ".\MonProjet",
  ".\MonProjet\allData",
  ".\connectors",
  ".\node_modules",
  ".\node_modules\express",
  ".\vendor",
  ".\vendor\wheels",
  ".\proofs\lean"
)

foreach ($d in $RequiredDirs) {
  if (Test-Path $d) { OK "Dossier présent : $d" }
  else { FAIL "Dossier manquant : $d" }
}

# ------------------------------------------------------------
# 2. Fichiers vitaux
# ------------------------------------------------------------

Write-Host "`n=== FICHIERS VITAUX ===" -ForegroundColor Yellow

$RequiredFiles = @(
  ".\package.json",
  ".\package-lock.json",
  ".\requirements.terrain.txt",
  ".\MonProjet\server.kernel.sealed.cjs",
  ".\sigma\contracts.py",
  ".\sigma\aggregation.py",
  ".\sigma\guard.py",
  ".\sigma\protocols.py",
  ".\sigma\run_pipeline.py",
  ".\sigma\registry.py",
  ".\sigma\obsidia_sigma_v130.py",
  ".\audit_merkle.py",
  ".\merkle_seal.json",
  ".\START_TERRAIN.ps1",
  ".\STOP_TERRAIN.ps1",
  ".\TEST_BANK.ps1",
  ".\CHECK_DEPS_TERRAIN.ps1",
  ".\proofs\lean\lakefile.lean",
  ".\proofs\lean\lean-toolchain"
)

foreach ($f in $RequiredFiles) {
  if (Test-Path $f) {
    $size = [math]::Round((Get-Item $f).Length / 1KB, 2)
    OK "Fichier présent : $f ($size KB)"
  } else {
    FAIL "Fichier manquant : $f"
  }
}

# ------------------------------------------------------------
# 3. Commandes système nécessaires
# ------------------------------------------------------------

Write-Host "`n=== COMMANDES SYSTEME ===" -ForegroundColor Yellow

$RequiredCommands = @(
  "node",
  "npm.cmd",
  "python",
  "pip",
  "git",
  "sqlcmd",
  "sqllocaldb",
  "elan",
  "lean",
  "lake"
)

foreach ($cmd in $RequiredCommands) {
  $c = Get-Command $cmd -ErrorAction SilentlyContinue
  if ($c) {
    OK "Commande disponible : $cmd -> $($c.Source)"
  } else {
    WARN "Commande absente ou non dans PATH : $cmd"
  }
}

# ------------------------------------------------------------
# 4. Versions
# ------------------------------------------------------------

Write-Host "`n=== VERSIONS ===" -ForegroundColor Yellow

$VersionCommands = @(
  "node --version",
  "npm.cmd --version",
  "python --version",
  "python -m pip --version",
  "git --version",
  "elan --version",
  "lean --version",
  "lake --version"
)

foreach ($vc in $VersionCommands) {
  "`n===== $vc =====" | Tee-Object "$Out\versions.txt" -Append
  cmd /c $vc 2>&1 | Tee-Object "$Out\versions.txt" -Append
}

# ------------------------------------------------------------
# 5. Node local / express
# ------------------------------------------------------------

Write-Host "`n=== NODE DEPENDENCIES ===" -ForegroundColor Yellow

if (Test-Path ".\node_modules\express\package.json") {
  OK "Express présent dans node_modules"
} else {
  FAIL "Express absent dans node_modules"
}

node -e "require('express'); console.log('express import OK')" 1> "$Out\node_express.stdout.txt" 2> "$Out\node_express.stderr.txt"
if ($LASTEXITCODE -eq 0) {
  OK "Node peut importer express"
} else {
  FAIL "Node ne peut pas importer express"
  Get-Content "$Out\node_express.stderr.txt" -ErrorAction SilentlyContinue
}

npm.cmd list --depth=0 1> "$Out\npm_list_depth0.txt" 2> "$Out\npm_list_depth0.err.txt"
if ($LASTEXITCODE -eq 0) {
  OK "npm list OK"
} else {
  WARN "npm list retourne un avertissement/erreur"
}

# ------------------------------------------------------------
# 6. Python minimal terrain
# ------------------------------------------------------------

Write-Host "`n=== PYTHON DEPENDENCIES ===" -ForegroundColor Yellow

python -m compileall .\sigma 1> "$Out\compile_sigma.stdout.txt" 2> "$Out\compile_sigma.stderr.txt"
if ($LASTEXITCODE -eq 0) {
  OK "sigma compileall OK"
} else {
  FAIL "sigma compileall FAIL"
  Get-Content "$Out\compile_sigma.stderr.txt" -ErrorAction SilentlyContinue
}

$ImportCheck = Join-Path $Out "python_import_check.py"

@"
import importlib

mods = ["requests", "pytest", "json", "hashlib", "pathlib", "dataclasses", "enum"]
bad = []

for m in mods:
    try:
        importlib.import_module(m)
        print(f"[OK] import {m}")
    except Exception as e:
        print(f"[FAIL] import {m}: {e}")
        bad.append(m)

raise SystemExit(1 if bad else 0)
"@ | Set-Content $ImportCheck -Encoding UTF8

python $ImportCheck 1> "$Out\python_imports.stdout.txt" 2> "$Out\python_imports.stderr.txt"
if ($LASTEXITCODE -eq 0) {
  OK "Imports Python terrain OK"
} else {
  FAIL "Imports Python terrain FAIL"
  Get-Content "$Out\python_imports.stderr.txt" -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 7. Wheelhouse offline
# ------------------------------------------------------------

Write-Host "`n=== PYTHON WHEELS OFFLINE ===" -ForegroundColor Yellow

if (Test-Path ".\requirements.terrain.txt") {
  $Reqs = Get-Content ".\requirements.terrain.txt" |
    Where-Object { $_ -match "\S" -and $_ -notmatch "^\s*#" }

  foreach ($r in $Reqs) {
    $pkg = ($r -split "==|>=|<=|~=|>|<")[0].Trim().ToLower().Replace("_","-")
    $found = Get-ChildItem ".\vendor\wheels" -File -Filter "*.whl" -ErrorAction SilentlyContinue |
      Where-Object { $_.Name.ToLower().Replace("_","-").StartsWith($pkg + "-") }

    if ($found) {
      OK "Wheel présent pour : $pkg"
    } else {
      WARN "Wheel non trouvé localement pour : $pkg"
    }
  }

  python -m pip install --no-index --find-links ".\vendor\wheels" -r ".\requirements.terrain.txt" 1> "$Out\pip_offline_install.stdout.txt" 2> "$Out\pip_offline_install.stderr.txt"
  if ($LASTEXITCODE -eq 0) {
    OK "Installation Python offline depuis vendor/wheels OK"
  } else {
    WARN "Installation Python offline depuis vendor/wheels à vérifier"
    Get-Content "$Out\pip_offline_install.stderr.txt" -ErrorAction SilentlyContinue
  }
} else {
  FAIL "requirements.terrain.txt absent"
}

# ------------------------------------------------------------
# 8. Connectors / endpoint
# ------------------------------------------------------------

Write-Host "`n=== CONNECTORS ENDPOINT CHECK ===" -ForegroundColor Yellow

$ConnectorHits = Select-String -Path ".\connectors\*.py" `
  -Pattern "localhost:3001|localhost:3018|OBSIDIA_URL|kernel/ragnarok" `
  -ErrorAction SilentlyContinue

$ConnectorHits | Format-List | Out-File "$Out\connectors_endpoint_scan.txt"

if ($ConnectorHits) {
  OK "Connectors scannés"
} else {
  WARN "Aucun endpoint détecté dans connectors"
}

$Hard3001 = Select-String -Path ".\connectors\*.py" -Pattern "localhost:3001" -ErrorAction SilentlyContinue
if ($Hard3001) {
  WARN "Connectors encore en localhost:3001 détectés. OK seulement si serveur lancé en 3001 ou patch OBSIDIA_URL fait."
} else {
  OK "Pas de hardcode localhost:3001 dans connectors"
}

# ------------------------------------------------------------
# 9. SQL local
# ------------------------------------------------------------

Write-Host "`n=== SQL CHECK ===" -ForegroundColor Yellow

Get-Service |
  Where-Object { $_.Name -match "SQL|MSSQL" -or $_.DisplayName -match "SQL Server" } |
  Select-Object Name, DisplayName, Status, StartType |
  Format-Table -AutoSize |
  Tee-Object "$Out\sql_services.txt"

sqlcmd -S ".\SQLEXPRESS" -E -Q "SELECT @@SERVERNAME AS server_name, DB_NAME() AS db_name;" 1> "$Out\sql_sqlexpress.stdout.txt" 2> "$Out\sql_sqlexpress.stderr.txt"
if ($LASTEXITCODE -eq 0) {
  OK "SQL SQLEXPRESS accessible"
} else {
  WARN "SQL SQLEXPRESS non accessible"
}

sqlcmd -S "(LocalDB)\MSSQLLocalDB" -E -Q "SELECT @@SERVERNAME AS server_name, DB_NAME() AS db_name;" 1> "$Out\sql_localdb.stdout.txt" 2> "$Out\sql_localdb.stderr.txt"
if ($LASTEXITCODE -eq 0) {
  OK "SQL LocalDB accessible"
} else {
  WARN "SQL LocalDB non accessible"
}

# ------------------------------------------------------------
# 10. Lean / Lake
# ------------------------------------------------------------

Write-Host "`n=== LEAN / LAKE BUILD ===" -ForegroundColor Yellow

if (Test-Path ".\proofs\lean\lakefile.lean") {
  Push-Location ".\proofs\lean"
  lake build 1> "$PSScriptRoot\$Out\lake_build.stdout.txt" 2> "$PSScriptRoot\$Out\lake_build.stderr.txt"
  $LakeCode = $LASTEXITCODE
  Pop-Location

  if ($LakeCode -eq 0) {
    OK "lake build OK"
  } else {
    WARN "lake build FAIL ou toolchain à vérifier"
  }
} else {
  WARN "Projet Lean absent du pack terrain"
}

# ------------------------------------------------------------
# 11. Test serveur réel terrain
# ------------------------------------------------------------

Write-Host "`n=== SERVER RUNTIME TEST ===" -ForegroundColor Yellow

# Stop serveur déjà ouvert sur 3018
Get-NetTCPConnection -LocalPort 3018 -ErrorAction SilentlyContinue |
  Where-Object { $_.OwningProcess -and $_.OwningProcess -ne 0 } |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object {
    Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
  }

$env:OBSIDIA_PORT = "3018"
$env:OBSIDIA_URL = "http://localhost:3018/kernel/ragnarok"
$env:PYTHONPATH = (Get-Location).Path

$Server = Start-Process -FilePath "npm.cmd" `
  -ArgumentList "start" `
  -WorkingDirectory (Get-Location).Path `
  -RedirectStandardOutput "$Out\server.stdout.log" `
  -RedirectStandardError "$Out\server.stderr.log" `
  -PassThru `
  -WindowStyle Hidden

Start-Sleep -Seconds 4

$Listening = Get-NetTCPConnection -LocalPort 3018 -ErrorAction SilentlyContinue |
  Where-Object { $_.State -eq "Listen" }

if ($Listening) {
  OK "Serveur écoute sur 3018"
} else {
  FAIL "Serveur ne démarre pas sur 3018"
}

$Body = @{
  domain = "bank"
  data = @{
    transaction_type = "transfer"
    amount = 219.10
    channel = "mobile"
    counterparty_known = $false
    counterparty_age_days = 0
    account_balance = 1000
    available_cash = 1000
    historical_avg_amount = 80
    behavior_shift_score = 0.8
    fraud_score = 0.9
    policy_limit = 500
    affordability_score = 0.7
    urgency_score = 0.9
    identity_mismatch_score = 0.4
    narrative_conflict_score = 0.4
    device_trust_score = 0.4
    recent_failed_attempts = 2
    elapsed_s = 1
    min_required_elapsed_s = 108
  }
} | ConvertTo-Json -Depth 10 -Compress

try {
  $Resp = Invoke-RestMethod `
    -Uri "http://localhost:3018/kernel/ragnarok" `
    -Method Post `
    -ContentType "application/json" `
    -Body $Body `
    -TimeoutSec 20

  $Resp | ConvertTo-Json -Depth 30 | Set-Content "$Out\runtime_bank_response.json" -Encoding UTF8

  if ($Resp.domain -eq "bank" -and $Resp.x108_gate -and $Resp.confidence_integrity -ne $null -and $Resp.confidence_governance -ne $null -and $Resp.confidence_readiness -ne $null) {
    OK "Runtime bank endpoint OK : $($Resp.domain) / $($Resp.market_verdict) / $($Resp.x108_gate)"
  } else {
    FAIL "Runtime bank endpoint incomplet"
  }
} catch {
  FAIL "Runtime bank endpoint inaccessible : $($_.Exception.Message)"
} finally {
  if ($Server -and $Server.Id) {
    Stop-Process -Id $Server.Id -Force -ErrorAction SilentlyContinue
  }

  Get-NetTCPConnection -LocalPort 3018 -ErrorAction SilentlyContinue |
    Where-Object { $_.OwningProcess -and $_.OwningProcess -ne 0 } |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object {
      Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------
# 12. Résumé final
# ------------------------------------------------------------

Write-Host "`n=== FINAL ===" -ForegroundColor Cyan

if ($Errors -eq 0) {
  OK "DEPENDENCY CHECK GLOBAL PASS"
} else {
  FAIL "DEPENDENCY CHECK GLOBAL FAIL : $Errors erreur(s)"
}

if ($Warnings -gt 0) {
  WARN "$Warnings warning(s) à lire"
}

"`nERRORS=$Errors" | Add-Content "$Out\SUMMARY.txt"
"WARNINGS=$Warnings" | Add-Content "$Out\SUMMARY.txt"
"REPORT_DIR=$Out" | Add-Content "$Out\SUMMARY.txt"

Write-Host "`nREPORT_DIR=$Out" -ForegroundColor Green
Write-Host "SUMMARY=$Out\SUMMARY.txt" -ForegroundColor Green


