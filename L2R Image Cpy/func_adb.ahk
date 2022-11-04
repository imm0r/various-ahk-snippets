adb_GetInstanceDetails(PlayerID)
{
	global oLDP_Basics		
	
	strStdOut := stdCmd( oLDP_Basics.console . " list2" )
	Loop, parse, % strStdOut, `n, `r
	{
		If A_LoopField is not space
		{
				oLDP := []
				oLDP := strSplit(A_LoopField, ",")
				if (oLDP[1] = PlayerID)
					return Object("id", oLDP[1], "winTitle", oLDP[2], "topHwnd", FHex( oLDP[3] ), "bindHwnd", FHex( oLDP[4] ), "isRunning", oLDP[5] ? 1 : 0, "mainPid", oLDP[6], "vboxPid", oLDP[7], "rHeight", oLDP[8], "rWidth", oLDP[9], "rDPI", oLDP[10])
		}
	}
	return 0
}

adb_GetDevice( )
{
	If FileExist( oLDP_Basics.adb )
    {
		If( WinExist( "ahk_id " . oLDP_Basics.hwnd ) )
        {
			strStdOut := stdCmd( oLDP_Basics.adb . " devices" )
            Loop, parse, % strStdOut, `n, `r
            {
                If ( A_Index > 1 )
                {
                    If InStr( A_LoopField, "device", true )
                    {
                        t_STRarr := StrSplit( A_LoopField, A_Tab )
                        return, % t_STRarr[1]
                    }
                }
            }
		}
		return -1
	}
	return -2
}

adb_isConnectedToDevice(device)
{
	If FileExist( oLDP_Basics.adb ) {
		If( !InStr( device, ":" ) ) {
			t_StdOut := adb_shell( device, "echo", " $USER:$USER_ID" )
			If( !InStr( t_StdOut, " not " ) && !InStr( t_StdOut, "unable" ) && !InStr( t_StdOut, "error: " ) )
				return, true
		} else {
			strStdOut := stdCmd( oLDP_Basics.adb . " connect " . device)
			If InStr( strStdOut, "connected to", true ) {
				t_StdOut := adb_shell( device, "echo", " $USER:$USER_ID" )
				If( !InStr( t_StdOut, " not " ) && !InStr( t_StdOut, "unable" ) && !InStr( t_StdOut, "error: " ) )
					return, true
			}
		}
	}
	return, false
}


; ===============================================================================================


adb_shell( DEVICE := 0, CMD = "", PARAMS := "" )
{
	global oLDP_Basics
	If FileExist( oLDP_Basics.adb )
	{
		If( DEVICE )
			shellStr := oLDP_Basics.adb . " -s " . DEVICE . " shell " . CMD . " " . PARAMS
		else
			shellStr := oLDP_Basics.adb . " shell " . CMD . " " . PARAMS
		return stdCmd( shellStr )
	}
	return, -1
}

adb_isInstalled(package)
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected ) {
		Loop, parse, % adb_shell( oADB.device, "pm", "list packages -3" ), `n, `r
        {
            If InStr( A_LoopField, package ) {
                t_STRarr := StrSplit( A_LoopField, ":" )
                return, % t_STRarr[2]
            }
        }
	}
	return, 0
}

_ADB_GETPIDOFPACKAGE( PACKAGENAME )
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected )
		Loop, parse, % adb_shell( oADB.device, "pidof", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
				return, % A_LoopField
	return, 0
}

adb_getAPKPathFromPackage( PACKAGENAME )
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected )
		Loop, parse, % adb_shell( oADB.device, "pm list packages -f", PACKAGENAME ), `n, `r 
			If A_LoopField != ""
            {
                tStrPackage := "=" PACKAGENAME
                return, % RegexReplace( RegexReplace( A_LoopField, "package:/data/app/", "" ), tStrPackage, "" )
            }				
}

_ADB_GETRESOLUTION( )
{
	Loop, parse, % adb_shell( oADB.device, "wm", "size" ), `n, `r
		If InStr( A_LoopField, "Physical size:" ) {
			t_eRes := StrSplit( RegexReplace( A_LoopField, "Physical size: ", "" ), "x" )
			return, % t_eRes
		}
}

adb_runApp( PACKAGENAME, ACTIVITY )
{
	If FileExist( oLDP_Basics.adb )
		If( !_ADB_GETPIDOFPACKAGE( PACKAGENAME ) )
			return adb_shell( oADB.device, "am start -n", PACKAGENAME . "/" . ACTIVITY )
}

adb_input( action, xPos1, yPos1, xPos2="", yPos2="", duration="" )
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected ) {
        txPos2 := xPos2 != "" ? " " . xPos2 : ""
        tyPos2 := yPos2 != "" ? " " . yPos2 : ""
        tduration := duration != "" ? " " . duration : ""
        position := xPos1 . " " . yPos1 . txPos2 . tyPos2 . tduration
		tInput := "input " . action . " " . position
        tRet := adb_shell( oADB.device, "input " . action, position)
		if (tRet)
			return tInput
		return 1
	}
}