#Include <JSON>
#Include <Discord>

;Place your url here
webhook_url = https://discord.com/api/webhooks/1146998525759074316/Grq20cqWoZonuIARjHK14lumMa1Jthf7fFwbywo7o0hudOdJoFMXmQoiiZSO3vzCeKP3

token := "OTU3MjA1NjU3NTAzNjYyMDg.G_KGwF.EjK653LUfIEw8nCVe9RVtxiyrGCaak47DZuMms"

token_type = user

If (token_type = "user")
  client := new discord(token, "user")
Else
  client := new discord(token, "bot")
client.intents := 3276799 ; All intents

msg := []
msg := client.GetChannelMessages("1143848555484827818")

loop, % msg,MaxIndex()
    msgbox, % msg[A_Index]
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    