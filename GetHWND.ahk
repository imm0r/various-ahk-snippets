; Retrieve the HWND of a specific process
; Msgbox, % GetHwnd( "L2R(64)", "dnplayer.exe" )

GetHwnd( process, exename )
{
	IfWinExist, %process%
	{
		WinGet, WinID, List, %process%
		Loop, %WinID%
		{
			WinGet, ProcModuleName, ProcessName, % "ahk_id" WinID%A_Index%
			If( ProcModuleName != exename )
				continue
			hWnd:=WinID%A_Index%
		}
		return, % "0x" . Format( "{:X}", hWnd )
	} else
		return false
}