# Dépendances terrain — Obsidia X-108 Proof

## Runtime minimal

| Couche | Dépendance | Version validée |
|---|---:|---:|
| Node | node | 22.14.0 |
| Node | npm | 10.9.2 |
| Node package | express | 4.22.1 |
| Python | python | 3.13.3 |
| Python package | requests | 2.32.3 |
| Python package | pytest | 9.0.3 |
| Git | git | 2.52.0 |
| SQL | SQLEXPRESS | accessible |
| SQL | LocalDB MSSQLLocalDB | accessible |
| Lean | elan | 4.2.1 |
| Lean | lean | 4.30.0-rc2 |
| Lean | lake | 5.0.0 |

## Installation Node

```powershell
npm.cmd install
```

## Installation Python offline

```powershell
python -m pip install --no-index --find-links ".\vendor\wheels" -r ".\requirements.terrain.txt"
```

## Vérification globale

```powershell
powershell -ExecutionPolicy Bypass -File ".\CHECK_TERRAIN_DEPENDENCIES_FULL.ps1"
```

Validation attendue :

```text
[OK] DEPENDENCY CHECK GLOBAL PASS
```
