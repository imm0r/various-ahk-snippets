#NoEnv
#SingleInstance, Force
SetBatchLines, -1
;SetWinDelay, 10

ChromeClassName := "Chrome_RenderWidgetHostHWND1"
ChromeExe := "Chrome.exe"

F1::
	PrepareChrome( )
	If( USKENABLED := !USKENABLED ) {
		If( !ChromeCtrlhWnd || !ChromeWinhWnd )
			PrepareChrome( )
		SetTimer, AutoPlayFast, 25
	} else
		SetTimer, AutoPlayFast, off
return		

AutoPlayFast:
	IfWinNotActive, & "ahk_exe " ChromeExe
		ControlFocus, , % "ahk_id " ChromeCtrlhWnd
	ControlSend, ahk_parent, {space}, % "ahk_id " ChromeCtrlhWnd
return

F2::
	reload
return		

GetHwnd(process, exename)
{
	If WinExist(process) {
		WinGet, WinID, List, %process%
		Loop, %WinID% {
			WinGet, ProcModuleName, ProcessName, % "ahk_id" WinID%A_Index%
			If(ProcModuleName=exename) {
				If (WinID%A_Index%=WinActive("A"))
					ThisID:=WinActive("A")
				return WinID%A_Index%
			}
		}
	} else
		return false
}

PrepareChrome( )
{
	Global
	ChromeCtrlhWnd := GetControlHWNDFromWinTitle( FullWinTitle := GetFullWinTitle( "| GameTwist" ), ChromeClassName )
	ChromeWinhWnd := GetHwnd( FullWinTitle, "chrome.exe" )
}

GetWinTitleFromPid( pID ) {
	WinGetTitle, r, % "ahk_pid " pID
}

GetFullWinTitle( InTitleStr )
{
	objWMIService := ComObjGet( "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2" )
	colItems := objWMIService.ExecQuery( "SELECT ExecutablePath,	ProcessID FROM Win32_Process where ExecutablePath is not null" )._NewEnum
	While colItems[objItem]
		If InStr( r := GetWinTitleFromPid( objItem.ProcessID ), InTitleStr )
			Return, r
	WinGetTitle, r, % "ahk_id " WinExist( "A" )
	Return, r
}

GetControlHWNDFromWinTitle( InTitleStr, ChromeClassName := "" )
{
	ControlGet, r, Hwnd, , % ChromeClassName, % InTitleStr
	return, r
}