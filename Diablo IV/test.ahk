#NoEnv
#singleinstance, force
setbatchlines, -1
settitlematchmode, 2
SetControlDelay -1

#include <shinsoverlayclass>
elipseOL := new ShinsoverlayClass(1, 1, A_ScreenWidth, A_ScreenHeight, 1, vsync:=0, clickThrough:=1, taskBarIcon:=0)
if (elipseOL.BeginDraw()) {
  elipseOL.DrawEllipse(A_ScreenWidth / 2, A_ScreenHeight / 2, A_ScreenWidth  / 2, A_ScreenHeight / 2, 0x633b0532, 8)
  elipseOL.EndDraw()
}


; Define the ellipse's center coordinates
xCenter := A_ScreenWidth / 2
yCenter := A_ScreenHeight / 2

; Define the ellipse's major and minor axes
majorAxis := A_ScreenWidth / 2
minorAxis := A_ScreenHeight / 2

idxCircle := 1

; Define the ellipse's rotation angle (in radians)
rotationAngle := 0
Theta := 360
Deg := 15
Pi := ATan(1) * 4

; Define the mouse move speed (in milliseconds)
moveSpeed := 0

SetTimer, MouseCircle, On

MouseCircle:
  ; Move the mouse in an ellipse
  ; Calculate the ellipse's parametric equation
  t := (idxCircle / (Theta / Deg) * 2) * Pi
  x := xCenter + majorAxis * Cos(t) * Cos(rotationAngle) - minorAxis * Sin(t) * Sin(rotationAngle)
  y := yCenter + majorAxis * Cos(t) * Sin(rotationAngle) + minorAxis * Sin(t) * Cos(rotationAngle)
  idxCircle++

  ; Calculate a little bit of randomness
  if (x < (A_ScreenWidth - 10))
    x := x + random(-10,10)
  if (y < (A_ScreenHeight - 5))
    y := y + random(-5,5)

  ; Move the mouse to the calculated coordinates
  MouseMove, % x, % y, % moveSpeed
return

ESC::ExitApp