#NoEnv
#Include <GDIP_ALL>

Gui, 1: Color, 336699
Gui, 1: -Caption +LastFound +ToolWindow +AlwaysOnTop
Gui, 1: Add, Picture, % "x5 y5 w210 h35 0xE hwndgHwnd"

WinSet, TransColor, 336699 210
Gui, 1:Show, x5 y5 w250 h60 NoActivate

dpi := DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
sx := DllCall("GetSystemMetrics", "int", 76, "int")
sy := DllCall("GetSystemMetrics", "int", 77, "int")
sw := DllCall("GetSystemMetrics", "int", 78, "int")
sh := DllCall("GetSystemMetrics", "int", 79, "int")
DllCall("SetThreadDpiAwarenessContext", "ptr", dpi, "ptr")
d4hWnd := GetHwnd("Diablo IV", "Diablo IV.exe")

Token := Gdip_StartUp()

String := "Hello World"
FontName := "Franklin Gothic Medium Cond"
fSize := 49
fStyle := 1 ; FontStyleBold
fAlign := 1 ; Centered

pBitmap := Gdip_CreateBitmap( 230 , 50 )
pGraphics := Gdip_GraphicsFromImage( pBitmap )
Gdip_SetSmoothingMode( pGraphics , 2 )

pBrush := Gdip_BrushCreateSolid( "0x1F36373A" )
pPen := Gdip_CreatePen( "0xFF1A1C1F" , 2 )

PathBounds := Gdip_DrawOrientedString( pGraphics, String, FontName, fSize, fStyle, 1, 1, 230, 50, 0, pBrush, pPen, fAlign, 0 )

hBitmap := Gdip_CreateHBITMAPFromBitmap( pBitmap )
Result := SetImage( gHwnd, hBitmap )

MsgBox, 0, SetImage, % "x: " PathBounds.x "`ny: " PathBounds.y "`nw: " PathBounds.w "`nh: " PathBounds.h

Gdip_DeleteBrush(pBrush)
Gdip_DeletePen( pPen )
Gdip_DeleteGraphics( pGraphics )
Gdip_DisposeImage( pBitmap )
DeleteObject( hBitmap )
Gdip_ShutDown( Token )
ExitApp