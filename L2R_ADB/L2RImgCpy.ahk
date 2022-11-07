#noenv
#singleinstance, force
setbatchlines, -1
DetectHiddenWindows, On

#include <gdipp>
#include func.ahk
#include func_adb.ahk

;Start up gdip
pToken := Gdip_Startup()

global debug := 1
FormatTime, DateStr, , T12, Time
FormatTime, TimeStr, , T12, Time

;Run As Admin
if not A_IsAdmin
	RunAsAdmin()

; Creating a hidden console
Run, %ComSpec% /k, , Hide UseErrorLevel, pid_HiddenConsole
if not ErrorLevel
{
    while !(hConsole := WinExist("ahk_pid " pid_HiddenConsole))
        Sleep, 10
    DllCall("AttachConsole", "UInt", pid_HiddenConsole)
    DllCall("AllocConsole")
    WinHide % "ahk_id " DllCall("GetConsoleWindow")
}
Global objShell := ComObjCreate( "WScript.shell" )
; -------------------------

Global oLDP_Basics := GetLDPBasics()
FormatTime, strCDate, %A_Now%, yyyy-MM-dd
Global oBasics := Object("imgDir", A_ScriptDir . "\misc\img\", "dos2unix", A_ScriptDir "\misc\dos2unix.exe", "dbgDir", A_ScriptDir "\dbg\", "fDbg", A_ScriptDir "\dbg\" strCDate ".log")

Global startupActivity := "com.epicgames.ue4.GameActivity"

Global oDDL_Container := Object("LoginButton", "3150|1235", "SkipButton", "3260|1050", "Inventory", "2850|50", "BulkSale", "2800|1350"
                        , "SellButton1", "3300|1350", "SellButton2", "1950|1000", "OkButton", "1750|1000", "BackButton", "80|75"
                        , "StartQuest", "440|600")
Global strDDL_entries := Array("LoginButton|", "SkipButton", "Inventory", "BulkSale", "SellButton1", "SellButton2", "OKButton"
                        , "BackButton", "StartQuest")

tDevice := adb_GetDevice( )
Global oADB := Object("device", tDevice, "isConnected", adb_isConnectedToDevice(tDevice))

Global hConsole, c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput, DLLInputChoice
        , InputChoice, LABPic, Lbl_AutoQuest, enabled_AutoSkip, Lbl_LiveAppBroadcasting, enabled_LiveAppBroadc

oLDPi := {}

CmdGui()

F10::reload
Return

t_AutoQuest:
    Gui, Submit, NoHide
	GuiControl, , CmdOutput
    
    cSkipBtn := StrSplit(oDDL_Container["SkipButton"],"|")
    adb_input("tap", cOkayBtn[1], cOkayBtn[2])
    FormatTime, TimeString, T12, Time

    adb_input("tap", cSkip[1], cSkipBtn[2])
    gOutput := "[" TimeString "] clicked on SkipButton! ("  ") >> Next click in 2250ms.`n`r`n`r"
    AppendText(CmdOutputHwnd, gOutput)
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

F5::
    AddLog("This is a single line entry comming from a variable!", 1, oBasics.fDbg)
    AddLog("This is a multi line entry comming from a variable!", 2, oBasics.fDbg)
    AddLog("This is a single line entry comming from an array!", 3, oBasics.fDbg)
    AddLog("This is a multi line entry comming from an array!", 4, oBasics.fDbg)
return

AddLog(msg, cat := 1, LogFile := oBasics.fDbg)
{
    FormatTime, ts, %A_Now%, HH:mm:ss
    if (debug && msg)
        if isObject(msg)
            If A_Index = 1
                Loop, parse, % message, `n, `r
                    If A_LoopField is not space
                        If A_Index = 1
                            FileAppend, % "[" ts "] - (" cat ") - " msg[A_Index] "`n", % LogFile
                        else
                            FileAppend, % "`t`t(" cat ") - " msg[A_Index] "`n", % LogFile
                FileAppend, % "[" ts "] - (" cat ") - " msg[A_Index] "`n", % LogFile
            else
                FileAppend, % "`t`t(" cat ") - " msg[A_Index] "`n", % LogFile
        else
            Loop, parse, % message, `n, `r
                If A_LoopField is not space
                    If A_Index = 1
                        FileAppend, % "[" ts "] - (" cat ") - " msg "`n", % LogFile
                    else
                        FileAppend, % "`t`t(" cat ") - " msg "`n", % LogFile
}

OnExit:
	; Terminating the hidden console and cleaning up memory
	DllCall("CloseHandle", "uint", hConsole)
	DllCall("FreeConsole")

	Process Exist, % pid_HiddenConsole
	if (ErrorLevel == pid_HiddenConsole) {
		Process, Priority, % pid_HiddenConsole, Low
		Run *RunAs %A_WinDir%\System32\cmd.exe /c taskkill /f /pid %pid%,, hide
	}
	; -----------------------------------------------------
return

#include gui.ahk
