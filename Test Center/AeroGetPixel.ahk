
WinActivate, Diablo IV
hWND := WinActive("A")


F3::
	PixelGetColor, color, 1255, 1330, RGB
	if (ColorCompare(color, "0x360202") > 26)
		msgbox, % "use a potion"
	else
		msgbox, % "No need for a pot!"
return

F5::reload

ColorCompare(color1,color2)  ; colors in hex format  "0xff8728"
{
  Loop,2
  {
    param:=A_Index
    StringTrimLeft,color%param%,color%param%,2
    Loop,3
    {
      StringLeft,c%param%%A_Index%,color%param%,2
      value:=c%param%%A_Index%
      c%param%%A_Index%=0x%value%
      StringTrimLeft,color%param%,color%param%,2
    }
  } 
  difference:=(Abs(c11-c21)+Abs(c12-c22)+Abs(c13-c23))/3
  Return difference
}