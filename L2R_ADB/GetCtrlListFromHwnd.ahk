GetCtrlListFromHwnd(hWnd)
{
	Global CtrlListID
	ControlList := "", CtrlList := [], CtrlListID := []
	WinGet, ControlList, ControlListHwnd, % "ahk_id " hWnd
	VarSetCapacity(ctrlName, 32767 * (A_IsUnicode ? 2 : 1))
	Loop Parse, ControlList, `n
	{
		DllCall("GetWindowText", "ptr", A_LoopField, "str", ctrlName, "int", 32767)
		CtrlList[ctrlName] := DecToHex(A_LoopField)
		CtrlListID[A_Index] := ctrlName
	}
	return, % CtrlList
}