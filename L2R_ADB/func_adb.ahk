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

adb_getPIDfromPackage( pName )
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected ) {
		tPid := adb_shell( oADB.device, "pidof", pName )
		if tPid is alnum
			return, % tPid
	}	
	return, 0
}

adb_getAPKPathFromPackage( pName )
{
	If( FileExist( oLDP_Basics.adb ) && oADB.isConnected )
		Loop, parse, % adb_shell( oADB.device, "pm list packages -f", pName ), `n, `r 
			If inStr(A_LoopField, pName) {
                tStrPackage := "=" pName
                return, % RegexReplace( RegexReplace( A_LoopField, "package:/data/app/", "" ), tStrPackage, "" )
            }
	return 0
}

_ADB_GETRESOLUTION( )
{
	Loop, parse, % adb_shell( oADB.device, "wm", "size" ), `n, `r
		If InStr( A_LoopField, "Physical size:" ) {
			t_eRes := StrSplit( RegexReplace( A_LoopField, "Physical size: ", "" ), "x" )
			return, % t_eRes
		}
}

adb_runApp( pName, activity )
{
	If FileExist( oLDP_Basics.adb )
		If( !adb_getPIDfromPackage( pName ) )
			return adb_shell( oADB.device, "am start -n", pName . "/" . activity )
	return 0
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

; fOutput
adb_screenshot(hWnd := "", fOutput := "", rOpt := [1,1])
{
	if WinExist(hWnd)
	{
		If FileExist(oLDP_Basics.adb) && FileExist(oBasics.dos2unix) && oADB.isConnected
		{
			fAdb		:= """" oLDP_Basics.adb """"
			fOutput		:= oBasics.imgDir . A_NOW . "_pulled-SS.png"
			fOutput2	:= """" fOutput """"							; fOutput2 := """" oBasics.imgDir . A_NOW . "_pulled-SS.png" """"
			fDos2Unix	:= """" oBasics.dos2unix """"					; "C:\Users\m0nsu\OneDrive\Desktop\ahk\L2R_ADB\misc\dos2unix.exe"

			Gdip_BitmapFromHWND()

			RunWait, %ComSpec% /c "%fAdb% -s emulator-5554 shell screencap -p | %fDos2Unix% -f > %fOutput2%", , hide
			Loop {
				If !FileExist(fOutput)
					sleep 10
			} until A_Index=500
			
			if OutputType = "file"
			{
				return fOutput
			}
			else if OutputType = "pBitmap"
			{
				if !A_IsUnicode
				{
					VarSetCapacity(wFile, 1023)
					DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &fOutput, "int", -1, "uint", &wFile, "int", 512)
					DllCall("gdiplus\GdipCreateBitmapFromFile", "uint", &wFile, "uint*", pBitmap)
				}
				else
					DllCall("gdiplus\GdipCreateBitmapFromFile", "uint", &fOutput, "uint*", pBitmap)
				return Gdip_CreateBitmapFromFile(pBitmap)
			}
		}
	}
}