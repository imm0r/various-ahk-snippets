DetectHiddenWindows,On
Run,%ComSpec% /k,,Hide UseErrorLevel,pid
if not ErrorLevel
{
    while !WinExist("ahk_pid" pid)
    Sleep,10
    DllCall("AttachConsole","UInt",pid)
}
CMD=ping -n 10 8.8.8.8
objShell:=ComObjCreate("WScript.Shell")
objExec:=objShell.Exec(CMD)
Gui,1:-border
Gui,font,s8
Gui,Add,Text,W280 H300 vText gButtonCancel,Testing internet connection`r`nPinging Google DNS: 10 times
Gui,Show,w280 H300
while,!objExec.StdOut.AtEndOfStream
{
GuiControlGet,Text
strStdOut:=objExec.StdOut.readline()
GuiControl,,Text,%Text%`r`n%strStdOut%
}
GuiControlGet,Text
GuiControl,,Text,%Text%`r`n`r`n%A_Tab%%A_Tab%%A_Space%%A_Space%Click me to Close..
Return
ButtonCancel:
Gui,Destroy
Exitapp