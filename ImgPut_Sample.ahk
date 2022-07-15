#include <ImagePut>
#singleinstance force

global oPos_mType, oNdl_mType, oStr_mType, _dbg

_dbg := false

oPos_InvMP := Object("x", 1060, "y", 1210, "w", 110, "h", 130, "x2", 1210 + 130, "cX", 1060 + 80, "cY", 1210 + 35)
oPos_mType := Object("x", 1340, "y", 25, "w", 360, "h", 45, "x2", 25 + 45, "cX", 1340 + 80, "cY", 25 + 35)
oNdl_mType := Object(1, "agisc", 2, "rache", 3, "umano", 4, "ämon", 5, "ntot")
oStr_mType := Object(1, "Magical", 2, "Dragon", 3, "Humanoid", 4, "Demonic", 5, "Undead")

ImagePut.gdiplusStartup()

L2Rhwnd := GetHwnd( "LDPlayer", "dnplayer.exe" )
ControlGet, MainClassHwnd, hwnd,, SubWin1

rectHandle := DrawRectangle(oPos_mType["x"], oPos_mType["y"], oPos_mType["w"], oPos_mType["h"])
SetTimer, Timer_GetMobType, 1000

Timer_GetMobType:
   ; clearing shared variables
   if(sPic)
      ImageDestroy(sPic) 
   if(cPic)
      ImageDestroy(cPic)
   DllCall("DeleteObject", "Ptr", sPic)
   DllCall("DeleteObject", "Ptr", cPic)
   if WinActive("ahk_id " L2Rhwnd)
   {
      cPic := "", sPic := "", rStrOCR := "", pRAS := ""

      ; Getting a copy of the current inGame screen
      cPic := ImagePutBuffer("ahk_id " MainClassHwnd)

      ; Is Inventory opened?
      ; Cropping a specific area from the previously captured inGame screen. This area contains parts of interest.
      sPic := ImagePutBuffer({image: cPic, crop: [oPos_InvMP["x"], oPos_InvMP["y"], oPos_InvMP["w"], oPos_InvMP["h"]]})
      pRAS := ImagePutRandomAccessStream(sPic)

      ; trying to OCR the previously copped area
      rStrOCR := ocr(pRAS, "FirstFromAvailableLanguages")

      if(_dbg) {
         sPic.Show()
         traytip, % "OCR-Result:", % rStrOCR, , 34
      }
      ; checking if the OCR result matches what we are looking for.
      If if InStr(rStrOCR, "LP") || InStr(TextLine, "MP")
      {
         ; OCR check successfull! Drawing a red rectangle around the search area.
         chk_IsInvOpen := 1
         Gui % rectHandle ": Show", % "NA x" oPos_InvMP["cX"] " y" oPos_InvMP["cY"] " w" oPos_InvMP["w"] " h" oPos_InvMP["h"]
         Gui, +LastFound
         DllCall("RedrawWindow", "uint", rectHandle, "uint", 0, "uint", 0, "uint", 5)
      } else {
         chk_IsInvOpen := 0
      }
      ; clearing shared variables
      sPic := "", rOCR := "", pRAS := ""		

      ; Is Monster targeted? What kind of element is the monster?
      ; Cropping a specific area from the previously captured inGame screen. This area contains parts of interest.
      sPic := ImagePutBuffer({image: cPic, crop: [oPos_mType["x"], oPos_mType["y"], oPos_mType["w"], oPos_mType["h"]]})
      pRAS := ImagePutRandomAccessStream(sPic)

      ; trying to OCR the previously copped area
      rOCR := StrSplit(ocr(pRAS, "FirstFromAvailableLanguages"), "(")

      if(_dbg) {
         ;sPic.Show()
         traytip, % "OCR-Result:", % rOCR[1], , 34
      }

      ; checking if the OCR result matches what we are looking for.
      If(rOCR[1] != "")
      {
         loop, % oNdl_mType.MaxIndex()
         {
            If InStr(rOCR[1], oNdl_mType[A_Index])
            {
               If(rOCR[1] != oldMType)
               {
                  Gui % rectHandle ": Show", % "NA x" oPos_mType["cX"] " y" oPos_mType["cY"] " w" oPos_mType["w"] " h" oPos_mType["h"]
                  traytip, % rOCR[1], % "MobType found: " oStr_mType[A_Index] "`nOld MobType: " oldMType, , 34
                  oldMType := rOCR[1]
                  break
               }
            } else {
               oldMType := ""
            }
         }
      } else {
         if(oldMType == "") {
            Gui % rectHandle ": Hide"
         }
      }
   } else {
      Gui % rectHandle ": Hide"
   }
return

/*
WinActivate, % "ahk_id " hwnd
WinWaitActive, % "ahk_id " hwnd
if xy := cPic.ImageSearch(sPic)										; Search image
{
    MouseMove xy[1]+15, xy[2]+45											; Move cursor
	SendToHwnd( hwnd, "LButton" )
	msgbox, % "magic mobtype found at position:  " xy[1] " | " xy[2]+20
}
*/

   ImagePut.gdiplusShutdown()
DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
DllCall("DeleteObject", "ptr", hBitmap)
GdipShutdown(pToken)

HideTrayTip() {
   TrayTip ; Normale Methode zum Verstecken benutzen.
   if SubStr(A_OSVersion,1,3) = "10." {
      Menu Tray, NoIcon
      Sleep 200 ; Möglicherweise muss dieser Sleep-Wert angepasst werden.
      Menu Tray, Icon
   } else {
      TrayTip 
   }
}

DrawRectangle(x1:=0, y1:=0, w1:=0, h1:=0, n:=1, bw:=3, cl:="ff0000") { ; flyingDman, RRR
   Global FirstCall
   if (w1=0 && h1=0) {
      Gui % (n ": Destroy", FirstCall:=[])
      Return
   }
   FirstCall? "": FirstCall:=[], FirstCall[n]? "": (FirstCall[n]:=[], FirstCall[n].1:=1)
   , w1<0? (w1:=Abs(w1), x1:=x1-w1): "", h1<0? (h1:=Abs(h1), y1:=y1-h1): ""
   Gui % n ": +LastFound"
   w2:= w1 - bw, h2:= h1 - bw
   WinSet, Region, 0-0 %w1%-0 %w1%-%h1% 0-%h1% 0-0 %bw%-%bw% %w2%-%bw% %w2%-%h2% %bw%-%h2% %bw%-%bw%
   If FirstCall[n].1 {
      Gui % n ": -Caption +AlwaysOnTop +ToolWindow -DPIScale +HWNDhwnd +e0x8000088"
      Gui % n ": Color", % cl
      FirstCall[n].1:= 0
   } Gui % n ": Hide", NA x%x1% y%y1% w%w1% h%h1% ; performs better then WinMove over some controls
return, % n
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
      DllCall(NumGet(NumGet(OcrEngineStatics+0)+6*A_PtrSize), "ptr", OcrEngineStatics, "uint*", MaxDimension) ; MaxImageDimension
   }
   if (file = "ShowAvailableLanguages")
   {
      if (GlobalizationPreferencesStatics = "")
         CreateClass("Windows.System.UserProfile.GlobalizationPreferences", IGlobalizationPreferencesStatics := "{01BF4326-ED37-4E96-B0E9-C1340D1EA158}", GlobalizationPreferencesStatics)
      DllCall(NumGet(NumGet(GlobalizationPreferencesStatics+0)+9*A_PtrSize), "ptr", GlobalizationPreferencesStatics, "ptr*", LanguageList) ; get_Languages
      DllCall(NumGet(NumGet(LanguageList+0)+7*A_PtrSize), "ptr", LanguageList, "int*", count) ; count
      loop % count
      {
         DllCall(NumGet(NumGet(LanguageList+0)+6*A_PtrSize), "ptr", LanguageList, "int", A_Index-1, "ptr*", hString) ; get_Item
         DllCall(NumGet(NumGet(LanguageFactory+0)+6*A_PtrSize), "ptr", LanguageFactory, "ptr", hString, "ptr*", LanguageTest) ; CreateLanguage
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+8*A_PtrSize), "ptr", OcrEngineStatics, "ptr", LanguageTest, "int*", bool) ; IsLanguageSupported
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
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+10*A_PtrSize), "ptr", OcrEngineStatics, "ptr*", OcrEngine) ; TryCreateFromUserProfileLanguages
      else
      {
         CreateHString(lang, hString)
         DllCall(NumGet(NumGet(LanguageFactory+0)+6*A_PtrSize), "ptr", LanguageFactory, "ptr", hString, "ptr*", Language) ; CreateLanguage
         DeleteHString(hString)
         DllCall(NumGet(NumGet(OcrEngineStatics+0)+9*A_PtrSize), "ptr", OcrEngineStatics, ptr, Language, "ptr*", OcrEngine) ; TryCreateFromLanguage
      }
      if (OcrEngine = 0)
      {
         msgbox Can not use language "%lang%" for OCR, please install language pack.
            ExitApp
      }
      CurrentLanguage := lang
   }
   IRandomAccessStream := file
   DllCall(NumGet(NumGet(BitmapDecoderStatics+0)+14*A_PtrSize), "ptr", BitmapDecoderStatics, "ptr", IRandomAccessStream, "ptr*", BitmapDecoder) ; CreateAsync
   WaitForAsync(BitmapDecoder)
   BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
   DllCall(NumGet(NumGet(BitmapFrame+0)+12*A_PtrSize), "ptr", BitmapFrame, "uint*", width) ; get_PixelWidth
   DllCall(NumGet(NumGet(BitmapFrame+0)+13*A_PtrSize), "ptr", BitmapFrame, "uint*", height) ; get_PixelHeight
   if (width > MaxDimension) or (height > MaxDimension)
   {
      msgbox Image is to big - %width%x%height%.`nIt should be maximum - %MaxDimension% pixels
      ExitApp
   }
   BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
   DllCall(NumGet(NumGet(BitmapFrameWithSoftwareBitmap+0)+6*A_PtrSize), "ptr", BitmapFrameWithSoftwareBitmap, "ptr*", SoftwareBitmap) ; GetSoftwareBitmapAsync
   WaitForAsync(SoftwareBitmap)
   DllCall(NumGet(NumGet(OcrEngine+0)+6*A_PtrSize), "ptr", OcrEngine, ptr, SoftwareBitmap, "ptr*", OcrResult) ; RecognizeAsync
   WaitForAsync(OcrResult)
   DllCall(NumGet(NumGet(OcrResult+0)+6*A_PtrSize), "ptr", OcrResult, "ptr*", LinesList) ; get_Lines
   DllCall(NumGet(NumGet(LinesList+0)+7*A_PtrSize), "ptr", LinesList, "int*", count) ; count
   loop % count
   {
      DllCall(NumGet(NumGet(LinesList+0)+6*A_PtrSize), "ptr", LinesList, "int", A_Index-1, "ptr*", OcrLine)
      DllCall(NumGet(NumGet(OcrLine+0)+7*A_PtrSize), "ptr", OcrLine, "ptr*", hText) 
      buffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", length, "ptr")
      text .= StrGet(buffer, "UTF-16") "`n"
      ObjRelease(OcrLine)
   }
   Close := ComObjQuery(IRandomAccessStream, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
   DllCall(NumGet(NumGet(Close+0)+6*A_PtrSize), "ptr", Close) ; Close
   ObjRelease(Close)
   Close := ComObjQuery(SoftwareBitmap, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
   DllCall(NumGet(NumGet(Close+0)+6*A_PtrSize), "ptr", Close) ; Close
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

CreateHString(string, ByRef hString) {
   DllCall("Combase.dll\WindowsCreateString", "wstr", string, "uint", StrLen(string), "ptr*", hString)
}

DeleteHString(hString) {
   DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
}

WaitForAsync(ByRef Object)
{
   AsyncInfo := ComObjQuery(Object, IAsyncInfo := "{00000036-0000-0000-C000-000000000046}")
   loop
   {
      DllCall(NumGet(NumGet(AsyncInfo+0)+7*A_PtrSize), "ptr", AsyncInfo, "uint*", status) ; IAsyncInfo.Status
      if (status != 0)
      {
         if (status != 1)
         {
            DllCall(NumGet(NumGet(AsyncInfo+0)+8*A_PtrSize), "ptr", AsyncInfo, "uint*", ErrorCode) ; IAsyncInfo.ErrorCode
            msgbox AsyncInfo status error: %ErrorCode%
            ExitApp
         }
         ObjRelease(AsyncInfo)
         break
      }
      sleep 10
   }
   DllCall(NumGet(NumGet(Object+0)+8*A_PtrSize), "ptr", Object, "ptr*", ObjectResult) ; GetResults
   ObjRelease(Object)
   Object := ObjectResult
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