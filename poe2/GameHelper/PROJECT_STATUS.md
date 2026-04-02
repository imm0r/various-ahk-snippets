# PoE2 GameHelper — Projekt Status

**Zuletzt aktualisiert:** 01. April 2026  
**Status:** ✅ **PRODUKTIV**

## Zusammenfassung

Das Projekt ist ein **vollständiger AHK v2-Port** der Path of Exile 2 Memory-Reading-Engine.

**Referenz-Projekte (immer als Maßstab nutzen):**

1. C# Original: https://gitlab.com/bylafko/gamehelper2
2. DAT-Schema (für TSV-Generierung): https://github.com/poe-tool-dev/dat-schema
3. PoE2 Patch-Server: `patch.pathofexile2.com:13060` (gibt aktuelle Version z.B. `4.4.0.10`)
4. AHK v2 Docs: https://www.autohotkey.com/docs/v2/

**Standard Formatierungen / Layouting:**

1. Auf der gesamten GUI Oberfläche: Speicheradressen ausschließlich hexadecimal (0x00000000)
2. Memory-Layout: Il2CppDumper kompatibel
3. Pattern-Format: IDA-Notation (`48 ?? 33 ??`)

---

## Datei-Struktur

```
GameHelper/
├── InGameStateMonitor.ahk      — Main UI, AutoFlask, Layout, PatchChecker-Integration
├── PoE2MemoryReader.ahk        — Core Engine: Pattern-Scan, Memory-Read, Entity-Dekodierung
├── TreeViewWatchlistPanel.ahk  — TreeView-Rendering, Stat-Formatierung, Watchlist
├── PatchChecker.ahk            — Patch-Version via TCP (patch.pathofexile2.com:13060)
├── PoE2Offsets.ahk             — Offset-Maps
├── ProcessMemory.ahk           — Win32 Memory I/O
├── StaticOffsetsPatterns.ahk   — Pattern-Signaturen
├── last_known_patch.txt        — Zuletzt bekannte Patch-Version (z.B. 4.4.0.10)
├── data/
│   ├── stat_name_map.tsv       — Hash→stat_id (24887 Einträge, generiert von extract_stats_dat.py)
│   ├── stat_desc_map.tsv       — stat_id→Template (12958 Einträge, generiert von build_stat_desc_map.py)
│   ├── mod_name_map.tsv        — mod_id→Name
│   ├── base_item_name_map.tsv  — Basis-Item-Namen
│   ├── unique_item_name_map.tsv
│   ├── unique_name_map.tsv
│   ├── monster_name_map.tsv
│   └── raw_stats_debug.tsv     — Debug-Output (welche Stats noch "raw" sind)
└── tools/
    ├── compare_offsets.py      — Offset-Vergleich AHK↔C# (GitLab), Versionshistorie, Delta-Vorhersage
    ├── build_item_names.py     — Generiert alle item/mod/unique TSVs
    ├── build_stat_desc_map.py  — Generiert stat_desc_map.tsv aus CSD-Dateien
    ├── extract_stats_dat.py    — Generiert stat_name_map.tsv
    ├── extract_mods_dat.py
    ├── extract_monster_names.py
    ├── parse_index.py          — Shared: Bundle-Index Parser
    ├── analyze_shared.py       — Shared: Bundle-Reader
    └── explore_*, inspect_*   — Analyse-/Debug-Tools
```

**Nach jedem PoE2-Patch TSVs neu generieren:**

```
cd tools
python extract_stats_dat.py
python build_stat_desc_map.py
python build_item_names.py
python extract_monster_names.py
```

**Offset-Vergleich mit C#-Upstream nach Patch:**

```
cd tools
python compare_offsets.py              # Diff anzeigen (fetcht automatisch)
python compare_offsets.py --no-fetch   # Diff ohne Online-Abfrage
python compare_offsets.py --record     # Änderungen in offset_history.json aufnehmen
python compare_offsets.py --history    # Historische Änderungen anzeigen
python compare_offsets.py --predict    # Delta-Muster für Vorhersagen analysieren
```

`offset_history.json` (im Root) speichert alle Offset-Änderungen mit Spielversion und Typ (`fix` / `game_update`) für spätere Vorhersagen.

---

## Features (aktueller Stand)

| Feature                     | Status | Beschreibung                                                           |
| --------------------------- | ------ | ---------------------------------------------------------------------- | ---------------------- |
| Memory-Engine               | ✅     | Pattern-Scan, RIP-Relative, GameStates                                 |
| AutoFlask                   | ✅     | Life/Mana-Schwellen, Cooldown, Verification                            |
| Entity-Scanner              | ✅     | Awake/Sleeping, Distance-Sort, Highlights                              |
| Player-Stats (statsByItems) | ✅     | **Stat-Description-Enrichment implementiert**                          |
| Stat-Formatierung           | ✅     | CSD-Templates + Pattern-basiert, 185 Stats: ~107 fmt, 0 raw, 78 hidden |
| allStates-Namen             | ✅     | Zeigt State-Name statt Index                                           |
| Adressen-Format             | ✅     | Nur Hex (kein "dec (hex)" mehr)                                        |
| Patch-Version-Check         | ✅     | TCP-Query beim Start, MsgBox bei neuem Patch                           |
| Status-Leiste               | ✅     | Unten: "PoE2 v4.4.0.10                                                 | Last update: HH:MM:SS" |
| Responsive Layout           | ✅     | Fenster-Resize passt alle Controls an                                  |
| TSV-Ordnerstruktur          | ✅     | data/ und tools/ Unterordner                                           |

---

## Stat-Description-Enrichment (Kernfeature)

**Funktionsweise:**

1. `stat_name_map.tsv`: Hash (Speicher-Key) → stat_id-String
2. `stat_desc_map.tsv`: stat_id → Anzeige-Template (aus PoE2-CSD-Dateien)
3. `FormatStatEntry()` in TreeViewWatchlistPanel.ahk verbindet beides
4. Multi-stat-Gruppen (min+max Schaden) über `BuildStatSiblingContext()`
5. Pattern-basierte Formatierung für computed/virtual Stats

**Debug-Counter im Node-Label:**

```
statsByItems [Array, len=185 | 107 fmt, 0 raw, 78 hidden]
```

---

## Patch-Sicherheit

- **PatchChecker.ahk** fragt beim Script-Start `patch.pathofexile2.com:13060` ab
- Vergleicht mit `last_known_patch.txt`
- Bei neuer Version: MsgBox mit Hinweis auf TSV-Rebuild
- Implementiert als PS1-Tempfile (kein Inline-PowerShell-Escaping)

---

## Technische Details / Fallstricke

| Thema               | Detail                                                                           |
| ------------------- | -------------------------------------------------------------------------------- | --- | ---------------------- |
| AHK v2 static Map   | `static x := Map(...)` ist **nicht** erlaubt — stattdessen `                     |     | `-Kette oder lazy init |
| `finally` ohne `{}` | AHK-Linter beschwert sich — immer `finally { }` schreiben                        |
| stat_name_map Keys  | 1-basiert im Speicher → -1 für 0-basierten TSV-Lookup                            |
| CSD-Format          | Zwei Varianten: mit/ohne `lang "English"` Block                                  |
| base\_\* Alias      | CSD nutzt `base_maximum_life`, Speicher nutzt `maximum_life` → Alias-Strip nötig |
| permyriad           | ÷100 = %, nicht ÷10                                                              |
| PoE2 Patch-Server   | `patch.pathofexile2.com:13060` (PoE1: `patch.pathofexile.com:12995`)             |
| TSV-Pfade           | Alle in `data/`, Python-Scripts in `tools/`, Output immer nach `data/`           |

---

## Referenzen

- **C# Original:** https://gitlab.com/bylafko/gamehelper2
- **DAT-Schema:** https://github.com/poe-tool-dev/dat-schema
- **Patch-Update:** https://github.com/poe-tool-dev/poe-patch-update
- **AHK v2 Docs:** https://www.autohotkey.com/docs/v2/

## Zusammenfassung

Das Projekt ist ein **vollständiger AHK v2-Port** der Path of Exile 2 Memory-Reading-Engine mit integrierten:

- ✅ AutoFlask-Automation
- ✅ Live Entity-Scanner & Highlights
- ✅ Player-Vitals & Component-Dekodierung
- ✅ Buff/Debuff-Anzeige
- ✅ Echtzeit-UI Overlay

**Fertigstellungsgrad: ~90%** (Weitere Komponenten-Dekodierung möglich, aber nicht notwendig für aktuelle Features)

---

## Architektur-Übersicht

```
┌─────────────────────────────────────────────────┐
│         InGameStateMonitor.ahk (Main)           │
│  - UI Overlay (TreeView & Buttons)              │
│  - AutoFlask Logic                              │
│  - Entity-Scanner & Highlights                  │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────┐
│    PoE2MemoryReader.ahk (Core Engine)           │
│  - Pattern-Scanning                             │
│  - Static-Address-Auflösung                     │
│  - Entity-Dekodierung                           │
│  - Player-Vitals auslesen                       │
│  - Flask-Slot Management                        │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────┼──────────────────────────────┐
│    │                         │                 │
│    ▼                         ▼                 ▼
│ ProcessMemory.ahk      PoE2Offsets.ahk    StaticOffsetsPatterns.ahk
│ (Memory I/O)           (Offset Maps)       (Pattern Signatures)
└─────────────────────────────────────────────────┘
```

---

## Feature-Übersicht

### 1. **Memory-Engine (PoE2MemoryReader.ahk)**

| Feature                 | Status | Details                                            |
| ----------------------- | ------ | -------------------------------------------------- |
| Process Opening         | ✅     | Win32 API — `OpenProcess`, `ReadProcessMemory`     |
| Module Scanning         | ✅     | `CreateToolhelp32Snapshot` / `Module32FirstW`      |
| Pattern-Scanning        | ✅     | Generic mask-based scanning mit `??` & `^` anchors |
| RIP-Relative Resolution | ✅     | `addr = operand + *(int32*)operand + 4`            |
| GameStates Discovery    | ✅     | Fallback-Scans mit Kandidaten-Ranking              |
| InGameState Resolver    | ✅     | Scoring-basierte Adressenermittlung                |

**Scanned Patterns (6 kritisch, 8 optional):**

- Game States (kritisch)
- File Root, AreaChangeCounter (optional)
- Terrain Rotator/Selector, GameCullSize (optional)
- ... weitere bei Bedarf

### 2. **Entity-System**

| Feature                | Status | Details                              |
| ---------------------- | ------ | ------------------------------------ |
| Awake Entity-Map       | ✅     | StdMap auslesen @ AreaInstance+0xB50 |
| Sleeping Entity-Map    | ✅     | StdMap auslesen @ AreaInstance+0xB60 |
| Component-Dekodierung  | ✅     | Life, Buffs, Stats, Render, Position |
| Entity-Klassifizierung | ✅     | Combat/NPC/Chest/Shrine Heuristics   |
| Position-Berechnung    | ✅     | World-Space 3D Position aus Render   |
| Distance-Sorting       | ✅     | Zu Spieler-Position in Real-Time     |
| Deduplication          | ✅     | Nach EntityPtr+ID                    |

**Dekodierte Components:**

- ✅ Life (isAlive, currHp, maxHp)
- ✅ Buffs (effects: name, timeLeft, charges, buffType)
- ✅ Stats (via StatPairs + StatDefs)
- ✅ Render (world position vector)
- ✅ Targetable (isTargetable, isHighlightable)
- ✅ Positioned (isFriendly, movement)
- ✅ Charges (charges per charge type)
- ✅ Animated (current animation)
- ⏳ Actor (health from components) — partially
- ⏳ Mods (item modifications) — partially

### 3. **AutoFlask (Core Feature)**

| Komponente           | Status | Details                                    |
| -------------------- | ------ | ------------------------------------------ |
| Life-Schwelle        | ✅     | 1-100%, konfigurierbar via UI              |
| Mana-Schwelle        | ✅     | 1-100%, konfigurierbar via UI              |
| Flask-Slot 1 (Life)  | ✅     | Automatische Aktivierung                   |
| Flask-Slot 2 (Mana)  | ✅     | Automatische Aktivierung                   |
| Cooldown-Tracking    | ✅     | Pro Slot, default 450ms                    |
| ControlSend          | ✅     | Primary — `ControlSend("{Blind}{key}")`    |
| PostMessage Fallback | ✅     | VK code über PostMessage                   |
| Verification         | ✅     | Bestätigt Flask-Verbrauch via Charge-Delta |
| INI-Laden            | ✅     | `poe2_production_Config.ini` parsing       |
| Key-Normalisierung   | ✅     | DIK*/VK*/KEY\_ zu AHK-Format               |
| Performance-Mode     | ✅     | Skip Graphics, nur Vitals+Flasks           |

**Flask-Slot-Erkennung:**

- Server-Data via `ReadFlaskSlotsFromBuffs()`
- Oder Buff-basierte Slot-Zuordnung

### 4. **UI-Overlay (InGameStateMonitor.ahk)**

| UI-Element        | Status | Details                                  |
| ----------------- | ------ | ---------------------------------------- |
| TreeView          | ✅     | Expandable/Collapsible Struktur-Anzeige  |
| Auto-Expand       | ✅     | Max 5000 Nodes, lazy rendering           |
| Status-Zeile      | ✅     | PID, State, Modes, Schwellen             |
| Player-Position   | ✅     | Aus Render-Component                     |
| Active Buffs      | ✅     | Positive/Negative-Trennung, Timer        |
| Entity-Highlights | ✅     | Distanz-Sortiert, Sample-limitiert       |
| Entity-Scanner    | ✅     | NPC/Rare/Unique/Blocked Filter           |
| Button-Row        | ✅     | 8 Toggle-Buttons mit Live-Label          |
| Responsive Layout | ✅     | Passt sich an Fenster-Größe an           |
| Path-Memento      | ✅     | Speichert Expand-States zwischen Updates |

**Buttons:**

1. Debug — Zeigt PatternScanReport
2. Updates — Pausiert/Startet Refresh
3. AutoFlask — Flask-Automation an/aus
4. ReloadKeys — INI neu laden
5. SendMode — Strict (ControlSend) ↔ Hybrid (PostMessage)
6. RawStates — Zeigt interne State-Namen
7. Sample — Toggle Low ↔ High Entity-Sampling
8. AFPerf — Performance-Mode (nur AutoFlask-Updates)

---

## Implementierungs-Details

### Entity-Sampling

**Low Mode** (Standard):

- Awake: 16 Entities
- Sleeping: 8 Entities
- Gut für UI-Performance

**High Mode:**

- Awake: 32 Entities
- Sleeping: 16 Entities
- Für detaillierte Scans

### Combat-Sweep

Wenn Awake-Liste dünn / keine Combat-Entities gefunden:

- Auto-Retry mit alternativen Entity-List-Offsets
- Cooldown: 1200ms
- Fallback zu Default-Offset

### Entity-List-Discovery

Dynamische Offset-Validierung mit Scoring:

- Prüft `AreaInstance + offset + 0x10` auf StdMap-Struktur
- Zählt NPC/Chest-Entities
- Fallback: `0xB50` (hardcoded default)

### AutoFlask-Verification

Nach Flask-Send:

- Warte auf Charge-Delta oder Buff-Aktivierung
- Timeout: 650ms
- Bei Timeout → Slot auf Cooldown zurücksetzen

---

## Datei-Struktur

```
GameHelper/
├── PoE2MemoryReader.ahk          [4500+ lines] — Core Engine
├── PoE2Offsets.ahk               [150 lines]  — Offset-Maps
├── ProcessMemory.ahk             [300 lines]  — Memory I/O
├── StaticOffsetsPatterns.ahk     [15 lines]   — Pattern-Sigs
├── InGameStateMonitor.ahk        [3500+ lines] — Main UI+Logic
├── PatternScanDemo.ahk           [~ 100 lines] — Diagnostik
├── GgpkMemoryMonitor.ahk         [Separat]    — GGPK-Client
└── README.md                      [Doku]
```

**Größe:** ~9000 lines AHK Code

---

## Getestete Funktionen

✅ **Startup & Connection**

- Process-Öffnung
- Module-Scanning
- GameStates-Adresse-Auflösung
- InGameState-Validierung

✅ **Memory-Lesen**

- Player-Vitals (Life, Mana, Energy korrekt)
- Entity-Listen (Counts stimmen)
- Entity-Positionen (Distance-Calc funktioniert)
- Flask-Slots (Read-Cycle stabil)

✅ **AutoFlask**

- Life-Trigger bei Schwelle
- Mana-Trigger bei Schwelle
- Cooldown-Einhaltung
- Verification-Tracking
- Fallback zu PostMessage

✅ **UI**

- TreeView-Population
- Expand-State-Memento
- Button-Toggle
- Responsive Layout
- Performance bei 5000+ Nodes

---

## Performance-Charakteristiken

| Operation              | Zeit      | Anmerkung                        |
| ---------------------- | --------- | -------------------------------- |
| Pattern-Scan (initial) | ~1-3s     | Mit Timeout 12s                  |
| Snapshot lesen (full)  | ~10-20ms  | Pro ReadAndShow() Cycle          |
| AutoFlask-Snapshot     | ~5-10ms   | Nur Vitals+Flasks                |
| TreeView Update        | ~50-100ms | Mit Max 5000 Nodes               |
| ReadTimer Cycle        | 200ms     | Standard (kann angepasst werden) |

---

## Bekannte Probleme & Workarounds

| Problem                | Ursache            | Workaround                                          |
| ---------------------- | ------------------ | --------------------------------------------------- |
| Pattern nicht gefunden | Neue Game-Version  | Pattern-Sig updaten in StaticOffsetsPatterns.ahk    |
| AutoFlask sendet nicht | ControlSend-Fehler | Button "SendMode" zu Hybrid wechseln                |
| Leere Entity-Listen    | Falscher Offset    | Combat-Sweep triggert neu, oder alt. Offset suchen  |
| UI langsam             | > 5000 Nodes       | Button "Debug" ausschalten oder "AFPerf" aktivieren |
| Flask-Tasten falsch    | INI nicht gelesen  | "ReloadKeys" Button, oder manuell in Code setzen    |

---

## Erweiterungspunkte

### 1. **Weitere Entity-Komponenten**

```ahk
// In PoE2Offsets.ahk:
static CustomComponent := Map(
    "Field1", 0x00,
    "Field2", 0x08
)

// In PoE2MemoryReader.ahk:
ReadCustomComponent(entityPtr) {
    // Implementation
}

// In ReadInGameState():
"customComponent", this.ReadCustomComponent(localPlayerPtr)
```

### 2. **Neue Patterns**

```ahk
// In StaticOffsetsPatterns.ahk:
Map("name", "MyPattern", "pattern", "48 ?? 33 ?? ^ ?? ?? ?? 00")
```

### 3. **Erweiterte Flask-Logik**

- Conditionals (z.B. nur bei Boss)
- Multi-Flask-Sequencing
- Custom Buff-Checks

### 4. **UI-Erweiterungen**

- Export zu CSV
- Custom Alerts bei Bedingungen
- Minimap-Overlay

---

## Debug-Tipps

**Pattern-Scan Probleme:**

```ahk
reader := PoE2GameStateReader()
reader.Connect(true)  // Strict mode
reader.ExportPatternMatchesDebug()  // Schreibt Log in A_ScriptDir
reader.ExportPatternMatchesCsv()    // CSV für Analyse
```

**Memory-Read Fehler:**

- Überprüfe Admin-Rechte
- Prüfe PID in TreeView (Button "Debug" drücken)
- Stelle sicher, dass PoE2 läuft

**AutoFlask nicht triggernd:**

- Check Life/Mana % in TreeView
- Überprüfe Flask-Slots nicht leer
- Prüfe SendMode (Strict vs. Hybrid)
- Schau PoE-Fenster hat Focus

---

## Zukünftige Ideen

1. **Inventory-System** — Alle Slots dekodieren
2. **Skill-Tree-Parsing** — Passiv-Nodes auslesen
3. **NPC-Dialog-Tracking** — Shop-Zustand
4. **Map-Metadata** — Lädt modifiers → Risk-Assesment
5. **Loot-Filter** — Item-Ansprache real-time
6. **Skill-Cast-Logic** — Bestimmte Skills in bestimmten Situation automatisch casten
