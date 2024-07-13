#noenv
#singleinstance, force

combo1x := 1673
combo1y := 1235
combo2x := 1720
combo2y := 1235
combo3x := 1765
combo3y := 1235

comboClr := 0x45B8C7

D4hWnd := GetHwnd("Diablo IV", "Diablo IV.exe")
^!a::  ; Control+Alt+A hotkey.
	MouseGetPos, MouseX, MouseY
	PixelGetColor, color, %MouseX%, %MouseY% 
	color2 := FHex(DwmGetPixel(D4hWnd, MouseX, MouseY))
	color3 := DwmGetPixel2(MouseX, MouseY, D4hWnd)

	cbStr := "xCoord: " MouseX "`nyCoord: " MouseY "`n`nColor: " color " / " color2 " / " color3
	clipboard := cbStr
	MsgBox, % cbStr
return

^!g::
	
	loop, 3
	{
		tmpX := combo%A_Index%x
		tmpY := combo%A_Index%y
		PixelGetColor, color, %tmpX%, %tmpY%
		color2 := FHex(DwmGetPixel(D4hWnd, tmpX, tmpY))
		color3 := DwmGetPixel2(tmpX, tmpY, D4hWnd)
		cbStr := "color for Combopoint " A_Index ": " color " / " color2 " / " color3
		clipboard := cbStr
		
		mousemove, %tmpX%, %tmpY%
		MsgBox, % cbStr
	}
return
	
v::
	if(NrOfCp = 3)
		SendToHwnd(D4hWnd, ["1", "2", "RButton"], 129)
return

b::
	if(NrOfCp = 3)
		SendToHwnd(D4hWnd, ["1", "3", "RButton"], 144)
return

F3::  ; Control+Alt+A hotkey.
	WinActivate, % "ahk_id " D4hWnd
	
	If( enabled_AutoCP := !enabled_AutoCP ) {
		SetTimer, t_cp, 125
	} else {
		SetTimer, t_cp, off
    }
return
	
t_cp:
	Global NrOfCp := 0
	loop, 3
	{
		tmpX := combo%A_Index%x
		tmpY := combo%A_Index%y
		;if winactive("ahk_id " D4hWnd)
		;{
			PixelGetColor, color, %tmpX%, %tmpY%
			if(color = comboClr)
				NrOfCp++
		;}
	}
	;tooltip, % NrOfCp, 1
return
return



DwmGetPixel(hWnd, x, y)
{
    
   hDC := DllCall("user32.dll\GetDCEx", "UInt", hWnd, "UInt", 0, "UInt", 1|2)
   pix := DllCall("gdi32.dll\GetPixel", "UInt", hDC, "Int", x, "Int", y, "UInt")
   DllCall("user32.dll\ReleaseDC", "UInt", hWnd, "UInt", hDC)
   DllCall("gdi32.dll\DeleteDC", "UInt", hDC)
   return, % ConvertColor(pix)
}

DwmGetPixel2(x, y, hwnd)
{
   hDC := DllCall("user32.dll\GetDCEx", "UInt", hwnd, "UInt", 0, "UInt", 1|2)
   pix := DllCall("gdi32.dll\GetPixel", "UInt", hDC, "Int", x, "Int", y, "UInt")
   DllCall("user32.dll\ReleaseDC", "UInt", hwnd, "UInt", hDC)
   pix := DecToHex(pix)
   return pix
}

ConvertColor( BGRValue )
{
	BlueByte := ( BGRValue & 0xFF0000 ) >> 16
	GreenByte := BGRValue & 0x00FF00
	RedByte := ( BGRValue & 0x0000FF ) << 16
	return RedByte | GreenByte | BlueByte
}

DecToHex(dec)
{
   oldfrmt := A_FormatInteger
   hex := dec
   SetFormat, IntegerFast, hex
   hex += 0
   hex .= ""
   SetFormat, IntegerFast, %oldfrmt%
   return hex
}

Esc:: ExitApp
^Esc:: reload