#NoEnv
#SingleInstance Force
#include <Gdip_All>

Gui, New, +hwndhGUI
Gui, Show, w481 h381, Window
Gui, Add, Picture, w481 h381 +0xE

;GetAndSetScreenshot("Title1")
GetAndSetScreenshot("ahk_class Notepad")
Return

GuiEscape:
GuiClose:
ExitApp

GetAndSetScreenshot(Title){
	global hGui
	pToken := Gdip_Startup()
	pBitmap := Gdip_BitmapFromHWND(WinExist(title))

	Gdip_GetImageDimensions(pBitmap, vImgW, vImgH)
	vCtlW := 481, vCtlH := 381
	pBitmap2 := Gdip_CreateBitmap(vCtlW, vCtlH)
	G := Gdip_GraphicsFromImage(pBitmap2)
	Gdip_DrawImage(G, pBitmap, 0, 0, vCtlW, vCtlH, 0, 0, vImgW, vImgH)

	;image original size
	;hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)

	;image resized to fit control
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap2)
	SendMessage, 0x172, 0, % hBitmap, Static1, % "ahk_id " hGui
}
