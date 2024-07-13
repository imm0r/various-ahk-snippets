condition_AllwaysOnTop := 0

createGui() {
	Gui, Cmd:New, +Caption +LastFound -OwnDialogs -ToolWindow +Border +AlwaysOnTop +LabelCmd +HwndCmdHwnd +E0x02120000
	Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Button, g_GetBasics x5 y5 h25, get basics
	Gui, Cmd:Add, Button, g_GetLDPlayerID x+3 h25, get ID
	Gui, Cmd:Add, Button, g_GetDevice x+3 h25, get device
	Gui, Cmd:Add, Button, g_ConnectDevice x+3 h25, connect device
	Gui, Cmd:Add, Button, g_GetL2RInfo x+3 h25, get L2R info
	Gui, Cmd:Add, Button, g_RunL2R x+3 h25, run L2R
	;Gui, Cmd:Add, Button, g_RunCMDTest x+3 h25, runCMD Test

    loop, % oStrDDL.MaxIndex()
    {
        If (A_index < oStrDDL.MaxIndex())
            strDDL_coordinates .= oStrDDL[A_Index] . "|"
        else
            strDDL_coordinates .= oStrDDL[A_Index]
    }

    Gui, Cmd:Add, Pic, x825 y5 w425 h-1 hwndhpControl +0xE

    Gui, Cmd:Add, Button, g_AutoSkip vLbl_AutoQuest x5 y35 h25, auto Skip
    Gui, Cmd:Add, DropDownList, g_ApplyDLLChoice vDLLInputChoice x+94 w133, %strDDL_coordinates%
	Gui, Cmd:Add, Button, g_ApplyDLLSelection vDDL_CoordsCurrActive x+4 w141 h25, % "Click on a selection!"

	Gui, Cmd:Add, Button, g_guiToggleOnTop x450 y5 w95 h25, onTop
    Gui, Cmd:Add, Button, g_LiveAppBroadcasting vLbl_LiveAppBroadcasting x450 y35 h50 w95, Live App Broadcasting

	Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x7 y65 w438 h55, debug stuff

	    Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x20 y90, cursor position - X:
	    Gui, Cmd:Add, Text, +HwndCursorPosHwnd vCursorPosX border Center readonly x+4 y90 w40 h20
	    Gui, Cmd:Add, Text, x+4 y90, Y:
	    Gui, Cmd:Add, Text, +HwndCursorPosHwnd vCursorPosY border Center readonly x+4 y90 w40 h20
	    Gui, Cmd:Add, Text, x+40 y90, pixel color:
	    Gui, Cmd:Add, Text, +HwndCursorPosHwnd vCursorColor border Center x+7 y90 w70 h20
	    Gui, Cmd:Font, s20
	    Gui, Cmd:Add, Text, vColoredDot x+4 y82, % chr(0x25C9)

	; Gui, Cmd:Add, Text, x9 y77, enter your own ADB commands here:
	; Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	; Gui, Cmd:Add, Edit, hWndhEdit vCmdInput +HwndCmdInputHwnd -border x7 y+2 w438
	; Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	; Gui, Cmd:Add, Button, gExecCmd x+5 y97 w95 h29, execute

	Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Text, vLbl_ADBReturn x10 y+20, ADB returned the following results:
	Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Edit, vCmdOutput +HwndCmdOutputHwnd +border readonly x7 y+2 w535 h115
	GuiControl, Focus, Lbl_ADBReturn
    Gui, Cmd:Show, w551, LDP+ADB
;@ahk-neko-ignore-fn 1 line; at 14.11.2022, 12:20:45 ; var is assigned but never used.
    guiID := WinExist("A")
}

_ApplyDLLChoice() {
    Gui, Cmd:Submit, NoHide
    __coords := StrSplit(oDDL_Container[DLLInputChoice],"|")
	GuiControl, , DDL_CoordsCurrActive, % "tap on " RegExReplace(DLLInputChoice, "btn_", "")
	GuiControl, Focus, Lbl_ADBReturn
}

_GetBasics() {
	GuiControl, , CmdOutput
    gOutput := "Gathered Information for LDPlayer:`n`r`n`r`n`r"
        . "Windows Title`t: "   oLDP_Basics.title    "`n`r`n`r"
        . "Client Path`t: "     oLDP_Basics.cli      "`n`r`n`r"
        . "Version`t`t: "       oLDP_Basics.ver      "`n`r`n`r"
        . "Windows Handle`t: "  oLDP_Basics.hwnd     "`n`r`n`r"
        . "Process ID`t: "      oLDP_Basics.Pid      "`n`r`n`r"
        . "Console Path`t: "    oLDP_Basics.console  "`n`r`n`r"
        . "ADB Path`t`t: "      oLDP_Basics.adb
	AppendText(CmdOutputHwnd,gOutput)
	GuiControl, Focus, Lbl_ADBReturn
}

_GetLDPlayerID() {
	GuiControl, , CmdOutput
    oLDPi := adb_GetInstanceDetails(0)
    gOutput := "Gathered Information for instance #0:`n`r`n`r`n`r"
        . "Instance ID`t: "         oLDPi.id        "`n`r`n`r"
        . "Windows Title`t: "       oLDPi.winTitle  "`n`r`n`r"
        . "topHwnd`t`t: "           oLDPi.topHwnd   "`n`r`n`r"
        . "bindHwnd`t: "            oLDPi.bindHwnd  "`n`r`n`r"
        . "isRunning`t: "           oLDPi.isRunning "`n`r`n`r"
        . "mainPid`t`t: "           oLDPi.mainPid   "`n`r`n`r"
        . "vboxPid`t`t: "           oLDPi.vboxPid   "`n`r`n`r"
        . "resolution height`t: "   oLDPi.rHeight   "`n`r`n`r"
        . "resolution width`t: "    oLDPi.rWidth    "`n`r`n`r"
        . "DPI`t`t: "               oLDPi.rDPI
	AppendText(CmdOutputHwnd,gOutput)
	GuiControl, Focus, Lbl_ADBReturn
}

_GetDevice() {
	GuiControl, , CmdOutput
	AppendText(CmdOutputHwnd, adb_GetDevice( ))
	GuiControl, Focus, Lbl_ADBReturn
}

_ConnectDevice() {
	GuiControl, , CmdOutput
    If (adb_isConnectedToDevice(adb_GetDevice( )))
        gOutput := "Connection successfull!"
	AppendText(CmdOutputHwnd, gOutput)
	GuiControl, Focus, Lbl_ADBReturn
}

_GetL2RInfo() {
	GuiControl, , CmdOutput
    packageName := adb_isInstalled("netmarble")
    if (packageName != "") {
        APKPath := adb_getAPKPathFromPackage(packageName)
        gOutput := "Lineage 2 Revolution is already installed!`n`r`n`r`n`rPackageName: "packageName "`n`r`n`rAPK Path: " APKPath
    }   
	AppendText(CmdOutputHwnd, shellStr gOutput)
	GuiControl, Focus, Lbl_ADBReturn
}

_RunL2R() {
	GuiControl, , CmdOutput
    ;tTmp := adb_screenshot()
    if (pName := adb_isInstalled("netmarble"))
    {
        if (!PIDfromP := adb_getPIDfromPackage( pName ))
            gOutput := adb_runApp(pName, startupActivity)
        else
            gOutput := "L2R is already running!`n`r`n`r`n`rProcess`t: " pName "`n`r`n`rPID`t: " PIDfromP
    }
    
    AppendText(CmdOutputHwnd, gOutput)
	GuiControl, Focus, Lbl_ADBReturn
}

_ApplyDLLSelection() {
    Gui, Cmd:Submit, NoHide
	GuiControl, , CmdOutput
    FormatTime, strT, T12, Time

    __coords := StrSplit(oDDL_Container[DLLInputChoice],"|")
    _rADB := adb_input("tap", __coords[1], __coords[2])
    return_ADB := _rADB != 1 ? "input failed! (" _rADB ")" : "Success!"

    gOutput := "[" strT "]`tclicking on`t: " RegExReplace(DLLInputChoice, "btn_", "") "`n`r`n`r`tADB input returns`t: " return_ADB "`n`r`n"
    AppendText(CmdOutputHwnd, gOutput)

	GuiControl, Focus, Lbl_ADBReturn
}

_AutoSkip() {
    Gui, Cmd:Submit, NoHide
	GuiControl, , CmdOutput

    FormatTime, strT, T12, Time
	If( enabled_AutoSkip := !enabled_AutoSkip ) {
		SetTimer, t_AutoQuest, 750
        AppendText(CmdOutputHwnd, "[" strT "] Auto questing enabled!`n`r`n`r")
        Gui, Cmd:Show, w551 h125, auto questing is active
	} else {
		SetTimer, t_AutoQuest, off
        AppendText(CmdOutputHwnd, "[" strT "] Auto questing disabled!`n`r`n`r")
        Gui, Cmd:Show, w551 h273, LDP+ADB
    }

	GuiControl, Focus, Lbl_ADBReturn
}

_LiveAppBroadcasting() {
    Gui, Cmd:Submit, NoHide
	GuiControl, , CmdOutput
    FormatTime, strT, T12, Time
	If( enabled_LiveAppBroadc := !enabled_LiveAppBroadc ) {
        AppendText(CmdOutputHwnd, "[" strT "] Live Broadcasting activated!`n`r`n`r")
        GuiControl, , Lbl_LiveAppBroadcasting, LAB enabled
        Gui, Cmd:Show, w1850, LDP+ADB
		SetTimer, t_LiveAppBroadcasting, 2000
	} else {
        AppendText(CmdOutputHwnd, "[" strT "] Live Broadcasting de-activated!`n`r`n`r`n`r")
        GuiControl, , Lbl_LiveAppBroadcasting, LAB disabled
	    Gui, Cmd:Show, w815, LDP+ADB
		SetTimer, t_LiveAppBroadcasting, off
    }
	GuiControl, Focus, Lbl_ADBReturn
}

_guiToggleOnTop() {
	WinSet, AlwaysOnTop, % con_OnTop := !con_OnTop, % "ahk_id " guiID
	GuiControl, Focus, Lbl_ADBReturn
    ;currGuiHeight := con_OnTop != 1 ? "410" : "130"
    ;Gui, Cmd:Show, w551 h%currGuiHeight%, LDP+ADB
}

Gdip_ResizeBitmap(pBitmap, PercentOrWH, Dispose=1)
{
    Gdip_GetImageDimensions(pBitmap, origW, origH)
    if PercentOrWH contains w,h
    {
        RegExMatch(PercentOrWH, "i)w(\d*)", w), RegExMatch(PercentOrWH, "i)h(\d*)", h)
        NewWidth := w1, NewHeight := h1
        NewWidth := (NewWidth = "") ? origW/(origH/NewHeight) : NewWidth
        NewHeight := (NewHeight = "") ? origH/(origW/NewWidth) : NewHeight
    }
    else
        NewWidth := origW*PercentOrWH/100, NewHeight := origH*PercentOrWH/100
    pBitmap2 := Gdip_CreateBitmap(NewWidth, NewHeight)
    G2 := Gdip_GraphicsFromImage(pBitmap2), Gdip_SetSmoothingMode(G2, 4), Gdip_SetInterpolationMode(G2, 7)
    Gdip_DrawImage(G2, pBitmap, 0, 0, NewWidth, NewHeight)
    Gdip_DeleteGraphics(G2)
    if Dispose
        Gdip_DisposeImage(pBitmap)
    return pBitmap2
}

_RunCMDTest() {
    Gui, Cmd:Submit, NoHide
	GuiControl, , CmdOutput
    Process, Exist, adb.exe
    if !ErrorLevel
        RunWait,  %comSpec% /c adb devices
    devices := RunCMD("adb devices")
    AppendText(CmdOutputHwnd, "[ devices: ]" devices "`n`r`n`r")
    return devices
}