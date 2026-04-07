; UIHelpers.ahk
; UI helper functions for the InGameState monitor.
;
; Contains: OnApplyThresholdClick, ApplyThresholdsFromUI, ParseThresholdPercent, SafePercent,
; ShouldHideNode, FormatScalar, IsAddressLikeField, BuildHotkeyLegendText,
; UpdateActionButtonLabels, Toggle*Mode functions
;
; Included by InGameStateMonitor.ahk

; Click handler for the Apply Threshold button; delegates to ApplyThresholdsFromUI.
OnApplyThresholdClick(*)
{
    ApplyThresholdsFromUI()
}

; Reads life/mana threshold values from the UI edit controls, clamps them, and triggers a UI refresh.
ApplyThresholdsFromUI()
{
    global lifeThresholdEdit, manaThresholdEdit, lifeThresholdPercent, manaThresholdPercent, thresholdStatusText

    lifeRaw := lifeThresholdEdit.Value
    manaRaw := manaThresholdEdit.Value

    lifeThresholdPercent := ParseThresholdPercent(lifeRaw, lifeThresholdPercent)
    manaThresholdPercent := ParseThresholdPercent(manaRaw, manaThresholdPercent)

    lifeThresholdEdit.Value := lifeThresholdPercent
    manaThresholdEdit.Value := manaThresholdPercent
    thresholdStatusText.Value := "Applied: Life=" lifeThresholdPercent "% | Mana=" manaThresholdPercent "%"

    ReadAndShow()
}

; Parses a percentage string from a UI input field and clamps the result to [1, 100].
; Params: raw - raw string value from the edit control; fallback - returned when parsing fails
; Returns: integer percentage in [1, 100]
ParseThresholdPercent(raw, fallback)
{
    text := Trim(raw)
    if !RegExMatch(text, "^-?\d+$")
        return fallback

    val := Integer(text)
    if (val < 1)
        val := 1
    if (val > 100)
        val := 100
    return val
}

; Returns (current / max) * 100 as a float, or -1 if max is zero to avoid division by zero.
SafePercent(current, max)
{
    if (max <= 0)
        return -1
    return (current * 100.0) / max
}

; Returns true if the given tree node should be suppressed from the display.
; Hides noise nodes such as patternScanReport, inventory ID lists, and duplicate vitals paths.
ShouldHideNode(nodePath, name)
{
    pathLower := StrLower(nodePath)
    nameLower := StrLower(name)

    if (nameLower = "patternscanreport")
        return true

    if (nameLower = "inventoryidsseen" || nameLower = "flaskinventoryselectreason")
        return true

    if InStr(pathLower, "/patternscanreport")
        return true

    ; Legacy-Compat: Vitaldaten nur einmal anzeigen (top-level vitalStruct unter areaInstance).
    if (pathLower = "snapshot/ingamestate/areainstance/playervitals")
        return true
    if (pathLower = "snapshot/ingamestate/areainstance/playerstruct/playervitals")
        return true
    if (pathLower = "snapshot/ingamestate/areainstance/playerstruct/vitalstruct")
        return true

    return false
}

; Formats a raw memory value for TreeView display; renders large integers and address-like fields as hex.
; Params: fieldName - optional field name hint; nodePath - optional path used by the address heuristic
FormatScalar(value, fieldName := "", nodePath := "")
{
    valueType := Type(value)

    if (valueType = "String")
        return value

    if (valueType = "Integer")
    {
        if (value > 0x10000 || IsAddressLikeField(fieldName, nodePath))
            return PoE2GameStateReader.Hex(value)
        return value
    }

    if (valueType = "Float")
        return value

    if (valueType = "Buffer")
        return "<Buffer size=" value.Size ">"

    return value
}

; Heuristic: returns true if the field name or path suggests the value is a memory pointer or address.
IsAddressLikeField(fieldName, nodePath := "")
{
    nameLower := StrLower(Trim(fieldName))
    pathLower := StrLower(Trim(nodePath))

    if (nameLower != "")
    {
        if (InStr(nameLower, "address") || InStr(nameLower, "addr") || InStr(nameLower, "ptr") || InStr(nameLower, "pointer"))
            return true
    }

    if (pathLower != "")
    {
        if (InStr(pathLower, "/address") || InStr(pathLower, "address/") || InStr(pathLower, "/ptr") || InStr(pathLower, "ptr/"))
            return true
    }

    return false
}

; Builds the hotkey legend string shown in the status row, reflecting all current toggle states.
; Returns: formatted legend string with Debug/Updates/AutoFlask/AF Perf/Tree/TreeMode/Pinned status
BuildHotkeyLegendText()
{
    global debugMode, updatesPaused, autoFlaskEnabled, autoFlaskPerformanceMode, pinnedNodePaths, showTreePane, activeTreeTabKey

    return (
        "Buttons: "
        . "Debug(" (debugMode ? "ON" : "OFF") ") | "
        . "Updates(" (updatesPaused ? "PAUSED" : "LIVE") ") | "
        . "AutoFlask(" (autoFlaskEnabled ? "ON" : "OFF") ") | "
        . "AFPerf(" (autoFlaskPerformanceMode ? "ON" : "OFF") ") | "
        . "Tree(" (showTreePane ? "ON" : "OFF") ") | "
        . "TreeMode(MANUAL:" activeTreeTabKey ") | "
        . "Pinned(" pinnedNodePaths.Length ")"
    )
}

; Refreshes all action button captions and enabled states to reflect current global toggle flags.
UpdateActionButtonLabels()
{
    global btnDebug, btnPause, btnAutoFlask, btnAutoFlaskPerf, btnPinSelected, btnWatchNearbyNpc, btnTreeToggle, btnTreeRefresh, btnClearPinned, btnRemovePinned, btnStartGame
    global debugMode, updatesPaused, autoFlaskEnabled, autoFlaskPerformanceMode, pinnedNodePaths, showTreePane, npcWatchAutoSync

    try btnDebug.Text := "Debug " (debugMode ? "ON" : "OFF")
    try btnPause.Text := "Updates " (updatesPaused ? "PAUSE" : "LIVE")
    try btnAutoFlask.Text := "AutoFlask " (autoFlaskEnabled ? "ON" : "OFF")
    try btnAutoFlaskPerf.Text := "AF Perf " (autoFlaskPerformanceMode ? "ON" : "OFF")
    try btnPinSelected.Text := "Watch Sel"
    try btnPinSelected.Enabled := showTreePane
    try btnWatchNearbyNpc.Text := "Watch NPC" (npcWatchAutoSync ? " ON" : "")
    try btnTreeToggle.Text := "Tree " (showTreePane ? "ON" : "OFF")
    try btnTreeRefresh.Text := "Tree Snap"
    try btnTreeRefresh.Enabled := showTreePane
    try btnClearPinned.Text := "Clear(" pinnedNodePaths.Length ")"
    try btnRemovePinned.Text := "Remove Sel"
    ; Show Start button only when PoE2 is not running
    try {
        pid := ProcessExist("PathOfExileSteam.exe")
        if (!pid)
            pid := ProcessExist("PathOfExile.exe")
        try btnStartGame.Visible := (pid ? false : true)
        try btnStartGame.Text := "Start PoE2"
    } catch {
    }
}

OnDebugButtonClick(*) => ToggleDebugMode()
OnPauseButtonClick(*) => ToggleUpdatesPause()
OnAutoFlaskButtonClick(*) => ToggleAutoFlaskMode()
OnAutoFlaskPerfButtonClick(*) => ToggleAutoFlaskPerformanceMode()
OnPinSelectedButtonClick(*) => PinSelectedTreeNodePath()
OnWatchNearbyNpcButtonClick(*) => AddNearbyNpcScannerToWatchlist()
OnTreeToggleButtonClick(*) => ToggleTreePaneVisibility()
OnTreeSnapButtonClick(*) => ForceRefreshActiveTree()
OnClearPinsButtonClick(*) => ClearPinnedNodePaths()

OnOffsetSearchChanged(*) => RefreshOffsetTableView()
OnRemovePinnedSelectedClick(*) => RemoveSelectedPinnedFromTable()

; Liest die aktuellen Checkbox-Zustände der Radar-Filter und schreibt sie in die globalen Flags.
; Wird von allen vier Radar-Checkboxen aufgerufen.
OnRadarFilterChanged(*)
{
    global radarShowEnemyNormal, radarShowEnemyRare, radarShowEnemyBoss, radarShowMinions, radarShowNpcs, radarShowChests
    global chkRadarEnemyNormal, chkRadarEnemyRare, chkRadarEnemyBoss, chkRadarMinions, chkRadarNpcs, chkRadarChests
    radarShowEnemyNormal := chkRadarEnemyNormal.Value ? true : false
    radarShowEnemyRare   := chkRadarEnemyRare.Value   ? true : false
    radarShowEnemyBoss   := chkRadarEnemyBoss.Value   ? true : false
    radarShowMinions := chkRadarMinions.Value ? true : false
    radarShowNpcs    := chkRadarNpcs.Value    ? true : false
    radarShowChests  := chkRadarChests.Value  ? true : false
}

; Dumps diagnostic info for all currently visible radar entities to data\radar_entity_debug_*.tsv.
; Use this to investigate ghost entities — the file shows raw targetable byte, HP, isAlive, etc.
OnDumpEntitiesClicked(*)
{
    global reader, g_radarLastSnap
    if !IsObject(reader)
    {
        MsgBox("Reader not initialised.", "Dump Entities", 0x10)
        return
    }
    snap := IsObject(g_radarLastSnap) ? g_radarLastSnap : 0
    if !snap
    {
        MsgBox("No radar snapshot available yet. Wait for the game to load.", "Dump Entities", 0x10)
        return
    }
    outPath := reader.DumpRadarEntityDebug(snap)
    if outPath
        MsgBox("Exported to:`n" outPath, "Dump Entities", 0x40)
    else
        MsgBox("Export failed (no entities or write error).", "Dump Entities", 0x10)
}

; Toggles the debugMode flag and triggers a full UI refresh.
ToggleDebugMode()
{
    global debugMode
    debugMode := !debugMode
    ReadAndShow()
}

; Toggles the updatesPaused flag; updates the tree root label when pausing, or resumes live updates.
ToggleUpdatesPause()
{
    global updatesPaused, valueTree
    updatesPaused := !updatesPaused
    if (updatesPaused)
    {
        if valueTree
        {
            root := TV_GetRoot(valueTree.Hwnd)
            if (root)
                valueTree.Modify(root, , RegExReplace(valueTree.GetText(root), "Updates:\s+(PAUSED|LIVE)", "Updates: PAUSED"))
        }
    }
    else
    {
        ReadAndShow()
        return
    }

    ReadAndShow()
}

; Toggles the autoFlaskEnabled flag and triggers a full UI refresh.
ToggleAutoFlaskMode()
{
    global autoFlaskEnabled
    autoFlaskEnabled := !autoFlaskEnabled
    ReadAndShow()
}

; Toggles autoFlaskPerformanceMode (skips full snapshot reads in the main loop) and triggers a refresh.
ToggleAutoFlaskPerformanceMode()
{
    global autoFlaskPerformanceMode
    autoFlaskPerformanceMode := !autoFlaskPerformanceMode
    ReadAndShow()
}

; ─────────────────────────────────────────────────────────────────────────────
; F3 Debug-Dump: dumps TreeView, a game-window screenshot, and the radar TSV.
; ─────────────────────────────────────────────────────────────────────────────

; Recursively walks a TreeView control and builds a JSON array of node objects.
; Each node: {"text": "...", "children": [...]}
; Returns: JSON array string
_DumpTreeNodeRecursiveJson(ctrl, hwnd, nodeId)
{
    items := []
    while (nodeId != 0)
    {
        label := ctrl.GetText(nodeId)
        ; Escape JSON string
        escaped := StrReplace(label, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`r", "\r")
        escaped := StrReplace(escaped, "`t", "\t")

        child := TV_GetChild(hwnd, nodeId)
        if child
        {
            childJson := _DumpTreeNodeRecursiveJson(ctrl, hwnd, child)
            items.Push('{"text":"' escaped '","children":' childJson '}')
        }
        else
            items.Push('{"text":"' escaped '"}')

        nodeId := TV_GetNext(hwnd, nodeId)
    }
    ; Join items into JSON array
    joined := ""
    for i, item in items
        joined .= (i > 1 ? "," : "") item
    return "[" joined "]"
}

; Dumps the content of every TreeView tab to debug\treeview_dump_<timestamp>.json.
; Returns: path of the created file, or "" on error.
DumpTreeViewContent()
{
    global treeControlsByTab, treeTabKeys

    outDir  := A_ScriptDir "\debug"
    if !DirExist(outDir)
        DirCreate(outDir)
    ts      := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    outPath := outDir "\treeview_dump_" ts ".json"

    ; Build JSON object: {"timestamp": "...", "tabs": {"tabKey": [...]}}
    tabsJson := ""
    first := true
    for _, tabKey in treeTabKeys
    {
        if !treeControlsByTab.Has(tabKey)
            continue
        ctrl := treeControlsByTab[tabKey]
        hwnd  := ctrl.Hwnd
        root  := TV_GetRoot(hwnd)
        nodes := root ? _DumpTreeNodeRecursiveJson(ctrl, hwnd, root) : "[]"

        escapedKey := StrReplace(tabKey, '"', '\"')
        tabsJson .= (first ? "" : ",") '"' escapedKey '"' ":" nodes
        first := false
    }

    ts_display := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    json := '{"timestamp":"' ts_display '","tabs":{' tabsJson '}}'

    try
    {
        FileAppend(json, outPath, "UTF-8")
        return outPath
    }
    catch
        return ""
}

; Captures a screenshot of the PoE2 game window (or the primary monitor as fallback)
; and saves it to debug\screenshot_<timestamp>.png.
; Returns: path of the created file, or "" on error.
CaptureGameWindowScreenshot()
{
    outDir  := A_ScriptDir "\debug"
    if !DirExist(outDir)
        DirCreate(outDir)
    ts      := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    outPath := outDir "\screenshot_" ts ".png"

    ; Find the PoE2 window
    gameHwnd := WinExist("ahk_exe PathOfExileSteam.exe")
    if !gameHwnd
        gameHwnd := WinExist("ahk_exe PathOfExile.exe")

    if gameHwnd
    {
        ; Bring game window to focus so BitBlt captures it correctly
        ; (do NOT activate — we just need its position)
        WinGetPos(&gwX, &gwY, &gwW, &gwH, "ahk_id " gameHwnd)
        if (gwW > 0 && gwH > 0)
        {
            x := gwX, y := gwY, w := gwW, h := gwH
        }
        else
        {
            x := 0, y := 0, w := A_ScreenWidth, h := A_ScreenHeight
        }
    }
    else
    {
        x := 0, y := 0, w := A_ScreenWidth, h := A_ScreenHeight
    }

    ; Use GDI+ to capture the screen region
    pToken := 0
    DllCall("LoadLibrary", "Str", "gdiplus")
    si := Buffer(24, 0)
    NumPut("UInt", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)

    ; Capture from screen DC (hDC=0 = entire virtual screen)
    hDC     := DllCall("GetDC", "Ptr", 0, "Ptr")
    hMemDC  := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
    hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", w, "Int", h, "Ptr")
    DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hBitmap)
    DllCall("BitBlt", "Ptr", hMemDC, "Int", 0, "Int", 0, "Int", w, "Int", h,
            "Ptr", hDC, "Int", x, "Int", y, "UInt", 0x00CC0020)  ; SRCCOPY

    ; Encode to PNG via GDI+
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmap, "Ptr", 0, "Ptr*", &pBitmap)

    pngClsid := Buffer(16, 0)
    _GetEncoderClsid("image/png", pngClsid)
    DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", outPath, "Ptr", pngClsid, "Ptr", 0)

    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", hMemDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)

    return FileExist(outPath) ? outPath : ""
}

; Retrieves the CLSID of a GDI+ image encoder by MIME type into the given buffer.
_GetEncoderClsid(mimeType, clsidBuf)
{
    numEncoders := 0
    size := 0
    DllCall("gdiplus\GdipGetImageEncodersSize", "UInt*", &numEncoders, "UInt*", &size)
    if (size = 0)
        return -1

    buf := Buffer(size, 0)
    DllCall("gdiplus\GdipGetImageEncoders", "UInt", numEncoders, "UInt", size, "Ptr", buf)

    ; Each ImageCodecInfo struct is 76 bytes (x64 with packing considerations, but layout below is standard)
    loop numEncoders
    {
        offset := (A_Index - 1) * 104  ; sizeof ImageCodecInfo = 104 on x64
        mimePtr := NumGet(buf, offset + 64, "Ptr")   ; MimeType field offset
        mime    := StrGet(mimePtr, "UTF-16")
        if (mime = mimeType)
        {
            ; CLSID is at offset 0
            DllCall("RtlCopyMemory", "Ptr", clsidBuf, "Ptr", buf.Ptr + offset, "Ptr", 16)
            return A_Index - 1
        }
    }
    return -1
}

; F3 handler: dumps TreeView, captures a game screenshot, then dumps the radar entity TSV.
; All three files land in debug\ with matching timestamps.
OnF3DebugDump()
{
    global reader, g_radarLastSnap

    debugDir := A_ScriptDir "\debug"
    if !DirExist(debugDir)
        DirCreate(debugDir)

    ; 1) TreeView dump
    tvPath := DumpTreeViewContent()

    ; 2) Screenshot of game window
    ssPath := CaptureGameWindowScreenshot()

    ; 3) Radar entity TSV — use cached snapshot or read a fresh one
    tsvPath := ""
    if IsObject(reader)
    {
        snap := IsObject(g_radarLastSnap) ? g_radarLastSnap : 0
        if !snap
        {
            try snap := reader.ReadRadarSnapshot()
        }
        if snap
            tsvPath := reader.DumpRadarEntityDebug(snap, debugDir)
    }

    ; Show a brief non-blocking tooltip so the user knows the dump succeeded
    msg := "F3 Debug Dump:`n"
        . (tvPath  ? "  TreeView : " tvPath  "`n" : "  TreeView : FAILED`n")
        . (ssPath  ? "  Screenshot: " ssPath "`n" : "  Screenshot: FAILED`n")
        . (tsvPath ? "  Radar TSV : " tsvPath     : "  Radar TSV : FAILED (no snapshot?)")
    ToolTip(msg)
    SetTimer(() => ToolTip(), -4000)
}
