GetWinTitleFromProc(proc) {
	WinGetTitle, tProc, % "ahk_exe " proc
	WinGetTitle, tProc, % "ahk_id " GethWnd(tProc, proc)
	return tProc
}