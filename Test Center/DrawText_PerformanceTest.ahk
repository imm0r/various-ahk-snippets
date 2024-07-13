#include shinsoverlayclass.ahk
SetBatchLines -1

dpi := DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
sx := DllCall("GetSystemMetrics", "int", 76, "int")
sy := DllCall("GetSystemMetrics", "int", 77, "int")
sw := DllCall("GetSystemMetrics", "int", 78, "int")
sh := DllCall("GetSystemMetrics", "int", 79, "int")
DllCall("SetThreadDpiAwarenessContext", "ptr", dpi, "ptr")

; with outlined text
x := floor(sw * 0.45), y := sy, h := sh
oL := new ShinsOverlayClass(x, y, sw, h)

DllCall("QueryPerformanceFrequency", "int64*", frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", start:=0)
while (y < sy + sh) {
   if (oL.BeginDraw()) {
      oL.DrawText("outlined text - " f := A_Index, x, y, 24, 0xFFFFFFFF, "Arial", "olFFFF0000")
      oL.EndDraw()
   }
   y++
}
DllCall("QueryPerformanceCounter", "int64*", end:=0)

tms1 := round((end - start) / frequency * 1000, 2)
fps1 := round(f / ((end - start) / frequency), 2)
bench1 := "with outlines scene took " tms1 " ms and got " fps1 " fps"

; without outlined text
x := floor(sw * 0.45), y := sy, h := sh

DllCall("QueryPerformanceFrequency", "int64*", frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", start:=0)
while (y < sy + sh) {
   if (oL.BeginDraw()) {
      oL.DrawText("normal text - " f := A_Index, x, y, 24, 0xFFFF00FF, "Arial")
      oL.EndDraw()
   }
   y++
}
DllCall("QueryPerformanceCounter", "int64*", end:=0)

tms2 := round((end - start) / frequency * 1000, 2)
fps2 := round(f / ((end - start) / frequency), 2)
bench2 := "without outlines scene took " tms2 " ms and got " fps2 " fps"
conc := "using outlines is " round(fps2 / fps1, 2) "% slower"

; final result
if (oL.BeginDraw()) {
   oL.FillRoundedRectangle(floor(sw * 0.25), floor(sh * 0.7) - 10,695,180,5,2,0x66151A24)
   oL.DrawText("DrawText performance benchmark:", floor(sw * 0.25), floor(sh * 0.7), 30, 0xFF00FF00, "Arial", "w695 aCenter olFF0000FF")
   oL.DrawText(bench2 "`n" bench1, floor(sw * 0.26), floor(sh * 0.7) + 50, 24, 0xFFFFFF00, "Tahoma", "w650 aRight olFF000000")
   oL.DrawText(conc, floor(sw * 0.25), floor(sh * 0.7) + 120, 24, 0xFFFFFFFF, "Arial", "w695 aCenter olFF363636")
   oL.EndDraw()
}

F12::Reload
ESC::ExitApp
