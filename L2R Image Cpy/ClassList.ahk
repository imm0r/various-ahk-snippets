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

WinGetTextFast()

return

F8::
	WinGet, ControlList, ControlListHwnd, A
	clipboard := ControlList
	VarSetCapacity(buf, 32767 * (A_IsUnicode ? 2 : 1))
	Loop Parse, ControlList, `n
	{
		IsVisible := DllCall("IsWindowVisible", "ptr", A_LoopField)
		WinText := DllCall("GetWindowText", "ptr", A_LoopField, "str", buf, "int", 32767)
		msgbox, % "Current Control ID: " A_LoopField "`n`nIsVisible: " IsVisible "`t`tControlText: " WinText "`nbuf: " buf
	}
	clipboard := ControlList
return

