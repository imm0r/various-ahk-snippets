CmdGui() {    
	Gui, Cmd:New, +LabelCmd +HwndCmdHwnd, Console
	Gui, Font, s11, Arial New
	Gui, Add, Button, gExample1 x5 y5, get basics
	Gui, Add, Button, gExample2 x+0, get ID
	Gui, Add, Button, gExample3 x+0, get device
	Gui, Add, Button, gExample4 x+0, connect device
	Gui, Add, Button, gExample5 x+0, get L2R info
	Gui, Add, Button, gExample6 x+0, run L2R

    loop, % strDDL_entries.MaxIndex()
    {
        If (A_index < strDDL_entries.MaxIndex())
            strDDL_coordinates .= strDDL_entries[A_Index] . "|"
        else
            strDDL_coordinates .= strDDL_entries[A_Index]
    }
    Gui, Add, DropDownList, gApplyDLLChoice vDLLInputChoice x+73 y7 w110, %strDDL_coordinates%
	Gui, Add, Button, gExample7 x+5 y5, Click on selection!

    Gui, Add, Pic, x825 y5 w425 h-1 hwndhpControl +0xE 
	;Gui, Add, Edit, +HwndCmdOutputHwnd x825 y5 w425 border
    ;Gui, Add, Pic, x825 y5 w425 h-1 +Border vLABPic, % "HBITMAP:*" LoadPicture(A_Scriptdir . "\misc\img\ss.png")

    Gui, Add, Button, gBtn_AutoQuest vLbl_AutoQuest x5 y40, AQ AutoSkip
    Gui, Add, Button, gBtn_LiveAppBroadcasting vLbl_LiveAppBroadcasting x697 y40 R2 w110, Live App Broadcasting

	Gui, Font, s12, Verdana New
	gui, add, Text, x9 y75, enter your own ADB commands here:
	Gui, Font, s11, Verdana New
	Gui, Add, Edit, vCmdInput +HwndCmdInputHwnd x7 y+2 w800 r1 border
	Gui, Font, s12, Verdana New
	gui, add, Text, x10 y+5, ADB returned the following results:
	Gui, Font, s11, Verdana New
	Gui, Add, Edit, vCmdOutput +HwndCmdOutputHwnd x7 y+2 w800 h250 border readonly w800 h250
    Gui, Show, w815, LDP+ADB
	
	GuiControl, Focus, CmdInput
}

GuiClose:
    Gui, Destroy
    ExitApp
Return

ApplyDLLChoice() {
    Gui, Submit, NoHide
    __coords := StrSplit(oDDL_Container[DLLInputChoice],"|")
}

Example1() {
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
}

Example2() {
	GuiControl, , CmdOutput
    oLDPi := adb_GetInstanceDetails(0)
    gOutput := "Gathered Information for instance #0:`n`r`n`r`n`r"
        . "Instance ID`t: "         oLDPi.id        "`n`r`n`r"
        . "Windows Title`t: "       oLDPi.winTitle  "`n`r`n`r"
        . "topHwnd`t`t: "           oLDPi.topHwnd   "`n`r`n`r"
        . "bindHwnd`t`t: "          oLDPi.bindHwnd  "`n`r`n`r"
        . "isRunning`t`t: "         oLDPi.isRunning "`n`r`n`r"
        . "mainPid`t`t: "           oLDPi.mainPid   "`n`r`n`r"
        . "vboxPid`t`t: "           oLDPi.vboxPid   "`n`r`n`r"
        . "resolution height`t: "   oLDPi.rHeight   "`n`r`n`r"
        . "resolution width`t: "    oLDPi.rWidth    "`n`r`n`r"
        . "DPI`t`t: "               oLDPi.rDPI
	AppendText(CmdOutputHwnd,gOutput)
}

Example3() {
	GuiControl, , CmdOutput
	AppendText(CmdOutputHwnd, adb_GetDevice( ))
}

Example4() {
	GuiControl, , CmdOutput
    If (adb_isConnectedToDevice(adb_GetDevice( )))
        gOutput := "Connection successfull!"
	AppendText(CmdOutputHwnd, gOutput)
}

Example5() {
	GuiControl, , Output
    packageName := adb_isInstalled("netmarble")
    if (packageName != "") {
        APKPath := adb_getAPKPathFromPackage(packageName)
        gOutput := "Lineage 2 Revolution is already installed!`n`r`n`r`n`rPackageName: "packageName "`n`r`n`rAPK Path: " APKPath
    }   
	AppendText(CmdOutputHwnd, shellStr "`n`r`n`r" gOutput "`n`r`n`r")
}

Example6() {
	GuiControl, , CmdOutput
    tTmp := adb_screenshot()
    ;pName := adb_isInstalled("netmarble")
    ;PIDfromP := adb_getPIDfromPackage( pName )
    ;gOutput := adb_runApp(adb_isInstalled("netmarble"), startupActivity)
    AppendText(CmdOutputHwnd, tTmp)
}

Example7() {
    Gui, Submit, NoHide
	GuiControl, , CmdOutput
    
    loop, % strDDL_entries.MaxIndex()
        if (DLLInputChoice = strDDL_entries[A_Index])
            currSelection := A_Index
    __coords := StrSplit(oDDL_Container[DLLInputChoice],"|")
    gOutput := "clicked on " DLLInputChoice "!`n`r`n`r`n`rADB input resulted: " adb_input("tap", __coords[1], __coords[2])
    AppendText(CmdOutputHwnd, gOutput)
    GuiControl, Choose, DLLInputChoice, % currSelection + 1
}

Btn_AutoQuest() {
    Gui, Submit, NoHide
	GuiControl, , CmdOutput
    FormatTime, TimeString, T12, Time
    
	If( enabled_AutoSkip := !enabled_AutoSkip ) {
        GuiControl, , Lbl_AutoQuest, AQ enabled
        AppendText(CmdOutputHwnd, "[" TimeString "] Auto Skip enabled!`n`r`n`r`n`r")
		SetTimer, t_AutoQuest, 2250
	} else {
        GuiControl, , Lbl_AutoQuest, AQ disabled
        AppendText(CmdOutputHwnd, "[" TimeString "] Auto Skip disabled!`n`r`n`r`n`r")
		SetTimer, t_AutoQuest, off
    }
}

Btn_LiveAppBroadcasting() {
    Gui, Submit, NoHide
	GuiControl, , CmdOutput
    FormatTime, TimeString, T12, Time
	If( enabled_LiveAppBroadc := !enabled_LiveAppBroadc ) {
        AppendText(CmdOutputHwnd, "[" TimeString "] Live Broadcasting activated!`n`r`n`r")
        GuiControl, , Lbl_LiveAppBroadcasting, LAB enabled
        Gui, Show, w1850, LDP+ADB
		SetTimer, t_LiveAppBroadcasting, 2000
	} else {
        AppendText(CmdOutputHwnd, "[" TimeString "] Live Broadcasting de-activated!`n`r`n`r`n`r")
        GuiControl, , Lbl_LiveAppBroadcasting, LAB disabled
	    Gui, Show, w815, LDP+ADB
		SetTimer, t_LiveAppBroadcasting, off
    }
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