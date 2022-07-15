
WinActivate, % "ahk_class LDPlayerMainFrame"
hWND := WinActive("A")


F3::msgbox, % AeroGetPixel(150, 150, hWND)
AeroGetPixel(x, y, hwnd := 0)
{
	hDC := DllCall("user32.dll\GetDCEx", "Ptr", hwnd, "UInt", 0, "UInt", 1|2)
	pix := DllCall("gdi32.dll\GetPixel", "Ptr", hDC, "Int", x, "Int", y, "UInt")
	DllCall("user32.dll\ReleaseDC", "Ptr", hwnd, "Ptr", hDC)
	DllCall("gdi32.dll\DeleteDC", "Ptr", hDC)
	VarSetCapacity(hex, 8 << !!A_IsUnicode, 0)
    DllCall("shlwapi.dll\wnsprintf", "Str", hex, "Int", 8, "Str", "%06I64X", "Int", pix, "Int")
    return "0x" hex
}