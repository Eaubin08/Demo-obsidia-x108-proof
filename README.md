# Demo Obsidia X-108 Proof — Terrain Runtime

Pack terrain minimal pour lancer le bridge Obsidia X-108, exécuter les domaines `bank`, `trading`, `gps_defense_aviation`, vérifier les dépendances, le serveur Node, Python, SQL Server, Lean/Lake et le scellage Merkle.

## 1. Pré-requis validés

```text
Node.js 22.14.0
npm 10.9.2
Python 3.13.3
Git 2.52.0
SQL Server SQLEXPRESS
SQL LocalDB MSSQLLocalDB
Elan 4.2.1
Lean 4.30.0-rc2
Lake 5.0.0
```

## 2. Installer les dépendances Node

```powershell
npm.cmd install
```

## 3. Installer les dépendances Python offline

```powershell
python -m pip install --no-index --find-links ".\vendor\wheels" -r ".\requirements.terrain.txt"
```

## 4. Lancer le serveur terrain

```powershell
.\START_TERRAIN.ps1
```

URL :

```text
http://localhost:3018/kernel/ragnarok
```

## 5. Stopper le serveur terrain

```powershell
.\STOP_TERRAIN.ps1
```

## 6. Test Bank

```powershell
.\TEST_BANK.ps1
```

Résultat attendu :

```text
domain                : bank
market_verdict        : ANALYZE
x108_gate             : BLOCK
confidence_integrity  : 0,5
confidence_governance : 0,95
confidence_readiness  : 0,66
severity              : S4
reason_code           : CONTRADICTION_THRESHOLD_REACHED
```

## 7. Commandes domaines

Serveur lancé requis.

### Bank

```powershell
python .\connectors\bank_normal_flow.py
```

### Trading

```powershell
python .\connectors\trading_live.py
```

### Aviation / GPS Defense

```powershell
python .\connectors\aviation_robo.py
```

## 8. Lean / Lake

```powershell
Set-Location ".\proofs\lean"
lake build
```

Résultat attendu :

```text
Build completed successfully
```

## 9. Vérification globale terrain

```powershell
powershell -ExecutionPolicy Bypass -File ".\CHECK_TERRAIN_DEPENDENCIES_FULL.ps1"
```

Résultat attendu :

```text
[OK] DEPENDENCY CHECK GLOBAL PASS
```

## 10. Notes

- `node_modules/` n’est pas versionné. Il se régénère avec `npm.cmd install`.
- `vendor/wheels/` contient seulement les dépendances Python minimales terrain.
- `MonProjet/allData/` n’est pas versionné : données runtime générées.
- `audit_terrain/` n’est pas versionné : audits locaux.
- Les caractères bizarres dans certains logs sont un problème d’encodage console Windows, pas un problème moteur.
