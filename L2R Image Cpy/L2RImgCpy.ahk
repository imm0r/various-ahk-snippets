#noenv
#singleinstance, force
setbatchlines, -1
DetectHiddenWindows, On

#include func_adb.ahk

global debug := 1

;Run As Admin
if not A_IsAdmin
	RunAsAdmin()

; Creating a hidden console
Run "%ComSpec%" /k,, Hide, pid_HiddenConsole
while !(hConsole := WinExist("ahk_pid " pid_HiddenConsole))
	Sleep 10
DllCall( "AttachConsole", "UInt", pid_HiddenConsole )
DllCall( "AllocConsole" )
WinHide % "ahk_id " DllCall( "GetConsoleWindow", "ptr" )
Global objShell := ComObjCreate( "WScript.shell" )
; -------------------------

strClsName := "LDPlayerMainFrame", strAdbFile := "adb.exe", strConsoleFile := "dnconsole.exe"
Global startupActivity := "com.epicgames.ue4.GameActivity"

Winget, cPid, PID, % "ahk_class " strClsName
WinGetTitle, wTitle, % "ahk_class " strClsName
vPath := GetModuleFileNameEx(cPid)
fTitle := GetFileTitleFromPath(vPath)
SplitPath, vPath, fName, fPath
wHwnd := GetHwnd(wTitle, fName)
FileGetVersion, fVer, % vPath

if FileExist(fPath . "\" . strAdbFile)
    adbPath := fPath . "\" . strAdbFile
if FileExist(fPath . "\" . strConsoleFile)
    consolePath := fPath . "\" . strConsoleFile

Global oLDP_Basics := Object("cli", vPath, "adb", adbPath, "console", consolePath, "title", wTitle, "hwnd", wHwnd, "Pid", cPid, "ver", fVer)
Global oDDL_Container := Object("LoginButton", "3150|1235", "SkipButton", "3260|1050", "Inventory", "2850|50", "BulkSale", "2800|1350", "SellButton1", "3300|1350", "SellButton2", "1950|1000", "OkButton", "1750|1000", "BackButton", "80|75", "StartQuest", "440|600")
Global strDDL_entries := Array("LoginButton|", "SkipButton", "Inventory", "BulkSale", "SellButton1", "SellButton2", "OKButton", "BackButton", "StartQuest")

tDevice := adb_GetDevice( )
Global oADB := Object("device", tDevice, "isConnected", adb_isConnectedToDevice(tDevice))

Global hConsole, c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput, DLLInputChoice
        , InputChoice, Lbl_AutoQuest, enabled_AutoSkip

oLDPi := {}

CmdGui()

F10::reload
Return

AutoQuest:
    Gui, Submit, NoHide
	GuiControl, , CmdOutput
    
    cSkipBtn := StrSplit(oDDL_Container["SkipButton"],"|")
    cOkayBtn := StrSplit(oDDL_Container["SellButton2"],"|")
    adb_input("tap", cOkayBtn[1], cOkayBtn[2])
    FormatTime, TimeString, T12, Time

    adb_input("tap", cSkip[1], cSkipBtn[2])
    gOutput := "[" TimeString "] clicked on SkipButton! ("  ") >> Next click in 2250ms.`n`r`n`r"
    AppendText(CmdOutputHwnd, gOutput)
return

AddLog(LogFile, message)
{
    LogFile := "log.txt"
    if(debug) {
        FormatTime, ts, %A_Now%, yyyyMMdd HH:mm:ss
        FileAppend, % ts " - " message "`n", % LogFile
    }
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
