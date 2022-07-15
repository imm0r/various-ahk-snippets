#NoEnv
#SingleInstance force
SetWorkingDir %A_ScriptDir%

#Include <dict>

; Defining the variables in this script
SysGet, display, MonitorName
rotation:={1:0,2:1,3:2,4:3}

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

; Defining the variables in this script
SysGet, display, MonitorName
rotation:={1:0,2:1,3:2,4:3}

; Hotkey for Screen Orientation Switch
^!w::
	sRes:=strSplit((cRes:=screenRes_Get(display)),["x","@","-"])
	If(cOri:=Get_DisplayOrientation(display) == "landscape")			; rotating to portrait
		sResult := screenRes_Set(sRes[2] "x" sRes[1] "@" sRes[3],display,rotation[4])
	else If(cOri:=Get_DisplayOrientation(display) == "portrait")			; rotating to landscape
		sResult := screenRes_Set(sRes[2] "x" sRes[1] "@" sRes[3],display,rotation[1])
	else
		sResult := "Could not retrieve the current screen orientation!`nFound: " cOri
	msgbox, % sResult
Return

;https://www.autohotkey.com/boards/viewtopic.php?t=77664€
screenRes_Set(WxHaF, Disp:=0, orient:=0)
{
	Local DM, N:=VarSetCapacity(DM,220,0), F:=StrSplit(WxHaF,["x","@"],A_Space)
	Return DllCall("ChangeDisplaySettingsExW",(Disp=0 ? "Ptr" : "WStr"),Disp,"Ptr",NumPut(F[3],NumPut(F[2],NumPut(F[1]
		,NumPut(32,NumPut(0x5C0080,NumPut(220,NumPut(orient,DM,84,"UInt")-20,"UShort")+2,"UInt")+92,"UInt"),"UInt")
		,"UInt")+4,"UInt")-188, "Ptr",0, "Int",0, "Int",0)  
}

screenRes_Get(Disp:=0)
{
	Local DM, N:=VarSetCapacity(DM,220,0) 
	Return DllCall("EnumDisplaySettingsW", (Disp=0 ? "Ptr" : "WStr"),Disp, "Int",-1, "Ptr",&DM)=0 ? ""
		: Format("{:}x{:}@{:}-{:}", NumGet(DM,172,"UInt"),NumGet(DM,176,"UInt"),NumGet(DM,184,"UInt"),NumGet(DM,84,"WStr")) 
}

Check(X,Y,HWND) {
   SendMessage, 0x84,, (X & 0xFFFF)|(Y & 0xFFFF) << 16 ,, ahk_id %HWND%
   ; Return true if the mouse is over the title bar caption or a resizable border
   ; (Notepad and Explorer gave me ErrorLevel 17 instead of 2 when tested on Win7)
   Return ((ErrorLevel=2)||(ErrorLevel>=10 && ErrorLevel<=17))
}