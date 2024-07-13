#NoEnv
SetBatchLines, -1
SetKeyDelay, 80, 41
CoordMode, Pixel, Screen
Gdip_Startup()

;Place your url here
global token := "OTU3MjA1NjU3NTAzNjYyMDg.G_KGwF.EjK653LUfIEw8nCVe9RVtxiyrGCaak47DZuMms"
global token_type := "user"
global _application_id := "574652751745777665"
global _guild_id := ""
global _channel_id := ""
global _button_id := "sell all"
global hWnd_discord := WinExist("ahk_exe Discord.exe")
global fishnames := { "Salmon": 0, "Cod": 0, "TropicalFish": 0, "Pufferfish": 0, "FieryPuffer": 0, "HotCod": 0, "Turtle": 0, "Dolphin": 0, "Guardian": 0, "EmeraldSquid": 0, "RainbowFish": 0, "SpaceFish": 0, "GalacticCrab": 0, "Squid": 0, "Fish": 0 }
global exotic := {"Gold": 0, "Emerald": 0, "Lava": 0, "Diamond": 0}
global sessionxp, startLvl, maxxp, captcha
global _cd := 3000
global firstRun := true

If (token_type = "user")
  client := new discord(token, "user")
Else
  client := new discord(token, "bot")

client.intents := 3276799 ; All intents
sleep 2000
_guild_id := client.GetGuildNameOrID("ZORN")
oChannelList := client.GetChannels(_guild_id)

testtmp := Json.Dump(client)
testtmp2 := Jxon.Load(testtmp)
msgbox, % testtmp2 "`n" testtmp2.MaxIndex()
;msgbox, % testtmp
;msgbox, % testtmp2.MaxIndex()

#Include gui.ahk
;#include gLabel.ahk
createGui()
loadtree(testtmp2)
FormatTime, LogTime, A_NOW, yyyy/MM/dd hh:mm:ss
GuiControl, Cmd:, _timestamp, % LogTime
GuiControl, Cmd:, _state, % "building guild and channel lists!"
GuiControl, Cmd:, _trips, % "done!" 

_cd:
    Gui, Cmd:Submit, NoHide
return

_guildlist:
   Gui, Cmd:Submit, NoHide
   _guild_id := client.GetGuildNameOrID("index" . _selectedGuild)
   oChannelList := client.GetChannels(_guild_id)
   Loop % oChannelList.MaxIndex() {
	if (A_Index = 1)
		_channellist := oChannelList[A_Index].name . "|"
	else
		_channellist .= "|" . oChannelList[A_Index].name
   }
   GuiControl,, _selectedChannel, % _channellist
   GuiControl,, _selectedGuildID, % _guild_id
return

_channellist:
   Gui, Cmd:Submit, NoHide
   _channel_id := client.guilds[_selectedGuild].channels[_selectedChannel].id
   GuiControl,, _selectedChannelID, % _channel_id
return

t_fishing:
   messages := {}
   messages := client.GetChannelMessages(_channel_id, 1)
   tmpLoot := regexreplace(client.content, "  ", " ")
   
   Loop, parse, tmpLoot, `n, `r
   {
      loot := StrSplit(A_LoopField, A_Space)
      if inStr(A_LoopField, "XP") {
         tripxp := RegExReplace(loot[1], "[^0-9]", "")
         sessionxp += tripxp
         if (sessionxp > maxxp) {
            firstRun := true
            response := client.ClickButton(_application_id, _guild_id, _channel_id, "play")
            client.GetChannelMessages(_channel_id, 1)
            sleep, 500
            GuiControl, Cmd:, _timestamp, % LogTime
            GuiControl, Cmd:, _state, % "switch back to fishing"
            response := client.ClickButton(_application_id, _guild_id, _channel_id, client.component_custom_id)
         }
         tripxp := 0
      } else {
         _fish := loot[2] . loot[3]
         for k, v in fishnames
            if (k == _fish) {
               fishnames[_fish] += loot[1]
            }
         _fish := ""
         
         for k, v in exotic
            if inStr(A_Loopfield, k . " Fish") {
               tmpExotic := RegExReplace(A_Loopfield, "[^0-9]", "")
               exotic[k] += tmpExotic
               tmpExotic := 0
            }
      }
   }
   tIndex := 0
   For k, v in fishnames {
      if (v) {
         tIndex++
         loottable .= k ": " v "`n"
         vLabel1 := "_fish_" tIndex "t"
         vLabel2 := "_fish_" tIndex
         GuiControl, Cmd:, %vLabel1%, %k%:
         GuiControl, Cmd:, %vLabel2%, % FormatNumber(v)
         Continue
      }
   }
   GuiControl, Cmd:, _session_xp, % FormatNumber(sessionxp)
   GuiControl, Cmd:, _exotic_Gold, % FormatNumber(exotic["Gold"])
   GuiControl, Cmd:, _exotic_Emerald, % FormatNumber(exotic["Emerald"])
   GuiControl, Cmd:, _exotic_Lava, % FormatNumber(exotic["Lava"])
   GuiControl, Cmd:, _exotic_Diamond, % FormatNumber(exotic["Diamond"])

   firstRun := true
   response := client.ClickButton(_application_id, _guild_id, _channel_id, client.component_custom_id)
    
return

F1::
   loottable := "fish:`n"
   For k, v in fishnames
      if (v)
         loottable .= k ": " v "`n"
   loottable .= "`nexotic fish:`n"
   For k, v in exotic
      if (v)
         loottable .= k "Fish: " v "`n"
   loottable .= "`n`nsession xp: " sessionxp
   msgbox, % loottable
return

F2::
   client.GetChannelMessages(_channel_id, 50)
return

t_verification:
   client.Verify(client.captcha)
return

#Include <class_Discord>
#Include <json>
#Include <jxon>
#include <Gdip_all>
#include jsontree.ahk