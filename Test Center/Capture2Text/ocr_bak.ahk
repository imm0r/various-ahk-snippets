
readCaptcha()
{
  hWnd_discord := WinExist("ahk_exe Discord.exe")

  global oText := []
  global oLastMsg := []
  global oDiscordPos := []
  getClientRect(hWnd_discord, cX, cY, cW, cH)
  oDiscordPos.push(cX + 450, cY, cW - 450 - 350, cH)

  fullText := imgToText(hWnd_discord, oDiscordPos)
  GetLastMsg(fullText)
  Loop, % oText.MaxIndex()
  {
      msgbox, % oText[A_Index]
    If InStr(oText[A_Index], "All captchas are case") || InStr(oText[A_Index], "This captcha gets sent")
    {
      captchaLine := A_Index - 1
      latestCaptcha := regexreplace(oText[captchaLine], " ", "")
      if StrLen(latestCaptcha == 6)
        return, % latestCaptcha
      else
        return, false
    }
  }
}

GDIP(C:="Startup") {                                      ; By SKAN on D293 @ bit.ly/2krOIc9
;@ahk-neko-ignore-fn 1 line; at 31.8.2023, 12:14:48 ; case sensitivity
  Static SI:=Chr(!(VarSetCapacity(Si,24,0)>>16)), pToken:=0, hMod:=0, Res:=0, AOK:=0
  If (AOK := (C="Startup" and pToken=0) Or (C<>"Startup" and pToken<>0)) {
      If (C="Startup") {
         hMod := DllCall("LoadLibrary", "Str","gdiplus.dll", "Ptr")
         Res  := DllCall("gdiplus\GdiplusStartup", "PtrP",pToken, "Ptr",&SI, "UInt",0)
      } Else { 
         Res  := DllCall("gdiplus\GdiplusShutdown", "Ptr",pToken)
         DllCall("FreeLibrary", "Ptr",hMod),   hMod:=0,   pToken:=0
      }
   }
   Return (AOK ? !Res : Res:=0)    
}

imgToText(hWnd, oCoords := "")
{
   if WinExist("ahk_id " hWnd)
   {
      WinActivate, % "ahk_id " hWnd
      if isObject(oCoords)
      {
         hBitmap := HBitmapFromScreen(oCoords[1], oCoords[2], oCoords[3], oCoords[4])
         pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
         DllCall("DeleteObject", "Ptr", hBitmap)
         return, % ocr(pIRandomAccessStream, "FirstFromAvailableLanguages")
      }
   }
}

GetLastMsg(text)
{
   global oText := []
   if(text)
   {
      Loop, parse, text, `n, `r
      {
         if A_Loopfield is not Space
         {
            if StrLen(A_Loopfield) > 1
            {
               oText.Push(A_Loopfield)
               If InStr(A_LoopField, "heute um") || InStr(A_LoopField, "gestern um")
                  LastMsgStart := A_Index
            }
         }
      }
      tMsgHandler := ""
      tLoop := oText.MaxIndex() - LastMsgStart
      loop, % tLoop
      {
         tMsgHandler .= oText[LastMsgStart] "`n"
         LastMsgStart++
         if instr(oText[LastMsgStart], "Fish Again") || instr(oText[LastMsgStart], "Nachricht an #") || instr(oText[LastMsgStart], "Return")
            break
      }
      return tMsgHandler
   }
}