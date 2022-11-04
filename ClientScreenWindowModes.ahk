;note: this is based on the AHK source code, another approach is to use GetCaretPos
q:: ;recreate A_CaretX and A_CaretY built-in variables

hwnd := GetHwnd( "LDPlayer", "dnplayer.exe" )

VarSetCapacity(GUITHREADINFO, A_PtrSize=8?72:48, 0)
NumPut(A_PtrSize=8?72:48, &GUITHREADINFO, 0, "UInt") ;cbSize
vTID := DllCall("user32\GetWindowThreadProcessId", Ptr,hWnd, UIntP,0, UInt)
DllCall("user32\GetGUIThreadInfo", UInt,vTID, Ptr,&GUITHREADINFO)
hWndC := NumGet(&GUITHREADINFO, A_PtrSize=8?48:28, "Ptr") ;hwndCaret
vPosX := NumGet(&GUITHREADINFO, A_PtrSize=8?56:32, "Int") ;rcCaret ;x
vPosY := NumGet(&GUITHREADINFO, A_PtrSize=8?60:36, "Int") ;rcCaret ;y
JEE_ClientToScreen(hWndC, vPosX, vPosY, vPosXS, vPosYS)
JEE_ClientToScreen(hWnd, 0, 0, vOgnXC, vOgnYC)
JEE_WindowToScreen(hWnd, 0, 0, vOgnXW, vOgnYW)
vPosXC := vPosXS - vOgnXC
vPosYC := vPosYS - vOgnYC
vPosXW := vPosXS - vOgnXW
vPosYW := vPosYS - vOgnYW
vOutput1 := Format("{} {}`r`n{} {}`r`n{} {}", "Client PosX: " vPosXC, "Client PosY: " vPosYC, "Screen PosX: " vPosXS, "Screen PosY: " vPosYS, "Window PosX: " vPosXW, "Window PosY: " vPosYW)

vOutput2 := ""
vList := "Client,Screen,Window"
Loop, Parse, vList, % ","
{
	CoordMode, Caret, % A_LoopField
	Sleep, 1
	vOutput2 .= (A_Index=1?"":"`r`n") A_CaretX " " A_CaretY
}
MsgBox, % (vOutput1 = vOutput2) "`r`n`r`n" vOutput1 "`r`n`r`n" vOutput2
return

;==================================================

w:: ;test converting between coordinate modes

hwnd := GetHwnd( "LDPlayer", "dnplayer.exe" )

vOutput := ""
vList := "Client,Screen,Window"
Loop, Parse, vList, % ","
{
	CoordMode, Caret, % A_LoopField
	vChar := SubStr(A_LoopField, 1, 1)
	Sleep, 1
	vPosX%vChar% := A_CaretX
	vPosY%vChar% := A_CaretY
	vOutput .= (A_Index=1?"":"`r`n") vPosX%vChar% " " vPosY%vChar%
}
MsgBox, % vOutput

oArray := {C:"Client",S:"Screen",W:"Window"}
vList := "CS,CW,SC,SW,WC,WS"
Loop, Parse, vList, % ","
{
	vTemp1 := SubStr(A_LoopField, 1, 1)
	vTemp2 := SubStr(A_LoopField, 2, 1)
	vFunc := "JEE_" oArray[vTemp1] "To" oArray[vTemp2]
	%vFunc%(hWnd, vPosX%vTemp1%, vPosY%vTemp1%, vPosX, vPosY)
	vIsMatch := (vPosX%vTemp2% " " vPosY%vTemp2% = vPosX " " vPosY)
	MsgBox, % A_LoopField "`r`n" vIsMatch "`r`n" Format("{} {}`r`n{} {}", vPosX%vTemp2%, vPosY%vTemp2%, vPosX, vPosY)
}
return

;==================================================

JEE_ClientToScreen(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ClientToScreen", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}

;==================================================

JEE_ScreenToClient(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ScreenToClient", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}

;==================================================

JEE_ScreenToWindow(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 := vPosX - vWinX
	vPosY2 := vPosY - vWinY
}

;==================================================

JEE_WindowToScreen(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16, 0)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 := vPosX + vWinX
	vPosY2 := vPosY + vWinY
}

;==================================================

JEE_ClientToWindow(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ClientToScreen", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")

	VarSetCapacity(RECT, 16)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 -= vWinX
	vPosY2 -= vWinY
}

;==================================================

JEE_WindowToClient(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16, 0)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")

	VarSetCapacity(POINT, 8)
	NumPut(vPosX+vWinX, &POINT, 0, "Int")
	NumPut(vPosY+vWinY, &POINT, 4, "Int")
	DllCall("user32\ScreenToClient", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}

;==================================================

F5::reload