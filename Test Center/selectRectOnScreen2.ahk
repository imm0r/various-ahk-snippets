#NoEnv
SetBatchLines, -1
#SingleInstance, Force

; Exit Func - Controls everything that needs to be done before exiting the script.
OnExit("ExitFunc")
ExitFunc()
{
    DeleteObject( hBitmap )
	Gdip_DisposeImage( pBitmap )
	Gdip_ShutDown( pToken )
	return
}

SaveToFile := 1
IfNotExist, %A_ScriptDir%\Saved Clips ; if there is no folder for saved clips
	FileCreateDir, %A_ScriptDir%\Saved Clips ; create the folder.
SetWorkingDir, %A_ScriptDir%\Saved Clips ;Set the saved clips folder as the working dir.

#Include <Gdip_All>
pToken := Gdip_Startup() ;Start using Gdip

OnMessage(0x14, "WM_ERASEBKGND")
Gui, 1:New, +hwndhGuiRect
Gui, 1:-Caption +ToolWindow
Gui, 1:+LastFound
WinSet, TransColor, Black

Msgbox, % "hWnd GuiRect: " hGuiRect "`nhWnd GuiReport: " hGuiReport
; Create the pen here so we don't need to create/delete it every time.
RedPen := DllCall("CreatePen", "int", PS_SOLID:=0, "int", 2, "uint", 0xff)
return

WM_ERASEBKGND(wParam, lParam)
{
    global x1, y1, x2, y2, RedPen
    Critical 50
    if A_Gui = 1
    {
        ; Retrieve stock brush.
        blackBrush := DllCall("GetStockObject", "int", BLACK_BRUSH:=0x4)
        ; Select pen and brush.
        oldPen := DllCall("SelectObject", "uint", wParam, "uint", RedPen)
        oldBrush := DllCall("SelectObject", "uint", wParam, "uint", blackBrush)
        ; Draw rectangle.
        DllCall("Rectangle", "uint", wParam, "int", 0, "int", 0, "int", x2-x1, "int", y2-y1)
        ; Reselect original pen and brush (recommended by MS).
        DllCall("SelectObject", "uint", wParam, "uint", oldPen)
        DllCall("SelectObject", "uint", wParam, "uint", oldBrush)
        return 1
    }
}

+LButton::
    coordmode, mouse, screen
    MouseGetPos, xorigin, yorigin
    ; msgbox, %xorigin%, %yorigin%
    SetTimer, rectangle, 10
return

rectangle:
    Gui, 67: Cancel
    coordmode, mouse, screen
    MouseGetPos, x2, y2
;   msgbox, %xorigin%, %yorigin%
    ; Has the mouse moved?
    if (x1 y1) = (x2 y2)
        return
   
    ; Allow dragging to the left of the click point.
    if (x2 < xorigin) {
        x1 := x2
        x2 := xorigin
    } else
        x1 := xorigin
   
    ; Allow dragging above the click point.
    if (y2 < yorigin) {
        y1 := y2
        y2 := yorigin
    } else
        y1 := yorigin
    
    Gui, 67:New, +hwndhGuiReport +Alwaysontop -Caption +LastFound +ToolWindow +E0x20 -DPIScale
   
    Gui, 1:Show, % "NA X" x1 " Y" y1 " W" x2-x1 " H" y2-y1
    Gui, 1:+LastFound +AlwaysOnTop
	WinGetPos, X, Y, W, H
	Tooltip % "X: " X ", Y: " Y "`nWidth: " W ", Height: " H
    DllCall("RedrawWindow", "uint", hGuiRect, "uint", 0, "uint", 0, "uint", 5)
    Gui, 67:Destroy
return

+LButton Up::
    SetTimer, rectangle, Off
    Gui, 1: Cancel
    
	pBitmap := Gdip_BitmapFromScreen( X "|" Y "|" W "|" H ) ;Create a bitmap of the screen.

	Gdip_SaveBitmapToFile( pBitmap , A_WorkingDir "\" ( ( SaveToFile = 1 ) ? ( ClipName := "Saved Clip " A_Now ) : ( ClipName := "Temp Clip" ) ) ".png" , 100 ) ; Save the bitmap to file

    coordmode, mouse, window
    tooltip
    Clipboard := % "X`t`t: " X "`nY`t`t: " Y "`nWidth`t: " W "`nHeight`t: " H

    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
    
    Gui, 67:Add, Picture, % "x1 y1 w" W " h" H " +0xE +hWndhCtrlPic"
    SetImage(hCtrlPic, hBitmap)
    Gui, 67:Show, % "x25 y25 w" W + 2 " h" H + 2, Window

    DeleteObject( hBitmap )
	Gdip_DisposeImage( pBitmap ) ;Dispose of the bitmap to free memory.
return

; Reload the script
F11::
{
    DeleteObject( hBitmap )
	Gdip_DisposeImage( pBitmap )
	Gdip_ShutDown( pToken )
	Reload
}
return

; Exit the script by triggering the Exit Func.
F12::
	ExitApp
return