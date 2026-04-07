#Requires AutoHotkey v2.0
#SingleInstance Force

#Include PoE2MemoryReader.ahk
#Include PatchChecker.ahk
#Include RadarOverlay.ahk

reader := PoE2GameStateReader("PathOfExileSteam.exe")
debugMode := false
updatesPaused := false
autoFlaskEnabled := false
lifeThresholdPercent := 55
manaThresholdPercent := 35
flaskUseCooldownMs := 450
lastFlaskUseBySlot := Map(1, 0, 2, 0)
pendingFlaskVerifyBySlot := Map()
autoFlaskLastReason := "idle"
autoFlaskPerformanceMode := false
pinnedNodePaths := []
lastSnapshotForUi := 0
g_radarOverlay  := 0   ; lazy-init beim ersten Render-Aufruf
g_radarLastSnap := 0   ; last successful radar snapshot — used by Dump Entities button
g_radarReadMs   := 0  ; Last ReadRadarSnapshot() duration (ms)
g_radarRenderMs := 0  ; Last RadarOverlay.Render() duration (ms)
g_profReadLastMs  := 0
g_profReadAvgMs   := 0
g_profTreeLastMs  := 0
g_profTotalLastMs := 0
offsetTableRowPathByRow := Map()
offsetPreviousValueByPath := Map()
offsetTableSortCol := 1
offsetTableSortDesc := false
npcWatchRadius := 1200
npcWatchAutoSync := false
npcWatchIgnoredKeys := Map()
treeRefreshRequested := true
readAndShowRunning := false
showTreePane := true
treeTabKeys := ["Overview", "Buffs", "Entities", "UI", "gameState"]
activeTreeTabKey := "Overview"
flaskConfigPath := A_MyDocuments "\My Games\Path of Exile 2\poe2_production_Config.ini"
flaskKeyBySlot := Map(1, "1", 2, "2", 3, "3", 4, "4", 5, "5")

; Radar Entity-Filter
radarShowEnemyNormal := true
radarShowEnemyRare   := true
radarShowEnemyBoss   := true
radarShowMinions := true
radarShowNpcs    := true
radarShowChests  := true

flaskKeyLoadStatus := "default"
errorLogPath := A_ScriptDir "\InGameStateMonitor.error.log"
errorLogMaxBytes := 1024 * 512
overlayGui := Gui("+AlwaysOnTop +Resize", "PoE2 Memory Monitor")
overlayGui.SetFont("s10", "Bahnschrift")
lifeLabel := overlayGui.AddText("x10 y12", "Life %")
lifeThresholdEdit := overlayGui.AddEdit("x58 y9 w52 Number", lifeThresholdPercent)
manaLabel := overlayGui.AddText("x125 y12", "Mana %")
manaThresholdEdit := overlayGui.AddEdit("x178 y9 w52 Number", manaThresholdPercent)
applyThresholdBtn := overlayGui.AddButton("x246 y8 w70 h24", "Apply")
thresholdStatusText := overlayGui.AddText("x330 y12 w650", "")
applyThresholdBtn.OnEvent("Click", OnApplyThresholdClick)
btnDebug := overlayGui.AddButton("x10 y38 w92 h24", "Debug")
btnPause := overlayGui.AddButton("x108 y38 w92 h24", "Updates")
btnAutoFlask := overlayGui.AddButton("x206 y38 w92 h24", "AutoFlask")
btnAutoFlaskPerf := overlayGui.AddButton("x304 y38 w92 h24", "AF Perf")
btnPinSelected := overlayGui.AddButton("x402 y38 w92 h24", "PinSel")
btnWatchNearbyNpc := overlayGui.AddButton("x500 y38 w92 h24", "WatchNPC")
btnTreeToggle := overlayGui.AddButton("x598 y38 w92 h24", "Tree ON")
btnTreeRefresh := overlayGui.AddButton("x696 y38 w92 h24", "Tree Snap")
btnClearPinned := overlayGui.AddButton("x794 y38 w92 h24", "ClearPins")
btnStartGame := overlayGui.AddButton("x892 y38 w92 h24", "Start PoE2")

btnDebug.OnEvent("Click", OnDebugButtonClick)
btnPause.OnEvent("Click", OnPauseButtonClick)
btnAutoFlask.OnEvent("Click", OnAutoFlaskButtonClick)
btnAutoFlaskPerf.OnEvent("Click", OnAutoFlaskPerfButtonClick)
btnPinSelected.OnEvent("Click", OnPinSelectedButtonClick)
btnWatchNearbyNpc.OnEvent("Click", OnWatchNearbyNpcButtonClick)
btnTreeToggle.OnEvent("Click", OnTreeToggleButtonClick)
btnTreeRefresh.OnEvent("Click", OnTreeSnapButtonClick)
btnClearPinned.OnEvent("Click", OnClearPinsButtonClick)

autoFlaskStatusText := overlayGui.AddText("x10 y66 w980", "AutoFlask: idle")
hotkeyLegendText := overlayGui.AddText("x10 y86 w980", "")

radarFilterLabel    := overlayGui.AddText("x10 y110", "Radar:")
chkRadarEnemyNormal := overlayGui.AddCheckbox("x55  y108 Checked", "Normal")
chkRadarEnemyRare   := overlayGui.AddCheckbox("x135 y108 Checked", "Rare")
chkRadarEnemyBoss   := overlayGui.AddCheckbox("x200 y108 Checked", "Boss")
chkRadarMinions     := overlayGui.AddCheckbox("x265 y108 Checked", "Minions")
chkRadarNpcs        := overlayGui.AddCheckbox("x345 y108 Checked", "NPCs")
chkRadarChests      := overlayGui.AddCheckbox("x405 y108 Checked", "Chests")
chkRadarEnemyNormal.OnEvent("Click", OnRadarFilterChanged)
chkRadarEnemyRare.OnEvent("Click",   OnRadarFilterChanged)
chkRadarEnemyBoss.OnEvent("Click",   OnRadarFilterChanged)
chkRadarMinions.OnEvent("Click",     OnRadarFilterChanged)
chkRadarNpcs.OnEvent("Click",        OnRadarFilterChanged)
chkRadarChests.OnEvent("Click",      OnRadarFilterChanged)
btnDumpEntities := overlayGui.AddButton("x480 y105 w110 h20", "Dump Entities")
btnDumpEntities.OnEvent("Click", OnDumpEntitiesClicked)

treeTabs := overlayGui.AddTab3("x10 y132 w980 h668", treeTabKeys)
treeControlsByTab := Map()
treeNodePathsByTab := Map()

tabTreeX := 20
tabTreeY := 198
tabTreeW := 960
tabTreeH := 634
loop treeTabKeys.Length
{
    idx := A_Index
    key := treeTabKeys[idx]
    treeTabs.UseTab(idx)
    treeCtrl := overlayGui.AddTreeView("x" tabTreeX " y" tabTreeY " w" tabTreeW " h" tabTreeH)
    treeControlsByTab[key] := treeCtrl
    treeNodePathsByTab[key] := Map()
}
treeTabs.UseTab()
treeTabs.Value := 1
valueTree := treeControlsByTab["Overview"]
nodePaths := treeNodePathsByTab["Overview"]
offsetPanelTitle := overlayGui.AddText("x10 y106 w980", "PatternTool Panel - selected offsets (Filter links)")
offsetSearchEdit := overlayGui.AddEdit("x10 y126 w250", "")
btnRemovePinned := overlayGui.AddButton("x270 y126 w100 h24", "RemoveSel")
offsetTable := overlayGui.AddListView("x10 y156 w980 h644 -Multi", ["LastUpdate", "NodeName", "Value", "Delta", "Path", "_State"])
offsetSearchEdit.OnEvent("Change", OnOffsetSearchChanged)
btnRemovePinned.OnEvent("Click", OnRemovePinnedSelectedClick)
offsetTable.OnEvent("ColClick", OnOffsetTableColClick)
OnMessage(0x4E, OnOffsetTableWmNotify)
treeTabs.OnEvent("Change", OnTreeTabChanged)
overlayGui.OnEvent("Size", OnOverlaySize)

; Status bar at bottom
statusBar := overlayGui.AddText("x0 y808 w1020 h22 +0x1000 +Border", "")  ; SS_SUNKEN
overlayGui.Show("x20 y20 w1020 h852")
ApplyOverlayLayout(1020, 852)
overlayGui.OnEvent("Close", (*) => ExitApp())

LoadFlaskHotkeysFromConfig(flaskConfigPath)

; Check for PoE2 patch updates (async-like: runs PowerShell hidden, max ~5s)
CheckPoePatchVersion()
UpdateStatusBar()

if !reader.Connect()
{
    valueTree.Delete()
    valueTree.Add("Konnte PathOfExileSteam.exe oder GameStates-Adresse nicht auflösen.")
    valueTree.Add("Starte das Skript als Admin, falls nötig.")
    return
}

InitializeErrorLog()
SetTimer(TryAutoFlaskFast, 150)
SetTimer(UpdateRadarFast, 100)
SetTimer(ReadAndShow, 2000)
ReadAndShow()
return

; Updates the status bar text with the current PoE2 patch version and last-update timestamp.
UpdateStatusBar()
{
    global statusBar, g_radarReadMs, g_radarRenderMs, g_profReadLastMs, g_profReadAvgMs, g_profTreeLastMs, g_profTotalLastMs, reader
    patch := GetLastKnownPoeVersion()
    now   := FormatTime(A_Now, "HH:mm:ss")

    ; Radar sub-timings from PoE2MemoryReader.RadarTimings
    radarDetail := ""
    try
    {
        rt := reader.RadarTimings
        if IsObject(rt)
            radarDetail := "  radar-detail: state=" rt["state"] " player=" rt["player"] " ui=" rt["ui"] " awake=" rt["awake"] " sleep=" rt["sleep"] " filter=" rt["filter"]
    }

    text  := "PoE2 v" (patch != "" ? patch : "unknown") "   |   Last update: " now
           . "   |   Profiling(ms): read=" g_profReadLastMs "(avg=" g_profReadAvgMs ")"
           . "  tree=" g_profTreeLastMs "  total=" g_profTotalLastMs
           . "  radar=r" g_radarReadMs "+d" g_radarRenderMs
           . radarDetail
    statusBar.Text := text
}

; Creates or appends a session-start header to the error log file on script launch.
InitializeErrorLog()
{
    global errorLogPath
    try
    {
        header := "`n===== Start " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " | PID=" DllCall("GetCurrentProcessId", "UInt") " =====`n"
        FileAppend(header, errorLogPath, "UTF-8")
    }
    catch
    {
    }
}

; Appends a timestamped error entry to the log file; rotates the log to a .1 backup if it exceeds 512 KB.
; Params: context - label identifying the call site; err - optional AHK Error object with message/stack
LogError(context, err := "")
{
    global errorLogPath, errorLogMaxBytes
    static _logging := false

    if _logging
        return
    _logging := true
    try
    {
        try
        {
            if FileExist(errorLogPath)
            {
                size := FileGetSize(errorLogPath)
                if (size >= errorLogMaxBytes)
                {
                    backupPath := errorLogPath ".1"
                    try FileDelete(backupPath)
                    FileMove(errorLogPath, backupPath, true)
                }
            }
        }
        catch
        {
        }

        msg := ""
        try msg := err.Message
        what := ""
        try what := err.What
        line := ""
        try line := err.Line
        extra := ""
        try extra := err.Extra
        stack := ""
        try stack := err.Stack

        text := "[" FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "] " context
        if (msg != "")
            text .= " | msg=" msg
        if (what != "")
            text .= " | what=" what
        if (line != "")
            text .= " | line=" line
        if (extra != "")
            text .= " | extra=" extra
        if (stack != "")
            text .= "`n" stack
        text .= "`n"

        FileAppend(text, errorLogPath, "UTF-8")
    }
    catch
    {
    }
    finally
        _logging := false
}

; GUI Size event handler; calls ApplyOverlayLayout to reposition controls when the window is resized.
OnOverlaySize(guiObj, minMax, width, height)
{
    if (minMax = -1)
        return
    ApplyOverlayLayout(width, height)
}

; Repositions and resizes all GUI controls to fit the given window dimensions.
; Delegates font size adjustments to ApplyResponsiveTypography and updates the status bar.
ApplyOverlayLayout(width, height)
{
    global lifeLabel, lifeThresholdEdit, manaLabel, manaThresholdEdit, applyThresholdBtn
    global thresholdStatusText, autoFlaskStatusText, hotkeyLegendText, treeTabs, treeControlsByTab, offsetPanelTitle, offsetSearchEdit, btnRemovePinned, offsetTable
    global btnDebug, btnPause, btnAutoFlask, btnAutoFlaskPerf, btnPinSelected, btnWatchNearbyNpc, btnTreeToggle, btnTreeRefresh, btnClearPinned, showTreePane
    global statusBar
    global radarFilterLabel, chkRadarEnemyNormal, chkRadarEnemyRare, chkRadarEnemyBoss, chkRadarMinions, chkRadarNpcs, chkRadarChests

    ApplyResponsiveTypography(height)

    statusBarH := 22
    statusBar.Move(0, height - statusBarH, width, statusBarH)
    UpdateStatusBar()

    ; Reserve bottom for status bar
    height -= statusBarH

    compact := (height < 700)
    margin := 10
    gap := compact ? 6 : 8
    rowH := compact ? 22 : 24

    yTop := 8
    yActions := yTop + rowH + (compact ? 4 : 6)
    yStatus := yActions + rowH + (compact ? 4 : 6)
    yLegend := yStatus + (compact ? 18 : 20)
    yRadarFilter := yLegend + (compact ? 18 : 22)
    yTree := yRadarFilter + (compact ? 22 : 26)

    lifeLabel.Move(margin, yTop + 4)
    lifeThresholdEdit.Move(margin + 48, yTop, 52, rowH)

    manaLabel.Move(margin + 115, yTop + 4)
    manaThresholdEdit.Move(margin + 168, yTop, 52, rowH)

    applyX := margin + 236
    applyThresholdBtn.Move(applyX, yTop, 70, rowH)

    statusX := applyX + 70 + gap
    statusW := width - margin - statusX
    if (statusW < 100)
        statusW := 100
    thresholdStatusText.Move(statusX, yTop + 4, statusW, compact ? 18 : 20)

    btnGap := compact ? 5 : 6
    buttonCount := 10
    availableButtonW := width - (margin * 2) - (btnGap * (buttonCount - 1))
    btnW := Floor(availableButtonW / buttonCount)
    if (btnW > (compact ? 86 : 92))
        btnW := compact ? 86 : 92
    if (btnW < 66)
        btnW := 66

    btnX := margin
    btnDebug.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnPause.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnAutoFlask.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnAutoFlaskPerf.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnPinSelected.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnWatchNearbyNpc.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnTreeToggle.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnTreeRefresh.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnStartGame.Move(btnX, yActions, btnW, rowH), btnX += btnW + btnGap
    btnClearPinned.Move(btnX, yActions, btnW, rowH)

    autoFlaskStatusText.Move(margin, yStatus, width - (margin * 2), compact ? 18 : 20)
    hotkeyLegendText.Move(margin, yLegend, width - (margin * 2), compact ? 18 : 20)

    chkW := compact ? 54 : 60
    radarFilterLabel.Move(margin, yRadarFilter + (compact ? 3 : 4))
    chkRadarEnemyNormal.Move(margin + 48,               yRadarFilter, chkW, compact ? 18 : 22)
    chkRadarEnemyRare.Move(  margin + 48 + chkW + 2,    yRadarFilter, chkW, compact ? 18 : 22)
    chkRadarEnemyBoss.Move(  margin + 48 + chkW*2 + 4,  yRadarFilter, chkW, compact ? 18 : 22)
    chkRadarMinions.Move(    margin + 48 + chkW*3 + 10,  yRadarFilter, chkW, compact ? 18 : 22)
    chkRadarNpcs.Move(       margin + 48 + chkW*4 + 12,  yRadarFilter, chkW, compact ? 18 : 22)
    chkRadarChests.Move(     margin + 48 + chkW*5 + 14,  yRadarFilter, chkW, compact ? 18 : 22)
    btnDumpEntities.Move(    margin + 48 + chkW*6 + 20,  yRadarFilter, 110, compact ? 18 : 22)

    treeH := height - yTree - margin
    if (treeH < 120)
        treeH := 120

    if showTreePane
    {
        panelW := Round((width - (margin * 3)) * 0.38)
        if (panelW < 320)
            panelW := 320

        treeW := width - (margin * 3) - panelW
        if (treeW < 320)
        {
            treeW := 320
            panelW := width - (margin * 3) - treeW
            if (panelW < 240)
                panelW := 240
        }

        treeX := margin
        panelX := treeX + treeW + margin
        treeTabs.Move(treeX, yTree, treeW, treeH)

        innerX := treeX + 8
        innerY := yTree + 30
        innerW := Max(120, treeW - 16)
        innerH := Max(80, treeH - 38)
        for _, treeCtrl in treeControlsByTab
            treeCtrl.Move(innerX, innerY, innerW, innerH)
    }
    else
    {
        treeW := 0
        panelW := width - (margin * 2)
        if (panelW < 320)
            panelW := 320
        panelX := margin
        treeTabs.Move(-2000, -2000, 0, 0)
        for _, treeCtrl in treeControlsByTab
            treeCtrl.Move(-2000, -2000, 0, 0)
    }

    panelTitleH := compact ? 18 : 20
    searchY := yTree + panelTitleH + 2
    searchH := rowH
    panelInnerW := panelW
    removeBtnW := compact ? 92 : 100
    searchW := panelInnerW - removeBtnW - gap
    if (searchW < 120)
        searchW := 120

    offsetPanelTitle.Move(panelX, yTree, panelInnerW, panelTitleH)
    offsetSearchEdit.Move(panelX, searchY, searchW, searchH)
    btnRemovePinned.Move(panelX + searchW + gap, searchY, removeBtnW, searchH)

    tableY := searchY + searchH + 4
    tableH := height - tableY - margin
    if (tableH < 120)
        tableH := 120
    offsetTable.Move(panelX, tableY, panelInnerW, tableH)
}

; Switches all GUI controls between compact (s9) and normal (s10) font sizes based on window height.
; No-ops when the size mode has not changed since the last call.
ApplyResponsiveTypography(height)
{
    global overlayGui, lifeLabel, lifeThresholdEdit, manaLabel, manaThresholdEdit, applyThresholdBtn
    global thresholdStatusText, autoFlaskStatusText, hotkeyLegendText, treeTabs, treeControlsByTab, offsetPanelTitle, offsetSearchEdit, btnRemovePinned, offsetTable
    global btnDebug, btnPause, btnAutoFlask, btnAutoFlaskPerf, btnPinSelected, btnWatchNearbyNpc, btnTreeToggle, btnTreeRefresh, btnClearPinned
    global radarFilterLabel, chkRadarEnemyNormal, chkRadarEnemyRare, chkRadarEnemyBoss, chkRadarMinions, chkRadarNpcs, chkRadarChests

    static lastMode := ""
    mode := (height < 700) ? "compact" : "normal"
    if (mode = lastMode)
        return

    if (mode = "compact")
    {
        overlayGui.SetFont("s9", "Bahnschrift")
        lifeLabel.SetFont("s9", "Bahnschrift")
        lifeThresholdEdit.SetFont("s9", "Bahnschrift")
        manaLabel.SetFont("s9", "Bahnschrift")
        manaThresholdEdit.SetFont("s9", "Bahnschrift")
        applyThresholdBtn.SetFont("s9", "Bahnschrift")
        btnDebug.SetFont("s9", "Bahnschrift")
        btnPause.SetFont("s9", "Bahnschrift")
        btnAutoFlask.SetFont("s9", "Bahnschrift")
        btnAutoFlaskPerf.SetFont("s9", "Bahnschrift")
        btnPinSelected.SetFont("s9", "Bahnschrift")
        btnWatchNearbyNpc.SetFont("s9", "Bahnschrift")
        btnTreeToggle.SetFont("s9", "Bahnschrift")
        btnTreeRefresh.SetFont("s9", "Bahnschrift")
        btnStartGame.SetFont("s9", "Bahnschrift")
        btnClearPinned.SetFont("s9", "Bahnschrift")
        thresholdStatusText.SetFont("s9", "Bahnschrift")
        autoFlaskStatusText.SetFont("s9", "Bahnschrift")
        hotkeyLegendText.SetFont("s9", "Bahnschrift")
        radarFilterLabel.SetFont("s9", "Bahnschrift")
        chkRadarEnemyNormal.SetFont("s9", "Bahnschrift")
        chkRadarEnemyRare.SetFont("s9", "Bahnschrift")
        chkRadarEnemyBoss.SetFont("s9", "Bahnschrift")
        chkRadarMinions.SetFont("s9", "Bahnschrift")
        chkRadarNpcs.SetFont("s9", "Bahnschrift")
        chkRadarChests.SetFont("s9", "Bahnschrift")
        btnDumpEntities.SetFont("s9", "Bahnschrift")
        treeTabs.SetFont("s9", "Bahnschrift")
        for _, treeCtrl in treeControlsByTab
            treeCtrl.SetFont("s9", "Bahnschrift")
        offsetPanelTitle.SetFont("s9", "Bahnschrift")
        offsetSearchEdit.SetFont("s9", "Bahnschrift")
        btnRemovePinned.SetFont("s9", "Bahnschrift")
        offsetTable.SetFont("s9", "Bahnschrift")
    }
    else
    {
        overlayGui.SetFont("s10", "Bahnschrift")
        lifeLabel.SetFont("s10", "Bahnschrift")
        lifeThresholdEdit.SetFont("s10", "Bahnschrift")
        manaLabel.SetFont("s10", "Bahnschrift")
        manaThresholdEdit.SetFont("s10", "Bahnschrift")
        applyThresholdBtn.SetFont("s10", "Bahnschrift")
        btnDebug.SetFont("s10", "Bahnschrift")
        btnPause.SetFont("s10", "Bahnschrift")
        btnAutoFlask.SetFont("s10", "Bahnschrift")
        btnAutoFlaskPerf.SetFont("s10", "Bahnschrift")
        btnPinSelected.SetFont("s10", "Bahnschrift")
        btnWatchNearbyNpc.SetFont("s10", "Bahnschrift")
        btnTreeToggle.SetFont("s10", "Bahnschrift")
        btnTreeRefresh.SetFont("s10", "Bahnschrift")
        btnStartGame.SetFont("s10", "Bahnschrift")
        btnClearPinned.SetFont("s10", "Bahnschrift")
        thresholdStatusText.SetFont("s10", "Bahnschrift")
        autoFlaskStatusText.SetFont("s10", "Bahnschrift")
        hotkeyLegendText.SetFont("s10", "Bahnschrift")
        radarFilterLabel.SetFont("s10", "Bahnschrift")
        chkRadarEnemyNormal.SetFont("s10", "Bahnschrift")
        chkRadarEnemyRare.SetFont("s10", "Bahnschrift")
        chkRadarEnemyBoss.SetFont("s10", "Bahnschrift")
        chkRadarMinions.SetFont("s10", "Bahnschrift")
        chkRadarNpcs.SetFont("s10", "Bahnschrift")
        chkRadarChests.SetFont("s10", "Bahnschrift")
        btnDumpEntities.SetFont("s10", "Bahnschrift")
        treeTabs.SetFont("s10", "Bahnschrift")
        for _, treeCtrl in treeControlsByTab
            treeCtrl.SetFont("s10", "Bahnschrift")
        offsetPanelTitle.SetFont("s10", "Bahnschrift")
        offsetSearchEdit.SetFont("s10", "Bahnschrift")
        btnRemovePinned.SetFont("s10", "Bahnschrift")
        offsetTable.SetFont("s10", "Bahnschrift")
    }

    lastMode := mode
}

; Main update loop: reads a game snapshot, runs auto-flask logic, renders the radar overlay, and rebuilds the TreeView.
; Uses a reentrancy guard (readAndShowRunning) to prevent overlapping executions from timer calls.
; Params: forceTreeRefresh - when true, rebuilds the tree regardless of treeRefreshRequested
ReadAndShow(forceTreeRefresh := false)
{
    static _readCycles := 0
    static _readTotalMs := 0
    static _readLastMs := 0
    static _treeLastMs := 0
    static _totalLastMs := 0
    global readAndShowRunning
    if readAndShowRunning
        return
    readAndShowRunning := true
    totalStart := A_TickCount
    try
        {
        global reader, valueTree, nodePaths, debugMode, updatesPaused, autoFlaskEnabled, flaskKeyLoadStatus, flaskKeyBySlot, showTreePane
        global lifeThresholdPercent, manaThresholdPercent, autoFlaskLastReason, autoFlaskStatusText, hotkeyLegendText, autoFlaskPerformanceMode, lastSnapshotForUi
        global treeRefreshRequested, g_profReadLastMs, g_profReadAvgMs, g_profTreeLastMs, g_profTotalLastMs

        if (updatesPaused && !forceTreeRefresh)
            return

        SetActiveTreeContextFromTab()

        readStart := A_TickCount
        snapshot := autoFlaskPerformanceMode ? reader.ReadAutoFlaskSnapshot() : reader.ReadSnapshot()
        _readLastMs := A_TickCount - readStart
        _readCycles += 1
        _readTotalMs += _readLastMs
        readAvgMs := (_readCycles > 0) ? Round(_readTotalMs / _readCycles, 1) : 0
        entityModeText := "-"
        try entityModeText := reader.LastEntityReadMode
        entityOffsetText := "-"
        try entityOffsetText := PoE2GameStateReader.Hex(reader.LastEntityReadOffset)
        entityFallbackAgeText := "-"
        try
        {
            lastFbTick := reader.LastEntityFallbackTick
            if (lastFbTick > 0)
                entityFallbackAgeText := Round((A_TickCount - lastFbTick) / 1000.0, 1) "s"
        }

        if !snapshot
        {
            valueTree.Delete()
            nodePaths := Map()
            StoreNodePathMapForActiveTab(nodePaths)
            valueTree.Add("Lesefehler: Snapshot leer")
            return
        }

        TryAutoFlask(snapshot)
        lastSnapshotForUi := snapshot

        try
        {
            UpdateActionButtonLabels()

            if autoFlaskStatusText
            {
                slot1Key := flaskKeyBySlot.Has(1) ? flaskKeyBySlot[1] : "?"
                slot2Key := flaskKeyBySlot.Has(2) ? flaskKeyBySlot[2] : "?"
                perfText := autoFlaskPerformanceMode ? "ON" : "OFF"
                autoFlaskStatusText.Value := "AutoFlask Action: " autoFlaskLastReason " | LifeKey(Slot1): " slot1Key " | ManaKey(Slot2): " slot2Key " | Perf: " perfText
            }

            if hotkeyLegendText
            {
                hotkeyLegendText.Value := BuildHotkeyLegendText()
            }
        }
        catch
        {
        }

        nowTick := A_TickCount
        doTreeRefresh := showTreePane && (treeRefreshRequested || forceTreeRefresh)

        expandedPaths := Map()
        treeFocus := 0
        if doTreeRefresh
        {
            expandedPaths := CaptureExpandedPaths()
            treeFocus := CaptureTreeFocusState()
        }

        snapshotModeText := (snapshot.Has("snapshotMode") && snapshot["snapshotMode"] != "")
            ? snapshot["snapshotMode"]
            : "full"

        if doTreeRefresh
        {
            treeStart := A_TickCount
            valueTree.Opt("-Redraw")
            valueTree.Delete()
            nodePaths := Map()
            StoreNodePathMapForActiveTab(nodePaths)

            RenderActiveTreeTab(snapshot, snapshotModeText, readAvgMs, _readLastMs, _treeLastMs, _totalLastMs, entityModeText, entityOffsetText, entityFallbackAgeText, expandedPaths)
            RestoreTreeFocusState(treeFocus)
            valueTree.Opt("+Redraw")
            _treeLastMs := A_TickCount - treeStart
            treeRefreshRequested := false
        }
        _totalLastMs := A_TickCount - totalStart
        g_profReadLastMs  := _readLastMs
        g_profReadAvgMs   := readAvgMs
        g_profTreeLastMs  := _treeLastMs
        g_profTotalLastMs := _totalLastMs
        UpdateOffsetTable(snapshot)
    }
    catch as ex
    {
        ; Never propagate timer callback errors as modal dialogs.
        LogError("ReadAndShow", ex)
    }
    finally
    {
        readAndShowRunning := false
        UpdateStatusBar()
    }
}

; Marks a tree refresh as requested and triggers an immediate ReadAndShow call if one is not already running.
ForceRefreshActiveTree()
{
    global showTreePane, treeRefreshRequested, readAndShowRunning

    if !showTreePane
        return

    treeRefreshRequested := true

    ; Kein zweiter Renderpfad: verhindert inkonsistente Trees durch Parallel-Refresh.
    if readAndShowRunning
        return

    ReadAndShow(true)
}

; Synchronises the valueTree and nodePaths globals with the currently-selected tab control.
SetActiveTreeContextFromTab()
{
    global treeTabs, treeTabKeys, treeControlsByTab, treeNodePathsByTab, activeTreeTabKey, valueTree, nodePaths

    idx := 1
    try idx := treeTabs.Value
    if (idx < 1 || idx > treeTabKeys.Length)
        idx := 1

    key := treeTabKeys[idx]
    activeTreeTabKey := key
    valueTree := treeControlsByTab[key]
    nodePaths := treeNodePathsByTab.Has(key) ? treeNodePathsByTab[key] : Map()
    treeNodePathsByTab[key] := nodePaths
}

; Persists the given node-path Map into the per-tab store for the currently active tab.
; Params: paths - Map of TreeView item ID → snapshot path string
StoreNodePathMapForActiveTab(paths)
{
    global treeNodePathsByTab, activeTreeTabKey
    treeNodePathsByTab[activeTreeTabKey] := paths
}

; Rebuilds the active TreeView tab with snapshot data, per-read timing, and entity debug info.
; Delegates to tab-specific helpers (AddActiveBuffsNode, AddEntityScannerNode, BuildTreeNode, etc.).
RenderActiveTreeTab(snapshot, snapshotModeText, readAvgMs, readLastMs, treeLastMs, totalLastMs, entityModeText, entityOffsetText, entityFallbackAgeText, expandedPaths)
{
    global valueTree, nodePaths, reader, debugMode, updatesPaused, autoFlaskEnabled, autoFlaskPerformanceMode
    global lifeThresholdPercent, manaThresholdPercent, flaskKeyLoadStatus, autoFlaskLastReason, flaskKeyBySlot, activeTreeTabKey
    global g_radarReadMs, g_radarRenderMs

    title := "Updated: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
       . " | PID: " reader.Mem.Pid
        " | Debug: " (debugMode ? "ON" : "OFF")
        " | Updates: " (updatesPaused ? "PAUSED" : "LIVE")
        " | AutoFlask: " (autoFlaskEnabled ? "ON" : "OFF")
        " | AFPerf: " (autoFlaskPerformanceMode ? "ON" : "OFF")
      . " | Snap: " snapshotModeText
      . " | Profiling(ms): read=" readLastMs "(avg=" readAvgMs ") tree=" treeLastMs " total=" totalLastMs " radar=r" g_radarReadMs "+d" g_radarRenderMs
      . " | EntityMode: " StrUpper(entityModeText)
      . " | EntityOff: " entityOffsetText
      . " | FallbackAgo: " entityFallbackAgeText
      . " | L/M %: " lifeThresholdPercent "/" manaThresholdPercent
      . " | Keys: " flaskKeyLoadStatus
      . " | AF: " autoFlaskLastReason

    header := valueTree.Add(title)
    nodePaths[header] := "snapshot"

    EnsureLegacyGameStateAliases(snapshot)

    switch activeTreeTabKey
    {
        case "Overview":
            inGame := (snapshot && snapshot.Has("inGameState")) ? snapshot["inGameState"] : 0
            areaInst := (inGame && inGame.Has("areaInstance")) ? inGame["areaInstance"] : 0
            playerPosText := BuildPlayerPositionText(areaInst)
            if (playerPosText != "-")
                valueTree.Add("Player Position: " playerPosText, header)

            keyNode := valueTree.Add("Flask Hotkeys (active mapping)", header)
            loop 5
            {
                slot := A_Index
                key := flaskKeyBySlot.Has(slot) ? flaskKeyBySlot[slot] : "?"
                valueTree.Add("Slot " slot " -> " key, keyNode)
            }
            valueTree.Modify(keyNode, "Expand")

        case "Buffs":
            AddActiveBuffsNode(header, snapshot, expandedPaths)

        case "Entities":
            if (snapshotModeText = "autoflask-performance")
            {
                perfNode := valueTree.Add("Performance Mode: Entity Highlights/Scanner deaktiviert", header)
                nodePaths[perfNode] := "snapshot/performanceMode"
            }
            else
            {
                AddDecodedEntityHighlightsNode(header, snapshot, expandedPaths)
                AddEntityScannerNode(header, snapshot, expandedPaths)
            }

        case "UI":
            AddImportantUiElementsNode(header, snapshot, expandedPaths)

        case "gameState":
            counters := Map("nodes", 0)
            BuildTreeNode(header, "snapshot", snapshot, 0, counters, expandedPaths, "snapshot")
    }

    valueTree.Modify(header, "Expand")
}

; Injects compatibility keys (vitalStruct, playerStruct) into the snapshot Map for older TreeView code.
; Params: snapshot - the current game state Map; modified in place if aliases are missing
EnsureLegacyGameStateAliases(snapshot)
{
    if !(snapshot && Type(snapshot) = "Map" && snapshot.Has("inGameState"))
        return

    inGameState := snapshot["inGameState"]
    if !(inGameState && Type(inGameState) = "Map" && inGameState.Has("areaInstance"))
        return

    areaInstance := inGameState["areaInstance"]
    if !(areaInstance && Type(areaInstance) = "Map")
        return

    playerVitals := areaInstance.Has("playerVitals") ? areaInstance["playerVitals"] : 0

    if (playerVitals && !areaInstance.Has("vitalStruct"))
        areaInstance["vitalStruct"] := playerVitals

    if !areaInstance.Has("playerStruct")
    {
        playerStruct := Map(
            "localPlayerPtr", areaInstance.Has("localPlayerPtr") ? areaInstance["localPlayerPtr"] : 0,
            "localPlayerRawPtr", areaInstance.Has("localPlayerRawPtr") ? areaInstance["localPlayerRawPtr"] : 0
        )

        if playerVitals
        {
            playerStruct["vitalStruct"] := playerVitals
            playerStruct["playerVitals"] := playerVitals
        }

        areaInstance["playerStruct"] := playerStruct
    }
}

; Tab Change event handler; switches the active tree context and requests a full tree refresh.
OnTreeTabChanged(*)
{
    global treeRefreshRequested

    SetActiveTreeContextFromTab()
    treeRefreshRequested := true
    ReadAndShow()
}

#Include TreeViewWatchlistPanel.ahk


#Include AutoFlask.ahk
#Include UIHelpers.ahk

; F3: one-shot debug dump — TreeView content, game window screenshot, radar entity TSV.
F3::OnF3DebugDump()
