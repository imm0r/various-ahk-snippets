#include shinsoverlayclass.ahk
#MaxThreads 10
SetBatchLines -1

dpi := DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
sx := DllCall("GetSystemMetrics", "int", 76, "int")
sy := DllCall("GetSystemMetrics", "int", 77, "int")
sw := DllCall("GetSystemMetrics", "int", 78, "int")
sh := DllCall("GetSystemMetrics", "int", 79, "int")
DllCall("SetThreadDpiAwarenessContext", "ptr", dpi, "ptr")

x := floor(sw * 0.2), y := sy, h := sh
oL := new ShinsOverlayClass(x, y, sw, h)

DllCall("QueryPerformanceFrequency", "int64*", frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", start:=0)
while (y < sy + sh) {
   if (oL.BeginDraw()) {
      oL.DrawText(f := A_Index, x, y, 24, 0xFFFFFFFF, "Arial", "olFFFF0000")
      oL.EndDraw()
   }
   y++
}
DllCall("QueryPerformanceCounter", "int64*", end:=0)

tms1 := round((end - start) / frequency * 1000, 2)
fps1 := round(f / ((end - start) / frequency), 2)
bench1 := "with outlines scene took " tms1 " ms and got " fps1 " fps"

x := floor(sw * 0.4), y := sy, h := sh

DllCall("QueryPerformanceFrequency", "int64*", frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", start:=0)
while (y < sy + sh) {
   if (oL.BeginDraw()) {
      oL.DrawText(f := A_Index, x, y, 24, 0xFFFF00FF, "Arial")
      oL.EndDraw()
   }
   y++
}
DllCall("QueryPerformanceCounter", "int64*", end:=0)

tms2 := round((end - start) / frequency * 1000, 2)
fps2 := round(f / ((end - start) / frequency), 2)
bench2 := "without outlines scene took " tms2 " ms and got " fps2 " fps"
conc := "using outlines is " round(fps2 / fps1, 2) "% slower`n`nF12 to reload`nESC to exit"

if (oL.BeginDraw()) {
   oL.DrawText("DrawText performance benchmark:", 400, 400, 30, 0xFF00FF00, "Arial", "w650 olFF0000FF")
   oL.DrawText(bench2 "`n" bench1, 400, 450, 24, 0xFFFFFF00, "Tahoma", "w650 aRight olFF000000")
   oL.DrawText(conc, 400, 510, 24, 0xFF363636, "Arial", "w650 olFFFFFFFF")
   oL.EndDraw()
}

F12::Reload
ESC::ExitApp