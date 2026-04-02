#NoEnv
#singleinstance, force
setbatchlines, -1
settitlematchmode, 2
SetControlDelay -1

#InstallKeybdHook
#InstallMouseHook

#include gui.ahk
#include <ocr>
#include <Class_Color>
#include <lib_gdipSwitch>
#include <shinsoverlayclass>
#Include <stringsimilarity>
#include %A_ScriptDir%\plugins\AreaLocations.ahk
#include %A_ScriptDir%\plugins\affixes.ahk

if (!WinExist("Diablo IV")) {
  msgbox % "Please run Diablo IV and press OK to reload"
  reload
}

options := []
GDIP_Startup()
sourceWidth := 73                  ;width of each skill button
sourcePadding := 11                ;padding between skills
barY := 1304                       ;top Y coordinate of skill buttons
barX := A_ScreenWidth // 2        ;skill bar Center
MaxLuminosity := 0
MaxSaturation := 0
MinLuminosity := 255
MinSaturation := 255
cooldownSaturation := 158
cooldownSaturation2 := 99
inactiveSaturation := 137

pos := [], pos.tp := [], pos.chat := []
pos.tp.x := 1630
pos.tp.y1 := 420
pos.tp.y2 := 465
pos.tp.hue_min := 60
pos.tp.hue_max := 65
pos.tp.sat_min := 205
pos.tp.sat_max := 225
pos.chat.x := 20
pos.chat.y := 1380

clr := [], clr.tp := [], clr.chat := []
clr.tp.rbg := 0x727415
clr.tp.hue_min := 60
clr.tp.hue_max := 65
clr.tp.sat_min := 205
clr.tp.sat_max := 225
clr.chat.rgb := 0x262425
clr.chat.hue := -40
clr.chat.sat := 20

; Array holding the position for the mapName
mapName := []
mapName.width := 300, mapName.heigth := 40
mapName.x := 3050, mapName.y := 15

; Array holding the position for masterworking
aMasterWorking := [], aMasterWorking.reset := [], aMasterWorking.upgrade := [], aMasterWorking.confirm := [], aMasterWorking.close := []
aMasterWorking.reset.x := 575, aMasterWorking.reset.y := 465
aMasterWorking.upgrade.x := 660, aMasterWorking.upgrade.y := 1200
aMasterWorking.confirm.x := 365, aMasterWorking.confirm.y := 1265
aMasterWorking.close.x := 470, aMasterWorking.close.y := 1095

aSkills := []
lastX := 0, lastY := 0, firstTime := 1
cX := A_ScreenWidth // 2, cY := A_ScreenHeight // 2
Pi := ATan(1) * 4, Theta := 0, Radius := 1455

; deactivating the overlays on start
toggle := 0, CircleAttackActive := 0, mPosOverlay := 0, infoOverlay := 0, potCounter := 0
toggle_MousePos := 0, toggle_autoHP := 0

; properties of the different overlays:
; Helltide overlay
HT_overlayWidth := 400, HT_overlayHeight := 60
HT_overlayX := (A_ScreenWidth // 2) - (HT_overlayWidth // 2)
HT_overlayY := (A_ScreenHeight // 1.5) - (HT_overlayHeight // 2)

; BuffWatch overlay3   
buffs_overlayWidth := 300, buffs_overlayHeight := 135
buffs_overlayX := A_ScreenWidth - buffs_overlayWidth - 25
buffs_overlayY := A_ScreenHeight - 450

; Character State overlay
overlay := [], overlay.state := []
overlay.state.w := 300, overlay.state.h := 60
overlay.state.X := A_ScreenWidth - overlay.state.w - 25
overlay.state.Y := A_ScreenHeight - 185

; Mouse Position overlay  
mPos_overlayWidth := 300, mPos_overlayHeight := 100
mPos_overlayX := A_ScreenWidth - mPos_overlayWidth - 25
mPos_overlayY := A_ScreenHeight - 120

; timed informational overlay
HT_info_overlayWidth := 400, HT_info_overlayHeight := 70
HT_info_overlayX := (A_ScreenWidth // 2) - (HT_info_overlayWidth // 2)
HT_info_overlayY := (A_ScreenHeight // 3.6313) - (HT_info_overlayHeight)

; masterworking global init
mwStep := 0

; string locations
strings := [], strings.locations := [], strings.locations.masterworking := []
strings.locations.masterworking.x := 50, strings.locations.masterworking.y := 850
strings.locations.masterworking.width := 850, strings.locations.masterworking.heigth := 160

oStringSimilarity := new stringsimilarity()

; init D4 hwnd and activate it
d4hWnd := GetHwnd("Diablo IV", "Diablo IV.exe")
WinActivate, % "ahk_id " d4hWnd

Gui, 1: Color, 0xAA36373A
Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
WinSet, TransColor, 0x0036373A
menuOverlay := new ShinsoverlayClass(3020, 42, 389, 27, 1, vsync:=0, clickThrough:=0, taskBarIcon:=0, guiID:=1)

if (menuOverlay.BeginDraw()) {
  menuOverlay.DrawRectangle(1, 1, 387, 26, 0x55838D93, 3)
  menuOverlay.FillRectangle(2, 2, 384, 23, 0xAA13110F)
  menuOverlay.EndDraw()
}

; creating the different overlays
options.AutoHeal := New GdipCheckbox(x := 2, y := 2, w := 198, Text := "Auto Heal", Font:="Bahnschrift", FontSize:= "18 Bold", FontColor:="FFD700", Window:="1", Background_Color:="13110F", State:=0, Label:="AutoHeal1")
options.WatchBuffs := New GdipCheckbox(x := 200, y := 2, w := 182, Text := "Watch Buffs", Font:="Bahnschrift", FontSize:= "18 Bold", FontColor:="FFD700", Window:="1", Background_Color:="13110F", State:=0, Label:="WatchBuffs")

buffs_overlay := new ShinsoverlayClass("Diablo IV")
mPos_overlay := new ShinsoverlayClass("Diablo IV")
info_overlay := new ShinsoverlayClass("Diablo IV")
olAction := new ShinsoverlayClass("Diablo IV")
olState := new ShinsoverlayClass("Diablo IV")
elipseOL := new ShinsoverlayClass("Diablo IV",,,1)

;SetTimer, memWatch, 1500

;CmdGui()
return


#include %A_ScriptDir%\plugins\gLabels.ahk

;Hotkeys
F11::reload
F12::exitapp

; Masterworking
; upgrading x4
F7::
  if (WinExist("ahk_id " d4hWnd)) {
    if infoOverlayActive
      SetTimer, kill_InfoOverlay, -1
    if (WinActive("ahk_id " d4hWnd)) {

      MWGui()
      /*
      Loop, 4
      {
        ControlClick, % "x" aMasterWorking.upgrade.x " y" aMasterWorking.upgrade.y, % "ahk_id " d4hWnd,,,, Pos
        Sleep, % random(250, 370)
      }
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
      sleep, % random(1410, 1590)
      res_mwCrit := readMasterworkingCrit(d4hWnd)
      clipboard := res_mwCrit
      InfoSplash(res_mwCrit)
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
      */
    }
  }
return

mw_reset() {
  global
  if (WinExist("ahk_id " d4hWnd)) {
    if infoOverlayActive
      SetTimer, kill_InfoOverlay, -1
    WinActivate, % "ahk_id " d4hWnd
    sleep, 50
    if (WinActive("ahk_id " d4hWnd)) {
      GuiControl, , ActionLog, % "reset masterworking rank"
      ControlClick, % "x" aMasterWorking.reset.x " y" aMasterWorking.reset.y, % "ahk_id " d4hWnd,,,, Pos
      sleep, % random(70, 110)
      ControlClick, % "x" aMasterWorking.confirm.x " y" aMasterWorking.confirm.y, % "ahk_id " d4hWnd,,,, Pos
      Sleep, % random(175, 320)
    }
  }
}
mw_upgrade() {
  global
  if (WinExist("ahk_id " d4hWnd)) {
    if infoOverlayActive
      SetTimer, kill_InfoOverlay, -1
    WinActivate, % "ahk_id " d4hWnd
    sleep, 50
    if (WinActive("ahk_id " d4hWnd)) {
      Loop, 4
      {
        ControlClick, % "x" aMasterWorking.upgrade.x " y" aMasterWorking.upgrade.y, % "ahk_id " d4hWnd,,,, Pos
        Sleep, % random(250, 370)
        GuiControl, , CurrMWlvl, % mwStep + A_Index "/12"
        GuiControl, , ActionLog, % "upgrade masterworking rank"
      }
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
      sleep, % random(1410, 1590)
      res_mwCrit := readMasterworkingCrit(d4hWnd)
      clipboard := res_mwCrit
      InfoSplash(res_mwCrit)
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
      return, % res_mwCrit
    }
  }
}

; reset
F8::
  if (WinExist("ahk_id " d4hWnd)) {
    if infoOverlayActive
      SetTimer, kill_InfoOverlay, -1
    if (WinActive("ahk_id " d4hWnd)) {
      ControlClick, % "x" aMasterWorking.reset.x " y" aMasterWorking.reset.y, % "ahk_id " d4hWnd,,,, Pos
      sleep, % random(70, 110)
      ControlClick, % "x" aMasterWorking.confirm.x " y" aMasterWorking.confirm.y, % "ahk_id " d4hWnd,,,, Pos
      Sleep, % random(175, 320)
      Loop, 4
      {
        ControlClick, % "x" aMasterWorking.upgrade.x " y" aMasterWorking.upgrade.y, % "ahk_id " d4hWnd,,,, Pos
        Sleep, % random(250, 370)
      }
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
      sleep, % random(1410, 1590)
      res_mwCrit := readMasterworkingCrit(d4hWnd)
      clipboard := res_mwCrit
      InfoSplash(res_mwCrit)
      ControlClick, % "x" aMasterWorking.close.x " y" aMasterWorking.close.y, % "ahk_id " d4hWnd,,,, Pos
    }
  }
return

F9::
  clipboard := readMasterworkingCrit(d4hWnd)
return

; Debugging Stuff
F10::
  ;BuffWatchPerformance := dbgFeatures()
  ;msgbox, % "BuffWatch Performance`n`n100 itterations took: " BuffWatchPerformance " ms`naverage loop took: " buffwatchperformance / 100 "ms"
return

; Circle Attack
F1::
  CoordMode, Mouse, Screen
  StartTime := A_TickCount

  ; Define the ellipse's center coordinates
  xCenter := A_ScreenWidth / 2
  yCenter := A_ScreenHeight / 2
  
  ; Define the ellipse's major and minor axes
  majorAxis := (A_ScreenWidth / 2) * (sliderEllipse / 100)
  minorAxis := (A_ScreenHeight / 2) * (sliderEllipse / 100)
  
  idxCircle := 1
  
  ; Define the ellipse's rotation angle (in radians)
  rotationAngle := 0
  Theta := 360
  Deg := 15
  Pi := ATan(1) * 4
  
  ; Calculate the ellipse's parametric equation
  t := (idxCircle / (Theta / Deg) * 2) * Pi
  
  ; Define the mouse move speed (in milliseconds)
  moveSpeed := 0
  
  ;ControlSend, , {Ctrl down}, % "ahk_id " d4hWnd
  SendInput, {Ctrl down}

  SetTimer, main, 500
  SetTimer, CircleAttack, 50
  SetTimer, CircleAttackCancel, -57500
  
  if (info_overlay.BeginDraw()) {
    info_overlay.FillRectangle(HT_info_overlayX, HT_info_overlayY, HT_info_overlayWidth, HT_info_overlayHeight, 0x77000000)
    info_overlay.DrawText("Helltide Accursed Ritual Module!`nAdd Phase Circle Attack", HT_info_overlayX, HT_info_overlayY + 5, 22, 0xAAFFD700, "Bahnschrift", "w400,aCenter,olFF000000,bold")
    info_overlay.EndDraw()
  }

  if (olAction.BeginDraw()) {
    olAction.DrawRectangle(HT_overlayX, HT_overlayY, HT_overlayWidth, HT_overlayHeight, 0x55336699, 4)
    olAction.FillRectangle(HT_overlayX, HT_overlayY, HT_overlayWidth, HT_overlayHeight, 0x55000000)
    olAction.DrawText("CircleAttack active`nHelltide boss spawning in " round(57 - ((A_TickCount - StartTime) / 1000.0), 1) " seconds...", HT_overlayX, HT_overlayY + 5, 20, 0x4a9733, "Bahnschrift", "w400,aCenter")
    olAction.EndDraw()
  }

  if (elipseOL.BeginDraw()) {
      elipseOL.DrawEllipse(A_ScreenWidth / 2, A_ScreenHeight / 2, ellipseWidth, ellipseHeight, 0xb4275132, 8)
      elipseOL.EndDraw()
  }
  
  SetTimer, kill_InfoOverlay, -2500
Return

F2::
  toggle_autoHP  := !toggle_autoHP
  if (toggle_autoHP) {
    InfoSplash("AUTOHEAL ACTIVATED!")
    SetTimer, autoheal, 100
  } else {
    InfoSplash("AUTOHEAL STOPPED!")
    settimer,autoheal, off
  }
return

F3::
  toggle_MousePos := !toggle_MousePos
  if (toggle_MousePos) {
    mPosOverlay := 1
    SetTimer, MousePosDisplay, 100
  } else {
    settimer,MousePosDisplay, off
    mPos_overlay.BeginDraw()
    mPos_overlay.EndDraw()
  }
return
  
WatchBuffs:
F4::
  WinActivate, % "ahk_id " d4hWnd
  sleep, 10
  if (options.watchbuffs.FromInt = false)
    (options.watchbuffs.state:=!options.watchbuffs.state)?(options.watchbuffs.Draw_On()):(options.watchbuffs.Draw_Off())
  if (options.watchbuffs.state) {
    InfoSplash("WatchBuffs ACTIVATED!")
    ;options.WatchBuffs.Draw_On()
    SetTimer, WatchActivebuffs, on
  } else {
    InfoSplash("WatchBuffs STOPPED!")
    ;options.WatchBuffs.Draw_Off()
    buffs_overlay.BeginDraw()
    buffs_overlay.EndDraw()
    settimer, WatchActivebuffs, off
  }
  options.watchbuffs.FromInt := false
  WinActivate, % "ahk_id " d4hWnd
return
  
F5::
  /*
  MouseGetPos, x, y
  MouseMove, 1482, 1172, 1
  PixelGetColor, tmp_curClr, 1482, 1172, Fast RGB
  clipboard := x ", " y " - " tmp_curClr
  rndSkill := random(1,6)
  msgbox, % "Skill: " rndSkill "`ncolor: " aSkills[rndSkill].clr "`nhue: " aSkills[rndSkill].hue "`nsaturation: " aSkills[rndSkill].saturation "`non Cooldown: " aSkills[rndSkill].onCD "`nis useable: " aSkills[rndSkill].rdy
  */
  msgbox, % "Benchmark for chatOpen, isTele and isInTown starts now."
  WinActivate, % "ahk_id " d4hWnd
  sleep, 100
  critical, On
  QPC( True )
  loop, 500
    stateChat := isChatOpen()
  chat_perfTotalTime := QPC( False )
  QPC( True )
  loop, 500
    stateTele := isChatOpen()
  tele_perfTotalTime := QPC( False )
  QPC( True )
  loop, 500
    stateTown := isChatOpen()
  town_perfTotalTime := QPC( False )
  critical, Off
  msgbox, % "Benchmark completed."

  OutputDebug, % "Function Benchmark (1000 itterations):`n-----------------------------------------------`nisChatOpen (tot/avg)`t:" round(chat_perfTotalTime, 2) " s / " chat_perfTotalTime / 500 * 1000 " ms`nisTeleporting (tot/avg)`t:" round(tele_perfTotalTime, 4) " s / " tele_perfTotalTime / 500 * 1000 " ms`nisInTown (tot/avg)`t:" round(town_perfTotalTime, 2) " s / " town_perfTotalTime / 500 * 1000 " ms"
return

~b::
  if (WinExist("ahk_id " d4hWnd)) {
    if (WinActive("ahk_id " d4hWnd)) {
      if !isChatOpen() {
        ControlSend, , {e down}, % "ahk_id " d4hWnd
        hBitmap := HBitmapFromScreen(mapName.x, mapName.y, mapName.width, mapName.heigth)
        pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
        DllCall("DeleteObject", "Ptr", hBitmap)
        curMapOrig_ := ocr(pIRandomAccessStream, "FirstFromAvailableLanguages")
        
        MouseMove, 1710, 740, % random(2, 8)
        ControlSend, , {e up}, % "ahk_id " d4hWnd
        curMapOrig := ""
        while (curMapOrig = "")
        { 
          hBitmap := HBitmapFromScreen(mapName.x, mapName.y, mapName.width, mapName.heigth)
          pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
          DllCall("DeleteObject", "Ptr", hBitmap)
          _curMapOrig := ocr(pIRandomAccessStream, "FirstFromAvailableLanguages")
          if (_curMapOrig != curMapOrig_)
            curMapOrig := _curMapOrig
        }
        if (tFound := inStr(curMapOrig, " ("))
          curMapName := SubStr(curMapOrig, 1 , tFound - 1)
        else
          curMapName := curMapOrig
        curMapName := StrReplace(curMapName, "`n")
        
        Blockinput, 1
        ; open map
        ControlSend, , {Tab}, % "ahk_id " d4hWnd
        sleep, % random(160, 320)
        
        ; click reset dungeons
        ControlClick, % "x" random(3025, 3185) " y" random(1165, 1150), % "ahk_id " d4hWnd,,,, Pos
        sleep, % random(80, 120)
        
        ; click accept
        ControlClick, % "x" random(1550, 1685) " y" random(865, 845), % "ahk_id " d4hWnd,,,, Pos
        sleep, % random(280, 320)
        
        ; close map
        ControlSend, , {Tab}, % "ahk_id " d4hWnd
        sleep, % random(80, 120)
        
        ; Boss entries
        if (curMapName == "Hakan's Oasis") {
          strUberBoss := Duriel
          MouseMove, % random(1400, 1551), % random(214, 593), % random(2, 8)   ; Duriel
        }
        else if (curMapName == "Orbei Monastery") {
          strUberBoss := "Grigor"
          MouseMove, % random(1812, 2033), % random(314, 382), % random(2, 8)   ; Grigor
        }
        else if (curMapName == "The Tree of Whispers") {
          strUberBoss := "Varshan"
          MouseMove, % random(1825, 1854), % random(475, 484), % random(2, 8)   ; Varshan
        }
        else if (curMapName == "Kasama") {
          strUberBoss := "Lord Zir"
          MouseMove, % random(1825, 1854), % random(475, 484), % random(2, 8)   ; Lord Zir
        }
        else {
          Blockinput, 0
          msgbox, % "Couldn't get your current location!`n`nFound Location: " curMapName
        }
          
        MouseClick
        Blockinput, 0
          
        InfoSplash("Location found: " curMapName "`n`n" strUberBoss " resetted and " curMapName " reentered!")
      }
    }
  }
return
  
~x::
  if (CircleAttackActive)
    SetTimer, CircleAttackCancel, -1
return


/*
~f::
  PixelGetColor, Res_pixelClr1, % pos.tp.x, % pos.tp.y1
  SplitBGR2HSL(Res_pixelClr1, hue1, sat1, Luminosity)
  PixelGetColor, Res_pixelClr2, % pos.tp.x, % pos.tp.y2
  SplitBGR2HSL(Res_pixelClr2, hue2, sat2, Luminosity)
  
  state := []
  if (hue1 >= pos.tp.hue_min and hue1 <= pos.tp.hue_max) || (hue2 >= pos.tp.hue_min and hue2 <= pos.tp.hue_max)
    state.isTeleporting := "yeah"
  else
    state.isTeleporting := "nope"
  mousemove, pos.tp.x, pos.tp.y
  clipboard := "clr: " Res_pixelClr " = " clr.tp "`nhue: " hue1 " / " hue2 " - " pos.tp.hue "`nsat: " sat1 " / " sat2 " - " pos.tp.sat
  msgbox, % "clr: " Res_pixelClr " = " clr.tp "`nhue: " hue1 " / " hue2 " - " pos.tp.hue_min " / " pos.tp.hue_max "`nsat: " sat1 " / " sat2 " - " pos.tp.sat_min " / " pos.tp.sat_max "`n`nis teleporting: " state.isTeleporting
return
*/

~v::
  clipboard := ""
  MouseMove, 20, 1380
  MouseGetPos, pxlCoord_lowHPX, pxlCoord_lowHPY
  PixelGetColor, Res_pixelClr, % pxlCoord_lowHPX, % pxlCoord_lowHPY, RGB
  SplitBGR2HSL(Res_pixelClr, Hue, Saturation, Luminosity)
  clipboard := "; x: " pxlCoord_lowHPX "`ty: " pxlCoord_lowHPY "`n`n; clr: "Res_pixelClr "`thue: " Hue "`tsat: " Saturation
  
  ;SetFormat, IntegerFast, Hex
  ;c := new Color(Color.Unpack(Res_pixelClr))
  ;MsgBox % "RGB: " FHEX(Color.Pack(c.RGB)) "`nBGR: " FHEX(Color.Pack(c.BGR)) "`nHSV: " FHEX(Color.Pack(c.HSV)) "`n`nHue: " c.HUE "`nSat: " c.Saturation

  ; full HP
  ; clr: 0x811620 hue: -6	sat: 212
  ; clr: 0xCC2731	hue: -4	sat: 206
  ; clr: 0x971B22	hue: -3	sat: 209
  ; full HP with barrrier
  ; clr: 0x75131D	hue: -6	sat: 214
  ; low HP
  ; clr: 0x111311	hue: 120	sat: 27
  ; clr: 0x24201C	hue: 30	sat: 57
  ; low HP with Barrier
  ; clr: 0x111315	hue: 210	sat: 49
  ; clr: 0x111318	hue: 223	sat: 74

  /*
  PixelGetColor, Res_pixelClr, % barX - 215 + (2 * (sourceWidth + sourcePadding + 0.5)), % barY
  SplitBGR2HSL(Res_pixelClr, Hue, Saturation, Luminosity)
  clipboard := Hue "`n" Saturation
  if (sklIdx > 5)
    sklIdx := 0
  if (mPosOverlay) {
    MouseMove, % barX - 210 + (sklIdx * (sourceWidth + sourcePadding)), % barY, % random(2, 4)
    clipboard := barX - 210 + (sklIdx * (sourceWidth + sourcePadding))", " barY " - " pixelClr
  }
  sklIdx++
  */
return

; Timer Subs
CircleAttackCancel:
  if (info_overlay.BeginDraw()) {
    info_overlay.DrawRectangle(HT_info_overlayX, HT_info_overlayY, HT_info_overlayWidth, HT_info_overlayHeight, 0x55336699, 4)
    info_overlay.FillRectangle(HT_info_overlayX, HT_info_overlayY, HT_info_overlayWidth, HT_info_overlayHeight, 0x33FF0000)
    info_overlay.DrawText("Helltide Accursed Ritual Module!`nfeature stopped!", HT_info_overlayX, HT_info_overlayY + 5, 22, 0xAAFFD700, "Bahnschrift", "w400,aCenter,olFF000000,bold")
    info_overlay.EndDraw()
  }

  if (elipseOL.BeginDraw()) {
    elipseOL.EndDraw()
  }  

  olAction.BeginDraw()
  olAction.EndDraw()

  SetTimer, kill_InfoOverlay, -2500
  SetTimer, CircleAttack, off
  SetTimer, main, off
  
  CircleAttackActive := 0
  sleep, 400
  SendInput, {Ctrl up}
  MouseMove, % (A_ScreenWidth // 2), % (A_ScreenHeight // 2), % random(2, 4)
return
    
CircleAttack:
  if !WinActive("ahk_id " d4hWnd) {
    SetTimer, CircleAttackCancel, -1
  } else {
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
    SendInput {5}
  }
  CircleAttackActive := 1
return

main:
  if (olAction.BeginDraw()) {
    ;olAction.DrawRectangle(HT_overlayX, HT_overlayY, HT_overlayWidth, HT_overlayHeight, 0x55336699, 4)
    ;olAction.FillRectangle(HT_overlayX, HT_overlayY, HT_overlayWidth, HT_overlayHeight, 0x55000000)
    olAction.DrawText("CircleAttack active`nHelltide boss spawning in " round(57 - ((A_TickCount - StartTime) / 1000.0), 0) " seconds...", HT_overlayX, HT_overlayY + 5, 20, 0x66FFFFFF, "Bahnschrift", "w400,aCenter")
    olAction.EndDraw()
  }
return
  
memWatch:
  if (olState.BeginDraw()) {
    olState.DrawRectangle(overlay.state.x, overlay.state.y, overlay.state.w, overlay.state.h, 0x55336699, 4)
    olState.FillRectangle(overlay.state.x, overlay.state.y, overlay.state.w, overlay.state.h, 0x55000000)
    Process, Exist, % "autohotkey.exe"
    olStrState := "mem usage: " GetProcessMemoryUsage(ErrorLevel) " MB`nprivate: " GetWorkingSetPrivateSize(Errorlevel) " MB"
    olState.DrawText(olStrState, overlay.state.x + 10, overlay.state.y + 5, 19, 0xBBFFD700, "Bahnschrift", "w300,aLeft")
    olState.EndDraw()
  }
return

state:
  currZone := readCurrentZone(d4hWnd)
  if (isInTown(currZone))
    strState := "in town"
  else if (isTeleporting())
    strState := "zone changing / teleporting"
  else if (isReadyToAttack())
    strState := "rdy to attack"
  else
    strState := "unknown"

  if (olState.BeginDraw()) {
    olState.DrawRectangle(overlay.state.x, overlay.state.y, overlay.state.w, overlay.state.h, 0x55336699, 4)
    olState.FillRectangle(overlay.state.x, overlay.state.y, overlay.state.w, overlay.state.h, 0x55000000)
    olStrState := "Zone: " currZone "`nstate: " strState
    olState.DrawText(olStrState, overlay.state.x + 10, overlay.state.y + 5, 19, 0xBBFFD700, "Bahnschrift", "w300,aLeft")
    olState.EndDraw()
  }
return
  
autoheal:
  pxlCoord_lowHPX := 1250, pxlCoord_lowHPY := 1280, pxlClr_lowHP := 0x111311

  if (WinExist("ahk_id " d4hWnd)) {
    if (WinActive("ahk_id " d4hWnd)) {
      currZone := readCurrentZone(d4hWnd)
      if (currZone != "") {
        if (!isInTown(currZone)) {
          Critical, On
          PixelGetColor, Res_pixelClr, %pxlCoord_lowHPX%, %pxlCoord_lowHPY%, RGB
          SplitBGR2HSL(Res_pixelClr, AH_hue, AH_sat, AH_Luminosity)
          If (AH_hue > 0) {
            SendInput {6}
            SendInput {q}
            ;potCounter++
            InfoSplash("!!!DANGER!!! >> HP POT USED!")
            ;FormatTime, curTime, % A_Now, hh:mm:ss tt
            ;FileAppend, % curTime ": AUTO HEAL TRIGGERED! (found clr: " Res_pixelClr " | hue: " AH_hue " > sat: " AH_sat " | similarity: " clrSim ")`n", autoheal.log
          }
          Critical, Off
        }
      }
    }
  }
return

WatchActivebuffs:
  wabStartTime := A_TickCount
  if (WinExist("ahk_id " d4hWnd)) {
    if (WinActive("ahk_id " d4hWnd)) {
      if !isChatOpen() {
        if isReadyToAttack() {
          loop, 6
          {
            aSkills[A_Index] := []

            ; define what skill to cast automatic:
            aSkills[1].autocast := false
            aSkills[2].autocast := false
            aSkills[3].autocast := true
            aSkills[4].autocast := true
            aSkills[5].autocast := false
            aSkills[6].autocast := false
            
            if (aSkills[A_Index].autocast) {
              PixelGetColor, Res_acClr, % barX - 215 + ((a_index - 1) * (sourceWidth + sourcePadding + 0.5)), % barY
              SplitBGR2HSL(Res_acClr, acHue, acSat, Luminosity)
              aSkills[A_Index].clr := Res_acClr
              aSkills[A_Index].hue := acHue
              aSkills[A_Index].saturation := acSat
              aSkills[A_Index].x := barX - 210 + ((a_index - 1) * (sourceWidth + sourcePadding))
              aSkills[A_Index].y := barY
              aSkills[A_Index].active := true
              if (acSat > cooldownSaturation) || (acSat < cooldownSaturation2) {
                Critical, On
                aSkills[A_Index].onCD := false
                aSkills[A_Index].rdy := true
                SendInput {%A_Index%}
                Critical, Off
                ;FormatTime, curTime, % A_Now, hh:mm:ss tt
                ;FileAppend, % curTime ": AutoCast triggered! [func took: " A_TickCount - wabStartTime "ms] (found clr: " Res_pixelClr " | hue: " acHue " | sat: " acSat "`n", wab.log
              } else {
                aSkills[A_Index].onCD := true
                aSkills[A_Index].rdy := false
              }
            }
          }
        }
      }
    }
  }
return

AutoHeal1:
  WinActivate, % "ahk_id " d4hWnd
  sleep, 10
  if (options.autoheal.state) {
    InfoSplash("AUTOHEAL ACTIVATED!")
    SetTimer, autoheal, 250
  } else {
    InfoSplash("AUTOHEAL STOPPED!")
    settimer, autoheal, off
  }
return

MousePosDisplay:
  if (mPos_overlay.BeginDraw()) {
    mPos_overlay.DrawRectangle(mPos_overlayX, mPos_overlayY, mPos_overlayWidth, mPos_overlayHeight, 0x55336699, 4)
    mPos_overlay.FillRectangle(mPos_overlayX, mPos_overlayY, mPos_overlayWidth, mPos_overlayHeight, 0x55000000)
    if (mPos_overlay.GetMousePos(mx2, my2)) {
      PixelGetColor, pixelClr, %mx2%, %my2%, RGB
      c := new Color(Color.Unpack(pixelClr))
      tRGB := FHex(SplitBGRColor(pixelClr))
      SplitBGR2HSL(pixelClr, Hue, Sat, Luminosity)
      mPosText := "Mouse Coordinates:`n   x pos.`t: " mx2 "`ty pos.`t: " my2 "`n   pxlClr`t: " pixelClr "`n   hue`t: " Hue "`tsat`t: " Sat
    }
    
    mPos_overlay.FillRoundedRectangle(mPos_overlayX + 19, mPos_overlayY + mPos_overlayHeight - 47, 275, 21 , 2, 2, pixelClr)
    mPos_overlay.DrawText(mPosText, mPos_overlayX + 10, mPos_overlayY + 5, 19, 0xBBFFD700, "Bahnschrift", "w300,aLeft")
    mPos_overlay.EndDraw()
  }
return

;D4 basic functions
readMasterworkingCrit(d4hWnd)
{
  global strings
  if (WinActive("ahk_id " d4hWnd)) {
    hBitmap := HBitmapFromScreen(strings.locations.masterworking.x, strings.locations.masterworking.y, strings.locations.masterworking.width, strings.locations.masterworking.heigth)
    pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
    DllCall("DeleteObject", "Ptr", hBitmap)
    return, % StrReplace(ocr(pIRandomAccessStream, "FirstFromAvailableLanguages"), "`n")
  }
}

readCurrentZone(d4hWnd)
{
  global mapName, oStringSimilarity, AreaLocations
  if (WinActive("ahk_id " d4hWnd)) {
    hBitmap := HBitmapFromScreen(mapName.x, mapName.y, mapName.width, mapName.heigth)
    pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
    DllCall("DeleteObject", "Ptr", hBitmap)
    curMapName := ocr(pIRandomAccessStream, "FirstFromAvailableLanguages")
    if (tFound := inStr(curMapName, " ("))
      curMapName := SubStr(curMapName, 1 , tFound - 1)
    curMapName := StrReplace(curMapName, "`n")
    
    return, % oStringSimilarity.simpleBestMatch(curMapName, AreaLocations)
  }
}

isInTown(currZone)
{
  global AreaLocations_towns

  if HasVal(AreaLocations_towns, currZone)
    return, true
  else
    return, false
}

IsInOpenWorld()
{
  pxlCoord_IsInWorldX := 3293, pxlCoord_IsInWorldY := 32, pxlClr_IsInWorld := 0x7A746C
  PixelGetColor, IsInWorld, pxlCoord_IsInWorldX, pxlCoord_IsInWorldY, Alt RGB
  If (CheckColorSimilarity(pxlClr_IsInWorld, IsInWorld) < 5)
    return true
  else
    return false
}

isTeleporting()
{
  global pos, clr
  PixelGetColor, Res_pixelClr1, % pos.tp.x, % pos.tp.y1
  SplitBGR2HSL(Res_pixelClr1, hue1, sat1, Luminosity)
  PixelGetColor, Res_pixelClr2, % pos.tp.x, % pos.tp.y2
  SplitBGR2HSL(Res_pixelClr2, hue2, sat2, Luminosity)
  
  if (hue1 >= pos.tp.hue_min and hue1 <= pos.tp.hue_max) || (hue2 >= pos.tp.hue_min and hue2 <= pos.tp.hue_max)
    return, true
  else
    return, false
}
isChatOpen()
{
  global pos, clr

  PixelGetColor, Res_pixelClr, % pos.chat.x, % pos.chat.y
  if (Res_pixelClr = clr.chat.rgb)
    return, true
  else
    return, false
}

isReadyToAttack()
{
  global d4hWnd, currZone
  pxlCoord_IsRdyAttackX := 1482, pxlCoord_IsRdyAttackY := 1172, pxlCoord_IsRdyAttack := 0x20AB0B
  
  if (currZone != "") {
    if (!isTeleporting() && !isInTown(CurrZone)) {
      PixelGetColor, IsRdyAttack, pxlCoord_IsRdyAttackX, pxlCoord_IsRdyAttackY, RGB
      If (IsRdyAttack = pxlCoord_IsRdyAttack)
        return true
      else
        return false
    } else
      return false
  }
}

;@ahk-neko-ignore 1 line; at 7/10/2024, 5:22:22 PM ; https://www.autohotkey.com/docs/v1/Functions.htm
dbgFeatures()
{
  global
  dbgStartTime := A_TickCount
  loop, 100
  {
    ;msgbox, % "enters the loop without problems!`n`nLoopTime: " A_TickCount - dbgStartTime
    pxlCoord_buff2X := 1560, pxlCoord_buff2Y := 1290, pxlClr_buff2 := 0x5D9009
    pxlCoord_buff3X := 1642, pxlCoord_buff3Y := 1290, pxlClr_buff3 := 0x588807
    pxlCoord_buff4X := 1730, pxlCoord_buff4Y := 1290, pxlClr_buff4 := 0x588208
    pxlCoord_buff6X := 1900, pxlCoord_buff6Y := 1290, pxlClr_buff6 := 0x588308
    
    if (WinExist("ahk_id " d4hWnd)) {
      if (WinActive("ahk_id " d4hWnd)) {
        
        aSkills[A_Index] := []
        ; define what skill to cast automatic:
        aSkills[1].autocast := true
        aSkills[2].autocast := false
        aSkills[3].autocast := true
        aSkills[4].autocast := true
        aSkills[5].autocast := false
        aSkills[6].autocast := false
        
        loop, 6
        {
          if (aSkills[A_Index].autocast) {
            PixelGetColor, Res_pixelClr, % barX - 215 + ((a_index - 1) * (sourceWidth + sourcePadding + 0.5)), % barY
            SplitBGR2HSL(Res_pixelClr, Hue, Saturation, Luminosity)
            aSkills[A_Index].clr := Res_pixelClr
            aSkills[A_Index].hue := Hue
            aSkills[A_Index].saturation := Saturation
            aSkills[A_Index].x := barX - 210 + ((a_index - 1) * (sourceWidth + sourcePadding))
            aSkills[A_Index].y := barY
            aSkills[A_Index].active := true
            if (Saturation > cooldownSaturation) {
                aSkills[A_Index].onCD := false
                aSkills[A_Index].rdy := true
            } else {
                aSkills[A_Index].onCD := true
                aSkills[A_Index].rdy := false
            }
          }
        }
        
        if (isReadyToAttack()) {
          
          ; Ice Blades
          if (aSkills[1].autocast) {
            if (aSkills[1].rdy)
              SendInput {1}
          }
          
          ; Flame Shield
          if (aSkills[2].autocast) {
            PixelGetColor, clr_buff2, pxlCoord_buff2X, pxlCoord_buff2Y, Alt RGB
            if (clr_buff2 = pxlClr_buff2) {
              if (buff2_status = 0)
                buff2_start := A_TickCount
              buff2_status := 1
            } else {
              if (buff2_status = 1)
                buff2_duration := buff2_duration + (A_TickCount - buff2_start)
              buff2_status := 0
              if (aSkills[2].rdy)
                SendInput {2}
            }
          }
          
          ; Ice Armor
          if (aSkills[3].autocast) {
            PixelGetColor, clr_buff3, pxlCoord_buff3X, pxlCoord_buff3Y, Alt RGB
            if (clr_buff3 = pxlClr_buff3) {
              if (buff3_status = 0)
                buff3_start := A_TickCount
              buff3_status := 1
            } else {
              if (buff3_status = 1)
                buff3_duration := buff3_duration + (A_TickCount - buff3_start)
              buff3_status := 0
              if (aSkills[3].rdy)
                SendInput {3}
            }
          }

          ; Unstable Currents
          if (aSkills[4].autocast) {
            PixelGetColor, clr_buff4, pxlCoord_buff4X, pxlCoord_buff4Y, Alt RGB
            if (clr_buff4 = pxlClr_buff4) {
              if (buff4_status = 0)
                buff4_start := A_TickCount
              buff4_status := 1
            } else {
              if (buff4_status = 1)
                buff4_duration := buff4_duration + (A_TickCount - buff4_start)
              buff4_status := 0
              if (aSkills[4].rdy)
                SendInput {4}
            }
          }

          ; FlameShield
          if (aSkills[6].autocast) {
            PixelGetColor, clr_buff6, pxlCoord_buff6X, pxlCoord_buff6Y, Alt RGB
            if (clr_buff6 = pxlClr_buff6) {
              if (buff6_status = 0)
                buff6_start := A_TickCount
              buff6_status := 1
            } else {
              if (buff6_status = 1)
                buff6_duration := buff6_duration + (A_TickCount - buff6_start)
              buff6_status := 0
              if (aSkills[6].rdy)
                SendInput {6}
            }
          }
        }
      }
    }
  }
  dbgEndTime := A_TickCount - dbgStartTime
  return, % dbgEndTime
}

;internal functions
GetHwnd(process, exename) {
  If WinExist(process) {
    WinGet, WinID, List, %process%
    Loop, %WinID% {
      WinGet, ProcModuleName, ProcessName, % "ahk_id" WinID%A_Index%
      If(ProcModuleName=exename)
        return WinID%A_Index%
    }
  } else
    return false
}

InfoSplash(strMsg)
{
  global info_overlay, infoOverlayActive
  aStrMetrics := info_overlay.GetTextMetrics(strMsg, 26, "Bahnschrift")
  info_overlayWidth := aStrMetrics.w + 20, info_overlayHeight := aStrMetrics.h + 10
  global info_overlayX := (A_ScreenWidth // 2) - (info_overlayWidth // 2)
  info_overlayY := (A_ScreenHeight // 4.2) - (info_overlayHeight // 2)
  if (info_overlay.BeginDraw()) {
    info_overlay.DrawRectangle(info_overlayX, info_overlayY, info_overlayWidth, info_overlayHeight, 0x55996633, 4)
    info_overlay.FillRectangle(info_overlayX, info_overlayY, info_overlayWidth, info_overlayHeight, 0x77000000)
    info_overlay.DrawText(strMsg, info_overlayX, info_overlayY + 5, 26, 0xAAFFD700, "Bahnschrift", "w" info_overlayWidth ",aCenter,olFF000000,bold")
    info_overlay.SetPosition(0, 0)
    info_overlay.EndDraw()
    WinSet, Transparent, 255, % "ahk_id " info_overlay.hwnd
    WinSet, Redraw, , % "ahk_id " info_overlay.hwnd
  }
  if infoOverlayActive
    SetTimer, kill_InfoOverlay, -2500
  infoOverlayActive := true
}

kill_InfoOverlay:
  info_overlay.BeginDraw()
  newx := 0
  offset := random(0, 1) + 0 = 0 ? -2 : 2 
  loop, 160
  {
    newx := newx + offset
    alpha := 255 - Ceil(A_Index/160 * 255)
    info_overlay.SetPosition(newx, info_overlayY)
    WinSet, Transparent, % alpha, % "ahk_id " info_overlay.hwnd
    WinSet, Redraw, , % "ahk_id " info_overlay.hwnd
    if Mod(a_index, 2) = 0
      sleep, 1
  }
  info_overlay.EndDraw()
  infoOverlayActive := false
return
CheckColorSimilarity(targetColor, color)
{
  ;split target color into rgb
  tr := format("{:d}","0x" . substr(targetColor,3,2))
  tg := format("{:d}","0x" . substr(targetColor,5,2))
  tb := format("{:d}","0x" . substr(targetColor,7,2))

  ;split pixel into rgb
  pr := format("{:d}","0x" . substr(color,3,2))
  pg := format("{:d}","0x" . substr(color,5,2))
  pb := format("{:d}","0x" . substr(color,7,2))

  ;return distance
  return, % sqrt((tr-pr)**2+(tg-pg)**2+(pb-tb)**2)
}

ATan2(x,y) {
  Return DllCall("msvcrt\atan2", "Double", y, "Double", x, "CDECL Double")
}

;color MUST be in BGR form
;this function splits the color into its Red, Green, and Blue parts
SplitBGRColor(BGRColor)
{
    Red := BGRColor & 0xFF
    Green := BGRColor >> 8 & 0xFF
    Blue := BGRColor >> 16 & 0xFF
    ;msgbox, % "Blue: " Blue "`nGreen: " Green "`nRed: " Red
    return, % format("{:d}","0x" . Red . Green . Blue)
}

SplitBGR2HSL(BGRColor, ByRef Hue, ByRef Saturation, ByRef Brightness)
{
  Blue := BGRColor & 0xFF
  Green := BGRColor >> 8 & 0xFF
  Red := BGRColor >> 16 & 0xFF

  Max := Max(Red, Green, Blue)
  Min := Min(Red, Green, Blue)
  Delta := Max - Min
  
  ; Calculate Hue
  if (Delta = 0)
    Hue := 0
  else if (Max = Red)
    Hue := Mod((Green - Blue) / Delta, 6) * 60
  else if (Max = Green)
    Hue := ((Blue - Red) / Delta + 2) * 60
  else if (Max = Blue)
    Hue := ((Red - Green) / Delta + 4) * 60

  ; Calculate Saturation
  if (Max = 0)
    Saturation := 0
  else
    Saturation := Delta / Max * 255

  ; Calculate Brightness
  Brightness := Max

	Hue := Round(Hue)
	Saturation := Round(Saturation)
	Brightness := Round(Brightness)
  ; Return the HSB values
  return Hue, Saturation, Brightness
}

;simple class to handle dot behaviours
class _dot {
  
  __New(x, y, size, col, dir, speed, friction, growDir, growCol) {
    this.x := x
    this.y := y
    this.size := size
    this.speed := speed
    this.friction := friction
    this.rgb := (col & 0xFFFFFF)
    this.alpha := (col&0xFF000000)>>24
    this.dir := dir
    this.growDir := growDir
    this.growCol := growCol
  }
  
  Draw(olAction) {
    this.size += this.growDir
    if (this.size < 0.1)
      return 0
      
    this.x += cos(this.dir) * this.speed
    this.y += sin(this.dir) * this.speed

    this.speed *= this.friction
    
    this.alpha += this.growCol
    
    if (this.alpha < 1)
      return 0

    olAction.fillellipse(this.x, this.y, this.size, this.size, (floor(this.alpha)<<24) + this.rgb)
    return 1
  }
}