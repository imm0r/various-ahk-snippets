GetLDPBasics(strClsName := "LDPlayerMainFrame", strAdbFile := "adb.exe", strConsoleFile := "dnconsole.exe")
{
    Winget, cPid, PID, % "ahk_class " strClsName
    WinGetTitle, wTitle, % "ahk_class " strClsName
    vPath := GetModuleFileNameEx(cPid), fTitle := GetFileTitleFromPath(vPath)
    SplitPath, vPath, fName, fPath
    wHwnd := GetHwnd(wTitle, fName)
    FileGetVersion, fVer, % vPath

    if FileExist(fPath . "\" . strAdbFile)
        adbPath := fPath . "\" . strAdbFile
    if FileExist(fPath . "\" . strConsoleFile)
        consolePath := fPath . "\" . strConsoleFile

    return, % Object("cli", vPath, "adb", adbPath, "console", consolePath, "title", wTitle, "hwnd", wHwnd, "Pid", cPid, "ver", fVer)
}

