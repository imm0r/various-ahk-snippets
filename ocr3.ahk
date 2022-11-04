#NoEnv
SetBatchLines, -1
DetectHiddenWindows, On

#include <win>

pToken := GdipStartup()

textrect := [], results := []

hwnd := GetHwnd( "LDPlayer", "dnplayer.exe" )
ControlGet, MainClassHwnd, hwnd,, SubWin1


Physical_Monitor := GetPhysicalMonitorsFromHMONITOR()

ChildPointStruct := []
ChildPointStruct := GetChildHWND(MainClassHwnd, "SubWin1")
msgbox, % "Child X: " ChildPointStruct.x
msgbox, % "Child X: " ChildPointStruct%x% "`nChild Y: " ChildPointStruct%y%
msgbox, % "Child X: " ChildPointStruct[x]
msgbox, % "Child X: " ChildPointStruct["x"]

pBitmap := Gdip_BitmapFromScreen(hBitmap, MainClassHwnd)


GdipGetImageDimensions(pBitmap, Width, Height)
SS_BITMAP := 0xE, STM_SETIMAGE := 0x172, IMAGE_BITMAP := 0
Gui, -DPIScale ToolWindow
Gui, Margin, 0, 0
Gui, Add, Text, hWndPic w%Width% h%Height% +%SS_BITMAP%
PostMessage, STM_SETIMAGE, IMAGE_BITMAP, hBitmap,, ahk_id %Pic%
Gui, Show, x24 y24


pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)

text := ocr(pIRandomAccessStream, "")
Loop, parse, text, `n, `r
	NrOfLines := A_Index
Loop, parse, text, `n, `r
{
	textrect.insert(A_LoopField)
    If InStr(A_LoopField, "Join") || InStr(A_LoopField, "Accept")  {
		If( commend > 0 ) {
			textnew := ""
			loop, % commend - commstart
				textnew .= textrect[commstart + A_Index - 1] " "
			if( textold != textnew ) {
				results.insert( textnew )
				commend := 0, textold := textnew
			}
			
		}
		textnew := A_LoopField " "
		commstart := A_Index
	}
    If InStr(A_LoopField, "Public") || InStr(A_LoopField, "Office") || A_Index = NrOfLines
		commend := A_Index
}

msgbox, % "Nr of lines: " NrOfLines

loop, % results.MaxIndex()
	MsgBox, % results[A_Index]

DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
DllCall("DeleteObject", "ptr", hBitmap)
GdipShutdown(pToken)
Return

GuiClose:
GuiEscape:
	ExitApp

GdipStartup() {
	if !DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
		DllCall("LoadLibrary", "str", "gdiplus")
	VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", "uptr*", pToken, "ptr", &si, "ptr", 0)
	return pToken
}
GdipShutdown(pToken) {
	DllCall("gdiplus\GdiplusShutdown", "uptr", pToken)
	if hModule := DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
		DllCall("FreeLibrary", "ptr", hModule)
	return 0
}
GdipGetImageDimensions(pBitmap, ByRef Width, ByRef Height) {
	DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", Width)
	DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", Height)
}
Gdip_BitmapFromScreen(ByRef hBitmap, Screen=0, Raster="") {
	if (Screen = 0) {
		Sysget, x, 76
		Sysget, y, 77
		Sysget, w, 78
		Sysget, h, 79
	}
	else if (SubStr(Screen, 1, 5) = "hwnd:") {
		Screen := SubStr(Screen, 6)
		if !WinExist( "ahk_id " Screen)
			return -2
		WinGetPos,,, w, h, ahk_id %Screen%
		x := y := 0
		hhdc := GetDCEx(Screen, 3)
	}
	else if (SubStr(Screen, 1, 12) = "client_hwnd:") {
		Screen := SubStr(Screen, 13)
		if !WinExist( "ahk_id " Screen)
			return -2
		WinP := WinGetP(Screen)
		x := WinP.Client2Win.x, y := WinP.Client2Win.y, w := WinP.Client2Win.w, h := WinP.Client2Win.h
		hhdc := GetDCEx(Screen, 3)
	}
	else if (Screen&1 != "") {
		Sysget, M, Monitor, %Screen%
		x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
	}
	else {
		StringSplit, S, Screen, |
		x := S1, y := S2, w := S3, h := S4
	}
	
	if (x = "") || (y = "") || (w = "") || (h = "")
		return -1

	chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
	BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
	ReleaseDC(hhdc)

	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hBitmap, "uint", 0xffffffff)
	SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
	return pBitmap
}
GetDCEx(hwnd, flags=0, hrgnClip=0) {
	return DllCall("GetDCEx", "uint", hwnd, "uint", hrgnClip, "int", flags)
}
CreateCompatibleDC(hdc=0) {
	return DllCall("CreateCompatibleDC", "uint", hdc)
}
CreateDIBSection(w, h, hdc:="", bpp:=32, ByRef ppvBits:=0) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	hdc2 := hdc ? hdc : GetDC()
	
	VarSetCapacity(bi, 40, 0)

	NumPut(w, bi, 4, "uint"), NumPut(h, bi, 8, "uint"), NumPut(40, bi, 0, "uint")
	NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16, "uInt"), NumPut(bpp, bi, 14, "ushort")

	hbm := DllCall("CreateDIBSection", Ptr, hdc2, Ptr, &bi, "uint", 0, A_PtrSize ? "UPtr*" : "uint*", ppvBits, Ptr, 0, "uint", 0, Ptr)

	if !hdc
		ReleaseDC(hdc2)
	return hbm
}
GetDC(hwnd=0){
	return DllCall("GetDC", "uint", hwnd)
}
ReleaseDC(hdc, hwnd=0) {
	return DllCall("ReleaseDC", "uint", hwnd, "uint", hdc)
}
SelectObject(hdc, hgdiobj) {
	return DllCall("SelectObject", "uint", hdc, "uint", hgdiobj)
}
BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="") {
	return DllCall("gdi32\BitBlt", "uint", dDC, "int", dx, "int", dy, "int", dw, "int", dh
	, "uint", sDC, "int", sx, "int", sy, "uint", Raster ? Raster : 0x00CC0020)
}
Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0) {
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "uint", hBitmap, "uint", Palette, "uint*", pBitmap)
	return pBitmap
}
DeleteObject(hObject) {
	return DllCall("DeleteObject", "uint", hObject)
}
DeleteDC(hdc) {
	return DllCall("DeleteDC", "uint", hdc)
}
WinGetP(hwnd) {
	WinGetPos, x, y, w, h, ahk_id %hWnd%
	WinP := {x:x, y:y, w:w, h:h}
	VarSetCapacity(pt, 16)
	NumPut(x, pt, 0) || NumPut(y, pt, 4) || NumPut(w, pt, 8) || NumPut(h, pt, 12)
	if (!DllCall("GetClientRect", "uint", hwnd, "uint", &pt))
		Return
	if (!DllCall("ClientToScreen", "uint", hwnd, "uint", &pt))
		Return
	x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
	w := NumGet(pt, 8, "int"), h := NumGet(pt, 12, "int")
	Client := {x:x, y:y, w:w, h:h}
	Client2Win := {x:x-WinP.x, y:y-WinP.y, w:w, h:h}
	Return WinP := {x:WinP.x, y:WinP.y, w:WinP.w, h:WinP.h, Client2Win:Client2Win, Client:Client}
}
getClientRect(hwnd=0, byRef tX="", byRef tY="", byRef tW="", byRef tH="") {
	hwnd:=hwnd ? hwnd : WinExist()    ; use LFW if no hwnd given
	VarSetCapacity(rt, 16)            ; alloc. mem. for RECT struc.
	VarSetCapacity(pt, 8, 0)          ; alloc. mem. for POINT struc.
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rt)
	DllCall("ClientToScreen", "ptr", hWnd, "ptr", &pt)
	tX:=NumGet(pt, 0, "int"), tY:=NumGet(pt, 4, "int")
	tW:=NumGet(rt, 8, "int"), tH:=NumGet(rt, 12, "int")
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

GetArea() {
   area := []
   StartSelection(area)
   while !area.w
      Sleep, 100
   Return area
}
   
StartSelection(area) {
   handler := Func("Select").Bind(area)
   Hotkey, LButton, % handler, On
   ReplaceSystemCursors("IDC_CROSS")
}

Select(area) {
   static hGui := CreateSelectionGui()
   Hook := new WindowsHook(WH_MOUSE_LL := 14, "LowLevelMouseProc", hGui)
   Loop {
      KeyWait, LButton
      WinGetPos, X, Y, W, H, ahk_id %hGui%
   } until w > 0
   ReplaceSystemCursors("")
   Hotkey, LButton, Off
   Hook := ""
   Gui, %hGui%:Show, Hide
   for k, v in ["x", "y", "w", "h"]
      area[v] := %v%
}

ReplaceSystemCursors(IDC = "")
{
   static IMAGE_CURSOR := 2, SPI_SETCURSORS := 0x57
        , exitFunc := Func("ReplaceSystemCursors").Bind("")
        , SysCursors := { IDC_APPSTARTING: 32650
                        , IDC_ARROW      : 32512
                        , IDC_CROSS      : 32515
                        , IDC_HAND       : 32649
                        , IDC_HELP       : 32651
                        , IDC_IBEAM      : 32513
                        , IDC_NO         : 32648
                        , IDC_SIZEALL    : 32646
                        , IDC_SIZENESW   : 32643
                        , IDC_SIZENWSE   : 32642
                        , IDC_SIZEWE     : 32644
                        , IDC_SIZENS     : 32645 
                        , IDC_UPARROW    : 32516
                        , IDC_WAIT       : 32514 }
   if !IDC {
      DllCall("SystemParametersInfo", UInt, SPI_SETCURSORS, UInt, 0, UInt, 0, UInt, 0)
      OnExit(exitFunc, 0)
   }
   else  {
      hCursor := DllCall("LoadCursor", Ptr, 0, UInt, SysCursors[IDC], Ptr)
      for k, v in SysCursors  {
         hCopy := DllCall("CopyImage", Ptr, hCursor, UInt, IMAGE_CURSOR, Int, 0, Int, 0, UInt, 0, Ptr)
         DllCall("SetSystemCursor", Ptr, hCopy, UInt, v)
      }
      OnExit(exitFunc)
   }
}

CreateSelectionGui() {
   Gui, New, +hwndhGui +Alwaysontop -Caption +LastFound +ToolWindow +E0x20 -DPIScale
   WinSet, Transparent, 130
   Gui, Color, FFC800
   Return hGui
}

LowLevelMouseProc(nCode, wParam, lParam) {
   static WM_MOUSEMOVE := 0x200, WM_LBUTTONUP := 0x202
        , coords := [], startMouseX, startMouseY, hGui
        , timer := Func("LowLevelMouseProc").Bind("timer", "", "")
   
   if (nCode = "timer") {
      while coords[1] {
         point := coords.RemoveAt(1)
         mouseX := point[1], mouseY := point[2]
         x := startMouseX < mouseX ? startMouseX : mouseX
         y := startMouseY < mouseY ? startMouseY : mouseY
         w := Abs(mouseX - startMouseX)
         h := Abs(mouseY - startMouseY)
         try Gui, %hGUi%: Show, x%x% y%y% w%w% h%h% NA
      }
   }
   else {
      (!hGui && hGui := A_EventInfo)
      if (wParam = WM_LBUTTONUP)
         startMouseX := startMouseY := ""
      if (wParam = WM_MOUSEMOVE)  {
         mouseX := NumGet(lParam + 0, "Int")
         mouseY := NumGet(lParam + 4, "Int")
         if (startMouseX = "") {
            startMouseX := mouseX
            startMouseY := mouseY
         }
         coords.Push([mouseX, mouseY])
         SetTimer, % timer, -10
      }
      Return DllCall("CallNextHookEx", Ptr, 0, Int, nCode, UInt, wParam, Ptr, lParam)
   }
}

class WindowsHook {
   __New(type, callback, eventInfo := "", isGlobal := true) {
      this.callbackPtr := RegisterCallback(callback, "Fast", 3, eventInfo)
      this.hHook := DllCall("SetWindowsHookEx", "Int", type, "Ptr", this.callbackPtr
                                              , "Ptr", !isGlobal ? 0 : DllCall("GetModuleHandle", "UInt", 0, "Ptr")
                                              , "UInt", isGlobal ? 0 : DllCall("GetCurrentThreadId"), "Ptr")
   }
   __Delete() {
      DllCall("UnhookWindowsHookEx", "Ptr", this.hHook)
      DllCall("GlobalFree", "Ptr", this.callBackPtr, "Ptr")
   }
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

F10::
	reload
return

F12::
	exitapp
return