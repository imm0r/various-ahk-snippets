#singleinstance,force
setbatchlines,-1
settitlematchmode,2

#include <shinsoverlayclass>

overlay := new ShinsOverlayClass(50,50,1100,130) ;initally create a static overlay

rot := 0 ;rotation value for drawing the circling ellipse
len := (overlay.width > overlay.height ? overlay.height : overlay.width) / 4 ;length to rotate around
stickFrame := 0
nextStickFrame := a_tickcount + 100
stickRot := 0 ;rotation for stickman
settimer,draw,10 ;overlay essentially requires a timer if attaching to window, as the window checks are done in the BeginDraw() function
return

f1::
overlay.AttachToWindow("ahk_id " GetHwnd( "L2R(64)", "dnplayer.exe" ), 2)
len := (overlay.width > overlay.height ? overlay.height : overlay.width) / 4
return

esc::exitapp


draw:
if (overlay.BeginDraw()) { ;must always be called to start drawing; BeginDraw() also handles window checks, for position/size/foreground change (if attached)
	
	if (overlay.attachHwnd) { ;if the overlay is attached to a window
		
		;update some math variables
		rot+= 0.02
		if (rot > 6.28)
			rot := 0
		x := (overlay.width/2) + cos(rot) * len
		y := (overlay.height/2) + sin(rot) * len
		
		;draw rectangle around window using real coordinates
		;otherwise by default it may include the invisible borders
		rx := overlay.realX
		ry := overlay.realY
		rx2 := overlay.realX2
		ry2 := overlay.realY2
		rw := overlay.realWidth
		rh := overlay.realHeight
		
		if (overlay.GetMousePos(mx,my,1)) {
			;draw lines to the mouse position			
			overlay.DrawLine(rx+1,my,rx2,my,0xFF000000,3)
			overlay.DrawLine(mx,ry+1,mx,ry2,0xFF000000,3)
			overlay.DrawLine(rx+1,my,rx2,my,0xFF3EF9CE,1)
			overlay.DrawLine(mx,ry+1,mx,ry2,0xFF3EF9CE,1)
		}

		overlay.DrawRectangle(rx+1,ry+1,rw-1,rh-1,0xFFFF0000,2) ;draw a rectangle around the window
		
		overlay.DrawText("L2R Overlay by AidMaiden", overlay.width // 2, 4, 18, 0xFF000000, "Bahnschrift", "dsFFFF0000") ;draw text that grows and shrinks
		overlay.DrawText("Press ESC to close!", 10, 10 + (24+(rot*3)), 24 + (rot*3), 0xFF000000, "Bahnschrift", "dsFFFFFFFF") ;draw text that grows and shrinks
	} else {
		overlay.FillRectangle(0,0,overlay.width,overlay.height,0xaa000000)
		overlay.DrawText("Press F1 to attach the overlay to a window to begin!`nYou can do this multiple times!",0,0,40,0xFFFFFFFF,"Courier","dsFF000000")
	}
	overlay.EndDraw() ;must always be called to end the drawing and update the overlay
}
return
