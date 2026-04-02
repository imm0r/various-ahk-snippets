; RadarOverlay.ahk
; Transparentes, click-through Overlay — zeichnet Entity-Dots auf Mini- und Großkarte.
;
; ── Koordinatentransformation (portiert von Radar.cs / GameHelper2) ────────────────────
;   Kamerawinkel: 38.7°
;   Projektionsformel:
;     mapScale   = 240 / zoom  (Großkarte: zoom *= LARGE_MAP_ZOOM_FACTOR = 0.1738)
;     projCos    = mapDiagonal * cos(38.7°) / mapScale
;     projSin    = mapDiagonal * sin(38.7°) / mapScale
;     gridDelta  = (worldPosition - playerWorldPosition) / WORLD_TO_GRID_RATIO
;     screenDelta.x = (gridDelta.x - gridDelta.y) * projCos
;     screenDelta.y = (gridDelta.z - gridDelta.x - gridDelta.y) * projSin
;     dotScreenPos  = mapCenter + screenDelta
;
; ── UI-Positionsberechnung (portiert von UiElement.cs / GameHelper2) ──────────────────
;   GetUnscaledPosition(): Laufe die Parent-Chain hoch, akkumuliere relativePosition.
;   Finales Ergebnis: unscaledPos * GameWindowScale(scaleIndex, localMultiplier)
;     Referenzauflösung des Spiels: 2560×1600
;     scaleFactorX = windowWidth  / 2560
;     scaleFactorY = windowHeight / 1600
;     scaleIndex 1 → uiScaleX = localMult * scaleFactorX, uiScaleY = localMult * scaleFactorX
;     scaleIndex 2 → uiScaleX = localMult * scaleFactorY, uiScaleY = localMult * scaleFactorY
;     scaleIndex 3 → uiScaleX = localMult * scaleFactorX, uiScaleY = localMult * scaleFactorY  (Standard für UI)
;
; ── Kartentypen ───────────────────────────────────────────────────────────────────────
;   MiniMap:   gespeicherte Position = LINKS OBEN  → Mitte = pos + size/2 + defaultShift + shift
;   Großkarte: gespeicherte Position = KARTENMITTE → Mitte = pos + defaultShift + shift
;              mapDiagonal = sqrt(windowWidth² + windowHeight²)  (rawsz=0 → Fenster als Äquivalent)

class RadarOverlay
{
    ; Transparenzfarbe: fast Schwarz (0x000000 wird von manchen Systemen ignoriert)
    static TRANSPARENT_BACKGROUND := 0x010101

    ; Kamerawinkel-Konstanten für 38.7°
    static CAMERA_COS := 0.78094   ; cos(38.7° in Radiant)
    static CAMERA_SIN := 0.62470   ; sin(38.7° in Radiant)

    ; Zoom-Korrekturfaktor für die Großkarte (aus RadarSettings.cs, default = 0.1738)
    static LARGE_MAP_ZOOM_FACTOR := 0.1738

    ; Umrechnungsfaktor WorldPosition → GridPosition (aus Radar.cs: ratio = 10.86957)
    static WORLD_TO_GRID_RATIO := 10.86957

    ; Dot-Farben (GDI erwartet BGR, nicht RGB)
    static COLOR_ENEMY   := 0x0000FF   ; rot
    static COLOR_NPC     := 0x00FF80   ; grün
    static COLOR_CHEST   := 0x00FFFF   ; gelb
    static COLOR_PLAYER  := 0xFFFFFF   ; weiß

    ; Maximum world-unit radius drawn on the radar. Entities beyond this distance are skipped.
    ; 6000 world units ≈ 552 grid units — matches the outer scoring penalty in the entity sampler.
    static RADAR_MAX_WORLD_DIST_SQ := 36000000   ; 6000^2

    ; Creates the transparent, click-through overlay GUI window and initialises all GDI state fields.
    __New()
    {
        this.overlayGui      := Gui("-Caption +AlwaysOnTop -DPIScale +E0x80000")
        this.overlayGui.BackColor := "010101"
        this.windowHandle    := this.overlayGui.Hwnd
        this.memoryDC        := 0
        this.backBitmap      := 0
        this.bufferWidth     := 0
        this.bufferHeight    := 0
        this.isVisible            := false
        this.stylesApplied        := false
        this._lastMiniMapDiagonal := 0   ; cached minimap diagonal used for large-map projection
    }

    ; Main render entry point: aligns the overlay window, clears the back-buffer, and draws all map layers.
    ; Params: snapshot - full game state snapshot; gameWindow* - screen position and size of the PoE window.
    ; Hauptmethode — wird bei jedem Snapshot-Update aufgerufen.
    ; gameWindowX/Y/Width/Height: Position und Größe des PoE-Fensters in Bildschirmkoordinaten.
    Render(snapshot, gameWindowX, gameWindowY, gameWindowWidth, gameWindowHeight)
    {
        if (gameWindowWidth < 100 || gameWindowHeight < 100)
            return

        ; Overlay-Fenster auf das Spielfenster ausrichten (vor GDI-Operationen)
        WinMove(gameWindowX, gameWindowY, gameWindowWidth, gameWindowHeight, this.windowHandle)
        if !this.isVisible
        {
            this.overlayGui.Show("x" gameWindowX " y" gameWindowY " w" gameWindowWidth " h" gameWindowHeight " NoActivate")
            this.isVisible := true
            if !this.stylesApplied
            {
                WinSetTransColor("010101", this.windowHandle)
                WinSetExStyle("+0x20", this.windowHandle)   ; WS_EX_TRANSPARENT → click-through
                this.stylesApplied := true
            }
        }

        if (this.bufferWidth != gameWindowWidth || this.bufferHeight != gameWindowHeight)
            this._InitBuffers(gameWindowWidth, gameWindowHeight)
        if !this.memoryDC
            return

        ; Neuen Frame mit der Transparenzfarbe füllen
        frameRect := Buffer(16, 0)
        NumPut("Int", gameWindowWidth,  frameRect, 8)
        NumPut("Int", gameWindowHeight, frameRect, 12)
        backgroundBrush := DllCall("CreateSolidBrush", "UInt", RadarOverlay.TRANSPARENT_BACKGROUND, "Ptr")
        DllCall("FillRect", "Ptr", this.memoryDC, "Ptr", frameRect, "Ptr", backgroundBrush)
        DllCall("DeleteObject", "Ptr", backgroundBrush)

        ; Daten aus dem Snapshot extrahieren
        inGameState    := (snapshot && snapshot.Has("inGameState"))           ? snapshot["inGameState"]                 : 0
        uiElements     := (inGameState && inGameState.Has("importantUiElements")) ? inGameState["importantUiElements"]  : 0
        areaInstance   := (inGameState && inGameState.Has("areaInstance"))    ? inGameState["areaInstance"]             : 0
        playerRender   := (areaInstance && areaInstance.Has("playerRenderComponent")) ? areaInstance["playerRenderComponent"] : 0
        miniMapData    := (uiElements && uiElements.Has("miniMapData"))       ? uiElements["miniMapData"]               : 0
        largeMapData   := (uiElements && uiElements.Has("largeMapData"))      ? uiElements["largeMapData"]              : 0

        hasPlayerPosition   := (playerRender && playerRender.Has("worldPosition"))
        awakeEntityCount    := (areaInstance && areaInstance.Has("awakeEntities") && areaInstance["awakeEntities"].Has("sampleCount"))
                               ? areaInstance["awakeEntities"]["sampleCount"] : "?"

        ; Status-Zeile immer sichtbar (Lebenszeichen oben links)
        miniMapSize    := miniMapData  ? (Round(miniMapData["sizeW"])  "x" Round(miniMapData["sizeH"]))  : "no-mm"
        largeMapSize   := largeMapData ? (Round(largeMapData["sizeW"]) "x" Round(largeMapData["sizeH"])) : "no-lm"
        miniMapVisible := miniMapData  ? (miniMapData["isVisible"]  ? "V" : "H") : "-"
        largeMapVisible := largeMapData ? (largeMapData["isVisible"] ? "V" : "H") : "-"
        miniMapPos     := miniMapData  ? (Round(miniMapData["unscaledPosX"]) "," Round(miniMapData["unscaledPosY"])) : "-"
        this._DrawText(4, 4,
            "area:" (areaInstance?"OK":"NIL") " pr:" (hasPlayerPosition?"OK":"NIL") " ent:" awakeEntityCount
            " mm:" miniMapSize "[" miniMapVisible "]" " upos:" miniMapPos " lm:" largeMapSize "[" largeMapVisible "]",
            0x00FFFF)

        this._DrawDot(8, 8, 0xFFFFFF, 5)   ; weißer Punkt = Overlay läuft

        if !hasPlayerPosition
        {
            this._DrawDot(20, 8, 0x0000FF, 5)   ; blauer Punkt = kein Spieler gefunden
            this._Blit(gameWindowWidth, gameWindowHeight)
            return
        }

        playerWorldPosition := playerRender["worldPosition"]
        playerWorldX        := playerWorldPosition["x"]
        playerWorldY        := playerWorldPosition["y"]
        playerTerrainHeight := playerRender.Has("terrainHeight") ? playerRender["terrainHeight"] : 0.0

        ; Minimap-Diagonale auch dann cachen, wenn die Minimap gerade unsichtbar ist
        ; (die Großkarte braucht sie, ist aber oft offen wenn Minimap verdeckt ist).
        if miniMapData
        {
            sfX := gameWindowWidth  / 2560.0
            sfY := gameWindowHeight / 1600.0
            si  := miniMapData["scaleIdx"]
            lm  := miniMapData["localMult"]
            s   := (si = 1 || si = 3) ? lm * sfX : (si = 2) ? lm * sfY : lm
            mmW := miniMapData["sizeW"] * s
            mmH := miniMapData["sizeH"] * s
            if (mmW > 20 && mmH > 20)
                this._lastMiniMapDiagonal := Sqrt(mmW * mmW + mmH * mmH)
        }

        if (miniMapData && miniMapData["isVisible"])
        {
            try this._RenderMapLayer(miniMapData, playerWorldX, playerWorldY, playerTerrainHeight,
                                     areaInstance, gameWindowWidth, gameWindowHeight, false)
            catch
                this._DrawDot(40, 8, 0x00FF00, 4)   ; grüner Punkt = MiniMap-Fehler
        }

        if (largeMapData && largeMapData["isVisible"])
        {
            try this._RenderMapLayer(largeMapData, playerWorldX, playerWorldY, playerTerrainHeight,
                                     areaInstance, gameWindowWidth, gameWindowHeight, true)
            catch
                this._DrawDot(56, 8, 0x00FFFF, 4)   ; cyaner Punkt = Großkarten-Fehler
        }

        this._Blit(gameWindowWidth, gameWindowHeight)
    }

    ; Renders entity dots onto one map layer using isometric projection and the game's UI scale math.
    ; Params: isLargeMap - switches between large-map center/window-diagonal vs. mini-map top-left formulas.
    ; Zeichnet Entities auf eine Kartenschicht (Mini- oder Großkarte).
    _RenderMapLayer(mapData, playerWorldX, playerWorldY, playerTerrainHeight,
                    areaInstance, gameWindowWidth, gameWindowHeight, isLargeMap)
    {
        ; ── UI-Skalierung berechnen (nach GameWindowScale.cs) ────────────────────────────
        ; Das Spiel nutzt 2560×1600 als Design-Referenzauflösung für alle UI-Positionen.
        ; scaleFactorX/Y rechnen unscaled UI-Koordinaten in echte Pixelkoordinaten um.
        scaleFactorX    := gameWindowWidth  / 2560.0
        scaleFactorY    := gameWindowHeight / 1600.0
        scaleIndex      := mapData["scaleIdx"]
        localMultiplier := mapData["localMult"]

        if      scaleIndex = 1
            uiScaleX := localMultiplier * scaleFactorX, uiScaleY := localMultiplier * scaleFactorX
        else if scaleIndex = 2
            uiScaleX := localMultiplier * scaleFactorY, uiScaleY := localMultiplier * scaleFactorY
        else if scaleIndex = 3
            uiScaleX := localMultiplier * scaleFactorX, uiScaleY := localMultiplier * scaleFactorY
        else
            uiScaleX := localMultiplier,                uiScaleY := localMultiplier

        ; ── Kartenposition auf dem Bildschirm ────────────────────────────────────────────
        ; MiniMap: unscaledPos = LINKS OBEN → mapCenter = pos + size/2 + shifts
        ; LargeMap: Die Position-Traversal liefert bereits den Kartenmittelpunkt (der Großkarte
        ;           ist im UI-Baum relativ zum Bildschirmmittelpunkt positioniert → kein +size/2)
        mapElementScreenX := mapData["unscaledPosX"] * uiScaleX
        mapElementScreenY := mapData["unscaledPosY"] * uiScaleY

        ; ── Kartengröße und Mittelpunkt auf dem Bildschirm ───────────────────────────────
        mapScreenWidth  := mapData["sizeW"] * uiScaleX
        mapScreenHeight := mapData["sizeH"] * uiScaleY

        if isLargeMap
        {
            ; Großkarte: Position-Traversal gibt Mittelpunkt → nur Shifts hinzuaddieren.
            ; Die gespeicherte Elementgröße ist oft 0 → Fenstergröße als Displayfallback.
            mapCenterX := mapElementScreenX + mapData["defaultShiftX"] + mapData["shiftX"]
            mapCenterY := mapElementScreenY + mapData["defaultShiftY"] + mapData["shiftY"]
            if (!(mapScreenWidth > 20) || !(mapScreenHeight > 20)) {
                mapScreenWidth  := gameWindowWidth
                mapScreenHeight := gameWindowHeight
            }
        }
        else
        {
            if (!(mapScreenWidth > 20) || !(mapScreenHeight > 20))
                return
            ; MiniMap: Position ist Links-Oben → Mittelpunkt = pos + size/2 + shifts.
            mapCenterX := mapElementScreenX + mapScreenWidth  / 2 + mapData["defaultShiftX"] + mapData["shiftX"]
            mapCenterY := mapElementScreenY + mapScreenHeight / 2 + mapData["defaultShiftY"] + mapData["shiftY"]
        }

        if (mapCenterX < -mapScreenWidth  || mapCenterX > gameWindowWidth  + mapScreenWidth
         || mapCenterY < -mapScreenHeight || mapCenterY > gameWindowHeight + mapScreenHeight)
            return

        ; ── Diagonale für Projektionsskalierung ──────────────────────────────────────────
        ; MiniMap: Diagonale des tatsächlichen Kartenelements.
        ; LargeMap: UnscaledSize=0 im Speicher → Minimap-Diagonale verwenden (gecacht in Render()).
        ;           Wird ohne LARGE_MAP_ZOOM_FACTOR kombiniert, weil dieser Faktor die
        ;           Fensterdiagonale auf Minimap-Diagonale herunterskaliert — bei direkter
        ;           Nutzung der Minimap-Diagonale wird er nicht mehr benötigt.
        if isLargeMap
            mapDiagonal := (this._lastMiniMapDiagonal > 0)
                ? this._lastMiniMapDiagonal
                : Sqrt(gameWindowWidth * gameWindowWidth + gameWindowHeight * gameWindowHeight)
        else
            mapDiagonal := Sqrt(mapScreenWidth * mapScreenWidth + mapScreenHeight * mapScreenHeight)

        ; ── Zoom-Wert für Radar-Projektion ───────────────────────────────────────────────
        ; LARGE_MAP_ZOOM_FACTOR ist NUR nötig wenn Fensterdiagonale verwendet wird.
        ; Mit Minimap-Diagonale direkt → rohen Zoom-Wert verwenden (kein Faktor).
        mapZoom := mapData["zoom"]
        if (!(mapZoom > 0) || mapZoom > 20)
            mapZoom := 0.5

        ; ── DEBUG: Kartenrahmen und Mittelpunkt ──────────────────────────────────────────
        debugColor := isLargeMap ? 0xFFFF00 : 0xFF8800
        this._DrawDot(Round(mapCenterX), Round(mapCenterY), debugColor, 15)
        ; MiniMap: Rahmen startet oben-links bei mapElementScreenX/Y.
        ; LargeMap: Position-Traversal liefert den Mittelpunkt → Rahmen zentrieren.
        rectX := isLargeMap ? Round(mapCenterX - mapScreenWidth / 2) : Round(mapElementScreenX)
        rectY := isLargeMap ? Round(mapCenterY - mapScreenHeight / 2) : Round(mapElementScreenY)
        this._DrawRect(rectX, rectY, Round(mapScreenWidth), Round(mapScreenHeight), debugColor, 1)
        debugTextRow := isLargeMap ? 32 : 16
        this._DrawText(4, debugTextRow,
            (isLargeMap?"L":"M") " ctr=" Round(mapCenterX) "," Round(mapCenterY)
            " spos=" Round(mapElementScreenX) "," Round(mapElementScreenY)
            " rawsz=" Round(mapData["sizeW"]) "x" Round(mapData["sizeH"])
            " sz=" Round(mapScreenWidth) "x" Round(mapScreenHeight)
            " si=" mapData["scaleIdx"] " dep=" mapData["chainDepth"] " z=" Round(mapZoom, 3),
            debugColor)

        ; ── Projektionsfaktoren für Radar-Koordinatentransformation ──────────────────────
        baseMapScale := 240.0 / mapZoom
        projectionCos := mapDiagonal * RadarOverlay.CAMERA_COS / baseMapScale
        projectionSin := mapDiagonal * RadarOverlay.CAMERA_SIN / baseMapScale

        ; Spieler-Dot in der Kartenmitte
        this._DrawDot(Round(mapCenterX), Round(mapCenterY), RadarOverlay.COLOR_PLAYER, isLargeMap ? 4 : 2)

        ; ── Entities zeichnen ────────────────────────────────────────────────────────────
        awakeEntities   := (areaInstance && areaInstance.Has("awakeEntities"))    ? areaInstance["awakeEntities"]    : 0
        sleepingEntities := (areaInstance && areaInstance.Has("sleepingEntities")) ? areaInstance["sleepingEntities"] : 0

        statTotal     := 0
        statNoDecoded := 0
        statNoRender  := 0
        statFiltered  := 0
        statDead      := 0
        statDrawn     := 0
        firstEntityPath := ""

        for _, entitySource in [awakeEntities, sleepingEntities]
        {
            if !(entitySource && entitySource.Has("sample"))
                continue
            for _, sampleEntry in entitySource["sample"]
            {
                if !(sampleEntry && sampleEntry.Has("entity"))
                    continue
                entity := sampleEntry["entity"]
                statTotal += 1

                if (firstEntityPath = "" && entity.Has("path"))
                    firstEntityPath := SubStr(entity["path"], 1, 40)

                ; Skip stale/removed entities (flags bit-0 set = invalid in game engine)
                if (entity.Has("isValid") && !entity["isValid"]) {
                    statDead += 1
                    continue
                }

                decodedComponents := entity.Has("decodedComponents") ? entity["decodedComponents"] : 0
                if !decodedComponents {
                    statNoDecoded += 1
                    continue
                }

                renderComponent := decodedComponents.Has("render") ? decodedComponents["render"] : 0
                if !(renderComponent && renderComponent.Has("worldPosition")) {
                    statNoRender += 1
                    continue
                }

                ; Path-Filter: nur Monster, Spielercharaktere und NPCs anzeigen
                entityPathLower := entity.Has("path") ? StrLower(entity["path"]) : ""
                isMonster   := InStr(entityPathLower, "metadata/monsters/")
                isCharacter := InStr(entityPathLower, "metadata/characters/")
                isNpc       := InStr(entityPathLower, "metadata/npc/")
                if !(isMonster || isCharacter || isNpc) {
                    statFiltered += 1
                    continue
                }

                entityWorldPos      := renderComponent["worldPosition"]
                entityTerrainHeight := renderComponent.Has("terrainHeight") ? renderComponent["terrainHeight"] : 0.0

                ; Hard distance cutoff: skip entities further than 6000 world units from the player.
                ; This matches the outermost priority penalty in the entity sampler and prevents
                ; stale/dead entity positions from projecting to the screen after the player moves.
                wdx := entityWorldPos["x"] - playerWorldX
                wdy := entityWorldPos["y"] - playerWorldY
                if (wdx * wdx + wdy * wdy > RadarOverlay.RADAR_MAX_WORLD_DIST_SQ) {
                    statFiltered += 1
                    continue
                }

                ; Welt-Delta → Grid-Delta umrechnen
                gridDeltaX := (entityWorldPos["x"] - playerWorldX)        / RadarOverlay.WORLD_TO_GRID_RATIO
                gridDeltaY := (entityWorldPos["y"] - playerWorldY)        / RadarOverlay.WORLD_TO_GRID_RATIO
                gridDeltaZ := (entityTerrainHeight - playerTerrainHeight) / RadarOverlay.WORLD_TO_GRID_RATIO

                ; Isometrische Radar-Projektion (Kamerawinkel 38.7°)
                screenDeltaX := (gridDeltaX - gridDeltaY) * projectionCos
                screenDeltaY := (gridDeltaZ - gridDeltaX - gridDeltaY) * projectionSin

                dotScreenX := Round(mapCenterX + screenDeltaX)
                dotScreenY := Round(mapCenterY + screenDeltaY)

                ; Skip only if the life component was successfully decoded AND explicitly reports dead.
                ; If life component is absent (failed plausibility) we allow through — radar decode
                ; now scans all components, so a missing life key means the address was unreadable.
                lifeComponent := decodedComponents.Has("life") ? decodedComponents["life"] : 0
                if (lifeComponent && Type(lifeComponent) = "Map"
                    && lifeComponent.Has("isAlive") && !lifeComponent["isAlive"]) {
                    statDead += 1
                    continue
                }

                ; Dot-Farbe nach Entity-Typ
                positionedComponent := decodedComponents.Has("positioned") ? decodedComponents["positioned"] : 0
                isFriendly := positionedComponent && positionedComponent.Has("isFriendly") && positionedComponent["isFriendly"]

                dotColor := (isNpc || isFriendly) ? RadarOverlay.COLOR_NPC
                          :                         RadarOverlay.COLOR_ENEMY

                dotRadius := isLargeMap ? 4 : 3
                this._DrawDot(dotScreenX, dotScreenY, dotColor, dotRadius)
                statDrawn += 1
            }
        }

        ; Debug-Statuszeile: zeigt wie viele Entities durch welchen Filter gefallen sind
        debugStatsRow := isLargeMap ? 48 : 56
        this._DrawText(4, debugStatsRow,
            (isLargeMap?"L":"M") "-ent: tot=" statTotal " noD=" statNoDecoded " noR=" statNoRender
            " flt=" statFiltered " dead=" statDead " drawn=" statDrawn " p0=" firstEntityPath,
            debugColor)
    }

    ; ── GDI Zeichen-Helfer ───────────────────────────────────────────────────────────────

    ; Draws a text string at the given back-buffer coordinates using transparent background mode.
    _DrawText(screenX, screenY, text, colorBGR)
    {
        DllCall("SetTextColor", "Ptr", this.memoryDC, "UInt", colorBGR)
        DllCall("SetBkMode",    "Ptr", this.memoryDC, "Int", 1)   ; TRANSPARENT
        DllCall("TextOutW", "Ptr", this.memoryDC,
                "Int", screenX, "Int", screenY, "Str", text, "Int", StrLen(text))
    }

    ; Draws a straight line on the back-buffer between two screen coordinates.
    _DrawLine(x1, y1, x2, y2, colorBGR, penWidth := 1)
    {
        pen    := DllCall("CreatePen", "Int", 0, "Int", penWidth, "UInt", colorBGR, "Ptr")
        oldPen := DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", pen, "Ptr")
        DllCall("MoveToEx", "Ptr", this.memoryDC, "Int", x1, "Int", y1, "Ptr", 0)
        DllCall("LineTo",   "Ptr", this.memoryDC, "Int", x2, "Int", y2)
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", oldPen)
        DllCall("DeleteObject", "Ptr", pen)
    }

    ; Draws a filled circle on the back-buffer at (centerX, centerY) with the given radius.
    _DrawDot(centerX, centerY, colorBGR, radius := 3)
    {
        pen      := DllCall("CreatePen",        "Int", 0, "Int", 1, "UInt", colorBGR, "Ptr")
        brush    := DllCall("CreateSolidBrush", "UInt", colorBGR, "Ptr")
        oldPen   := DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", pen,   "Ptr")
        oldBrush := DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", brush, "Ptr")
        DllCall("Ellipse", "Ptr", this.memoryDC,
                "Int", centerX - radius, "Int", centerY - radius,
                "Int", centerX + radius, "Int", centerY + radius)
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", oldPen)
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", oldBrush)
        DllCall("DeleteObject", "Ptr", pen)
        DllCall("DeleteObject", "Ptr", brush)
    }

    ; Draws a hollow rectangle outline on the back-buffer; uses NULL_BRUSH to avoid filling the interior.
    _DrawRect(screenX, screenY, width, height, colorBGR, penWidth := 1)
    {
        pen      := DllCall("CreatePen",      "Int", 0, "Int", penWidth, "UInt", colorBGR, "Ptr")
        nullBrush := DllCall("GetStockObject", "Int", 5, "Ptr")   ; NULL_BRUSH (kein Fill)
        oldPen   := DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", pen,       "Ptr")
        oldBrush := DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", nullBrush, "Ptr")
        DllCall("Rectangle", "Ptr", this.memoryDC,
                "Int", screenX, "Int", screenY, "Int", screenX + width, "Int", screenY + height)
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", oldPen)
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", oldBrush)
        DllCall("DeleteObject", "Ptr", pen)
    }

    ; ── Interne Buffer-Verwaltung ────────────────────────────────────────────────────────

    ; Creates (or re-creates) the compatible memory DC and DIB bitmap used for off-screen rendering.
    _InitBuffers(width, height)
    {
        if this.backBitmap
        {
            stockBitmap := DllCall("GetStockObject", "Int", 0, "Ptr")
            DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", stockBitmap)
            DllCall("DeleteObject", "Ptr", this.backBitmap)
            DllCall("DeleteDC",     "Ptr", this.memoryDC)
        }
        screenDC          := DllCall("GetDC", "Ptr", this.windowHandle, "Ptr")
        this.memoryDC     := DllCall("CreateCompatibleDC",     "Ptr", screenDC,              "Ptr")
        this.backBitmap   := DllCall("CreateCompatibleBitmap", "Ptr", screenDC, "Int", width, "Int", height, "Ptr")
        DllCall("SelectObject", "Ptr", this.memoryDC, "Ptr", this.backBitmap)
        DllCall("ReleaseDC", "Ptr", this.windowHandle, "Ptr", screenDC)
        this.bufferWidth  := width
        this.bufferHeight := height
    }

    ; Copies the completed back-buffer to the overlay window's screen DC for flicker-free display.
    _Blit(width, height)
    {
        screenDC := DllCall("GetDC", "Ptr", this.windowHandle, "Ptr")
        DllCall("BitBlt", "Ptr", screenDC,
                "Int", 0, "Int", 0, "Int", width, "Int", height,
                "Ptr", this.memoryDC, "Int", 0, "Int", 0, "UInt", 0x00CC0020)   ; SRCCOPY
        DllCall("ReleaseDC", "Ptr", this.windowHandle, "Ptr", screenDC)
    }

    ; Hides the overlay GUI window and resets the visibility flag.
    Hide()
    {
        if this.isVisible
        {
            this.overlayGui.Hide()
            this.isVisible := false
        }
    }

    ; Destructor: hides the overlay and releases the GDI back-buffer DC and bitmap.
    __Delete()
    {
        this.Hide()
        if this.backBitmap
            DllCall("DeleteObject", "Ptr", this.backBitmap)
        if this.memoryDC
            DllCall("DeleteDC", "Ptr", this.memoryDC)
    }
}
