# Nächste Schritte — PoE2 GameHelper
**Stand:** 30. März 2026  
**Ort:** Nach diesem Workspace

## Sofort verfügbar (keine weiteren Änderungen nötig)

- ✅ AutoFlask mit Life/Mana-Thresholds
- ✅ Entity-Scanner (NPC/Rare/Unique/Blocked)
- ✅ Live-Monitoring UI
- ✅ Pattern-Scanning + Debug-Export
- ✅ Performance-Optionen (Low/High Sampling, AFPerf)

## Roadmap für zukünftige Sessions

### Phase 1: Stabilitäts-Updates (wenn Bugs auftauchen)
- [ ] Pattern-Sigs aktualisieren (falls neue PoE2-Version)
- [ ] Offset-Validierung bei Crashes
- [ ] Memory-Leak-Cleanup (bei langen Sessions)
- [ ] UI-Performance bei >100k Entities

### Phase 2: Feature-Expansions (Nice-to-Have)
- [ ] **Item-Parse-System** — Alle Inventar-Slots dekodieren
- [ ] **Loot-Filter Integration** — Item-Bewerautage real-time
- [ ] **Skill-Tree-Reader** — Passive-Nodes auslesen
- [ ] **NPC-Dialog-Tracker** — Shop/Quest-State
- [ ] **Map-Metadata** — Modifier-Auslese

### Phase 3: Advanced Features (nur bei Bedarf)
- [ ] **Multi-Box-Support** — Mehrere PoE2-Instanzen
- [ ] **Overlay-Graphics** — In-Game Minimap/Markers
- [ ] **Teleport-Macros** — Automatisierte Hilfen
- [ ] **Export-System** — CSV/JSON für externe Tools

## Was müsste noch getan werden

### Pattern-Maintenance
```ahk
// In StaticOffsetsPatterns.ahk bei neuer PoE2-Version:
// Alte Signaturen aktualisieren
// Oder PatternScanDemo.ahk laufen lassen → neue Sigs suchen
```

### Component-Erweiterung
```ahk
// Weitere Components in PoE2Offsets.ahk hinzufügen:
static MyComponent := Map(...)

// Reader-Funktion schreiben:
ReadMyComponent(entityPtr) { ... }

// In ReadInGameState() aufrufen
```

### UI-Verbesserungen
- Export-Buttons (CSV, JSON)
- Realtime-Graphen (DPS-Meter, etc.)
- Custom-Alerts bei Bedingungen
- Hotkey-Customization UI

## Testing-Checkliste bei nächster Session

```
[ ] Admin-Rechte?
[ ] PoE2 läuft?
[ ] Process-Connection erfolgreich?
[ ] TreeView zeigt Daten?
[ ] AutoFlask triggert bei Schwelle?
[ ] Flask-Tasten-Normalisierung OK?
[ ] Entity-Counts stimmen?
[ ] Performance OK (< 200ms Update)?
[ ] Keine Memory-Leaks (nach 1h)?
```

## Debugging Quick-Reference

```ahk
// Pattern-Scan debuggen
reader.ExportPatternMatchesDebug()
reader.ExportPatternMatchesCsv()

// Memory-Fehler
reader.Mem.Pid  // Sollte ≠ 0
reader.GameStatesAddress  // Sollte valide Adresse sein
reader.LastInGameStateAddress  // Sollte <= 0 ODER valide sein

// Flask-Probleme
ControlSend("{Blind}{1}")  // Manuell testen
// Falls fehlschlag → SendMode zu Hybrid

// Entity-Listen
awakeMapAddress @ AreaInstance+0xB50
sleepingMapAddress @ AreaInstance+0xB60
```

## Code-Review Punkte

1. **Performance-Kritisch:**
   - `ReadAreaEntityMapSummary()` — Entity-Map traversal
   - `BuildTreeNode()` — Recursive TreeView-Building
   - `DecodeEntity()` — Component-Dekodierung

2. **Stabilitäts-Kritisch:**
   - `ValidateGameStatesAddress()— Pointer-Validierung
   - `ResolveEntityListOffset()` — Fallback-Logic
   - `FindLocalPlayerEntityFromArea()` — Scan-Loop

3. **Sicherheits-Kritisch:**
   - `ControlSend()` → Sollte nur zu PoE2 gehen
   - Memory-Read-Bounds → Buffer-Overflow-Prävention

## Ressourcen zum Lernen

- **Il2CppDumper** — Meta-Daten für Strukturen
- **Cheat Engine** — Pattern-Sig Finder
- **IDA Pro** — Reverse-Engineering Referenz
- **PoE2 Plugin** — Bestehende Memory-Tools

## Diskussions-Punkte (für Projektplanung)

1. **AutoFlask-Aggressivität:** Sollte die Schwelle dynamisch sein (bei Boss vs. normal)?
2. **Entity-Decoder:** Ist die Component-Coverage ausreichend, oder brauchen wir mehr?
3. **UI-Komplexität:** Zu viele Buttons? Performance-Impact?
4. **Memory-Safety:** Sollten wir Checksums/Validierungen erweitern?

## Abkürzungen/Glossar

- **RIP:** Relative Instruction Pointer (x86-64)
- **StdMap:** C++ std::map Container (Red-Black-Tree)
- **Component:** Entity-Daten-Struktur (Life, Buffs, etc.)
- **Entity-List:** Awake/Sleeping Entity-Mappen
- **GameStates:** Central State-Machine (Menu/InGame/Load)
- **InGameState:** Aktueller Spielzustand wenn ingame

---

**Last Updated:** 30. März 2026  
**Next Review:** TBD (nach nächsten Werkstatt-Session)
