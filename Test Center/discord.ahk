#NoEnv
FileEncoding, UTF-8
SetBatchLines, -1
CoordMode, Pixel, Screen

#Include <Discord>
#Include <notify>
#Include <json>
#include <ocr>

GDIP("Startup")

;Place your url here
token := "OTU3MjA1NjU3NTAzNjYyMDg.G_KGwF.EjK653LUfIEw8nCVe9RVtxiyrGCaak47DZuMms"
token_type := "user"
_channel_id := "1143848555484827818"
_button_id := "sell all"
_guild_id := "95722198492250112"
_application_id := "574652751745777665"

If (token_type = "user")
  client := new discord(token, "user")
Else
  client := new discord(token, "bot")

client.intents := 3276799 ; All intents

;msgbox, % ocr("F:\ahk\Test Center\captcha.png")

messages := client.GetChannelMessages("1143848555484827818", 1)
return

t_fishing:
    messages := {}
    messages := client.GetChannelMessages(_channel_id, 1)
    ;msgbox, % "Nachrichten ID: " messages[1].id "`n`nNachrichteninhalt:`n" messages[1].embeds[1].description
    response := client.ClickButton(_application_id, _guild_id, _channel_id, client.component_custom_id)
    ;msgbox, % response
    
return

2::
    messages := client.GetChannelMessages(_channel_id, 1)
    response := client.ClickButton(_application_id, _guild_id, _channel_id, _button_id)
    ;msgbox, % response
return

3::
  runCMD("Capture2Text_CLI.exe -i captcha.png")
  captcha := readCaptcha()
  clipboard := captcha
  msgbox, % captcha
return

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