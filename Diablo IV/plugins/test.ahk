#NoEnv
#SingleInstance force
 
#include <GDIP_All>
 
WM_PAINT = 0x0F
WM_WINDOWPOSCHANGED = 0x47
OnMessage(WM_WINDOWPOSCHANGED, "MSGH")
OnMessage(WM_PAINT, "MSGH")
; OnMessage(0x201, "WM_LBUTTONDOWN")
 
OnExit, GuiClose
 
If !pToken := Gdip_Startup()
{
  MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
  ExitApp
}
 
;============================
;;-- Größe der Zeichenfläche
;============================
Width  := 1200
Height := 1200
 
hTB := 20  ; Höhe für Text und Button-Zeile
 
; Gui, 1:-Caption
; Gui, 1:+Resize +0x300000  ; WS_VSCROLL | WS_HSCROLL
Gui, 1:Color, D0D0D0
Gui, 1:Add, Picture,  % "x"0    " y"0            " w"Width " h"Height-hTB " hwndPRpict1 vPRpicture1",
Gui, 1:Add, Button,   % "x"0    " y"Height-hTB   " w"70    " h"hTB " g_RotateLine   vPRbutton1"  , Rotate Line
Gui, 1:Add, Button,   % "xp+"70 " yp"            " w"80    " h"hTB " g_RotateFrame  vPRbutton2"  , Rotate Frame
Gui, 1:Add, Checkbox, % "xp+"85 " yp"            " w"65    " h"hTB " g_DrawStepwise vPRcheckbox1", Stepwise
Gui, 1:Add, Button,   % "xp+"65 " yp"            " w"40    " h"hTB " g_ResetCanvas  vPRbutton3"  , Reset
Gui, 1:Add, Text,     % "xp+"40 " y"Height-hTB+3 " w"40    " h"hTB " -Wrap Right    vPRtext1"    , Angle°:
Gui, 1:Add, Edit,     % "xp+"45 " y"Height-hTB   " w"25    " h"hTB " -Wrap Center   vPRedit1"    ,
Gui, 1:Add, Text,     % "xp+"30 " y"Height-hTB+3 " w"30    " h"hTB " -Wrap Right    vPRtext2"    , Steps:
Gui, 1:Add, Edit,     % "xp+"35 " y"Height-hTB   " w"25    " h"hTB " -Wrap Center   vPRedit2"    ,
Gui, 1:Show, % "w"Width " h"Height, PinRotate-Test
WinSet, Transparent, 100, PinRotate-Test
ControlGetPos, pictX, pictY, pictW, pictH,, ahk_id %PRpict1%
 
;=======================================================================
; Mittel-Position (der fixierte Punkt, um den sich alles dreht ...)
;=======================================================================
PinX := pictW//2 , PinY := pictH//2
MidX := PinX , MidY := PinY
 
;======================================
;;-- Prepare 'canvas' to work upon
;======================================
hdc_PRpict1 := GetDC(PRpict1)
hbm := CreateDIBSection(pictW, pictH)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
 
gosub initColors
gosub drawBackground
gosub drawCoord
gosub initLine
gosub initFrame
; gosub _ResetCanvas
gosub updateCanvas
return
 
;=== Line ==============================================================
initLine:
  DISTANCE  := pictW//2-40  ; Länge der Linie
  DRAW_ANGLE := 0    ; Startwinkel der ersten Linie (0° = Ost)
  PEN_COLOR := c_Red
  STEP := 0
  x1L := MidX, y1L := MidY
  ; Linienlänge und Endpunkt berechnen
  polar(x1L,y1L, dtr(DRAW_ANGLE), DISTANCE, x2L,y2L)
  ; Linie um Winkel 'DRAW_ANGLE' rotieren
  gosub rotateLinePoint
  gosub drawLine
return
 
rotateLinePoint:
  Loop, 2
  {
    i := A_Index
    rotatePoint(x%i%L,y%i%L, PinX,PinY, DRAW_ANGLE, ROT_X%i%L,ROT_Y%i%L)
  }
return
 
drawLine:
  Gdip_SetSmoothingMode(G, 4)
  DrawPen := Gdip_CreatePen(PEN_COLOR, 1)
  DllCall("gdiplus\GdipSetPenDashStyle", "Uint", DrawPen, "Int", 0)
  Gdip_DrawLine(G, DrawPen, ROT_X1L, ROT_Y1L, ROT_X2L, ROT_Y2L)
  Gdip_DeletePen(DrawPen)
return
 
;=== Frame =============================================================
initFrame:
  ; Anzahl Rahmenpunkte
  points := 4
 
  ; Rahmen-Kantenlängen
  d1 := 50     ; rechts u. links
  d2 := 70     ; oben u. unten
 
  ; Rahmen-Winkel in Grad
  a1 := 10        ; Winkel für Linie 'x1,y1' - 'x2,y2'
  a2 := a1 + 90   ; Winkel für Linie 'x2,y2' - 'x3,y3'
  a3 := a2 + 90   ; Winkel für Linie 'x3,y3' - 'x4,y4'
 
  PinD := 150 ; Entfernung 'PinX,PinY' - Rahmenpunkt unten rechts
  PinA := 5   ; Winkel 'PinX,PinY' - Rahmenpunkt unten rechts (0°=Ost, 90°=Nord)
 
  ; Rahmenpunkte berechnen
  polar(MidX,MidY, dtr(PinA), PinD, x1F,y1F)   ; 1. Pt. unten rechts
  polar(x1F,y1F, dtr(a1), d1, x2F,y2F)         ; 2. Pt. oben rechts
  polar(x2F,y2F, dtr(a2), d2, x3F,y3F)         ; 3. Pt. oben links
  polar(x3F,y3F, dtr(a3), d1, x4F,y4F)         ; 4. Pt. unten links
 
  ROTATION_LINE_LENGTH_F := PinD-10
  DRAW_ANGLE := 0
  PEN_COLOR := c_White
  STEP := 0
 
  gosub rotateFramePoints
  gosub drawFrame
return
 
rotateFramePoints:
  Loop, % points
  {
    i := A_Index
    rotatePoint(x%i%F,y%i%F, PinX,PinY, DRAW_ANGLE, ROT_X%i%F,ROT_Y%i%F)
  }
return
 
drawFrame:
  Gdip_SetSmoothingMode(G, 4)
  DrawPen := Gdip_CreatePen(PEN_COLOR, 1)
  Loop, % points
  {
    i := A_Index
    ii := (i = points) ? 1 : i + 1
    Gdip_DrawLine(G, DrawPen, ROT_X%i%F,ROT_Y%i%F, ROT_X%ii%F,ROT_Y%ii%F)
  }
  Gdip_DeletePen(DrawPen)
return
 
drawFrameExtent:
  xmin := ROT_X1F, ymin := ROT_Y1F
  xmax := ROT_X1F, ymax := ROT_Y1F
  Loop, % points
  {
    i := A_Index
    xmin := (ROT_X%i%F < xmin) ? ROT_X%i%F : xmin
    ymin := (ROT_Y%i%F < ymin) ? ROT_Y%i%F : ymin
    xmax := (ROT_X%i%F > xmax) ? ROT_X%i%F : xmax
    ymax := (ROT_Y%i%F > ymax) ? ROT_Y%i%F : ymax
  }
  DrawPen := Gdip_CreatePen(c_Extent, 1)
  DllCall("gdiplus\GdipSetPenDashStyle", "Uint", DrawPen, "Int", 2)
  DllCall("gdiplus\GdipPenSetAlignment", "Uint", DrawPen, "Int", 1)
  Gdip_DrawLine(G, DrawPen, xmin,ymin, xmax,ymin)  ; oben
  Gdip_DrawLine(G, DrawPen, xmax,ymin, xmax,ymax)  ; links
  Gdip_DrawLine(G, DrawPen, xmax,ymax, xmin,ymax)  ; unten
  Gdip_DrawLine(G, DrawPen, xmin,ymax, xmin,ymin)  ; rechts
  Gdip_DeletePen(DrawPen)
return
 
;=======================================================================
; Koordinatensystem zeichnen
drawCoord:
  Gdip_SetSmoothingMode(G, 4)
  DrawPen := Gdip_CreatePen(c_Coord, 3)
  DllCall("gdiplus\GdipSetPenDashStyle", "Uint", DrawPen, "Int", 2)
  DllCall("gdiplus\GdipSetPenEndCap", "Uint", DrawPen, "Int",0x14) ; Arrow Cap
 
  angleList := "0|90|180|270"  ; Ost|Nord|West|Süd
  subtractionX := 10
  subtractionY := 10
  pictW2 := pictW - subtractionX
  pictH2 := pictH - subtractionY
  x0   := pictW2 , y0   := PinY
  x90  := PinX   , y90  := subtractionY
  x180 := subtractionX, y180 := PinY
  x270 := PinX   , y270 := pictH2
  Loop, parse, angleList,|
    Gdip_DrawLine(G, DrawPen, PinX,PinY, x%A_LoopField%, y%A_LoopField%)
  Gdip_DeletePen(DrawPen)
 
  ;=================================================
  ;;-- Raster zeichnen
  ;=================================================
  gridX := 25
  gridY := gridX
  ;;-- Raster-Nullpunkt
  gridX0 := PinX, gridY0 := PinY
 
  ;====================================
  ; Quadrant 1 (oben rechts) 0-90°
  ;====================================
  x := gridX0, gx := 0
  while (x < pictW2)
  {
    x++, gx++
    if (mod(gx, gridx) = 0)
    {
      y := gridY0, gy := 0
      while (y > subtractionY)
      {
        y--, gy++
        if (mod(gy, gridY) = 0)
          drawPoint(G, x, y, c_Coord, 1)
      }
    }
  }
  ;====================================
  ; Quadrant 2 (oben links) 90-180°
  ;====================================
  x := gridX0, gx := 0
  while (x > subtractionX)
  {
    x--, gx++
    if (mod(gx, gridX) = 0)
    {
      y := gridY0, gy := 0
      while (y > subtractionY)
      {
        y--, gy++
        if (mod(gy, gridY) = 0)
          drawPoint(G, x, y, c_Coord, 1)
      }
    }
  }
  ;====================================
  ; Quadrant 3 (unten links) 180-270°
  ;====================================
  x := gridX0, gx := 0
  while (x > subtractionX)
  {
    x--, gx++
    if (mod(gx, gridX) = 0)
    {
      y := gridY0, gy := 0
      while (y < pictH2)
      {
        y++, gy++
        if (mod(gy, gridY) = 0)
          drawPoint(G, x, y, c_Coord, 1)
      }
    }
  }
  ;====================================
  ; Quadrant 4 (unten rechts) 270-360°
  ;====================================
  x := gridX0, gx := 0
  while (x < pictW2)
  {
    x++, gx++
    if (mod(x, gridX) = 0)
    {
      y := gridY0, gy := 0
      while (y < pictH2)
      {
        y++, gy++
        if (mod(gy, gridY) = 0)
          drawPoint(G, x, y, c_Coord, 1)
      }
    }
  }
return
 
drawText:
  Gdip_SetSmoothingMode(G, 1)
 
  ; Textfeld löschen
  Gdip_SetCompositingMode(G, 1) ; set to overdraw
  pBrush := Gdip_BrushCreateSolid(c_Background)
  Gdip_FillRectangle(G, pBrush, xMSG,yMSG, wMSG, hMSG)
  Gdip_DeleteBrush(pBrush)
 
  ; Text schreiben
  if MSG
  {
    Gdip_SetCompositingMode(G, 0) ; switch off overdraw
    drawText(G, MSG, 14, "Left", PEN_COLOR, "Arial", xMSG,yMSG, wMSG, hMSG)
  }
return
 
; Hintergrund zeichnen
drawBackground:
  pBrush := Gdip_BrushCreateSolid(c_Background)
  Gdip_FillRectangle(G, pBrush, 0, 0, pictW, pictH)
  Gdip_DeleteBrush(pBrush)
return
 
initColors:
  A := "0xFF" ; transparity byte
  c_0    := A . "FFFFFF"  ; White
  c_90   := A . "5959ff"  ; Blue
  c_270  := A . "48ff48"  ; Green
  c_180  := A . "FFFF00"  ; Yellow
  c_360  := A . "ff5b5b"  ; Red
  c_Fuchsia    := A . "FF00FF"  ; Lila
  c_Black      := A . "000000"  ; Black
  c_White      := A . "FFFFFF"  ; White
  c_Red        := A . "FF0000"  ; White
  c_Background := A . "505050"  ; Gray
  c_Extent     := A . "AFFFFF"
  c_Coord      := A . "000000"
 
  SetFormat, IntegerFast, H
  c_Extent &= 0xFFFFFF   ; get rid of transparency byte
  c_Coord  &= 0xFFFFFF
  c_Extent += 0x55000000 ; set new transparency byte
  c_Coord  += 0xCC000000
  SetFormat, IntegerFast, D
return
 
;#######################################################################
_ROTATE_STEPWISE_:
  WORKING := True
 
  ANGLE := DRAW_ANGLE + ROTATION_ANGLE
 
  ; Farbe für 0°, 90°, 180°, 270°, 360°
  If ANGLE in 0,90,180,270,360
    PEN_COLOR := c_%ANGLE%
  else
  {
    If (STEP = ROTATION_STEPS) or (STEP = ROTATION_STEPS)
      PEN_COLOR := c_Fuchsia  ; Farbe für letzten Schritt
    else   ; Farbe für laufenden Schritt
      PEN_COLOR := c_White
  }
 
  if (DRAW = "Line")
  {
    if (STEP = 0)  ; clear Canvas
    {
      gosub drawBackground
      gosub drawCoord
      gosub initLine
    }
    DRAW_ANGLE += ROTATION_ANGLE
    gosub rotateLinePoint
    gosub drawLine
 
    MSG := "Step " ++STEP "/" ROTATION_STEPS
  }
  else if (DRAW = "Frame")
  {
    if (STEP = 0)  ; clear Canvas
    {
      gosub drawBackground
      gosub drawCoord
      gosub initFrame
    }
    DRAW_ANGLE += ROTATION_ANGLE
    gosub rotateFramePoints
    gosub drawFrame
 
    ; Drehwinkel-Linie zeichnen
    PEN_COLOR2 := PEN_COLOR
    PEN_COLOR -= 0xCC000000
    ROT_X1L := PinX , ROT_Y1L := PinY
    polar(PinX,PinY, dtr(DRAW_ANGLE), ROTATION_LINE_LENGTH_F, ROT_X2L, ROT_Y2L)
    gosub drawLine
 
    drawPoint(G, ROT_X1F, ROT_Y1F, PEN_COLOR, 4.5*2)
    PEN_COLOR := PEN_COLOR2
 
    MSG := "Step " ++STEP "/" ROTATION_STEPS
  }
  ; Step-Text, Textposition für MSG
  xMSG := 5 , yMSG := 5 , wMSG := 100 , hMSG := 20
  gosub drawText
 
  ; Winkel-Text
  ANGLE := round(rtd(angleFix(dtr(ANGLE))),0)
  MSG := "Angle " . ANGLE . "°"
  ; Textposition für MSG
  xMSG := 5 , yMSG := 30 , wMSG := 100 , hMSG :=20
  gosub drawText
 
  gosub updateCanvas
  WORKING := False
return
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_ROTATE_:
  STOP_WORKING := False
  WORKING := True
  Loop, % ROTATION_STEPS
  {
    if STOP_WORKING
      break
 
    ; clear Canvas
    if (STEP = 0) and (STEP = 0) and (A_Index = 1)
    {
      gosub drawBackground
      gosub drawCoord
      if (DRAW = "Line")
        gosub initLine
      if (DRAW = "Frame")
        gosub initFrame
    }
 
    ANGLE := DRAW_ANGLE + ROTATION_ANGLE
 
    ; Farbe für 0°, 90°, 180°, 270°, 360°
    If ANGLE in 0,90,180,270,360
      PEN_COLOR := c_%ANGLE%
    else
    {
      If (A_Index = ROTATION_STEPS)
        PEN_COLOR := c_Fuchsia  ; Farbe für letzten Schritt
      else   ; Farbe für den laufenden Schritt
        PEN_COLOR := c_White
    }
 
    if (DRAW = "Line")
    {
      DRAW_ANGLE += ROTATION_ANGLE
      gosub rotateLinePoint
      gosub drawLine
    }
    else if (DRAW = "Frame")
    {
      DRAW_ANGLE += ROTATION_ANGLE
      gosub rotateFramePoints
      gosub drawFrame
 
      ; Drehwinkel-Linie zeichnen
      PEN_COLOR2 := PEN_COLOR
      PEN_COLOR -= 0xCC000000
      ROT_X1L := PinX , ROT_Y1L := PinY
      polar(PinX,PinY, dtr(DRAW_ANGLE), ROTATION_LINE_LENGTH_F, ROT_X2L, ROT_Y2L)
      gosub drawLine
 
      drawPoint(G, ROT_X1F, ROT_Y1F, PEN_COLOR, 4.5*2)
      PEN_COLOR := PEN_COLOR2
 
      if (A_Index = ROTATION_STEPS)
        gosub drawFrameExtent
    }
 
    ; Winkel-Text setzen
    ANGLE := round(rtd(angleFix(dtr(ANGLE))),0)
    MSG := "Angle " . ANGLE . "°"
    ; Textposition
    xMSG := 5 , yMSG := 30 , wMSG := 100 , hMSG :=20
    gosub drawText
 
    ; Step-Text
    MSG := "Step " A_Index "/" ROTATION_STEPS
    ; Textposition für MSG
    xMSG := 5 , yMSG := 5 , wMSG := 100 , hMSG := 20
    gosub drawText
 
    gosub updateCanvas
  }
return
;#######################################################################
 
_RotateLine:
  if WORKING or (DRAW = "Frame")
    return
  DRAW := "Line"
  ROTATION_ANGLE := 1  ; Drehwinkel pro Schritt
  ROTATION_STEPS := 360     ; Anzahl Drehungen
 
  GuiControlGet, PRedit1Val,, PRedit1
  if PRedit1Val
    ROTATION_ANGLE := PRedit1Val
  else
    GuiControl,, PRedit1, %ROTATION_ANGLE%
 
  GuiControlGet, PRedit2Val,, PRedit2
  if PRedit2Val
    ROTATION_STEPS := PRedit2Val
  else
    GuiControl,, PRedit2, %ROTATION_STEPS%
 
  gosub _DrawStepwise
  If DRAW_STEPWISE
  {
    if (STEP < ROTATION_STEPS)
      gosub _ROTATE_STEPWISE_
  }
  else
  {
    ROTATION_STEPS -= STEP
    gosub _ROTATE_
  }
return
 
_RotateFrame:
  if WORKING or (DRAW = "Line")
    return
  DRAW := "Frame"
  ROTATION_ANGLE := 30  ; Drehwinkel pro Schritt
  ROTATION_STEPS := 12        ; Anzahl Drehungen
 
  GuiControlGet, PRedit1Val,, PRedit1
  if PRedit1Val
    ROTATION_ANGLE := PRedit1Val
  else
    GuiControl,, PRedit1, %ROTATION_ANGLE%
 
  GuiControlGet, PRedit2Val,, PRedit2
  if PRedit2Val
    ROTATION_STEPS := PRedit2Val
  else
    GuiControl,, PRedit2, %ROTATION_STEPS%
 
  gosub _DrawStepwise
  If DRAW_STEPWISE
  {
    if (STEP < ROTATION_STEPS)
      gosub _ROTATE_STEPWISE_
  }
  else
  {
    ROTATION_STEPS -= STEP
    gosub _ROTATE_
  }
return
 
_DrawStepwise:
  gui,submit,nohide
  DRAW_STEPWISE := PRcheckbox1
return
 
_ResetCanvas:
  ANGLE := False
  DRAW := False
  STEP := 0
  STOP_WORKING := True
  WORKING := False
 
  gosub drawBackground
  gosub drawCoord
  gosub initLine
  gosub initFrame
 
  MSG := "'Ctrl+LButton' to set different Rotation-Point"
  ; Textposition für MSG
  xMSG := 5 , yMSG := 5 , wMSG := Width-10 , hMSG := 20
  PEN_COLOR := c_White
  gosub drawText
 
  gosub updateCanvas
  GuiControl,, PRedit1,
  GuiControl,, PRedit2,
return
 
updateCanvas:
  Critical
  BitBlt(hdc_PRpict1, 0, 0, Width, Height, hdc, 0, 0, 0x00CC0020) ; SRCCOPY
  Critical, off
Return
 
GuiClose:
  ; Select the object back into the hdc
  SelectObject(hdc, obm)
  ; Now the bitmap may be deleted
  DeleteObject(hbm)
  ; Also the device context related to the bitmap may be deleted
  DeleteDC(hdc)
  ; The graphics may now be deleted
  Gdip_DeleteGraphics(G)
 
  ; ...and gdi+ may now be shutdown
  Gdip_Shutdown(pToken)
  ExitApp
return
 
; Function midpt
; Calculate middle point 'Mx,My' of line 'x1,y1 - x2,y2'
; midpt(x1,y1, x2,y2, Byref Mx,Byref My)
; {
  ; Mx := (x1 + x2) / 2
  ; My := (y1 + y2) / 2
; }
 
; Function angle
; Calculate angle of line 'x1,y1 - x2,y2' in radians
; angle(x1,y1, x2,y2)
; {
  ; a := ACos((x2-x1)/((x2-x1)**2+(y2-y1)**2)**0.5)
  ; If (y2-y1) < 0
    ; a := 6.28319 - a
  ; Return a
; }
 
;{ ========= Functions for Rotation =====================
; Function rotatePoint
; Rotate point about z-axis.
; Calculate target point 'Tx,Ty' of point 'x,y' from rotation
; point 'rotX,rotY' through an angle 'rotAng' (rotAng in degrees).
rotatePoint(x,y, rotX,rotY, rotAng, Byref Tx,Byref Ty)
{
  a := angleDeg(rotX,rotY, x,y)
  d := distance(rotX,rotY, x,y)
  polar(rotX, rotY, dtr(a + rotAng), d, Tx, Ty)
}
; Function distance
; Calculate distance between 2 points
distance(x1,y1, x2,y2)
{
  return ((x2-x1)**2+(y2-y1)**2)**0.5
}
; Function angleDeg
; Calculate angle of line 'x1,y1 - x2,y2' in degrees
angleDeg(x1,y1 , x2,y2)
{
  ; Richting holen (Anwendung des Skalarproduktes zur Winkelberechnung)
  a := ACos( (x2-x1) / ((x2-x1)** 2 + (y2-y1)** 2)** 0.5 ) * 57.29578
  If (y2-y1) > 0  ; Den Unteren Halbkreis berechnen
    a := 360 - a
  Return a
}
; Function polar
; Calculate target point 'Tx,Ty' from base point 'x,y'
; in distance 'd' through an angle 'a' (a in radians).
polar(x,y, a, d, Byref Tx,Byref Ty)
{
  Tx := x + d * Cos(a)
  Ty := y - d * Sin(a)
}
; Convert a degree value to radians
dtr(deg)
{
  Return deg * (3.141592653589793 / 180)
}
; Convert a radian value to degrees
rtd(rad)
{
  Return rad * (180 / 3.141592653589793)
}
 
; Force the angle (radian) 0 <= ang < 2pi
; Reduces to [0°, 360°]
; Takes an angle in radians and reduces it to less than 2pi if ang>=2pi
angleFix(ang)
{
  Static pi2 := 6.28319  ; 6.28319 = pi * 2
  if (ang < 0)
    ang += pi2
  else if (ang > pi2)
    ang -= pi2
  Return ang
}
;} ======================================================
 
drawPoint(G, X, Y, C, R:=0.5, LW:=1, Fill:=0)
{
  ; C  = Color
  ; X  = X coordinate
  ; Y  = Y coordinate
  ; X2 = Second X coordinate
  ; Y2 = Second Y coordinate
  ; R  = Radius
  ; LW  = Linewidth
 
  X2 := X
  Y2 := Y
  Xpos := X + R / 2
  Ypos := Y + R / 2
  Width  := X2 - X - R
  Height := Y2 - Y - R
  if Fill
  {
    pBrush := Gdip_BrushCreateSolid©
    Gdip_FillEllipse(G, pBrush, Xpos, Ypos, Width, Height)
    Gdip_DeleteBrush(pBrush)
  }
  else
  {
    pPen := Gdip_CreatePen(C, LW)
    Gdip_DrawEllipse(G, pPen, Xpos, Ypos, Width, Height)
    Gdip_DeletePen(pPen)
  }
}
 
drawText(G, str, size, options, colr, font, x, y, w, h, measure=0)
{
  ; Align options: Near,Left,Centre,Center,Far,Right,
  ;                Top,Up,Bottom,Down,vCentre,vCenter
  ; Style options: Regular,Bold,italic,Bolditalic,underline,strikeout
  colr := "c" . RegExReplace(colr, "^0x", "")
  options2 = X%x% Y%y% S%size% %options% %colr%
  Return Gdip_TextToGraphics(G, str, options2, font, w, h, measure)
}
 
MSGH(wParam, lParam)
{
  Gosub, updateCanvas
}
 
;=======================================================================
#IfWinActive, PinRotate-Test
 
  ; Uncomment for quick reload while programing
  ; #r::
    ; Reload
  ; return
 
  ^LButton::
    ;;-- Drehpunkt versetzen
    GuiControlGet, PRedit1Val,, PRedit1
    GuiControlGet, PRedit2Val,, PRedit2
    CoordMode, Mouse, Client
    MouseGetPos, mx, my
    PinX := mx, PinY := my
    gosub _ResetCanvas
    GuiControl,, PRedit1, %PRedit1Val%
    GuiControl,, PRedit2, %PRedit2Val%
  return
 
  #s::
    Path := A_ScriptDir . "\"
    if (DRAW = "Line")
      Name := "PinRotate-Test-Line"
    else if (DRAW = "Frame")
      Name := "PinRotate-Test-Frame"
    else
      Name := "PinRotate-Test"
    Ext  := ".png"
    outFile := Path . Name . Ext
    pBitmapHBM := Gdip_CreateBitmapFromHBITMAP(hbm)
    Gdip_SaveBitmapToFile(pBitmapHBM, outFile)
    ; The bitmap can be deleted
    Gdip_DisposeImage(pBitmapHBM)
    MsgBox, % outFile . " gespeichert!"
  return
#IfWinActive
 
WM_LBUTTONDOWN()
{
  PostMessage, 0xA1, 2,,, A ;LeftClick to drag around
}
 
Esc::
  ExitApp