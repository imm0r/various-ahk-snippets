# GitHub Copilot – Projektregeln für poe2/GameHelper

## Datei-Ablage

- **Tool-Skripte** (`*.py`, die für das Projekt dauerhaft genutzt werden) kommen **immer** in `poe2/GameHelper/tools/`.
- **Datendateien** (`*.tsv`, `*.json` die von Tools generiert werden, ausser `offset_history.json` im Root und `schema.min.json`) kommen **immer** in `poe2/GameHelper/data/`.

## Dokumentation

- Jedes neue Tool in `tools/` wird **immer** in `poe2/GameHelper/PROJECT_STATUS.md` unter „Datei-Struktur → tools/" dokumentiert.
- Neue `data/`-Dateien werden ebenfalls in `PROJECT_STATUS.md` unter „Datei-Struktur → data/" aufgeführt.

## Git

- `dumped_tables/` und `.upstream_cache/` nicht committen (→ `.gitignore`).
