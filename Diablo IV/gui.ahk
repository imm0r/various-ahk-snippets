CmdGui() {
    global
	Gui, Cmd:New, +LabelCmd +HwndCmdHwnd +AlwaysOnTop
	Gui, Font, s13, Bahnschrift Condensed
	gui, add, Text, x5 y5 BackgroundTrans, Circle Attack > Ellipse Size (in `%):
    Gui, Add, Slider, x+5 y4 w200 h26 Border vsliderEllipse gsliderEllipse ToolTipLeft, 100
	gui, add, Text, x+5 w55 h26 Center Border vSliderVal, % "100%"
	Gui, Add, Button, x+5 y3 h29 vcaption_toggleEllipse gToggleEllipse, Show Ellipse
	Gui, Add, Button, x+5 y3 h29 vcaption_toggleCircleAttack gToggleCircleAttack, Start Circle Attack
	Gui, Add, Button, x+5 y3 h29 vcaption_toggleLog gToggleLog, Show Log

	Gui, Font, s12, Bahnschrift Condensed
	Gui, Add, Edit, vCmdOutput +HwndCmdOutputHwnd x5 y+8 w735 h250 border readonly
    Gui, Show, w745 h35, Lazy-Loot
    guiHwnd := WinActive("A")
}

MWGui() {
    global

	Gui, mw:New, +LabelCmd +HwndmwHwnd +AlwaysOnTop
	Gui, Font, s13, Bahnschrift Condensed
    ; Choose the masterworking level
    gui, mw:add, Text, x5 y5 w290 center BackgroundTrans, masterworking setup
    Gui, mw:add, Radio, vRadioMW1 x5 y38 w50 Checked gChkbox_mwAffix1, 4/12
    Gui, mw:add, Radio, vRadioMW2 x5 y+14 w50 gChkbox_mwAffix2, 8/12
    Gui, mw:add, Radio, vRadioMW3 x5 y+13 w50 gChkbox_mwAffix3, 12/12
    
    ; Choose affix we want to crit on lvl 4, 8 and 12
    Gui, mw:Add, DropDownList, vMWCrit1 x60 y35 h300 w205, % ddl_Affixes
    Gui, mw:Add, DropDownList, vMWCrit2 x60 y+5 h300 w205 disabled, % ddl_Affixes
    Gui, mw:Add, DropDownList, vMWCrit3 x60 y+5 h300 w205 disabled, % ddl_Affixes
    
    ; picture displaying a crit failure or success
    Gui, mw:Add, Picture, vMWCrit1Pic x270 y37,
    Gui, mw:Add, Picture, vMWCrit2Pic y+25,
    Gui, mw:Add, Picture, vMWCrit3Pic y+25,

    ; Buttons to innitiate the masterworking process
    Gui, mw:Add, Button, gStartMW x5 y140, Start Masterworking
    Gui, mw:Add, Button, gResetMW x+30, reset Masterworking

    ; Debug Output
    gui, mw:add, Text, x5 y+25 w290 center BackgroundTrans, debug output:

    ; logging the current state/actions/results
    gui, mw:add, edit, x5 y+10 w290 -border BackgroundTrans disabled vActionLog, 
    gui, mw:add, edit, x5 y+5 w40 -border BackgroundTrans disabled vCurrMWlvl, 
    gui, mw:add, edit, x+5 w245 -border BackgroundTrans disabled vCurrMWCritRes,
    gui, mw:add, edit, x5 y+5 w290 -border BackgroundTrans disabled vDebug, 

    Gui, mw:Add, Button, gReloadGui y+15, reload
    Gui, mw:Add, Button, gbtn_test x+30, test

    ; processing the gui
    Gui, mw:Show, w300 h450, Masterworking setup
    gui_mwHwnd := WinActive("A")
}

ReloadGui() {
    reload
}

StartMW() {
    pic_fail := "img\fail.png"
    pic_success := "img\success.png"

    ; Kritische Werte aus der GUI abrufen
    GuiControlGet, _mwCrit1, , MWCrit1
    GuiControlGet, _mwCrit2, , MWCrit2
    GuiControlGet, _mwCrit3, , MWCrit3

    ; Meisterwerk-Level bestimmen
    mwLvl := (_mwCrit1 ? 1 : 0) + (_mwCrit2 ? 1 : 0) + (_mwCrit3 ? 1 : 0)
    curStep := 0

    ; Falls kein Level aktiv ist, abbrechen
    if (mwLvl = 0) {
        MsgBox, Kein Meisterwerk-Level ausgewählt.
        return
    }

    ; Schritte der Meisterwerk-Logik
    while curStep <= mwLvl {
        mwStep := A_Index * 4 - 4 ; mwStep ist 0, 4 oder 8 für die 3 Level
        critTarget := [_mwCrit1, _mwCrit2, _mwCrit3]

        while true {
            critRes := mw_upgrade() ; Versuch zur Verbesserung

            ; GUI aktualisieren
            GuiControl mw: , CurrMWCritRes, % critRes
            GuiControl mw: MoveDraw, CurrMWCritRes
            GuiControl mw: , Debug, % mwStep " :: " curStep " / " mwLvl " | MWCrit" . curStep + 1 . "Pic"
            GuiControl mw: MoveDraw, Debug

            ; Erfolg überprüfen
            if InStr(critRes, critTarget[curStep + 1]) {
                curStep++
                GuiControl mw:, % "MWCrit" . curStep . "Pic", % pic_success
                break ; Nächsten Schritt beginnen
            } else {
                curStep := 0
                loop, % mwLvl
                    GuiControl mw:, % "MWCrit" . A_Index . "Pic", % pic_fail
                mw_reset() ; Meisterwerk wird zurückgesetzt
                continue
            }
        }
    }

    ; Erfolgreiches Meisterwerk
    MsgBox, Erfolgreich gemeistert!
}

StartMW1() {
    GuiControlGet, _mwCrit1, , MWCrit1
    GuiControlGet, _mwCrit2, , MWCrit2
    GuiControlGet, _mwCrit3, , MWCrit3
    if(_mwCrit1) {
        mwLvl := 1
        if(_mwCrit2) {
            mwLvl := 2
            if(_mwCrit3) {
                mwLvl := 3
            }
        }
    } else {
        mwLvl := 0
    }

    mwStep1:
    ittRes1 := 0
    if(mwLvl >= 1) {
        mwStep := 0
        while ittRes1 = 0
        {
            mw_reset()
            critRes := mw_upgrade()
            GuiControl, , CurrMWCritRes, % critRes
            GuiControl, MoveDraw, CurrMWCritRes
            If InStr(critRes, _mwCrit1)
                ittRes1 := 1
            else
                ittRes1 := 0
        }
    }
    mwStep2:
    if(mwLvl >= 2) {
        mwStep :=  4
        critRes := mw_upgrade()
        GuiControl, , CurrMWCritRes, % critRes
        GuiControl, MoveDraw, CurrMWCritRes
        If InStr(critRes, _mwCrit2)
           goto mwStep3
        else
           goto mwStep1
    }
    mwStep3:
    if(mwLvl >= 3) {
        mwStep := 8
        critRes := mw_upgrade()
        GuiControl, , CurrMWCritRes, % critRes
        GuiControl, MoveDraw, CurrMWCritRes
        If InStr(critRes, _mwCrit3)
            msgbox, % "Successfully masterworked!"
        else
            goto mwStep1
    }
}

ResetMW() {
    mw_reset()
}

sliderEllipse() {
  global sliderEllipse, ellipseWidth, ellipseHeight, SliderVal, toggle_circle
  ; resizing the ellipse based on the user setup
  ellipseWidth := (A_ScreenWidth  / 2) * (sliderEllipse / 100)
  ellipseHeight := (A_ScreenHeight / 2) * (sliderEllipse / 100)
  GuiControl, Text, SliderVal, % sliderEllipse "%"
  toggle_circle := 0
  ToggleEllipse()
}

ToggleEllipse() {
    global CmdOutput, CmdOutputHwnd, elipseOL, ellipseWidth, ellipseHeight, d4hWnd, toggle_circle, caption_ToggleEllipse
	GuiControl, , CmdOutput
    toggle_circle := !toggle_circle
    if (toggle_circle) {
        WinActivate, % "ahk_id " d4hWnd
        if (elipseOL.BeginDraw()) {
            elipseOL.DrawEllipse(A_ScreenWidth / 2, A_ScreenHeight / 2, ellipseWidth, ellipseHeight, 0xb4275132, 8)
            elipseOL.EndDraw()
            WinActivate, % "ahk_id " guiHwnd
	        AppendText(CmdOutputHwnd,"Ellipse drawn to d4 window")
        }
        GuiControl,, caption_ToggleEllipse, hide ellipse
    } else {
        cmdOutp := "Ellipse removed from d4 window"
        if (elipseOL.BeginDraw()) {
            elipseOL.EndDraw()
        }
        AppendText(CmdOutputHwnd, cmdOutp)
        GuiControl,, caption_ToggleEllipse, show ellipse
    }
}

ToggleCircleAttack() {
    global
	GuiControl, , CmdOutput
    GoSub F1
	AppendText(CmdOutputHwnd, "bla")
}

ToggleLog() {
	GuiControl, , CmdOutput
        gOutput := "Connection successfull!"
	AppendText(CmdOutputHwnd, gOutput)
}