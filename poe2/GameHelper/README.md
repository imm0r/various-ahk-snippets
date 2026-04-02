# AHK v2 Port – PoE2 Memory Reader & AutoFlask

Vollständiger AHK v2.0 Port der Path of Exile 2 Memory-Reading-Engine mit Live-Monitoring, Auto-Flask und Entity-Scanner.

**Status:** ✅ **Produktiv** — Memory-Engine, AutoFlask & Entity-Dekodierung komplett funktional

## Architektur

### Core-Module

- **`PoE2MemoryReader.ahk`** — Haupt-Memory-Engine
  - Prozesszugriff & Modul-Scanning (Win32 API)
  - Pattern-Scanning mit RIP-relative Adress-Auflösung
  - Static Addresses: GameStates, File Root, AreaChangeCounter, etc.
  - Entity-Dekodierung (Components, Life, Buffs, Stats, Position)
  - Player-Vitals & Flask-Slots auslesen
  - WorldData & AreaInstance-Struktur-Traversal
  - Debug-Export (CSV, Debug-Log)

- **`PoE2Offsets.ahk`** — Offset-Mapping
  - 1:1 Port von `GameOffsets/` C# Klassen
  - GameState, InGameState, AreaInstance, Entity, Component-Layouts

- **`StaticOffsetsPatterns.ahk`** — Pattern-Definitionen
  - 6 kritische + 8 optionale Signature-Patterns
  - Pattern-Namen für Reporting

### UI & Integration

- **`InGameStateMonitor.ahk`** (Main Entry Point)
  - Live-TreeView Overlay mit PoE2-Fenster-Integrationn
  - **AutoFlask** — Life/Mana-Schwellen, Flask-Slot Verwaltung, Cooldown-Tracking
  - **Entity-Highlights** — Distance-Sortierung zu Spieler-Position
  - **Entity-Scanner** — Filtert NPC/Rare/Unique/Blocked Entities
  - **Active Effects** — Buff/Debuff-Anzeige mit Zeiten
  - Konfigurierbare Tastenbelegung aus `poe2_production_Config.ini`
  - Performance-Mode (nur AutoFlask-relevante Daten)

- **`PatternScanDemo.ahk`** — Diagnostik-Tool
  - Pattern-Scan im strikten Modus
  - Debug-Export aller Matches

### Hilfsfunktionen

- **`ProcessMemory.ahk`** — Nieder-Level Memory I/O
  - `OpenProcess`, `ReadProcessMemory`, `WriteProcessMemory`
  - `ReadPtr`, `ReadInt`, `ReadFloat`, `ReadString` etc.
  - Modul-Snapshot für Pattern-Scanning

## Features

### ✅ Memory-Reading
- GameState-Tracking (InGameState aktiv vs. Menu/Loading)
- AreaInstance-Daten (Level, Hash, EntityListen)
- Player-Vitals (Life, Mana, Energie, Stats)
- PlayerComponent-Fleet (Stats, Buffs, Charges, Position, Animation)
- ServerData (Flask-Inventar + Slots)

### ✅ Entity-System
- **Awake & Sleeping Entity-Maps** auslesen
- **Component-Dekodierung**: Life, Buffs, Stats, Render-Position, Targetable
- **Entity-Path-Klassifizierung** (Combat/NPC/Chest/Shrine)
- **Distance-Berechnung** zu Spieler-Position
- **Entity-Highlights** mit konfigurierbarem Sample-Limit (16/32 Awake, 8/16 Sleeping)

### ✅ AutoFlask
- Life-Schwelle (1-100%, konfigurierbar)
- Mana-Schwelle (1-100%, konfigurierbar)
- Flask-Slot 1 (Leben), Slot 2 (Mana)
- Cooldown zwischen Nutzungen (450ms default)
- ControlSend + Fallback (PostMessage) Modus
- Verification-Tracking (bestätigt Flask-Verbrauch)
- Performance-Mode (nur relevante Daten aktualisieren)

### ✅ Konfiguration
- Auto-Laden von Flask-Tasten aus PoE2 INI (`poe2_production_Config.ini`)
- Fallback auf 1-5 Falls INI nicht lesbar
- Normalisierung von DIK_/VK_/KEY_-Präfixen

### ✅ UI-Overlay
- Echtzeit-TreeView mit Expand/Collapse-Speicherung
- Status-Zeile: CurrentState, GameStates-Addr, PID, Modes
- Player-Position & aktive Buffs
- Entity-Highlights mit Distanzanzeige
- Entity-Scanner mit Tags (Hostile, NPC, Rare, Unique, Blocked)
- Responsive Layout bei verschiedenen Fenster-Größen
- Schaltflächen: Debug, Updates, AutoFlask, ReloadKeys, SendMode, RawStates, Sample, AFPerf

## Start

1. **Voraussetzungen:**
   - AutoHotkey v2.0+ ([Download](https://www.autohotkey.com/download/))
   - PoE2 installiert und laufend
   - Terminal mit Admin-Rechten (für Memory-Zugriff)

2. **Starten:**
   ```powershell
   # Terminal als Administrator öffnen
   cd e:\ahk\poe2\GameHelper
   C:\Program Files\AutoHotkey\v2\AutoHotkey.exe InGameStateMonitor.ahk
   ```

3. **Beenden:** `Esc`

## Bedienung

| Button | Funktion |
|--------|----------|
| Debug | TreeView zeigt internals (PatternScanReport, Addresses) |
| Updates | Pausiert/Startet Daten-Aktualisierung |
| AutoFlask | Flask-Automation an/aus |
| ReloadKeys | Liest Flask-Tasten neu aus INI |
| SendMode | Schaltet von Strict (ControlSend) zu Hybrid (PostMessage) |
| RawStates | Zeigt interne State-Namen in TreeView |
| Sample | Toggle zwischen Low (16/8) & High (32/16) Entity-Sampling |
| AFPerf | Performance-Mode (nur AutoFlask-Daten) |

## Abgedeckte Offsets (C#→AHK)

**GameState:**
- `States` @ `+0x48` (12 StatePtr-Einträge, je 16 Bytes)
- `CurrentStateVecLast` @ `+0x10` (Zeigeradresse zu aktuellem State)

**InGameState:**
- `AreaInstanceData` @ `+0x290`
- `WorldData` @ `+0x308`
- `UiRootStructPtr` @ `+0x340`

**AreaInstance:**
- `CurrentAreaLevel/Hash` @ `+0xC4 / +0x104`
- `PlayerInfo` @ `+0xA08`
- `AwakeEntities/SleepingEntities` @ `+0xB50 / +0xB60` (StdMaps)

**Entity:**
- `EntityDetailsPtr` @ `+0x08`
- `ComponentsVec` @ `+0x10` (First/Last Pointer)
- `Id / Flags` @ `+0x80 / +0x84`

**Komponenten (dekodiert):**
- Life, Buffs, Stats, Charges, Positioned, Render, AnimationState, StateMachine, Targetable, Actor

## Erweiterung

### Neue Entity-Komponenten hinzufügen
1. Offset in `PoE2Offsets.ahk` definieren
2. Reader-Funktion in `PoE2MemoryReader.ahk` schreiben
3. In `ReadAreaInstance()` aufrufen
4. In `InGameStateMonitor.ahk` TreeView-Rendering hinzufügen

### Neue Patterns hinzufügen
1. Signatur in `StaticOffsetsPatterns.ahk` definieren
2. Optional-Flag setzen
3. Auto-Discovery in `ResolveGameStatesAddressFallback()` wird verfügbar

## Debugging

**Pattern-Scan testen:**
```ahk
reader := PoE2GameStateReader()
reader.Connect(true)  ; strict mode - schlägt fehl bei Problemen
path := reader.ExportPatternMatchesDebug(0, "")
path := reader.ExportPatternMatchesCsv(0, "")
```

**Memory-Dumps:**
- CSV/Debug-Logs landen im `A_ScriptDir`
- Zeitstempel: `yyyyMMdd_HHmmss`

## Performance-Merkmale

- **Sampling-Limits:** 16/32 Awake, 8/16 Sleeping Entities (konfigurierbar)
- **Combat-Sweep:** Auto-Retry bei Lücken (1200ms Cooldown)
- **Entity-List-Discovery:** Dynamische Offset-Validierung mit Fallback
- **TreeView-Limits:** Max 5000 Nodes, Auto-Pagination bei großen Arrays
- **AutoFlask-Perf-Mode:** Skip Graphics/Scanner, nur Vitals+Flask-Slots updaten

## Bekannte Limitierungen

- Pattern-Scanning zeitlich begrenzt (~12s) auf ersten Scan
- Entity-Components nur für DecodedEntity-Liste (nicht volle Struktur)
- Flask-Input nur ControlSend oder PostMessage (kein direktes Memory-Write)
- UI-Overlay kann bei >5000 Nodes ausgelastet sein
