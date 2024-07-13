#Persistent
CoordMode, Pixel, Client
DetectHiddenText, On

c1 := WinExist( "ahk_class TheRender" )
c2 := WinExist( "ahk_class sub" )
c3 := WinExist( "ahk_class LDPlayerMainFrame" )


WinGetTextFast(detect_hidden := 1)
{
	; WinGetText ALWAYS uses the "fast" mode - TitleMatchMode only affects
	; WinText/ExcludeText parameters.  In Slow mode, GetWindowText() is used
	; to retrieve the text of each control.
	WinGet controls, ControlListHwnd
	static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.
	VarSetCapacity(buf, WINDOW_TEXT_SIZE * (A_IsUnicode ? 2 : 1))
	text := ""
	Loop Parse, controls, `n
	{
		if !detect_hidden && !DllCall("IsWindowVisible", "ptr", A_LoopField)
			continue
		if !DllCall("GetWindowText", "ptr", A_LoopField, "str", buf, "int", WINDOW_TEXT_SIZE)
			continue
		text .= buf " - " A_LoopField "`r`n"
	}
	return text
}

F9::
	GetLDPClassIDs()
	msgbox, % WinGetTextFast()
return
return