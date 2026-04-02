#NoEnv
#singleinstance, force
SetBatchLines, -1

clipboard := ScreenResolution_List()

ClockWise:={1:[0,0],2:[1,1],3:[2,0],4:[3,1]}

SysGet, display, MonitorName
msgbox, % display "`n`n" Get_DisplayOrientation() "`n`n" ScreenResolution_Get()
clipboard := ScreenResolution_Get()
landscapeRes := "1440x3440@100"
portraitRes := "3440x1440@100"

ClassGuid:="{4d36e96e-e325-11ce-bfc1-08002be10318}", M1:="", M2:="", M3:=""
WMI:=ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" . A_ComputerName . "\root\cimv2")
For Monitor in  WMI.ExecQuery("SELECT * FROM Win32_PnPEntity WHERE ClassGuid='" . ClassGuid . "'")
{
	DeviceID := Monitor.DeviceID
	U := DeviceID
	M := StrSplit(U, ["\","UID"])
	M%A_Index% := Format("{2:}\{4:}", M*)
	RegRead, U, HKLM\SYSTEM\CurrentControlSet\Enum\%U%\Device Parameters, EDID
	U%A_Index% := Format("{1:}_{8:}{9:}{6:}{7:}{4:}{5:}{2:}{3:}", M[2], StrSplit(SubStr(U, 25, 8))*)
}

loop, % M.MaxIndex()
{
	msgbox, % "ScreenResGet: " ScreenResolution_Get(0) "`nLookUp: " lookup[a_thisHotkey][1]
	Menum .= "`t- M" . A_Index . ": " . M[A_Index] . "`n"
}

Msgbox, % "U (Monitor.DeviceID): " DeviceID "`n`nM (enumerated):`n" Menum

SysGet, display, MonitorName
return
lookup:={"^!down":[0,0],"^!right":[1,1],"^!up":[2,0],"^!left":[3,1]}

SysGet, SM_CXFULLSCREEN, 16
SysGet, SM_CYFULLSCREEN, 17

msgbox, % "Client area for a full-screen window on`nthe primary display monitor, in pixels:`n`n"
		. "width of client area`t: " SM_CXFULLSCREEN "`n"
		. "height of client area`t: " SM_CYFULLSCREEN

wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\wmi")
monitors := {}
for monitor in wmi.ExecQuery("Select * from WmiMonitorID")
{	
	fname := ""
	for char in monitor.UserFriendlyName
		fname .= chr(char)

	If fname
		monitors.push(fname)		
	else
		Break
}
msgbox, % "UserFriendlyName: " monitors[1]
		
mInfo := {}
mInfo.ID := {}, mInfo.Primary := {}, mInfo.MonCoords := {}, mInfo.WorkAreaCoords := {}
SysGet, MonitorCount, MonitorCount
SysGet, MonitorPrimary, MonitorPrimary
loop, % MonitorCount
{
	SysGet, DisplayID, MonitorName, % A_Index
	mInfo.ID.push(DisplayID)
	
	If(A_Index == MonitorPrimary)
		mInfo.Primary.push(true)
	else
		mInfo.Primary.push(false)
	
	SysGet, Monitor, Monitor, % A_Index
	MCoords := {"x":MonitorLeft,"y":MonitorTop,"w":MonitorRight,"h":MonitorBottom}
	mInfo.MonCoords.push(MCoords)
	
	SysGet, MonitorWorkArea, MonitorWorkArea, % A_Index
	WACoords := {"x":MonitorWorkAreaLeft,"y":MonitorWorkAreaTop,"w":MonitorWorkAreaRight,"h":MonitorWorkAreaBottom}
	mInfo.WorkAreaCoords.push(WACoords)
	
	;MsgBox, Monitor:`t#%A_Index%`nName:`t%MonitorName%`n89`nLeft:`t%MonitorLeft% (%MonitorWorkAreaLeft% work)`nTop:`t%MonitorTop% (%MonitorWorkAreaTop% work)`nRight:`t%MonitorRight% (%MonitorWorkAreaRight% work)`nBottom:`t%MonitorBottom% (%MonitorWorkAreaBottom% work)p2p2
}
msgbox, % mInfo.MonCoords[1]["w"]

GetDisplayDeviceList("display", false)
	
displayCNT	:= %display%
displayPRI	:= %display%Primary
displayNAME := %display%1
displayID	:= %display%1ID


F9::
	if(Get_DisplayOrientation() == "landscape")
		msgbox, % ScreenResolution_Set(portraitRes, "\\.\DISPLAY1", 3)
	else if(Get_DisplayOrientation() == "portrait")
		msgbox, % ScreenResolution_Set(landscapeRes, "\\.\DISPLAY1", 0)
return

^!down::
^!right::
^!up::
^!left::
if (lookup[a_thisHotkey][2]){ ; rotating to portrait
	sRes:=strSplit((cRes:=ScreenResolution_Get(display)),["x","@"])
	if (sRes[2] < sRes[1]) {
		cRes:=sRes[2] "x" sRes[1] "@" sRes[3]
	}
} else { ; rotating to landscape
	sRes:=strSplit((cRes:=ScreenResolution_Get(display)),["x","@"])
	if (sRes[2] > sRes[1]) {
		cRes:=sRes[2] "x" sRes[1] "@" sRes[3]
	}
}

ScreenOrientation_Get(Disp:=0) {
	sRes:=strSplit((cRes:=ScreenResolution_Get(Disp)),["x","@"])
	if (sRes[2] < sRes[1])
		return, "landscape"
	return, "portrait"
}

ScreenResolution_Set(WxHaF, Disp:=0, orient:=0) {       ; v0.90 By SKAN on D36I/D36M @ tiny.cc/screenresolution ; edited orientation in by Masonjar13
	Local DM, N:=VarSetCapacity(DM,220,0), F:=StrSplit(WxHaF,["x","@"],A_Space)
	Return DllCall("ChangeDisplaySettingsExW",(Disp=0 ? "Ptr" : "WStr"),Disp,"Ptr",NumPut(F[3],NumPut(F[2],NumPut(F[1]
	,NumPut(32,NumPut(0x5C0080,NumPut(220,NumPut(orient,DM,84,"UInt")-20,"UShort")+2,"UInt")+92,"UInt"),"UInt")
	,"UInt")+4,"UInt")-188, "Ptr",0, "Int",0, "Int",0)  
}

ScreenResolution_Get(Disp:=0) {              ; v0.90 By SKAN on D36I/D36M @ tiny.cc/screenresolution
	Local DM, N:=VarSetCapacity(DM,220,0) 
	Return DllCall("EnumDisplaySettingsW", (Disp=0 ? "Ptr" : "WStr"),Disp, "Int",-1, "Ptr",&DM)=0 ? ""
		: Format("{:}x{:}@{:}", NumGet(DM,172,"UInt"),NumGet(DM,176,"UInt"),NumGet(DM,184,"UInt")) 
}

ScreenResolution_List(Disp:=0) {             ; v0.90 By SKAN on D36I/D36M @ tiny.cc/screenresolution
Local DM, N:=VarSetCapacity(DM,220,0), L:="", DL:=","
  While DllCall("EnumDisplaySettingsW", (Disp=0 ? "Ptr" : "WStr"),Disp, "Int",A_Index-1, "Ptr",&DM)
  If ( NumGet(DM,168,"UInt")=32 && NumGet(DM,184,"UInt")>59)
    L.=Format("{:}x{:}@{:}" . DL, NumGet(DM,172,"UInt"),NumGet(DM,176,"UInt"),NumGet(DM,184,"UInt")) 
Return RTrim(L,DL) 
}