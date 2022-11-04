#noenv
#singleinstance, force
setbatchlines, -1
DetectHiddenWindows, On
SendMode Input
SetWorkingDir %A_ScriptDir%

#INCLUDE %A_ScriptDir%
#INCLUDE <CliSAK>

Global c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput
Global done := "__Batch Complete__"

CmdGui()

CmdGui() {
	Gui, Cmd:New, +LabelCmd +HwndCmdHwnd +Resize, Console
	Gui, Font, s10, Arial New
	Gui, Add, Button, gExample1 x5 y5, get devices
	Gui, Add, Button, gExample2 x+0, Connect to ADB
	Gui, Add, Button, gExample3 x+0, is L2R installed
	Gui, Add, Button, gExample4 x+0, Option4
	Gui, Add, Button, gExample5 x+0, Option5
	Gui, Add, Button, gExample6 x+0, Option6
	Gui, Add, Button, gExample7 x+0, Option7
	Gui, Add, Button, gExample8 x+0, Option8
	
	Gui, Add, Button, gShowWindow x+30, Show Window
	Gui, Add, Button, gHideWindow x+0, Hide Window

	Gui, Font, s12, Verdana New
	gui, add, Text, x10, enter your own ADB commands here:
	Gui, Add, Edit, vCmdInput +HwndCmdInputHwnd x8 y65 w600 r1
	Gui, Add, Edit, vCmdOutput +HwndCmdOutputHwnd x8 y120 w800 h400 ReadOnly
	Gui, Show
	
	GuiControl, Focus, CmdInput
}

ShowWindow() {
    InputBox, pid, bitte pid eingeben
    WinShow, % "ahk_pid " pid
	WinShow, % "ahk_pid " c.pid
}

HideWindow() {
	WinHide, % "ahk_pid " c.pid
}

CmdSize(GuiHwnd, EventInfo, Width, Height) {
	h1 := Height - 10 - 103, w1 := Width - 20
	GuiControl, Move, CmdOutput, h%h1% w%w1%
	y2 := Height - 75, w2 := Width - 20
	GuiControl, Move, CmdPrompt, y%y2% w%w2%
	y3 := Height - 55, w3 := Width - 20
	GuiControl, Move, CmdInput, y%y3% w%w3%
}

CmdClose() {
    c.CtrlBreak()
	c.close()
	ExitApp
}


strClsName := "LDPlayerMainFrame"
Winget, cPid, PID, % "ahk_class " strClsName
WinGetTitle, wTitle, % "ahk_class " strClsName
vPath := GetModuleFileNameEx(cPid)
fTitle := GetFileTitleFromPath(vPath)
SplitPath, vPath, fName, fPath
wHwnd := GetHwnd(wTitle, fName)
FileGetVersion, fVer, % vPath

global strClsName, wTitle, vPath, fPath, cPid, fName, wHwnd

; ============================================================================
; Callback Functions
; ============================================================================
quit_cb(quitStr,ID,cliObj) { ; stream until user-defined QuitString is encountered (optional).
    If (ID = "Mode_M")
        GuiControl, , %CmdOutputHwnd%, Download Complete.
    MsgBox % "QuitString encountered:`r`n`t" quitStr "`r`n`r`nWhatever you choose to do in this callback functions will be done."
}

stdout_cb(data,ID,cliObj) { ; Handle StdOut data as it streams (optional)
    dbg("    data: " data)
    
	If (ID = "Console_Streaming" Or ID = "Console_Simple") 
		AppendText(CmdOutputHwnd,data) ; append data to edit box
	Else If (ID = "mode_M") {
        dbg("mode_M")
        
        lastLine := cliObj.GetLastLine(data) ; capture last line containing progress bar and percent.
        a := StrSplit(lastLine,"["), p1 := a[1], a := StrSplit(p1," "), p2 := a[a.Length()]
        msg := "========================================================`r`n"
             . "This is the captured console grid.`r`n"
             . "========================================================`r`n"
             . data "`r`n`r`n"
             . "========================================================`r`n"
             . "wget.exe example:  (Check Ex #8 comments)`r`n"
             . "========================================================`r`n"
             . "Percent Complete: " p2
        
		GuiControl, , %CmdOutputHwnd%, %msg% ; write / overwrite data to edit box
    }
}

prompt_cb(prompt,ID,cliObj) { ; cliPrompt callback function --- default: cliPromptCallback()
	Gui, Cmd:Default ; need to set GUI as default if NOT using control HWND...
	GuiControl, , CmdPrompt, ========> new prompt =======> %prompt% ; set Text control to custom prompt
    
    If (ID = "error") {
        stdOut := ">>> StdOut:`r`n" RTrim(cliObj.stdout,"`r`n`t") "`r`n`r`n"
        stdErr := ">>> StdErr:`r`n" RTrim(cliObj.stderr,"`r`n`t") "`r`n`r`n"
        GuiControl, , %CmdOutputHwnd%, % stdOut stdErr ; write / overwrite data to edit box
        cliobj.stdOut := "", cliobj.stdErr := ""
    } Else If (ID = "PowerShell") {
        err := cliObj.stderr
        out := cliObj.clean_lines(cliObj.stdout)
        out .= (InStr(prompt,">>")?"`r`n>>":"") ; append >> to output edit when that prompt is used
        AppendText(CmdOutputHwnd, "`r`n" (err?err:"") out)
    }
}
; ============================================================================
; send command to CLI instance when user presses ENTER
; ============================================================================

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN
WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; wParam = keycode in decimal | 13 = Enter | 32 = space
    CtrlHwnd := "0x" Format("{:x}",hwnd) ; control hwnd formatted to match +HwndVarName
    If (CtrlHwnd = CmdInputHwnd And wParam = 13) ; ENTER in App List Filter
		SetTimer, SendCmd, -10 ; this ensures cmd is sent and control is cleared
}

SendCmd() { ; timer label from WM_KEYDOWN
	Gui, Cmd:Default ; give GUI the focus / required by timer(s) unless using hwnd in GuiControlGet / GuiControl commands
	GuiControlGet, CmdInput ; get cmd
	c.write(CmdInput) ; send cmd
	Gui, Cmd:Default
	GuiControl, , CmdInput ; clear control
	GuiControl, Focus, CmdInput ; put focus on control again
}

; ================================================================================
; ================================================================================
; support functions
; ================================================================================
; ================================================================================

AppendText(hEdit, sInput, loc="bottom") {
    ; ================================================================================
    ; AppendText(hEdit, ptrText)
    ; example: AppendText(ctlHwnd, &varText)
    ; Posted by TheGood:
    ; https://autohotkey.com/board/topic/52441-append-text-to-an-edit-control/#entry328342
    ; ================================================================================
    SendMessage, 0x000E, 0, 0,, ahk_id %hEdit%						;WM_GETTEXTLENGTH
	If (loc = "bottom")
		SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit%	;EM_SETSEL
	Else If (loc = "top")
		SendMessage, 0x00B1, 0, 0,, ahk_id %hEdit%
    SendMessage, 0x00C2, False, &sInput,, ahk_id %hEdit%			;EM_REPLACESEL
}

dbg(_in) {
    Loop, Parse, % _in, `n, `r
        OutputDebug, AHK: %A_LoopField%
}

; ================================================================================
; hotkeys
; ================================================================================



#IfWinActive, ahk_class AutoHotkeyGUI
^c::c.KeySequence("^c")
^CtrlBreak::c.KeySequence("^{CtrlBreak}")
^b::c.KeySequence("^{CtrlBreak}")			; in case user doesn't have BREAK key
^x::c.close()				; closes active CLi instance if idle
^d::c.KeySequence("^d")