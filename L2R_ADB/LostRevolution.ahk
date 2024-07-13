;Default settings
#noenv
#singleinstance, force
SetKeyDelay, 0
SetWinDelay, 0
SetBatchLines,-1
DetectHiddenWindows, On

;Run As Admin
if not A_IsAdmin
	RunAsAdmin()

;including local libraries

    #include func.ahk
    #include <objMgr>
    #include <gdipp>
    #include <TextRender>
    #include <adb>
    #include gui.ahk

;enable debug output?
global debug := false
global con_OnTop := 1

;Start up gdip
pToken := Gdip_Startup()

;creating some formated time strings
FormatTime, DateStr, , T12, Time
FormatTime, TimeStr, , T12, Time
FormatTime, strCDate, %A_Now%, yyyy-MM-dd

;the following arrays are all set to global.
    ;basic information about LD Player, stored inside 'oLDP_Basics'.
    Global oLDP_Basics      := GetLDPBasics()

    ;some needed basic information stored inside 'oBasics'
    Global oBasics          := Object("imgDir", A_ScriptDir . "\misc\img\", "dos2unix", A_ScriptDir "\misc\dos2unix.exe", "dbgDir", A_ScriptDir "\dbg\"
                            , "logFile", A_ScriptDir "\dbg\" strCDate ".log")

    ;startup activity used to launch the game from adb shell.
    Global startupActivity  := "com.epicgames.ue4.GameActivity"

    ;internal DropDownList array containing gui strings.
    Global oStrDDL          := Array("btn_Login|", "btn_Skip", "Inventory", "btn_BulkSale", "btn_Sell1", "btn_Sell2", "btn_OK", "btn_Back"
                                   , "ActiveQuest", "btn_StartQuest", "btn_Walk", "btn_Teleport", "btn_FulFullRequest", "btn_ClaimReward")

    ;inGame coordinates for specific locations
    Global oDDL_Container   := Object("btn_Login", "3150|1235", "btn_Skip", "3260|1050", "Inventory", "2850|50", "btn_BulkSale", "2800|1350"
                            , "btn_Sell1", "3300|1350", "btn_Sell2", "1950|1000", "btn_OK", "1750|1000", "btn_Back", "80|75"
                            , "ActiveQuest", "440|800", "btn_StartQuest", "1990|1225", "btn_Walk", "1450|1035", "btn_Teleport", "2025|1035"
                            , "btn_FulFullRequest", "2300|1050", "btn_ClaimReward", "1750|1225", "ClaimRewardHelper", "1950|1200", "SkipHelper", "3390|1150")

    ;sequence to run for auto questing
    Global oAutoQuestSeq    := Array("btn_ClaimReward", "ActiveQuest", "btn_FulFullRequest", "btn_OK", "btn_StartQuest", "btn_Walk")

    ;object containing specific colors to search for
    Global oScanClr         := Object("clr_Skip", "0x0", "clr_ClaimReward", "0x304B69")

    ;ADB device information stored inside 'oADB'
    tDevice := adb_GetDevice( ) 
    Global oADB             := Object("device", tDevice, "isConnected", adb_isConnectedToDevice(tDevice))

    ;log output categories
    Global oCategories      := ["INFO", "WARN", "ERROR", "DEBUG"]

;defining important global variables
    Global hConsole, c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput, DLLInputChoice
            , InputChoice, LABPic, Lbl_AutoQuest, enabled_AutoSkip, Lbl_LiveAppBroadcasting, enabled_LiveAppBroadc
            , DDL_CoordsCurrActive, con_OnTop, guiID, Lbl_ADBReturn, CursorPosX, CursorPosY, CursorColor, ColoredDot

oLDPi := {}
oL_LR := TextRender()
Global oCtrls := GetCtrlListFromHwnd(oLDP_Basics.hWnd)

SetTimer, t_UpdateCursorPos, 75

;creating the user interface
createGui()


#include labels.ahk

return