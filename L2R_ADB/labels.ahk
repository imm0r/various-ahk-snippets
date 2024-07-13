F10::reload
Return

F5::
    gOutput := ""
	GuiControl, , CmdOutput
    _cSkip := StrSplit(oDDL_Container["btn_ClaimReward"],"|")

    ControlGetPos, ControlX, ControlY, ControlWidth, ControlHeight, , % "ahk_id " oCtrls[A_Index].hWnd
    tClrSkip := FHex(DwmGetPixel(oCtrls[A_Index].hWnd, _cSkip[1], _cSkip[2]))
    
    cTolerance := ColorRGBCompare(oScanClr.clr_ClaimReward, tClrSkip, 100)
    gOutput := "`n`r`npixel color for ClaimReward position: " tClrSkip "`t(variation: " cTolerance ")"
    AppendText(CmdOutputHwnd, gOutput)
return

ColorRGBCompare(col1, col2, tol) {
	col1 := RGBfromColor(col1)
	col2 := RGBfromColor(col2)
	return (Abs(col1.r - col2.r) <= tol) && (Abs(col1.g - col2.g) <= tol) && (Abs(col1.r - col2.r) <= tol)
}

RGBfromColor(color) {
	return {r: (0xFF0000 & color) >> 16, g: (0xFF00 & color) >> 8, b: 0xFF & color}
}

F6::
AppendText(CmdOutputHwnd, GetTargetMType(""))
    ctrlList := GetCtrlListFromHwnd(oLDP_Basics.hWnd)
    strTitle := "subWin1"
    strClass := "sub"
    cHwnd := WinExist( strClass, strTitle )
    cPos := GetCursorPos()
    clipboard := cHwnd ; cPos.x "|" cPos.y "`n" FHex(DwmGetPixel(oLDP_Basics.hWnd, cPos.x, cPos.y))
return

t_UpdateCursorPos:
    cPos := GetCursorPos()
    cClr := FHex(DwmGetPixel(oLDP_Basics.hWnd, cPos.x, cPos.y))
	GuiControl, Cmd:, CursorPosX, % cPos.x
	GuiControl, Cmd:, CursorPosY, % cPos.y
    GuiControl, Cmd:, CursorColor, % " " cClr

	Gui, Cmd:Font, % "s20 c" SubStr(cClr, 3), % "Bahnschrift SemiCondensed"
    GuiControl, Cmd:Font, ColoredDot
return

t_AutoQuest:
    Gui, Submit, NoHide
    FormatTime, strT, T12, Time
    gOutput := ""

    ; setting up helper-arrays containing the coordinates to look at a specific color.
    _cHClaimR   := StrSplit(oDDL_Container["ClaimRewardHelper"],"|")
    _cHSkip     := StrSplit(oDDL_Container["SkipHelper"],"|")

    ; setting up arrays containing the coordinates to tap at.
    _cClaimR    := StrSplit(oDDL_Container["btn_ClaimReward"],"|")
    _cSkip      := StrSplit(oDDL_Container["btn_Skip"],"|")

    ; checking if the 'Claim Reward' Window is open.
    tClrRW := FHex(DwmGetPixel(oLDP_Basics.hWnd, _cHClaimR[1], _cHClaimR[2]))
    if (tClrRW = oScanClr.clr_ClaimReward)
    {
        gOutput := "`n`r`n[" strT "]`t'Claim Reward' Window found!`n`r`nRunning 'start quest' sequence now!"
        AppendText(CmdOutputHwnd, gOutput)

        Loop, % oAutoQuestSeq.MaxIndex()
        {
            _tTab := ""
            __coords := StrSplit(oDDL_Container[oAutoQuestSeq[A_Index]],"|")
            _rADB := adb_input("tap", __coords[1], __coords[2])
            return_ADB := _rADB != 1 ? "input failed! (" _rADB ")" : "Success!"

            _tTab := (A_Index = 4 || A_Index = 6) ? "`t`t" : "`t"
            gOutput := "`n`r`n`tCurrent step (" A_Index "/" oAutoQuestSeq.MaxIndex() ")`t: " RegExReplace(oAutoQuestSeq[A_Index], "btn_", "") _tTab "returns: " return_ADB
            AppendText(CmdOutputHwnd, gOutput)
            sleep, 950
        }
    }

    ; checking if the 'Skip' button is visible.
    tClrS := FHex(DwmGetPixel(oLDP_Basics.hWnd, _cHSkip[1], _cHSkip[2]))
    if (tClrS = oScanClr.clr_Skip)
    {
        gOutput := "`n`r`n[" strT "]`tskip button detect! Tapping it now! (" _cSkip[1] " / " _cSkip[2] ")"
        AppendText(CmdOutputHwnd, gOutput)
        _rADB := adb_input("tap", _cSkip[1], _cSkip[2])
    }

    ; For debugging
    if(debug = true) {
        If !gOutput {
            gOutput := "`n`r`n[" strT "]`tColor Detection: Claim Reward: " tClrRW " | Skip: " tClrS
            AppendText(CmdOutputHwnd, gOutput)
        }
    }
return

t_LiveAppBroadcasting:
    fPath := adb_screenshot(A_ScriptDir . "\misc\img\SS.png")
    pBitmap := Gdip_CreateBitmapFromFile(fPath)
    pBitmap2 := Gdip_ResizeBitmap(pBitmap, 30, 1)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap2)
    SetImage(hpControl, hBitmap)

    DeleteObject(hBitmap)
    Gdip_DisposeImage(pBitmap2)
return

ExecCmd:
    Gui, Submit, NoHide
    tmpReturnStr := "", ReturnStr := ""

    GuiControlGet, iCommandLine, , CmdInput
    tmpReturnStr := stdCmd( iCommandLine )

    FormatTime, strT, T12, Time
    AppendText(CmdOutputHwnd, "[" strT "] Command to execute: " iCommandLine "`n`r`n`r")

    Loop, parse, % tmpReturnStr, `n, `r
        if !A_Loopfield = ""
            ReturnStr .= A_Loopfield "`n`r`n`r", lb := A_Index

    if inStr(ReturnStr, "`n`r`n`r")
        _LB := 1
    else
        _LB := 0
    lb := _LB != 0 ? "`n`r`n`r" : ""

    AppendText(CmdOutputHwnd, "[" strT "] Returns: " lb . ReturnStr "`n`r`n`r")
    GuiControl, , CmdInput,
    Gui, Submit, NoHide
Return

GuiClose:
    Gui, Destroy
    ExitApp
Return

OnExit:
	DllCall("CloseHandle", "uint", hConsole)
	DllCall("FreeConsole")

	Process Exist, % pid_HiddenConsole
	if (ErrorLevel == pid_HiddenConsole) {
		Process, Priority, % pid_HiddenConsole, Low
		Run *RunAs %A_WinDir%\System32\cmd.exe /c taskkill /f /pid %pid%,, hide
	}
return