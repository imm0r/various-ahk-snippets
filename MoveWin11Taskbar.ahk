#NoEnv
#SingleInstance force
SetWorkingDir %A_ScriptDir%

#Include <dict>

;Windows11 Taskbar Location (registry binary value)
;	Path: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3
;	Key	: Settings
RegRead, StuckRects3, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings
CurrRegVal_p1 := SubStr(StuckRects3, 1, 42), CurrRegVal_p2 := SubStr(StuckRects3, 43)

TaskbarPos := new dict()
TaskbarPos.map(["left", "top", "right", "bottom"],["30000000FEFFFFFF7AF40000000000003C00000030","30000000FEFFFFFF7AF40000010000003C00000030","30000000FEFFFFFF7AF40000020000003C00000030","30000000FEFFFFFF7AF40000030000003C00000030"])

for k, v in TaskbarPos.data
	if(v == CurrRegVal_p1)
		CurrTaskbarPos := k, break

msgbox, % "Taskbar is at the " CurrTaskbarPos ".`n`nIdentified by finding this string in registry:`n" TaskbarPos.get(CurrTaskbarPos) "`n`nMoving to opposite side!"

if(CurrTaskbarPos == "top")
	NewBinaryRegValue := TaskbarPos.get("bottom") . CurrRegVal_p2
else if(CurrTaskbarPos == "bottom")
	NewBinaryRegValue := TaskbarPos.get("top") . CurrRegVal_p2
Else {
	NewBinaryRegValue := ""
	msgbox, % "Error occured!`nNot patching your taskbar position!"
}

If(NewBinaryRegValue)
{
	RegWrite, REG_BINARY, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings, % NewBinaryRegValue
	If(!ErrorLevel) {
		If(A_IsAdmin) {
			SilentRun("taskkill /f /im explorer.exe")
			SilentRun("start explorer.exe")
			If(!ErrorLevel)
				Msgbox, % "Your taskbar was successfully moved!"
		}
	}

	If(ErrorLevel) {
		msgbox, % "Something went terribly wrong!`nPlease check your registry on errors."
	}
}

SilentRun(cmd)
{
    exec := ComObjCreate("WScript.Shell").Exec(ComSpec " /c " cmd)
    return, % exec.StdOut.ReadAll()
}