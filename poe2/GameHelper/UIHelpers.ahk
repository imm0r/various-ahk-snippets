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
