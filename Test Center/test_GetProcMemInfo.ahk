DetectHiddenWindows, On

F2::
    strClsName := "LDPlayerMainFrame"
    Winget, cPid, PID, % "ahk_class " strClsName
    WinGetTitle, wTitle, % "ahk_class " strClsName
    vPath := GetModuleFileNameEx(cPid)
    fTitle := GetFileTitleFromPath(vPath)
    SplitPath, vPath, fName, fPath
    wHwnd := GetHwnd(wTitle, fName)
    FileGetVersion, fVer, % vPath
    bVer := DllCall("GetVersion") >> 16 & 0xffff

    if (bVer >= "7600") {
        oGPMI := GetProcessMemoryInfo_PMCEX(cPid)
        MsgBox, % "GetProcessMemoryInfo function`n"
                . "PROCESS_MEMORY_COUNTERS_EX structure`n"
                . "_________________________________________________________`n"
                . "name`t: " wTitle " | " fTitle " (v." fVer ")`npath`t: "  vPath "`n"
                . "_________________________________________________________`n"
                . "cb:`t`t`t`t"                         oGPMI[1]  "`n"
                . "PageFaultCount:`t`t`t"               FormatBytes(oGPMI[2])  "`n"
                . "PeakWorkingSetSize:`t`t`t"           FormatBytes(oGPMI[3])  "`n"
                . "WorkingSetSize:`t`t`t"               FormatBytes(oGPMI[4])  "`n"
                . "QuotaPeakPagedPoolUsage:`t`t"        FormatBytes(oGPMI[5])  "`n"
                . "QuotaPagedPoolUsage:`t`t"            FormatBytes(oGPMI[6])  "`n"
                . "QuotaPeakNonPagedPoolUsage:`t"       FormatBytes(oGPMI[7])  "`n"
                . "QuotaNonPagedPoolUsage:`t`t"         FormatBytes(oGPMI[8])  "`n"
                . "PagefileUsage:`t`t`t"                FormatBytes(oGPMI[9])  "`n"
                . "PeakPagefileUsage:`t`t"              FormatBytes(oGPMI[10]) "`n`n"
                . "_________________________________________________________`n"
                . "Build: " bVer " | HWND: " wHwnd " | PID: " cPid
    } else {
        oGPMI := GetProcessMemoryInfo_PMC(cPid)
        MsgBox, % "GetProcessMemoryInfo function`n"
                . "PROCESS_MEMORY_COUNTERS_EX structure`n"
                . "_________________________________________________________`n"
                . "name`t: " wTitle " | " fTitle " (v." fVer ")`npath`t: "  vPath "`n"
                . "_________________________________________________________`n"
                . "cb:`t`t`t`t"                         oGPMI[1]  "`n"
                . "PageFaultCount:`t`t`t"               FormatBytes(oGPMI[2])  "`n"
                . "PeakWorkingSetSize:`t`t"             FormatBytes(oGPMI[3])  "`n"
                . "WorkingSetSize:`t`t`t"               FormatBytes(oGPMI[4])  "`n"
                . "QuotaPeakPagedPoolUsage:`t`t"        FormatBytes(oGPMI[5])  "`n"
                . "QuotaPagedPoolUsage:`t`t"            FormatBytes(oGPMI[6])  "`n"
                . "QuotaPeakNonPagedPoolUsage:`t"       FormatBytes(oGPMI[7])  "`n"
                . "QuotaNonPagedPoolUsage:`t`t"         FormatBytes(oGPMI[8])  "`n"
                . "PagefileUsage:`t`t`t"                FormatBytes(oGPMI[9])  "`n"
                . "PeakPagefileUsage:`t`t"              FormatBytes(oGPMI[10]) "`n`n"
                . "_________________________________________________________`n"
                . "Build: " bVer " | HWND: " wHwnd " | PID: " cPid
    }
Return

F3::
    strExeName := "Ld9BoxHeadless.exe"
    Winget, cPid, PID, % "ahk_exe " strExeName
    WinGetTitle, wTitle, % "ahk_pid " cPid
    vPath := GetModuleFileNameEx(cPid)
    fTitle := GetFileTitleFromPath(vPath)
    FileGetVersion, fVer, % vPath
    wHwnd := GetHwnd(wTitle, strExeName)
    bVer := DllCall("GetVersion") >> 16 & 0xffff

    if (bVer >= "7600") {
        oGPMI := GetProcessMemoryInfo_PMCEX(cPid)
        MsgBox, % "GetProcessMemoryInfo function`n"
                . "PROCESS_MEMORY_COUNTERS_EX structure`n"
                . "_________________________________________________________`n"
                . "name`t: " wTitle " | " fTitle " (v." fVer ")`npath`t: "  vPath "`n"
                . "_________________________________________________________`n"
                . "cb:`t`t`t`t"                         oGPMI[1]  "`n"
                . "PageFaultCount:`t`t`t"               FormatBytes(oGPMI[2])  "`n"
                . "PeakWorkingSetSize:`t`t`t"           FormatBytes(oGPMI[3])  "`n"
                . "WorkingSetSize:`t`t`t"               FormatBytes(oGPMI[4])  "`n"
                . "QuotaPeakPagedPoolUsage:`t`t"        FormatBytes(oGPMI[5])  "`n"
                . "QuotaPagedPoolUsage:`t`t"            FormatBytes(oGPMI[6])  "`n"
                . "QuotaPeakNonPagedPoolUsage:`t"       FormatBytes(oGPMI[7])  "`n"
                . "QuotaNonPagedPoolUsage:`t`t"         FormatBytes(oGPMI[8])  "`n"
                . "PagefileUsage:`t`t`t"                FormatBytes(oGPMI[9])  "`n"
                . "PeakPagefileUsage:`t`t"              FormatBytes(oGPMI[10]) "`n"
                . "PrivateUsage:`t`t`t"                 FormatBytes(oGPMI[11]) "`n`n"
                . "_________________________________________________________`n"
                . "Build: " bVer " | HWND: " wHwnd " | PID: " cPid
    } else {
        oGPMI := GetProcessMemoryInfo_PMC(cPid)
        MsgBox, % "GetProcessMemoryInfo function`n"
                . "PROCESS_MEMORY_COUNTERS_EX structure`n"
                . "_________________________________________________________`n"
                . "name`t: " wTitle " | " fTitle " (v." fVer ")`npath`t: "  vPath "`n"
                . "_________________________________________________________`n"
                . "cb:`t`t`t`t"                         oGPMI[1]  "`n"
                . "PageFaultCount:`t`t`t"               FormatBytes(oGPMI[2])  "`n"
                . "PeakWorkingSetSize:`t`t"             FormatBytes(oGPMI[3])  "`n"
                . "WorkingSetSize:`t`t`t"               FormatBytes(oGPMI[4])  "`n"
                . "QuotaPeakPagedPoolUsage:`t`t"        FormatBytes(oGPMI[5])  "`n"
                . "QuotaPagedPoolUsage:`t`t"            FormatBytes(oGPMI[6])  "`n"
                . "QuotaPeakNonPagedPoolUsage:`t"       FormatBytes(oGPMI[7])  "`n"
                . "QuotaNonPagedPoolUsage:`t`t"         FormatBytes(oGPMI[8])  "`n"
                . "PagefileUsage:`t`t`t"                FormatBytes(oGPMI[9])  "`n"
                . "PeakPagefileUsage:`t`t"              FormatBytes(oGPMI[10]) "`n"
                . "_________________________________________________________`n"
                . "Build: " bVer " | HWND: " wHwnd " | PID: " cPid
    }
Return