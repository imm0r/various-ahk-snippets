#NoEnv
#singleinstance, force
DetectHiddenText, on 
SetBatchLines, -1

RunCMD()

hWnd := GetWinHWNDFromClass(cls)
oCtrls := GetCtrlListFromHwnd(hWnd)

msgbox, % "GetWinHWNDFromClass`t`t:" GetWinHWNDFromClass("SubWin1") "`nGetActiveProcessName:`t" GetActiveProcessName() "`nGetCtrlListFromHwnd`t: " oCtrls(2)

GetActiveProcessName() {
    WinGet name, ProcessName, A
    if (name = "ApplicationFrameHost.exe") {
        ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow1, A
        if hwnd {
            WinGet name, ProcessName, ahk_id %hwnd%
        }
    }
    return name
}