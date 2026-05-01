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
