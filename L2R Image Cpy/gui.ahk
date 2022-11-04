CmdGui() {
	Gui, Cmd:New, +LabelCmd +HwndCmdHwnd +Resize, Console
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
    Gui, Add, DropDownList, gApplyDLLChoice vDLLInputChoice x+15 y7 w110, %strDDL_coordinates%
	Gui, Add, Button, gExample7 x+5 y5, Click on selection!

    Gui, Add, Button, gBtn_AutoQuest vLbl_AutoQuest x+5, AQ AutoSkip

	Gui, Font, s12, Verdana New
	gui, add, Text, x10, enter your own ADB commands here:
	Gui, Font, s11, Verdana New
	Gui, Add, Edit, vCmdInput +HwndCmdInputHwnd x8 y65 w800 r1 border
	Gui, Font, s12, Verdana New
	gui, add, Text, x10, ADB returned the following results:
	Gui, Font, s11, Verdana New
	Gui, Add, Edit, vCmdOutput +HwndCmdOutputHwnd x8 y120 w800 h250 border readonly
	Gui, Show
	
	;GuiControl, Focus, CmdInput
}

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
	GuiControl, , CmdOutput
    packageName := adb_isInstalled("netmarble")
    if (packageName != "") {
        APKPath := adb_getAPKPathFromPackage(packageName)
        gOutput := "Lineage 2 Revolution is already installed!`n`r`n`r`n`rPackageName: "packageName "`n`r`n`rAPK Path: " APKPath
    }   
	AppendText(CmdOutputHwnd, gOutput)
}

Example6() {
	GuiControl, , CmdOutput
    gOutput := adb_runApp(adb_isInstalled("netmarble"), startupActivity)
    AppendText(CmdOutputHwnd, gOutput)
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
		SetTimer, AutoQuest, 2250
	} else {
        GuiControl, , Lbl_AutoQuest, AQ disabled
        AppendText(CmdOutputHwnd, "[" TimeString "] Auto Skip disabled!`n`r`n`r`n`r")
		SetTimer, AutoQuest, off
    }
}