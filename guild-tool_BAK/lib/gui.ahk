condition_AllwaysOnTop := 0
global cm_Curr := 1

createGui() {
    global
    aList_ClanMembersMain := GetClanMembersFromRange(xlRNG_listMembers)
	Gui, Cmd:New, +Caption +LastFound -OwnDialogs -ToolWindow +Border +AlwaysOnTop +LabelCmd +HwndCmdHwnd +E0x02120000
	Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Text, x5 y5 readonly w350 center vLvl_Descript, Enter the weekly donation points for clan member:
	Gui, Cmd:Font, s16, % "Bahnschrift SemiCondensed"
    Gui, Cmd:Add, Text, x5 y35 w150 h35 vLbl_CurrClanMember readonly right, % aList_ClanMembers[cm_Curr]
    Gui, Cmd:Add, Edit, x170 y34 w60 h30 vEdit_CurrDonation center number, 0
	Gui, Cmd:Font, s12, % "Bahnschrift SemiCondensed"
	Gui, Cmd:Add, Button, g_AddToTotal vLlbl_AddToTotal x110 y75 h30 hidden1, Transfer data now
	Gui, Cmd:Add, Button, g_AddDonation vLbl_AddDonation x105 y75 h30, &Add donations to member
    
	GuiControl, Focus, Lbl_CurrClanMember
    Gui, Cmd:Show, x1 y1, HF Clan Manager
    
    guiID := WinExist("A")
}
;   "pwsh.exe -Command "& {Start-Process pwsh.exe -ArgumentList '-ExecutionPolicy Bypass -File "F:\ahk\guild tool\apiCallback.ps1"' -Verb RunAs}"
_AddDonation()
{
    global

    cm_Amount := 5    ; aList_ClanMembersMain.MaxIndex()
    GuiControlGet, tDonat, , Edit_CurrDonation
    tAddress := AHK_SVerweis(aList_ClanMembersMain[cm_Curr], xlRNG_listMembers, 5, 2)
    tAddress2 := StrReplace(tAddress, "$", "")
    xlWS_cMembers.Range(tAddress2).Value := tDonat
    if (cm_Amount = cm_Curr)
    {
        GuiControl, Text, Lvl_Descript, adding donations for each member done!
        GuiControl, Hide, Lbl_CurrClanMember
        GuiControl, Hide, Edit_CurrDonation
        GuiControl, Hide, Lbl_AddDonation
        GuiControl, Show, Llbl_AddToTotal
        cm_Curr := 1
    }
    else
    {
        cm_Curr++
        GuiControl,, Lbl_CurrClanMember, % aList_ClanMembers[cm_Curr]
        GuiControl,, Edit_CurrDonation, 
        GuiControl, Focus, Edit_CurrDonation
    }
}

_AddToTotal()
{
    global
	; copy this weeks donation data to the data collecting sheet to get a long time view
	xlLastCol := xlLetterToNumber(xlGetColNr(xlWS_hDataTotal, 1, "")) - 1
	loop, % aList_ClanMembersMain.MaxIndex()
	{
		tAddress := AHK_SVerweis(aList_ClanMembersMain[A_Index], xlRNG_colToDaMembers, xlLastCol, 2)
		xlWS_hDataTotal.Range(tAddress) := xlWS_cMembers.Range("G" A_Index + 2).Value
	}
	xlApp.Run("copyFormat")
	Gui, Cmd:Font, s10, % "Bahnschrift SemiCondensed"
    GuiControl, Hide, Llbl_AddToTotal
    GuiControl, Text, Lvl_Descript, All data successfully added, you may close this window now.
}