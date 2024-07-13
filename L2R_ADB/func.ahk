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

GetLDPClassIDs(hWnd)
{
	local ClsID := object()
	WinGet, ControlList, ControlListHwnd, % "ahk_id " hWnd
	static WINDOW_TEXT_SIZE := 32767
	VarSetCapacity(ClsStr, WINDOW_TEXT_SIZE * (A_IsUnicode ? 2 : 1))
	Loop Parse, ControlList, `n
	{
		if (DllCall("GetWindowText", "ptr", A_LoopField, "str", ClsStr, "int", WINDOW_TEXT_SIZE))
			ClsID.Push(ClsStr, A_LoopField)
		;msgbox, % "Current Control ID: " A_LoopField "`n`nIsVisible: " IsVisible "`t`tClsStrLength: " ClsStrLength "`nClsStr: " ClsStr
	}
	return, % object(ClsID[1], ClsID[2], ClsID[3], ClsID[4])
}

DwmGetPixel(hWnd, x, y)
{
    
   hDC := DllCall("user32.dll\GetDCEx", "UInt", hWnd, "UInt", 0, "UInt", 1|2)
   pix := DllCall("gdi32.dll\GetPixel", "UInt", hDC, "Int", x, "Int", y, "UInt")
   DllCall("user32.dll\ReleaseDC", "UInt", hWnd, "UInt", hDC)
   DllCall("gdi32.dll\DeleteDC", "UInt", hDC)
   return, % ConvertColor(pix)
}

ConvertColor( BGRValue )
{
	BlueByte := ( BGRValue & 0xFF0000 ) >> 16
	GreenByte := BGRValue & 0x00FF00
	RedByte := ( BGRValue & 0x0000FF ) << 16
	return RedByte | GreenByte | BlueByte
}

AddLog(msg, cat := 1, logFile := "")
{
    logFile != "" ? oBasics.logFile : logFile
    FormatTime, ts, %A_Now%, HH:mm:ss
    if (debug && msg)
    {
        if isObject(msg)
        {
            Loop, % msg.MaxIndex()
                If msg[A_Index] != ""
                    If A_Index = 1
                        retMsg := "[" ts "] (" oCategories[cat] ")`t" msg[A_Index] "`n"
                    else
                        retMsg .= "`t`t`t`t`t" msg[A_Index] "`n"
        }
        else
        {
            Loop, parse, msg, `n, `r
                If A_LoopField is not space
                    If A_Index = 1
                        retMsg := "[" ts "] (" oCategories[cat] ")`t" A_LoopField "`n"
                    else
                        retMsg .= "`t`t`t`t`t" A_LoopField "`n"
        }
    }
    if (logFile = "")
        return
    fLog := FileOpen(logFile, "a")
    if !IsObject(fLog)
        return
    fLog.Write(retMsg)
    fLog.Close()
    return, % retMsg
}

HBitmapFromScreen(X, Y, W, H) {
   HDC := DllCall("GetDC", "Ptr", 0, "UPtr")
   PDC := DllCall("CreateCompatibleDC", "UPtr", HDC)

   VarSetCapacity(bi, 40, 0)
   NumPut(40, bi, 0, "uint")
   NumPut(W, bi, 4, "uint")
   NumPut(H, bi, 8, "uint")
   NumPut(1, bi, 12, "ushort")
   NumPut(32, bi, 14, "ushort")
   NumPut(0, bi, 16, "uInt")

   HBM := DllCall("CreateDIBSection", "UPtr", HDC, "UPtr", &bi, "UInt", 0, "UPtr*", 0, "UPtr", 0, "UInt", 0, "UPtr")

   DllCall("SelectObject", "Ptr", PDC, "Ptr", HBM)
   DllCall("BitBlt", "UPtr", PDC, "int", 0, "int", 0, "int", W, "int", H
                   , "UPtr", HDC, "int", X, "int", Y, "uint", 0x00CC0020)
   DllCall("DeleteDC", "Ptr", PDC)
   DllCall("ReleaseDC", "Ptr", 0, "Ptr", HDC)
   Return HBM
}

HBitmapToRandomAccessStream(hBitmap) {
   static IID_IRandomAccessStream := "{905A0FE1-BC53-11DF-8C49-001E4FC686DA}"
        , IID_IPicture            := "{7BF80980-BF32-101A-8BBB-00AA00300CAB}"
        , PICTYPE_BITMAP := 1
        , BSOS_DEFAULT   := 0
        
   DllCall("Ole32\CreateStreamOnHGlobal", "Ptr", 0, "UInt", true, "PtrP", pIStream, "UInt")
   
   VarSetCapacity(PICTDESC, sz := 8 + A_PtrSize*2, 0)
   NumPut(sz, PICTDESC)
   NumPut(PICTYPE_BITMAP, PICTDESC, 4)
   NumPut(hBitmap, PICTDESC, 8)
   riid := CLSIDFromString(IID_IPicture, GUID1)
   DllCall("OleAut32\OleCreatePictureIndirect", "Ptr", &PICTDESC, "Ptr", riid, "UInt", false, "PtrP", pIPicture, "UInt")
   ; IPicture::SaveAsFile
   DllCall(NumGet(NumGet(pIPicture+0) + A_PtrSize*15), "Ptr", pIPicture, "Ptr", pIStream, "UInt", true, "UIntP", size, "UInt")
   riid := CLSIDFromString(IID_IRandomAccessStream, GUID2)
   DllCall("ShCore\CreateRandomAccessStreamOverStream", "Ptr", pIStream, "UInt", BSOS_DEFAULT, "Ptr", riid, "PtrP", pIRandomAccessStream, "UInt")
   ObjRelease(pIPicture)
   ObjRelease(pIStream)
   Return pIRandomAccessStream
}

CLSIDFromString(IID, ByRef CLSID) {
   VarSetCapacity(CLSID, 16, 0)
   if res := DllCall("ole32\CLSIDFromString", "WStr", IID, "Ptr", &CLSID, "UInt")
      throw Exception("CLSIDFromString failed. Error: " . Format("{:#x}", res))
   Return &CLSID
}


ocr(file, lang := "FirstFromAvailableLanguages")
{
   static OcrEngineStatics, OcrEngine, MaxDimension, LanguageFactory, Language, CurrentLanguage, BitmapDecoderStatics, GlobalizationPreferencesStatics
   if (OcrEngineStatics = "")
   {
      CreateClass("Windows.Globalization.Language", ILanguageFactory := "{9B0252AC-0C27-44F8-B792-9793FB66C63E}", LanguageFactory)
      CreateClass("Windows.Graphics.Imaging.BitmapDecoder", IBitmapDecoderStatics := "{438CCB26-BCEF-4E95-BAD6-23A822E58D01}", BitmapDecoderStatics)
      CreateClass("Windows.Media.Ocr.OcrEngine", IOcrEngineStatics := "{5BFFA85A-3384-3540-9940-699120D428A8}", OcrEngineStatics)
      DllCall(NumGet(NumGet(OcrEngineStatics+0)+6*A_PtrSize), "ptr", OcrEngineStatics, "uint*", MaxDimension)   ; MaxImageDimension
   }
   if (file = "ShowAvailableLanguages")
   {
      if (GlobalizationPreferencesStatics = "")
         CreateClass("Windows.System.UserProfile.GlobalizationPreferences", IGlobalizationPreferencesStatics := "{01BF4326-ED37-4E96-B0E9-C1340D1EA158}", GlobalizationPreferencesStatics)
      DllCall(NumGet(NumGet(GlobalizationPreferencesStatics+0)+9*A_PtrSize), "ptr", GlobalizationPreferencesStatics, "ptr*", LanguageList)   ; get_Languages
      DllCall(NumGet(NumGet(LanguageList+0)+7*A_PtrSize), "ptr", LanguageList, "int*", count)   ; count
      loop % count
      {
         DllCall(NumGet(NumGet(LanguageList+0)+6*A_PtrSize), "ptr", LanguageList, "int", A_Index-1, "ptr*", hString)   ; get_Item
         DllCall(NumGet(NumGet(LanguageFactory+0)+6*A_PtrSize), "ptr", LanguageFactory, "ptr", hString, "ptr*", LanguageTest)   ; CreateLanguage
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+8*A_PtrSize), "ptr", OcrEngineStatics, "ptr", LanguageTest, "int*", bool)   ; IsLanguageSupported
         if (bool = 1)
         {
            DllCall(NumGet(NumGet(LanguageTest+0)+6*A_PtrSize), "ptr", LanguageTest, "ptr*", hText)
            buffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", length, "ptr")
            text .= StrGet(buffer, "UTF-16") "`n"
         }
         ObjRelease(LanguageTest)
      }
      ObjRelease(LanguageList)
      return text
   }
   if (lang != CurrentLanguage) or (lang = "FirstFromAvailableLanguages")
   {
      if (OcrEngine != "")
      {
         ObjRelease(OcrEngine)
         if (CurrentLanguage != "FirstFromAvailableLanguages")
            ObjRelease(Language)
      }
      if (lang = "FirstFromAvailableLanguages")
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+10*A_PtrSize), "ptr", OcrEngineStatics, "ptr*", OcrEngine)   ; TryCreateFromUserProfileLanguages
      else
      {
         CreateHString(lang, hString)
         DllCall(NumGet(NumGet(LanguageFactory+0)+6*A_PtrSize), "ptr", LanguageFactory, "ptr", hString, "ptr*", Language)   ; CreateLanguage
         DeleteHString(hString)
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+9*A_PtrSize), "ptr", OcrEngineStatics, ptr, Language, "ptr*", OcrEngine)   ; TryCreateFromLanguage
      }
      if (OcrEngine = 0)
      {
         msgbox Can not use language "%lang%" for OCR, please install language pack.
         ExitApp
      }
      CurrentLanguage := lang
   }
   IRandomAccessStream := file
   DllCall(NumGet(NumGet(BitmapDecoderStatics+0)+14*A_PtrSize), "ptr", BitmapDecoderStatics, "ptr", IRandomAccessStream, "ptr*", BitmapDecoder)   ; CreateAsync
   WaitForAsync(BitmapDecoder)
   BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
   DllCall(NumGet(NumGet(BitmapFrame+0)+12*A_PtrSize), "ptr", BitmapFrame, "uint*", width)   ; get_PixelWidth
   DllCall(NumGet(NumGet(BitmapFrame+0)+13*A_PtrSize), "ptr", BitmapFrame, "uint*", height)   ; get_PixelHeight
   if (width > MaxDimension) or (height > MaxDimension)
   {
      msgbox Image is to big - %width%x%height%.`nIt should be maximum - %MaxDimension% pixels
      ExitApp
   }
   BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
   DllCall(NumGet(NumGet(BitmapFrameWithSoftwareBitmap+0)+6*A_PtrSize), "ptr", BitmapFrameWithSoftwareBitmap, "ptr*", SoftwareBitmap)   ; GetSoftwareBitmapAsync
   WaitForAsync(SoftwareBitmap)
   DllCall(NumGet(NumGet(OcrEngine+0)+6*A_PtrSize), "ptr", OcrEngine, ptr, SoftwareBitmap, "ptr*", OcrResult)   ; RecognizeAsync
   WaitForAsync(OcrResult)
   DllCall(NumGet(NumGet(OcrResult+0)+6*A_PtrSize), "ptr", OcrResult, "ptr*", LinesList)   ; get_Lines
   DllCall(NumGet(NumGet(LinesList+0)+7*A_PtrSize), "ptr", LinesList, "int*", count)   ; count
   loop % count
   {
      DllCall(NumGet(NumGet(LinesList+0)+6*A_PtrSize), "ptr", LinesList, "int", A_Index-1, "ptr*", OcrLine)
      DllCall(NumGet(NumGet(OcrLine+0)+7*A_PtrSize), "ptr", OcrLine, "ptr*", hText) 
      buffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", length, "ptr")
      text .= StrGet(buffer, "UTF-16") "`n"
      ObjRelease(OcrLine)
   }
   Close := ComObjQuery(IRandomAccessStream, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
   DllCall(NumGet(NumGet(Close+0)+6*A_PtrSize), "ptr", Close)   ; Close
   ObjRelease(Close)
   Close := ComObjQuery(SoftwareBitmap, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
   DllCall(NumGet(NumGet(Close+0)+6*A_PtrSize), "ptr", Close)   ; Close
   ObjRelease(Close)
   ObjRelease(IRandomAccessStream)
   ObjRelease(BitmapDecoder)
   ObjRelease(BitmapFrame)
   ObjRelease(BitmapFrameWithSoftwareBitmap)
   ObjRelease(SoftwareBitmap)
   ObjRelease(OcrResult)
   ObjRelease(LinesList)
   return text
}

CreateClass(string, interface, ByRef Class)
{
   CreateHString(string, hString)
   VarSetCapacity(GUID, 16)
   DllCall("ole32\CLSIDFromString", "wstr", interface, "ptr", &GUID)
   result := DllCall("Combase.dll\RoGetActivationFactory", "ptr", hString, "ptr", &GUID, "ptr*", Class)
   if (result != 0)
   {
      if (result = 0x80004002)
         msgbox No such interface supported
      else if (result = 0x80040154)
         msgbox Class not registered
      else
         msgbox error: %result%
      ExitApp
   }
   DeleteHString(hString)
}

CreateHString(string, ByRef hString)
{
    DllCall("Combase.dll\WindowsCreateString", "wstr", string, "uint", StrLen(string), "ptr*", hString)
}

DeleteHString(hString)
{
   DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
}

WaitForAsync(ByRef Object)
{
   AsyncInfo := ComObjQuery(Object, IAsyncInfo := "{00000036-0000-0000-C000-000000000046}")
   loop
   {
      DllCall(NumGet(NumGet(AsyncInfo+0)+7*A_PtrSize), "ptr", AsyncInfo, "uint*", status)   ; IAsyncInfo.Status
      if (status != 0)
      {
         if (status != 1)
         {
            DllCall(NumGet(NumGet(AsyncInfo+0)+8*A_PtrSize), "ptr", AsyncInfo, "uint*", ErrorCode)   ; IAsyncInfo.ErrorCode
            msgbox AsyncInfo status error: %ErrorCode%
            ExitApp
         }
         ObjRelease(AsyncInfo)
         break
      }
      sleep 10
   }
   DllCall(NumGet(NumGet(Object+0)+8*A_PtrSize), "ptr", Object, "ptr*", ObjectResult)   ; GetResults
   ObjRelease(Object)
   Object := ObjectResult
}

TidyString( str )
{
   RetStr := RegExReplace( str,"(\n|\r|\t)+"," " )
   loop {
      StringReplace, RetStr, RetStr, %A_Space%%A_Space%, %A_Space%, All
      If( !InStr( RetStr, "  ") )
         return, % RetStr
   }
}


f_GetClientRect( hWnd )
{
	ControlGetPos, curWinX, curWinY, curWinW, curWinH, % GetCtrlIDFromHWND( hWnd ), % "ahk_id " hWnd
	return, % Object( "x", curWinX, "y", curWinY, "w", curWinW, "h", curWinH )
}

GetCtrlIDFromHWND( hWnd )
{
	ControlGetFocus, ControlID, % "ahk_id " hWnd
	return, ControlID
}

GetActiveSet(oSet)
{
   scan.GetWindowRect(w,h,x,y)
   cRect := f_GetClientRect(oLDP_Basics.hWnd)
   clientrect := object("x", w*0.9+x, "y", h*0.9+y, "w", w*0.1, "h", h*0.1)
   hBitmapOCR2 := HBitmapFromScreen(clientrect["x"],clientrect["y"],clientrect["w"],clientrect["h"])
   cSett := HBitmapToRandomAccessStream(hBitmapOCR2)
   DllCall("DeleteObject", "Ptr", hBitmapOCR2)
   cSet := RegExReplace(RegExReplace(trim(ocr(cSett)),"(\n|\r)"),"[^0-9]")
   if (dbg)
      overlay.DrawRectangle(cRect["w"]*0.9+cRect["x"], cRect["h"]*0.9+cRect["y"], cRect["w"]*0.1, cRect["h"]*0.1,0xFF0FFFF0,2)
   If (!cSet)
      cSet := oSet
   return cSet
}

GetTargetMType(oMType)
{
	local mAttrib := array("Magical","Dragon","Humanoid","Demon","Undead","Animal","Monster")
   ; get the attached window dimensions
   scan.GetWindowRect(w,h,x,y)
   cRect := f_GetClientRect(oLDP_Basics.hWnd)

   ; setting up the vector to calculate the region to search in and initializing gdip stuff
   screenrect := object("x", w*0.415+x, "y", h*0.03+y, "w", w*0.14, "h", h*0.07)
   ;hBitmapOCR := HBitmapFromScreen(screenrect["x"],screenrect["y"],screenrect["w"],screenrect["h"])

   pBitmap1 := Gdip_BitmapFromScreen(screenrect["x"] "|" screenrect["y"] "|" screenrect["w"] "|" screenrect["h"])
   Gdip_GetImageDimensions(pBitmap1, w, h), mf:= 10 ; mf: magnifying factor
   pBitmapNew:= Gdip_CreateBitmap(w*mf, h*mf)
   pGraphicsNew:= Gdip_GraphicsFromImage(pBitmapNew)
   Gdip_DrawImage(pGraphicsNew,pBitmap1,0,0,w*mf,h*mf,0,0,w,h)
   ;Gdip_SaveBitmapToFile(pBitmapNew, A_ScriptDir "\out.png")
   hBitmapOCR:= Gdip_CreateHBITMAPFromBitmap(pBitmapNew)
   DllCall("DeleteObject", "Ptr", hBitmapNew), Gdip_DeleteGraphics(pGrgraphicsNew)
   Gdip_DisposeImage(pBitmapNew)

   if (dbg)
      overlay.DrawRectangle(cRect["w"]*0.415+cRect["x"], cRect["h"]*0.01+cRect["y"], cRect["w"]*0.14, cRect["h"]*0.06,0xFF0FFFF0,2)
   pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmapOCR)
   DllCall("DeleteObject", "Ptr", hBitmapOCR)

   ; OCR magic and str preparation happens here
   oTargetInfo := StrSplit(ocr(pIRandomAccessStream), A_Space, , 2)

   ; checking for string similarity
   strMonsterAttrib := oStrSim.simpleBestMatch(TidyString(oTargetInfo[1]), mAttrib)
   if (!strMonsterAttrib)
      strMonsterAttrib := oMType
   return strMonsterAttrib
}

SwitchCurrentSet(cMType)
{
	SetIndexOffset := 105, SetIndexEndy := 1385, SetIndexStarty := 440, SetIndexStartx := 3365
	loop, % SetIndex.MaxIndex() {
		if (SetIndex[A_Index] = cMType) {
			adb_input("tap", SetIndexStartx, SetIndexEndy)
			sleep, 250
			adb_input("tap", SetIndexStartx, SetIndexStarty + (A_Index * SetIndexOffset) - SetIndexOffset)
			return A_Index
		}
	}
}