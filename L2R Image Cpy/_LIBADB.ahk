global g_pScreenBmp := 0 ; Global pBitmap
global ADB_TIME_REFRESH := 200
global adb := "V:\LDPlayer\adb.exe"
global AdbSN := "127.0.0.1:5555"
DetectHiddenWindows, on

; Creating a hidden Console Window
Run, %comspec% /k, , hide, pid
while !( hConsole := WinExist( "ahk_pid" pid ) )
	Sleep 10
DllCall( "AttachConsole", "UInt", pid )
DllCall( "AllocConsole" )
WinHide % "ahk_id " DllCall( "GetConsoleWindow", "ptr" )
Global s_shell := ComObjCreate( "WScript.shell" )

    gdipToken := Gdip_Startup()
    sCmd := adb " -s " AdbSN " shell screencap"
    if(!hBm := ADBScreenCapStdOutToHBitmap22( sCmd ))
    {	
        addlog( "ADBLib.log", " @ ADB Screen capture failed")
    }
    ret := Gdip_CreateBitmapFromHBITMAP(hBm)
    Gdip_SaveBitmapToFile(ret, "img.png" )

getAdbScreen() ;;Get screen from adb and save it in hBitmap
{
    if(g_pScreenBmp)
    {
        Gdip_DisposeImage(g_pScreenBmp) ;Free the memory of the old pBitmap address. To prevent memory leaks
    }
    sCmd := adb " -s " AdbSN " shell screencap"
    if(!hBitmap := ADBScreenCapStdOutToHBitmap22(sCmd ))
    {
        addlog( "ADBLib.log", " @ ADB Screen capture failed")
        return false
    }
    g_pScreenBmp := Gdip_CreateBitmapFromHBITMAP(hBitmap)
    DeleteObject(hBitmap)	
    return true
}

SaveAdbCropImage(filename, x1, y1, x2, y2)
{
    w := x2 - x1
    h := y2 - y1
    gdipToken := Gdip_Startup()
    sCmd := adb " -s " AdbSN " shell screencap"
    if(!hBm := ADBScreenCapStdOutToHBitmap22( sCmd ))
    {	
        addlog( "ADBLib.log", " @ ADB Screen capture failed")
        return false
    }
    ret := Gdip_CreateBitmapFromHBITMAP(hBm)
    ;ret2 := Gdip_CropImage(ret, x1, y1, w, h)
    Gdip_SaveBitmapToFile(ret, filename)
    addlog( "ADBLib.log", "# ADB (" x1 ", " y1 ", " x2 ", " y2 ") " filename " Save on")
    
    DllCall("DeleteObject", Ptr, hBm)
    Gdip_DisposeImage(ret)
    Gdip_DisposeImage(ret2)	
    Gdip_Shutdown(gdipToken)
}

CaptureAdb(filename)
{
    sCmd := adb " -s " AdbSN " shell screencap"
    if hbm := ADBScreenCapStdOutToHBitmap22( sCmd )
    {		
        ret := Gdip_CreateBitmapFromHBITMAP(hbm)
        Gdip_SaveBitmapToFile(ret,"adbCapture\" filename)
        DllCall("DeleteObject", Ptr, hbm)
        Gdip_DisposeImage(ret)
    }
    else
    {
        addlog( "ADBLib.log", "# ADB Screen capture failed")
        return false
    }
    log := "# 캡처 완료"
    addlog( "ADBLib.log", log)
    return
}

ClickAdb(x, y) ; adb클릭
{
    ;sleep, %ADB_TIME_REFRESH% ;It does not seem necessary
    if(x = 0 && y = 0)
    {
        log := "# Click failed due to image retrieval failure"
        addlog( "ADBLib.log", log)
        return false
    }	
    objExec := objShell.Exec(adb " -s " AdbSN " shell input tap " x " " y )
    addlog( "ADBLib.log", "# Click on: " x ", " y)
    ;while(!objExec.status)
    ;	sleep, 10
    sleep, %ADB_TIME_REFRESH%
}

DragAdb(x1,y1,x2,y2,duration)
{	
    objExec := objShell.Exec(adb " -s " AdbSN " shell input swipe " x1 " " y1 " " x2 " " y2) ;" " duration)
    addlog( "ADBLib.log", "# 드래그: " x1 ", " y1 " to " x2 ", " y2)
    sleep, %duration%
}

ClickToImgAdb(ByRef clickX, ByRef clickY, ImageName) ;Click-to-image Click and wait image
{
    ;sleep, %ADB_TIME_REFRESH%
    x := clickX
    y := clickY
    if(clickX= 0 && clickY = 0)
    {
        log := "# Click failed due to image retrieval failure"
        addlog( "ADBLib.log", log)
        return false
    }
    Loop
    {
        ClickAdb(x, y)
        ;objExec := objShell.Exec(adb " -s " AdbSN " shell input tap " x " " y )
        log := "  @ Waiting for images" ImageName
        addlog( "ADBLib.log", log)
        ;while(!objExec.status)
        ;	sleep, 10		
        sleep, 1000 ;%ADB_TIME_REFRESH%		
        Loop, 50
        {
            if(IsImgPlusAdb(clickX, clickY, ImageName, 60, 0))
                return true
            if(AfterRestart = 1)
            {
                log := "# Restart has occurred"
                addlog( "ADBLib.log", log)
                return false
            }
            sleep, 1000 ;%ADB_TIME_REFRESH%
        }
        if(A_Index > 10)
            AfterRestart := 1
        if(AfterRestart = 1)
        {
            log := "# Restart has occurred"
            addlog( "ADBLib.log", log)
            return false
        }
        sleep, 20000
    }
}

Gdip_ImageSearchWithPbm(bmpHaystack, Byref X,Byref Y,bmpNeedle,Variation=0,Trans="",sX = 0,sY = 0,eX = 0,eY = 0) ;Search from pBitmap
{
    RET := Gdip_ImageSearch(bmpHaystack,bmpNeedle,LIST,sX,sY,eX,eY,Variation,Trans,1,1)
    StringSplit, LISTArray, LIST, `,
    X := LISTArray1
    Y := LISTArray2
    
    if(RET = 1)
        return true
    else
        return false
}

;Search for images from pre-captured files
IsImgPlusWithFile(ByRef clickX, ByRef clickY, ImageName, errorRange, trans, sX = 0, sY = 0, eX = 0, eY = 0) ;gdip
{
    StringReplace, ImageName2, ImageName, Image\ , , All
    StringReplace, ImageName2, ImageName2, .bmp , , All		
    If(!bmp_%ImageName2%) ;If there is no image, it prints out the log of no image and returns
    {
        log := "  @ No image: " ImageName
        addlog( "ADBLib.log", log)
        return false
    }
    file := Gdip_CreateBitmapFromFile("adbCapture\sc.png")
    If(IsImgPlusAdbhBitmap(ClickX, ClickY, bmp_%ImageName2%, errorRange, trans, sX, sY, eX, eY))
    {
        log := "  @ Image found: " ImageName
        addlog( "ADBLib.log", log)	
        return true
    }
    else
    {
        clickX := 0
        clickY := 0
        ;log := "  @ Image not found: " ImageName
        ;addlog( "ADBLib.log", log)	
        return false
    }
}



IsImgWithoutCap(ByRef clickX, ByRef clickY, ImageName, errorRange, trans, sX = 0, sY = 0, eX = 0, eY = 0) ;gdip
{
    
    StringReplace, ImageName2, ImageName, Image\ , , All
    StringReplace, ImageName2, ImageName2, .bmp , , All
    
    if(!bmpPtrArr[(ImageName2)]) ;Wenn kein Bild vorhanden ist, wird das Protokoll ohne Bild ausgedruckt und zurückgegeben
    {
        log := "  @ No image: " ImageName
        addlog( "ADBLib.log", log)
        return false
    }	
    If(Gdip_ImageSearchWithPbm(g_pScreenBmp, ClickX, ClickY, bmpPtrArr[(ImageName2)], errorRange, trans, sX, sY, eX, eY))
    {
        log := "  @ Image found: " ImageName
        addlog( "ADBLib.log", log)	
        return true
    }
    else
    {
        clickX := 0
        clickY := 0
        ;log := "  @ Image not found: " ImageName
        ;addlog( "ADBLib.log", log)	
        return false
    }
}

IsImgWithoutCapLog(ByRef clickX, ByRef clickY, ImageName, errorRange, trans, sX = 0, sY = 0, eX = 0, eY = 0) ;Search without both capture and log
{
    StringReplace, ImageName2, ImageName, Image\ , , All
    StringReplace, ImageName2, ImageName2, .bmp , , All		
    If(!bmpPtrArr[(ImageName2)]) ; If there is no image, log out and return no image.
    {
        log := "  @ No image: " ImageName
        addlog( "ADBLib.log", log)
        return false
    }
    If(Gdip_ImageSearchWithPbm(g_pScreenBmp, ClickX, ClickY, bmpPtrArr[(ImageName2)], errorRange, trans, sX, sY, eX, eY))
    {
        ;log := "  @ Image found: " ImageName
        ;addlog( "ADBLib.log", log)	
        return true
    }
    else
    {
        clickX := 0
        clickY := 0
        return false
    }
}

; Create gdip hbitmap directly without writing files in adb
; https://autohotkey.tistory.com/40

; MCode22 Func
AdjustScreencapData := MCode22("2,x86:VVdWU4tsJBSLRCQYjXQF/zn1d1ONfv6NTQGJ6usRZpCJyIPCAYhZ/4PBATnydyI51w+2GnbqgPsNdeWAegENdd8PtloCgPsKdBa7DQAAAOvPKehbXl9dw5CNtCYAAAAAiciDwgPrvjHA6+iQkJCQkA==")

ScreencapToDIB := MCode22("2,x86:VVdWU4PsDItEJCiLdCQkhcB+fY0EtQAAAACLVCQsxwQkAAAAAMdEJAQAAAAA99iJRCQIi0QkKIPoAQ+vxo08goX2fjuLRCQgi0wkBDHbjSyIi0SdDInCweoQD7bKicIlAP8AAMHiEIHiAAD/AAnKCdCJBJ+DwwE53nXWAXQkBIMEJAEDfCQIiwQkOUQkKHWwg8QMW15fXcOQkJCQkJCQkA==")

ADBScreenCapStdOutToHBitmap22( sCmd ) 
{
    global AdjustScreencapData, ScreencapToDIB
    
	DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
	DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )

	VarSetCapacity( STARTUPINFO, 68,  0 )      ; STARTUPINFO
	NumPut( 68,         STARTUPINFO,  0 )      ; cbSize
	NumPut( 0x100,      STARTUPINFO, 44 )      ; dwFlags
	NumPut( hPipeWrite, STARTUPINFO, 60 )      ; hStdOutput
	NumPut( hPipeWrite, STARTUPINFO, 64 )      ; hStdError

	VarSetCapacity( PROCESS_INFORMATION, 16 ) 
	If !DllCall( "CreateProcess", UInt,0, UInt,&sCmd, UInt,0, UInt,0, UInt,1, UInt,0x08000000, UInt,0, UInt,0, UInt,&STARTUPINFO, UInt,&PROCESS_INFORMATION ) 
		Return "", DllCall( "CloseHandle", UInt,hPipeWrite ), DllCall( "CloseHandle", UInt,hPipeRead ), DllCall( "SetLastError", Int,-1 )

	hProcess := NumGet( PROCESS_INFORMATION, 0 ), hThread := NumGet( PROCESS_INFORMATION, 4 )                      

	DllCall( "CloseHandle", UInt,hPipeWrite )
    
    block := {}, blockIndex := 0, allSize := 0, nPipeAvail := 4096
    
    loop
    {
        ++blockIndex
        block[blockIndex] := {data:"", size:0, addr:0}
        ObjSetCapacity(block[blockIndex], "data", nPipeAvail)
        block[blockIndex].addr := ObjGetAddress(block[blockIndex], "data")
        
        nSz := 0
        
        if !DllCall( "ReadFile", UInt,hPipeRead, UInt,block[blockIndex].addr, UInt,nPipeAvail, UIntP,nSz, UInt,0 )
            break
        
        block[blockIndex].size := nSz, allSize += nSz
    }
    DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
    DllCall( "CloseHandle", UInt,hProcess  )
    DllCall( "CloseHandle", UInt,hThread   )
    DllCall( "CloseHandle", UInt,hPipeRead )
    
    if allSize
    {
        VarSetCapacity( bin, allSize, 0 ), tar := &bin
        for k,v in block
            if v.size
            DllCall("RtlMoveMemory", "UPTR",tar, "UPTR",v.addr, "UInt",v.size), tar += v.size
        allSize := DllCall(AdjustScreencapData, "UPTR",&bin, "UInt",allSize, "cdecl")
        width  := NumGet(&bin, 0, "uint"), height := NumGet(&bin, 4, "uint")
        hBM := CreateDIBSection(width, height,"",32, ppvBits)  
        DllCall(ScreencapToDIB, "UPtr",&bin, "UInt",width, "UInt",height, "UPtr",ppvBits, "cdecl")
        return hBM
    }
}

;--------------------------------------------------------------------

MCode22(MCode22) 
{
    static e := {1:4, 2:1}, c := (A_PtrSize=8) ? "x64" : "x86"
    if (!regexmatch(MCode22, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m))
        return
    if (!DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0))
        return
    p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
    if (c="x64")
        DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
    if (DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0))
        return p
    DllCall("GlobalFree", "ptr", p)
    return
}

SaveHBITMAPToFile(hBitmap, sFile)
{
    VarSetCapacity(DIBSECTION, A_PtrSize=8? 104:84, 0)
    NumPut(40, DIBSECTION, A_PtrSize=8? 32:24,"UInt") ;dsBmih.biSize
    DllCall("GetObject", "UPTR", hBitmap, "int", A_PtrSize=8? 104:84, "UPTR", &DIBSECTION)
    hFile:= DllCall("CreateFile", "UPTR", &sFile, "Uint", 0x40000000, "Uint", 0, "Uint", 0, "Uint", 2, "Uint", 0, "Uint", 0)
    DllCall("WriteFile", "UPTR", hFile, "int64P", 0x4D42|14+40+(biSizeImage:=NumGet(DIBSECTION, A_PtrSize=8? 52:44, "UInt"))<<16, "Uint", 6, "UintP", 0, "Uint", 0)
    DllCall("WriteFile", "UPTR", hFile, "int64P", 54<<32, "Uint", 8, "UintP", 0, "Uint", 0)
    DllCall("WriteFile", "UPTR", hFile, "UPTR", &DIBSECTION + (A_PtrSize=8? 32:24), "Uint", 40, "UintP", 0, "Uint", 0)
    DllCall("WriteFile", "UPTR", hFile, "Uint", NumGet(DIBSECTION, A_PtrSize=8? 24:20, "UPtr"), "Uint", biSizeImage, "UintP", 0, "Uint", 0)
    DllCall("CloseHandle", "UPTR", hFile)
}

IsImgPlusAdb(ByRef clickX, ByRef clickY, ImageName, errorRange, trans="", sX = 0, sY = 0, eX = 0, eY = 0) ;Image zu Image Plus
{	
    StringReplace, ImageName2, ImageName, Image\ , , All
    StringReplace, ImageName2, ImageName2, .bmp , , All		
    if(!bmpPtrArr[(ImageName2)]) ;; If the image does not exist, log out and return no image.
    {
        log := "  @ No image: " ImageName
        addlog( "ADBLib.log", log)
        return false
    }
    
    sCmd := adb " -s " AdbSN " shell screencap"
    if(!hBitmap := ADBScreenCapStdOutToHBitmap22( sCmd ))
    {
        addlog( "ADBLib.log", "  @ ADB Screen capture failed")
        return false
    }
    pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
    DllCall("DeleteObject", Ptr, hBitmap)
    If(Gdip_ImageSearchWithPbm(pBitmap, ClickX, ClickY, bmpPtrArr[(ImageName2)], errorRange, trans, sX, sY, eX, eY))
    {
        log := "  @ Image found: " ImageName
        addlog( "ADBLib.log", log)		
        Gdip_DisposeImage(pBitmap)
        return true
    }
    else
    {
        clickX := 0
        clickY := 0
        Gdip_DisposeImage(pBitmap)
        return false
    }
}

IsImgPlusAdbhBitmap(ByRef clickX, ByRef clickY, ImageName, errorRange, trans="", sX = 0, sY = 0, eX = 0, eY = 0) ;Izu Image Plus adb
{		
    IfNotExist, %ImageName% ; If the image does not exist, log out and return no image.
    {
        log := "  @ No image: " ImageName
        addlog( "ADBLib.log", log)		
    }
    
    sCmd := adb " -s " AdbSN " shell screencap"
    if(!hBm := ADBScreenCapStdOutToHBitmap22(sCmd ))
    {
        addlog( "ADBLib.log", " @ ADB Screen capture failed")
        return false
    }
    If(Gdip_ImageSearchWithHbm(hBm, ClickX, ClickY, ImageName, errorRange, trans, sX, sY, eX, eY))
    {
        log := "  @ Image found: " ImageName
        addlog( "ADBLib.log", log)
        DllCall("DeleteObject", Ptr, hBm)
        return true
    }
    else
    {
        clickX := 0
        clickY := 0
        DllCall("DeleteObject", Ptr, hBm)
        return false
    }
}

Gdip_ImageSearchWithHbm(hBitmap, Byref X,Byref Y,Image,Variation=0,Trans="",sX = 0,sY = 0,eX = 0,eY = 0) ;Search from hbitmap
{
    gdipToken := Gdip_Startup()
    bmpHaystack := Gdip_CreateBitmapFromHBITMAP(hBitmap) 
    bmpNeedle := Gdip_CreateBitmapFromFile(Image)
    addlog( "ADBLib.log", bmpNeedle)
    RET := Gdip_ImageSearch(bmpHaystack,bmpNeedle,LIST,sX,sY,eX,eY,Variation,Trans,1,1)
    addlog( "ADBLib.log", RET)
    Gdip_DisposeImage(bmpHaystack)
    Gdip_DisposeImage(bmpNeedle)
    Gdip_Shutdown(gdipToken)
    StringSplit, LISTArray, LIST, `,
    X := LISTArray1
    Y := LISTArray2
    
    if(RET = 1)
        return true
    else
        return false
}

_ADBSHELL( CMD = "" )
{
	If FileExist( adb ) {
		objExec := s_shell.Exec( CMD )
		strStdOut := ""
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
		return strStdOut
	}
}

addLog( FileName, StrToLog )
{
    FormatTime, TimeString, R
    StrToLog := "[ "TimeString " ]`t" StrToLog "`n"
    FileAppend , % StrToLog, % FileName 
}

#include <penis>