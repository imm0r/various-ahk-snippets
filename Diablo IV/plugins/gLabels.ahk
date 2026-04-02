Chkbox_mwAffix1:
    GuiControl, mw:Enable, MWCrit1
    GuiControl, mw:Disable, MWCrit2
    GuiControl, mw:Disable, MWCrit3
    GuiControl, MoveDraw, MWCrit1
    GuiControl, MoveDraw, MWCrit2
    GuiControl, MoveDraw, MWCrit3
return

Chkbox_mwAffix2:
    GuiControl, mw:Enable, MWCrit1
    GuiControl, mw:Enable, MWCrit2
    GuiControl, mw:Disable, MWCrit3
    GuiControl, MoveDraw, MWCrit1
    GuiControl, MoveDraw, MWCrit2
    GuiControl, MoveDraw, MWCrit3
return

Chkbox_mwAffix3:
    GuiControl, mw:Enable, MWCrit1
    GuiControl, mw:Enable, MWCrit2
    GuiControl, mw:Enable, MWCrit3
    GuiControl, MoveDraw, MWCrit1
    GuiControl, MoveDraw, MWCrit2
    GuiControl, MoveDraw, MWCrit3
return

btn_test:
    pic_success := "img\success.png"
    curStep := 0
    loop, 3
    {
        curStep++
        GuiControl,, % "MWCrit" . curStep . "Pic", % pic_success
    }
return