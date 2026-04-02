# Quick Start Guide — PoE2 GameHelper
**Für:** Neu aufgebauter Workspace  
**Ziel:** In 2 Minuten am Laufen

## Schritt 1: Vorbereitung (30 Sekunden)

1. ✅ [AutoHotkey v2.0+](https://www.autohotkey.com/download/) ist installiert
2. ✅ Path of Exile 2 ist **gestartet und du bist ingame**
3. ✅ Terminal als **Administrator** öffnen

## Schritt 2: Starten (10 Sekunden)

```powershell
cd e:\ahk\poe2\GameHelper
C:\Program Files\AutoHotkey\v2\AutoHotkey.exe InGameStateMonitor.ahk
```

Oder doppelklick auf `InGameStateMonitor.ahk` (mit Admin-Rechten)

## Schritt 3: Fenster sichtbar? ✅

Du solltest sehen:
- **Overlay-Fenster** oben-links mit Buttons
- **TreeView** Struktur-Anzeige (mit PoE2 Memory-Daten)
- **Status-Zeile** mit PID, State, Modes

**Falls nichts:** Siehe [Troubleshooting](#troubleshooting)

## Schritt 4: AutoFlask aktivieren (1 Minute)

1. Klicke **"AutoFlask ON"** Button (grün!)
2. Stelle die **Life %** auf 40-50 (UI oben)
3. Stelle die **Mana %** auf 30-40 (UI oben)
4. Klicke **"Apply"** Button

**Fertig!** AutoFlask läuft jetzt:
- Leben fällt unter 40%? → Flask Slot 1 wird aktiviert
- Mana fällt unter 30%? → Flask Slot 2 wird aktiviert

## Wichtige Buttons

| Button | Was macht es |
|--------|-------------|
| **Debug** | Zeigt interne Pattern-Scan-Infos (für Probleme) |
| **Updates** | Pausiert die Daten-Aktualisierung (nützlich zum Lesen) |
| **AutoFlask** | Flask-Automation an/aus |
| **ReloadKeys** | Liest Flask-Tasten aus PoE2 INI neu |
| **SendMode** | Strict (normal) ↔ Hybrid (bei Problemen) |
| **Sample** | Entity-Sampling: LOW (schnell) ↔ HIGH (detailliert) |
| **RawStates** | Zeigt technische State-Namen |
| **AFPerf** | Performance-Mode (nur Flask-Daten) |

## Tastenbelegung

Standard (wenn INI nicht gelesen):
- **Slot 1 (Leben):** `1`
- **Slot 2 (Mana):** `2`
- **Slot 3:** `3`
- **Slot 4:** `4`
- **Slot 5:** `5`

Falls anders: "ReloadKeys" Button drücken (liest aus PoE2 INI)

## Was du sehen solltest

### 1. **Hauptzeile (oben)**
```
Updated: 2026-03-30 15:30:45 | PID: 1234 | Debug: OFF | ... | AF: triggered
```
- ✅ PID ≠ 0 → Process gefunden
- ✅ AF: triggered/attempted → AutoFlask arbeitet

### 2. **TreeView (unten)**
```
Updated: 2026-03-30...
 └─ Player Position: X=-450.5 Y=200.3
 └─ Flask Hotkeys (active mapping)
    ├─ Slot 1 -> 1
    ├─ Slot 2 -> 2
    └─ ...
 └─ Active Effects (3)
    ├─ Positive Buffs (2)
    └─ Negative Buffs (1)
 └─ ...
```
- ✅ Player Position vorhanden → Memory-Reading läuft
- ✅ Active Effects vorhanden → Entity-Dekodierung funktioniert

## Troubleshooting

### „Konnte PathOfExileSteam.exe ... nicht auflösen"
**Problem:** Prozess nicht gefunden oder GameStates-Adresse nicht gelesen

**Lösung:**
1. Starte das Skript als **Administrator**
2. PoE2 **muss laufen**
3. Drücke "Debug" Button → TreeView zeigt Fehler
4. Falls "missingCritical" → Neue Game-Version, Patterns müssen aktualisiert werden

### AutoFlask sendet nicht
**Problem:** Flask-Taste wird nicht gesendet

**Lösung:**
1. Klicke "SendMode" → Wechsel zu **Hybrid**
2. Oder: Überprüfe Flask-Tasten → "ReloadKeys" drücken
3. Stelle sicher PoE2-Fenster **im Fokus** ist

### TreeView ist leer
**Problem:** Keine Memory-Daten sichtbar

**Lösung:**
1. Drücke "Updates" Button → sollte wieder aktualisieren
2. Oder: Drücke "AFPerf" aus → Full-Daten-Mode
3. Überprüfe Admin-Rechte

### Performance-Probleme (ursa laggy)
**Problem:** Fenster friert ein

**Lösung:**
1. Drücke "AFPerf" → **Performance-Mode aktivieren** ✅
2. Oder: "Sample" → **LOW** Sampling
3. Oder: "Updates" → Pausieren, dann manuell refreshen

---

## Nächste Schritte (Optional)

### 1. Flask-Tasten aus PoE2 INI laden
```
Pfad: C:\Users\[USER]\My Games\Path of Exile 2\poe2_production_Config.ini

Suche nach:
    [USE_FLASK_SLOT_1_PRIMARY]=
    [USE_FLASK_SLOT_2_PRIMARY]=
```

Das Skript versucht das automatisch. Falls nicht:
→ "ReloadKeys" Button drücken, oder manuell Tasten setzen.

### 2. Debug-Export
Falls AutoFlask nicht richtig triggert:
```ahk
reader := PoE2GameStateReader()
reader.Connect()
path := reader.ExportPatternMatchesDebug()  ; Datei wird gespeichert
MsgBox("Export: " path)
```

### 3. Manuell Pattern-Scan testen
```powershell
C:\Program Files\AutoHotkey\v2\AutoHotkey.exe PatternScanDemo.ahk
```

Zeigt alle Patterns & deren Matches an.

---

## FAQ

**F: Kann ich mehrere PoE2-Instanzen steuern?**  
A: Nein, aktuell nur eine. Aber könnte erweitert werden.

**F: Funktioniert das mit PoE1?**  
A: Nein, die Memory-Layouts sind unterschiedlich.

**F: Wie sicher ist das?**  
A: Read-Only. Nur Flask-Input wird gesendet, sonst nichts in Memory geschrieben.

**F: Kann ich das während des Spiels deaktivieren?**  
A: Ja! "AutoFlask OFF" Button oder "Updates PAUSE" drücken.

**F: Wo finde ich ausgecgebene Logs?**  
A: Im `A_ScriptDir` (GameHelper-Ordner):
- `PatternScanDebug_*.log` — Pattern-Analyse
- `PatternScanDebug_*.csv` — CSV-Export

---

## Support

**Fehler im Code?**
1. Drücke "Debug" Button
2. Schau TreeView → Was wird angezeigt?
3. Führe PatternScanDemo.ahk aus

**Feature-Wünsche?**
Siehe `PROJECT_STATUS.md` → Erweiterungspunkte

**Memory-Daten stimmen nicht?**
1. Überprüfe PoE2-Version
2. Offsets in `PoE2Offsets.ahk` können veraltet sein
3. Pattern-Scan könnte fehlschlagen (falsche Adresse)

---

## Kurzbefehle

```
Esc → Skript beenden
Alt+Tab → Fenster fokussieren
```

Mehr in `README.md` → Bedienung

---

**Viel Spaß! 🎮**
