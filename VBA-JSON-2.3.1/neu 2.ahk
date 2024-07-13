yPos := round(A_ScreenHeight / 2 - 100)
Gui, add, edit, w200 gLabel vEdit,
Gui, Add,Button,,Button
Gui, show, y%yPos% w222 h80,gLabel-Test
Return
#IfWinActive gLabel-Test ahk_class AutoHotkeyGUI
~LCtrl::
~RCtrl::
~Enter::
~LShift::
~RShift::
~F1::
~F2::
~F3::
~F4::
~F5::
~F6::
~F7::
~F8::
~F9::
~F10::
~F11::
~F12::
  ControlGetFocus,focus,gLabel-Test ahk_class AutoHotkeyGUI
  If (focus!="Edit1")
    msgbox, % "You just hit enter"
#IfWinActive
Label:
{
    FadeTrans := 250
    Progress, m2 b fs18 w210 zh0 , gLabel gestartet!,, Fade,
    SetTimer, Fade, 1
Return
}

Fade:
{
    WinSet, Transparent, %FadeTrans%, Fade
    FadeTrans -= 10
    if (FadeTrans < 0)
        SetTimer, Fade, off
Return
}
