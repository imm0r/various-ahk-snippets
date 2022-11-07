#SingleInstance Force
SetWorkingDir %A_ScriptDir%


;Run As Admin
if not A_IsAdmin
	RunAsAdmin()

strClsName := "LDPlayerMainFrame", strAdbFile := "adb.exe", strConsoleFile := "dnconsole.exe"
Winget, cPid, PID, % "ahk_class " strClsName
WinGetTitle, wTitle, % "ahk_class " strClsName
vPath := GetModuleFileNameEx(cPid)
fTitle := GetFileTitleFromPath(vPath)
SplitPath, vPath, fName, fPath
wHwnd := GetHwnd(wTitle, fName)
FileGetVersion, fVer, % vPath

if FileExist(fPath . "\" . strAdbFile)
    adbPath := fPath . "\" . strAdbFile
if FileExist(fPath . "\" . strConsoleFile)
    consolePath := fPath . "\" . strConsoleFile

Global oLDP_Basics := Object("cli", vPath, "adb", adbPath, "console", consolePath, "title", wTitle, "hwnd", wHwnd, "Pid", cPid, "ver", fVer)

msgbox, % "Gathered Information for LDPlayer:`n`n"
        . "Windows Title`t: "   oLDP_Basics.title    "`n"
        . "Client Path`t: "     oLDP_Basics.cli      "`n"
        . "Version`t`t: "       oLDP_Basics.ver      "`n"
        . "Windows Handle`t: "  oLDP_Basics.hwnd     "`n"
        . "Process ID`t: "      oLDP_Basics.Pid      "`n"
        . "Console Path`t: "    oLDP_Basics.console  "`n"
        . "ADB Path`t`t: "      oLDP_Basics.adb

F1::
    returnSpecificLineOnly := 2
    strStdOut := stdCmd("H:\LDPlayer64.v9.0\adb.exe devices")
    Loop, parse, % strStdOut, `n, `r
        If A_LoopField is not space
            if (A_Index = returnSpecificLineOnly)
                oStdOut := A_Loopfield, break
            else
                oStdOut.Push(A_LoopField)
    msgbox, % oStdOut
return

F2::
    returnSpecificLineOnly := 0, oLDP_devices := {}
    strStdOut := stdCmd("H:\LDPlayer64.v9.0\dnconsole.exe list2")
    Loop, parse, % strStdOut, `n, `r
        If A_LoopField is not space
            if (A_Index = returnSpecificLineOnly)
                oLDP_devices := A_Loopfield, break
            else
                oLDP_devices.Push(A_LoopField)
    loop, % oLDP_devices.MaxIndex()
        msgbox, % oLDP_devices[A_Index]
return

F3::
    oStrToCheck := ["blad34blubb"," blablubb","Wer hat was in den blablubb gemacht?"]
    loop, % oStrToCheck.MaxIndex()
    {
        if CheckStr(oStrToCheck[A_Index], "blablubb")
            msgbox, % "Loop count: " A_Index "`n`nThe checked string ('" oStrToCheck[A_Index] "') seems to be valid!"
        else
            msgbox, % "Loop count: " A_Index "`n`nThe checked string ('" oStrToCheck[A_Index] "') is NOT valid!"
    }
return

F4::
    _COUNTER := 0

    ; TESTING SCENARION!!!
    _LOOPCOUNT := 100

    ; SETTING QPC UP
    DllCall("QueryPerformanceFrequency", "Int64*", freq)
    DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)

    ; BUILDING THE TESTLOOP
    loop, % _LOOPCOUNT
    {
        _COUNTER++
        ; STUFF TO TEST COMES HERE
        oLDP_devices := stdCmd("H:\LDPlayer64.v9.0\adb.exe devices")
        ; ========================
    }

    ; CALCULATING TEST TIME AND RETURNING THE RESULT
    DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
    MsgBox % "Elapsed QPC time is " . (CounterAfter - CounterBefore) / freq * 1000 " ms"
return