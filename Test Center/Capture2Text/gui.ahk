Loop % client.guilds.MaxIndex() {
	if (A_Index = 1)
		_guildlist := client.guilds[A_Index].name . "|"
	else
		_guildlist .= "|" . client.guilds[A_Index].name
}

createGui() {
    global

	Gui, Cmd:New, +Caption +LastFound -OwnDialogs -ToolWindow +Border +AlwaysOnTop +LabelCmd +HwndCmdHwnd +E0x02120000
    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x5 y5 w175 h125, fish caught this session:

	    Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, v_fish_1t x20 y35 w100 right, 
	    Gui, Cmd:Add, Text, v_fish_1 border Center readonly x125 y35 w45 h20,
	    Gui, Cmd:Add, Text, v_fish_2t x20 y57 w100 right, 
	    Gui, Cmd:Add, Text, v_fish_2 border Center readonly x125 y57 w45 h20,
	    Gui, Cmd:Add, Text, v_fish_3t x20 y79 w100 right, 
	    Gui, Cmd:Add, Text, v_fish_3 border Center readonly x125 y79 w45 h20,
	    Gui, Cmd:Add, Text, v_fish_4t x20 y101 w100 right, 
	    Gui, Cmd:Add, Text, v_fish_4 border Center readonly x125 y101 w45 h20,

    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x195 y5 w175 h125, exotic fish this session:

	    Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x210 y35, Gold Fish:
	    Gui, Cmd:Add, Text, v_exotic_Gold border Center readonly x315 y35 w45 h20, 0
	    Gui, Cmd:Add, Text, x210 y57, Emerald Fish:
	    Gui, Cmd:Add, Text, v_exotic_Emerald border Center readonly x315 y57 w45 h20, 0
	    Gui, Cmd:Add, Text, x210 y79, Lava Fish:
	    Gui, Cmd:Add, Text, v_exotic_Lava border Center readonly x315 y79 w45 h20, 0
	    Gui, Cmd:Add, Text, x210 y101, Diamond Fish:
	    Gui, Cmd:Add, Text, v_exotic_Diamond border Center readonly x315 y101 w45 h20, 0

    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x5 y135 w365 h65, player stats:

        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, v_level border Center readonly x20 y165 w50,
	    Gui, Cmd:Add, Text, v_session_xp border Center readonly x100 y165 w120 h20,
	    Gui, Cmd:Add, Text, v_needed_xp border Center readonly x235 y165 w120 h20,

    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x5 y200 w365 h65, current state:

    	Gui, Cmd:Font, s11, % "Bahnschrift Condensed"
	    Gui, Cmd:Add, Text, v_timestamp border center readonly x15 y230 w110 h24
	    Gui, Cmd:Add, Text, v_state border center readonly x130 y230 w185 h24
	    Gui, Cmd:Add, Text, v_trips border center readonly x320 y230 w40 h24

    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x5 y265 w365 h180, config:

        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, readonly x15 y280 h20 w340 center, guild/channel to observe

	    Gui, Cmd:Add, Text, x5 y310 h20 w60 right, guild:
        Gui, Cmd:Font, s11, % "Bahnschrift Condensed"
	    Gui, Cmd:Add, DropDownList, v_selectedGuild g_guildlist AltSubmit x70 y307 w145 h125, % _guildlist
        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x222 y309 h20, ID:
        Gui, Cmd:Font, s11, % "Bahnschrift Condensed"
	    Gui, Cmd:Add, Text, x240 y309 h20 w120 center border v_selectedGuildID, % _guild_id
        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x5 y340 h20 w60 right, channel:
        Gui, Cmd:Font, s11, % "Bahnschrift Condensed"
	    Gui, Cmd:Add, DropDownList, v_selectedChannel g_channellist AltSubmit border x70 y337 w145 h125, % _channellist
        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x222 y339 h20, ID:
        Gui, Cmd:Font, s11, % "Bahnschrift Condensed"
	    Gui, Cmd:Add, Text, x240 y339 h20 w120 center border v_selectedChannelID, 
        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"

	Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Text, readonly x15 y370 h20 w340 center, misc

	    Gui, Cmd:Add, Text, x5 y392 h20 w60 right, cooldown:
        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Edit, v_cd g_cd x70 y390 w55 h23 center, % _cd
	    Gui, Cmd:Add, Text, x126 y392 h20, ms

    Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, GroupBox, x5 y465 w365 h120, performance:

        Gui, Cmd:Font, s11, % "Bahnschrift SemiCondensed"
	    Gui, Cmd:Add, Text, x5 y490 h20 w120 right, HTTP Request:
	    Gui, Cmd:Add, Text, v_qpc2 x130 y490 w60 h23 center border, 
	    Gui, Cmd:Add, Text, x191 y490 h20 left, ms

	    Gui, Cmd:Add, Text, x5 y520 h20 w120 right, onMessage():
	    Gui, Cmd:Add, Text, v_qpc x130 y520 w60 h23 center border, 
	    Gui, Cmd:Add, Text, x191 y520 h20 left, ms

		
		
		Gui, Cmd:Add, TreeView, xs y+30 w400 r17 Checked HwndtreeHwnd vMyTreeName

    Gui, Cmd:Show, , VF Bot
    guiID := WinExist("A")
	Gui, Cmd:Default
}