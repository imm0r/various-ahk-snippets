f_RestoreWindow( hWnd )
{
	DetectHiddenWindows, On
	WinGet, MMX, MinMax, % "ahk_id " hWnd
	If( MMX == -1 ) {
		PostMessage, 0x112, 0xF120,,, % "ahk_id " hWnd
		WinWait, % "ahk_id " hWnd, , 3
	}
}

f_GetWindowRect( hWnd )
{
	WinGetPos, curWinX, curWinY, curWinW, curWinH, % "ahk_id " hWnd
	return, % Object( "x", curWinX, "y", curWinY, "w", curWinW, "h", curWinH )
}

f_GetClientRect( hWnd )
{
	ControlGetPos, curWinX, curWinY, curWinW, curWinH, % GetCtrlIDFromHWND( hWnd ), % "ahk_id " hWnd
	return, % Object( "x", curWinX, "y", curWinY, "w", curWinW, "h", curWinH )
}

_GETCLIENTSIZE( hWnd )
{
	ControlSize := []
	ControlGetPos, ControlX, ControlY, ControlWidth, ControlHeight, % GetCtrlIDFromHWND( hWnd ), % "ahk_id " hWnd
	ControlSize.push( ControlX, ControlY, ControlWidth, ControlHeight )
	return ControlSize
}

TrayTip( UpperMsg="", LowerMsg=" " )
{
	TrayTip, % RegExReplace( UpperMsg, "`n", " | " ), %LowerMsg%, 1
}

f_SetFixedWindowSize( hWnd )
{
	If Win_Is( Hwnd, "win" )
		If !Win_Is( Hwnd, "hung" )
			iF Win_Move( hWnd, EMU.WINDOW["fSIZE"].x, EMU.WINDOW["fSIZE"].y, EMU.WINDOW["fSIZE"].w, EMU.WINDOW["fSIZE"].h )
				Return, true
	Return, false
}

f_FixClientSize( )
{
	If( WinExist( "ahk_id " EMU.WINDOW["ID"] ) )
	{
		EMUCtrlList := []
		EMUCtrlList := GetCtrlListFromHwnd( EMU.WINDOW["ID"] )
		if( EMUCtrlList["sub"] )
		{
			If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] )
			{
				Win_Move( EMUCtrlList["sub"], EMU.OBJSIZE["WIN"]["x"], EMU.OBJSIZE["WIN"]["y"], EMU.OBJSIZE["WIN"]["w"], EMU.OBJSIZE["WIN"]["h"] )
				objExec := ComObjCreate( "WScript.shell" ).Exec( EMU.PATH["ADBEXE"] . " -s " . ADB["DEVICE"] . " shell wm size " . EMU.OBJSIZE["CLS"]["w"] . "x" . EMU.OBJSIZE["CLS"]["h"] )
				strStdOut := ""
				while, !objExec.StdOut.AtEndOfStream
					strStdOut := objExec.StdOut.ReadAll( )
				return strStdOut
			}
		}
		return false
	}
	return false
}

f_OrigClientSize( )
{
	If( WinExist( "ahk_id " EMU.WINDOW["ID"] ) )
	{
		EMUCtrlList := []
		EMUCtrlList := GetCtrlListFromHwnd( EMU.WINDOW["ID"] )
		if( EMUCtrlList["sub"] )
		{
			If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] )
			{
				Win_Move( EMU.WINDOW["ID"], 1, 1, 3440, 1440 )
				Win_Move( EMUCtrlList["sub"], 2, 35, 3435, 1400 )
				objExec := ComObjCreate( "WScript.shell" ).Exec( EMU.PATH["ADBEXE"] . " -s " . ADB["DEVICE"] . " shell wm size 3440x1440" )
				strStdOut := ""
				while, !objExec.StdOut.AtEndOfStream
					strStdOut := objExec.StdOut.ReadAll( )
				return strStdOut
			}
		}
		return false
	}
	return false
}

_LDP_GETINSTANCES( )
{
	LDPInstances := []
	If( FileExist( EMU.PATH["CONSOLE"] ) ) {
		Loop, parse, % EMU.PATH["CONSOLE"] " list", `n, `r 
			If A_LoopField != ""
				LDPInstances.push( A_LoopField )
		return, % LDPInstances
	}
}

adb_shell( DEVICE := 0, CMD = "", PARAMS := "" )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		If( DEVICE )
			SHELLString := EMU.PATH["ADBEXE"] . " -s " . DEVICE . " shell " . CMD . " " . PARAMS
		else
			SHELLString := EMU.PATH["ADBEXE"] . " shell " . CMD . " " . PARAMS
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

_ADB_GETDEVICE( )
{
	If FileExist( EMU.PATH["ADBEXE"] ) {
		objExec := s_shell.Exec( EMU.PATH["ADBEXE"] . " devices" )
		strStdOut := objExec.StdOut.ReadAll( )
		Loop, parse, strStdOut, `n, `r
			If ( A_Index > 1 )
				If InStr( A_LoopField, "device", true ) {
					t_STRarr := StrSplit( A_LoopField, A_Tab )
					return, % t_STRarr[1]
				}
	}
}

_ADB_ISADBCONNECTED( )
{
	If FileExist( EMU.PATH["ADBEXE"] ) {
		If( !InStr( ADB["DEVICE"], ":" ) ) {
			t_StdOut := adb_shell( ADB["DEVICE"], "echo", " $USER:$USER_ID" )
			If( !InStr( t_StdOut, " not " ) && !InStr( t_StdOut, "unable" ) && !InStr( t_StdOut, "error: " ) )
				return, true
			else
				return, false
		} else {		
			objExec := s_shell.Exec( EMU.PATH["ADBEXE"] . " connect " . ADB["DEVICE"])
			strStdOut := ""
			while, !objExec.StdOut.AtEndOfStream
				strStdOut := objExec.StdOut.ReadAll( )
			If InStr( strStdOut, "connected to", true ) {
				t_StdOut := adb_shell( ADB["DEVICE"], "echo", " $USER:$USER_ID" )
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
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		Loop, parse, % adb_shell( ADB["DEVICE"], "pm", "list packages -3" ), `n, `r 
			If InStr( A_LoopField, "netmarble" ) {
				t_STRarr := StrSplit( A_LoopField, ":" )
				return, % t_STRarr[2]
			}
	}
	return, 0
}

_ADB_GETPIDOFPACKAGE( PACKAGENAME )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] )
		Loop, parse, % adb_shell( ADB["DEVICE"], "pidof", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
				return, % A_LoopField
	return, 0
}

_ADB_GETAPKPATHFROMPACKAGE( PACKAGENAME )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] )
		Loop, parse, % adb_shell( ADB["DEVICE"], "pm list packages -f", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
				return, % RegexReplace( RegexReplace( A_LoopField, "package:/data/app/", "" ), "=com.netmarble.lin2ws", "" )
}

_ADB_GETRESOLUTION( )
{
	Loop, parse, % adb_shell( ADB["DEVICE"], "wm", "size" ), `n, `r
		If InStr( A_LoopField, "Physical size:" ) {
			t_eRes := StrSplit( RegexReplace( A_LoopField, "Physical size: ", "" ), "x" )
			return, % t_eRes
		}
}

_ADB_RUNAPP( PACKAGENAME, ACTIVITY )
{
	If FileExist( EMU.PATH["ADBEXE"] ) {
		If( !_ADB_GETPIDOFPACKAGE( PACKAGENAME ) ) {
			adb_shell( ADB["DEVICE"], "am start -n", PACKAGENAME . "/" . ACTIVITY )
			DBGLog.Add( "Starting Lineage 2 Revolution." )
		}
	}
}

_ADB_PULLTRACES( TARGET_LOCATION )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		objExec := s_shell.Exec( EMU.PATH["ADBEXE"] . " -s " . ADB["DEVICE"] . " pull /data/anr/traces.txt  " . TARGET_LOCATION )
		strStdOut := ""
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
			
		If InStr( strStdOut, "bytes in", true )
			return true
		else
			return, % strStdOut
	}
}

_ADB_PULLSCREENSHOT( FILENAME )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		clipboard := "screencap -p | " . A_Scriptdir . "\DEBUG\DATA\dos2unix.exe -f > " . A_Scriptdir . "\DEBUG\PULLED_SS\" . FILENAME
		adb_shell( ADB["DEVICE"], "screencap -p | " . A_Scriptdir . "\DEBUG\DATA\dos2unix.exe -f > ", A_Scriptdir . "\DEBUG\PULLED_SS\" . FILENAME )
		while !( FileExist( A_Scriptdir . "\DEBUG\PULLED_SS\" . FILENAME ) )
		{
			if( A_Index > 40 )
				break
			Sleep 250
		}
		return, % A_Scriptdir . "\DEBUG\PULLED_SS\" . FILENAME
	}
}

_ADB_GETMEMUSAGE( PACKAGENAME )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		Loop, parse, % adb_shell( ADB["DEVICE"], "dumpsys", "meminfo" ), `n, `r 
			If InStr( A_LoopField, PACKAGENAME, true )
				__TMPaRR := StrSplit( A_LoopField, ":" )
		return, % RegExReplace(RegExReplace(RegExReplace(__TMPaRR[1], " ", ""), ",", ""), "K", "")
	}
}

_ADB_INPUT( action, xPos1, yPos1, xPos2="", yPos2="", duration="" )
{
	If( FileExist( EMU.PATH["ADBEXE"] ) && ADB["ISCONNECTED"] ) {
		addLog( A_Scriptdir . "\DEBUG\adb_shell.txt", "SHELL STRING: " EMU.PATH["ADBEXE"] . " -s " . ADB["DEVICE"] . " shell input " . action . " " . xPos1 . " " . yPos1 . " " . xPos2 . " " . yPos2 . " " . duration )
		objExec := s_shell.Exec( EMU.PATH["ADBEXE"] . " -s " . ADB["DEVICE"] . " shell input " . action . " " . xPos1 . " " . yPos1 . " " . xPos2 . " " . yPos2 . " " . duration )
	} else
		addLog( A_Scriptdir . "\DEBUG\adb_shell.txt", "ADB INPUT ERROR ADBEXE: " EMU.PATH["ADBEXE"] "`nADB INPUT ERROR CONNECT: " ADB["ISCONNECTED"] )
}

_L2R_Navigate( TARGET )
{
	Switch TARGET
	{
		Case "LOGIN_CHAR_RECENT":
			t_Action := "tap", t_cPosX1 := EMU.CPOS["X"][90], t_cPosY1 := EMU.CPOS["Y"][85]
		Case "MAP":
			t_Action := "tap", t_cPosX1 := EMU.CPOS["X"][90], t_cPosY1 := EMU.CPOS["Y"][10]
		Case "CLOSE_ADD", "CLOSE_INV":
			t_Action := "tap", t_cPosX1 := EMU.CPOS["X"][98], t_cPosY1 := EMU.CPOS["Y"][3]
		Case "CONQUEST":
			t_Action := "tap", t_cPosX1 := 235, t_cPosY1 := 480
		Case "CLAIM_REWARD":
			t_Action := "tap", t_cPosX1 := 2140, t_cPosY1 := 1190
		Case "CONTINUE_CONQUEST":
			t_Action := "tap", t_cPosX1 := 2180, t_cPosY1 := 1180
		Case "START_CONQUEST":
			t_Action := "tap", t_cPosX1 := 225, t_cPosY1 := 770			
		Case "QUESTLOG_BOTTOM":
			t_Action := "swipe", t_cPosX1 := EMU.CPOS["X"][7], t_cPosY1 := EMU.CPOS["Y"][55], t_cPosX2 := EMU.CPOS["X"][7], t_cPosY2 := EMU.CPOS["Y"][30], duration := 100
	}
	_ADB_INPUT( t_Action, t_cPosX1, t_cPosY1, t_cPosX2, t_cPosY2, duration )
	addLog( A_Scriptdir . "\DEBUG\adb_shell.txt", TARGET " " t_Action "'ed! (" t_cPosX1 "/" t_cPosY1 ( t_Action == "swipe" ? "/" t_cPosX2 "/" t_cPosY2 " : " duration ")" : ")" ) )
}

_READ_EMU_ROOTPATH( REGPATH, REGVAR, EXEFILE )
{
	RegRead, t_Path, % REGPATH, % REGVAR
	If( t_Path != "" ) {
		SplitPath, t_Path, FileName, FullPath
		;msgbox, % "REGPATH: " REGPATH "`nREGVAR: " REGVAR "`nEXEFILE: " EXEFILE "`n`nt_Path: " t_Path "`nFullExePath: " FullExePath "`nFullPath: " FullPath "`nFileName: " EXEFILE
		If FileExist( FullPath "\" EXEFILE )
			return, % FullPath "\" EXEFILE
		else
			return, % "FILE NOT FOUND!"
	} else
		return, % "Selected emulator installation not found!"
}

_EMU_STARTUP( PATH )
{
	SplitPath, PATH , FILENAME, PATH
	PATH := PATH . "\"
	DllCall("shell32\ShellExecute" (A_IsUnicode ? "":"A"), uint, 0, str, "RunAs", str, PATH . FILENAME, str, , str, PATH, int, 1)

	; Setting up all Timers
	; SetTimer, L2R_ANRDetect, 5000	; Set timer for periodicly pulling the traces.txt from emu to local
	; SetTimer, System_State, 7500	; Set timer for watching the state of the android system
	; SetTimer, L2R_MemUsage, 10000	; Set timer for periodicly comparing L2Rs MemUsage
}

; Options are:
;   "FULL"	: Closes everything related to the emulator you choose
;    "ADB"	: Closes only ADB related processes
;    "CMD"  : Closes only command shell processes 
_EMU_CLOSE( OPT := "FULL" )
{
	DetectHiddenWindows, On
	
	a_PIDList := [], RET := 0
	
	; GuiControlGet, SelectedEmu, , SelectedEmu
	SelectedEmu := 1
	
	Switch OPT
	{
		Case "FULL":
			a_PIDneeded := [EMU.FILE["ADB"][selectedEmu], EMU.FILE["CLIENT"][selectedEmu], "LdVBoxSVC.exe", "LdVBoxHeadless.exe", "cmd.exe"]
		Case "EMU":
			a_PIDneeded := [EMU.FILE["CLIENT"][selectedEmu], "LdVBoxSVC.exe", "LdVBoxHeadless.exe"]
		Case "CMD":
			a_PIDneeded := ["cmd.exe"]
		Case "ADB":
			a_PIDneeded := [EMU.FILE["ADB"][selectedEmu]]
	}
	
	a_PIDList := GetProcList( a_PIDneeded )
	DBGLog.Add( "SHUTTING DOWN EMULATOR AND RELATED PROCESSES! | " a_PIDList.MaxIndex( ) " corresponding processes where found.", , , "L2R Manager" )
	objExec := s_shell.Exec( EMU.PATH["CONSOLE"] . " quitall" )
	Loop, % a_PIDList.MaxIndex( )
	{
		Process, Close, % a_PIDList[A_Index]
		If( ErrorLevel )
			DBGLog.Add( "PROCESS WITH PID " a_PIDList[A_Index] " successfully killed!" )
		else {
			RET++
			DBGLog.Add( "UNABLE TO KILL PROCESS WITH PID " a_PIDList[A_Index] "!" )
		}
	}
	EMU.WINDOW["ID"] := ""
	return, % RET
}

;--------------------------------------------------------------------

f_GetLDPlayerAttributes( )
{
	;index, title, top window handle, bind window handle, android started, pid, pid of vbox
	Return, gA_LDPAttrib
}

GetEmuWinTitle( )
{
	;GuiControlGet, SelectedEmu, , SelectedEmu
	SelectedEmu := 1
	WinGetTitle, RET, % "ahk_class " EMU.WINDOW["CLASS"][SelectedEmu]
	Return, % RET
}

f_GetRelativeClientWindowRect( hwnd )
{
	obj_LDPWindowRect := f_GetWindowRect( hWnd ), obj_LDPClientRect := f_GetClientRect( hWnd )
	
	_newWinRect := []
	_newWinRect.x := obj_LDPWindowRect["x"] + obj_LDPClientRect["x"]
	_newWinRect.y := obj_LDPWindowRect["y"] + obj_LDPClientRect["y"]
	
	_newWinRect.w := A_ScreenWidth + 1 = obj_LDPClientRect["w"] ? A_ScreenWidth : obj_LDPClientRect["w"]
	_newWinRect.h := A_ScreenHeight + 1 = obj_LDPClientRect["h"] ? A_ScreenHeight : obj_LDPClientRect["h"]
	
	_newWinRect.isFullscreen := _newWinRect.x + _newWinRect.y = 0 ? true : false
	return, % _newWinRect
}