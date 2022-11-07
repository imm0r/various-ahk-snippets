

AddLog(LogFile, message)
{
	global debug
    LogFile := "log.txt"
    if(debug) {
        FormatTime, ts, %A_Now%, yyyyMMdd HH:mm:ss
        FileAppend, % ts " - " message "`n", % LogFile
    }
}

f_GetPathFromReg( REGPATH, REGVAR, EXEFILE )
{
	RegRead, t_Path, % REGPATH, % REGVAR
	If( t_Path != "" ) {
		SplitPath, t_Path, , t_Path
		If FileExist( t_Path . "\" . EXEFILE )
			return, % t_Path .  "\" . EXEFILE
		else
			return, % "FILE NOT FOUND!"
	} else
		return, % "Selected emulator installation not found!"
}

adb_GetInstance( )
{
	global
	LDPInstances := []
	If( FileExist( oLDP_fPath["console"] ) )
	{		
		;objShell := ComObjCreate( "WScript.shell" )
		objExec := objShell.Exec( oLDP_fPath["console"] . " list" )
		while,!objExec.StdOut.AtEndOfStream
		{
			strStdOut := objExec.StdOut.ReadAll()
			Loop, parse, % strStdOut, `n, `r
			{
				If A_LoopField is not space
				{
					LDPInstances.push( A_LoopField )
				}
			}
		}
		return LDPInstances
	}
}

adb_GetDevice( )
{
	global
	If FileExist( oLDP_fPath["adb"] ) {
		If( WinExist( "ahk_id " . L2RhWnd ) ) {
			;objShell := ComObjCreate( "WScript.shell" )
			objExec := objShell.Exec( oLDP_fPath["adb"] . " devices" )
			while,!objExec.StdOut.AtEndOfStream
			{
				strStdOut := objExec.StdOut.ReadAll()
				Loop, parse, % strStdOut, `n, `r
				{
					If ( A_Index > 1 ) {
						If InStr( A_LoopField, "device", true ) {
							t_STRarr := StrSplit( A_LoopField, A_Tab )
							return, % t_STRarr[1]
						}
					}
				}
			}
		}
		return -1
	}
	return -2
}

_ADB_SHELL( DEVICE := 0, CMD = "", PARAMS := "" )
{
	If( FileExist( oLDP_fPath["adb"] ) && ADB["ISCONNECTED"] ) {
		If( DEVICE )
			SHELLString := oLDP_fPath["adb"] . " -s " . DEVICE . " shell " . CMD . " " . PARAMS
		else
			SHELLString := oLDP_fPath["adb"] . " shell " . CMD . " " . PARAMS
		If( !InStr( CMD, "MEM") && !InStr( PARAMS, "MEM" ) )
			addLog( A_Scriptdir . "\DEBUG\adb_shell.txt", "SHELL STRING: " SHELLString )
		objExec := s_shell.Exec( SHELLString )
		strStdOut := ""
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
		If( !InStr( CMD, "MEM") && !InStr( PARAMS, "MEM" ) )
			addLog( A_Scriptdir . "\DEBUG\adb_shell.txt", "ADB RETURNED: " strStdOut )
		return strStdOut
	}
	return, -1
}

_ADB_ISADBCONNECTED( )
{
	If FileExist( oLDP_fPath["adb"] ) {
		If( !InStr( ADB["DEVICE"], ":" ) ) {
			t_StdOut := _ADB_SHELL( ADB["DEVICE"], "echo", " $USER:$USER_ID" )
			If( !InStr( t_StdOut, " not " ) && !InStr( t_StdOut, "unable" ) && !InStr( t_StdOut, "error: " ) )
				return, true
			else
				return, false
		} else {		
			objExec := s_shell.Exec( oLDP_fPath["adb"] . " connect " . ADB["DEVICE"])
			strStdOut := ""
			while, !objExec.StdOut.AtEndOfStream
				strStdOut := objExec.StdOut.ReadAll( )
			If InStr( strStdOut, "connected to", true ) {
				t_StdOut := _ADB_SHELL( ADB["DEVICE"], "echo", " $USER:$USER_ID" )
				If( !InStr( t_StdOut, " not " ) && !InStr( t_StdOut, "unable" ) && !InStr( t_StdOut, "error: " ) )
					return, true
				else
					return, false
			} else
				return, false
		}
	} else
		return, false
}

_ADB_ISL2RINSTALLED( )
{
	If( FileExist( oLDP_fPath["adb"] ) && ADB["ISCONNECTED"] ) {
		Loop, parse, % _ADB_SHELL( ADB["DEVICE"], "pm", "list packages -3" ), `n, `r 
			If InStr( A_LoopField, "netmarble" ) {
				t_STRarr := StrSplit( A_LoopField, ":" )
				return, % t_STRarr[2]
			}
	}
	return, 0
}

_ADB_GETPIDOFPACKAGE( PACKAGENAME )
{
	If( FileExist( oLDP_fPath["adb"] ) && ADB["ISCONNECTED"] )
		Loop, parse, % _ADB_SHELL( ADB["DEVICE"], "pidof", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
				return, % A_LoopField
	return, 0
}

_ADB_GETAPKPATHFROMPACKAGE( PACKAGENAME )
{
	If( FileExist( oLDP_fPath["adb"] ) && ADB["ISCONNECTED"] )
		Loop, parse, % _ADB_SHELL( ADB["DEVICE"], "pm list packages -f", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
				return, % RegexReplace( RegexReplace( A_LoopField, "package:/data/app/", "" ), "=com.netmarble.lin2ws", "" )
}

_ADB_GETRESOLUTION( )
{
	Loop, parse, % _ADB_SHELL( ADB["DEVICE"], "wm", "size" ), `n, `r
		If InStr( A_LoopField, "Physical size:" ) {
			t_eRes := StrSplit( RegexReplace( A_LoopField, "Physical size: ", "" ), "x" )
			return, % t_eRes
		}
}

_ADB_RUNAPP( PACKAGENAME, ACTIVITY )
{
	If FileExist( oLDP_fPath["adb"] ) {
		If( !_ADB_GETPIDOFPACKAGE( PACKAGENAME ) ) {
			_ADB_SHELL( ADB["DEVICE"], "am start -n", PACKAGENAME . "/" . ACTIVITY )
			DBGLog.Add( "Starting Lineage 2 Revolution." )
		}
	}
}   