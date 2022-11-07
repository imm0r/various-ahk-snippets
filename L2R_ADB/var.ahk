_EMU_CLOSE( "CMD" )

; Initialiasing global arrays:
Global ARR_LDPInstances := []
Global a_GDINeedle := []
Global OCR_RECT := []
Global DATADIR := []
Global ADB := []
Global EMU := []
Global L2R := []
Global IMG := []
Global REG := []
Global GL  := []

; global variables
SWOW6432NODE := A_Is64bitOS ? "Wow6432Node" : ""
LDPlayerRegEditUninstallFolder := A_Is64bitOS ? "LDPlayer64\" : "LDPlayer\"

Global ScriptTitle := "L2R-Manager"

img_wifi := A_Scriptdir . "\img\wifi.png"
img_startQuest := A_Scriptdir . "\img\startQuest1.png"

; Filling those global arrays from above
DATADIR := { "DEBUG":A_Scriptdir . "\DEBUG\", "ANR":A_Scriptdir . "\DEBUG\ANR\", "SS":A_Scriptdir . "\DEBUG\PULLED_SS\" }

SWOW6432NODE := A_Is64bitOS ? "Wow6432Node" : ""
LDPlayerRegEditUninstallFolder := A_Is64bitOS ? "LDPlayer64\" : "LDPlayer\"
regPath := "HKEY_LOCAL_MACHINE\SOFTWARE\" . SWOW6432NODE . "\Microsoft\Windows\CurrentVersion\Uninstall\" . LDPlayerRegEditUninstallFolder
oLDP := Object("cli", "dnplayer.exe", "adb", "adb.exe", "console", "dnconsole.exe", "regP", regPath, "regK", "DisplayIcon", "winTitle", "L2R(64)", "winCls", "LDPlayerMainFrame")

EMU.FILE["CLIENT"]	:= {  1:"dnplayer.exe"
						, 2:"ui\AndroidEmulator.exe"
						, 3:"bignox.exe"
						, 4:"MEmu\MEmu.exe"
						, 5:"HD-Player.exe" }
						
EMU.FILE["ADB"]		:= {  1:"adb.exe"
						, 2:"ui\adb.exe"
						, 3:"Nox_adb.exe"
						, 4:"MEmu\adb.exe"
						, 5:"HD-Adb.exe" }
						
EMU.FILE["CONSOLE"]	:= {  1:"dnconsole.exe"
						, 2:"glconsole.exe"
						, 3:"Nox_console.exe"
						, 4:""
						, 5:"" }

EMU.REG["PATH"]		:= {  1:"HKEY_LOCAL_MACHINE\SOFTWARE\" . SWOW6432NODE . "\Microsoft\Windows\CurrentVersion\Uninstall\" . LDPlayerRegEditUninstallFolder
						, 2:"HKEY_LOCAL_MACHINE\SOFTWARE\" . SWOW6432NODE . "\Tencent\MobileGamePC\UI"
						, 3:"HKEY_LOCAL_MACHINE\SOFTWARE\" . SWOW6432NODE . "\Microsoft\Windows\CurrentVersion\Uninstall\bignox"
						, 4:"HKEY_LOCAL_MACHINE\SOFTWARE\" . SWOW6432NODE . "\Microsoft\Windows\CurrentVersion\Uninstall\Memu"
						, 5:"HKEY_LOCAL_MACHINE\SOFTWARE\BlueStacks_arabica" }
						
EMU.REG["REGVAR"]	:= {  1:"DisplayIcon"
						, 2:"InstallPath"
						, 3:"InstallPath"
						, 4:"InstallLocation"
						, 5:"InstallDir" }
						
EMU.PATH["EMUEXE"]	:= _READ_EMU_ROOTPATH( EMU.REG["PATH"][1], EMU.REG["REGVAR"][1], EMU.FILE["CLIENT"][1] )
EMU.PATH["ADBEXE"]	:= _READ_EMU_ROOTPATH( EMU.REG["PATH"][1], EMU.REG["REGVAR"][1], EMU.FILE["ADB"][1] )
EMU.PATH["CONSOLE"]	:= _READ_EMU_ROOTPATH( EMU.REG["PATH"][1], EMU.REG["REGVAR"][1], EMU.FILE["CONSOLE"][1] )

EMU.PROVIDER["NAME"]:= {  1:"LDPlayer" ;	"L2R Bot"
						, 2:"Gameloop"
						, 3:"Nox"
						, 4:"MEmu"
						, 5:"BlueStacks" }

EMU.WINDOW["NAME"]	:= {  1:"LDPlayer" ;	"L2R Bot"
						, 2:"Gameloop"
						, 3:"NoxPlayer"
						, 4:"Memu"
						, 5:"BlueStacks" }
						
EMU.WINDOW["CLASS"]	:= {  1:"LDPlayerMainFrame"
						, 2:"GameloopClass"
						, 3:"NoxClass"
						, 4:"MemuClass"
						, 5:"BlueStacksClass" }
						
EMU.SYS["oRES"]		:= {  1:3440
						, 2:1440 }

eR := _ADB_GETRESOLUTION( )
EMU.SYS["uRES"]		:= {  1:eR[1]
						, 2:eR[2] }
						
EMU.WINDOW["fSIZE"]	:= {  "x":0
						, "y":0
						, "w":1920
						, "h":822 }

L2R.STARTUPACTIVITY := "com.epicgames.ue4.GameActivity"

; Check for various needed files and directories
if !FileExist( DATADIR["DEBUG"] )
	FileCreateDir, % DATADIR["DEBUG"]
if !FileExist( DATADIR["ANR"] )
	FileCreateDir, % DATADIR["ANR"]
if !FileExist( DATADIR["SS"] )
	FileCreateDir, % DATADIR["SS"]

; Assigning local Vars
MemUsageOld := 1, StateItt := 0
	
; Reading the config.ini
IniRead, CB_L2RAutoSkip, config.ini, GUI, CB_L2RAutoSkip, 0
IniRead, CB_L2RAutoStart, config.ini, GUI, CB_L2RAutoStart, 0
IniRead, CB_L2RAutoSetChange, config.ini, GUI, CB_L2RAutoSetChange, 0
IniRead, GuiPosX, config.ini, GUI, PosX, 1
IniRead, GuiPosY, config.ini, GUI, PosY, 1

; Initialiasing global variables:
Global DEBUG := 0, DBGrunning := 0
Global IsOnMainScreen, t_StateOld := 666
Global DBGLogFile_PIDList := A_Scriptdir . "\DEBUG\PIDList.txt"
Global DBGLogFile_ADBshell := A_Scriptdir . "\DEBUG\LogFileTesting.txt"

; Initiating the LogFile
DBGLog := new LogToFile( DBGLogFile_ADBshell )
DBGLog.Add( "------------------[ Logging session started! ]------------------`n`n`n" )

; Creating a hidden Console Window
Run, %comspec% /k, , hide, pid
while !( hConsole := WinExist( "ahk_pid" pid ) )
	Sleep 10
DllCall( "AttachConsole", "UInt", pid )
DllCall( "AllocConsole" )
WinHide % "ahk_id " DllCall( "GetConsoleWindow", "ptr" )
Global s_shell := ComObjCreate( "WScript.shell" )
If( s_shell )
	DBGLog.Add("Hidden console Window successfully created and added a WindowsScriptingShell to this window", 1)
else
	DBGLog.Add("Hidden console Window could not be created and/or WindowsScriptingShell could not be attached to this window", -1)

WINDOW["TITLE"] := GetEmuWinTitle( )
WINDOW["ID"]	:= GethWnd( EMU.WINDOW["TITLE"], EMU.FILE["CLIENT"][1] )

ADB["DEVICE"]		:= _ADB_GETDEVICE( )
ADB["ISCONNECTED"]	:= _ADB_ISADBCONNECTED( )

Global L2RState := 0

;---------------------------------  definition of variables and arrays  ---------------------------------
X := 0, Y := 0, Width := A_ScreenWidth, Height := A_ScreenHeight, Smoothing := 4, Name := "gdip"
fWidth := 140, fHeight := 80, i := 0

Global fontList := ["Arial", "Tahoma", "Candara", "Consolas", "Calibri", "Arial Narrow", "Forte"
				  , "Dubai Medium", "Eras Bold ITC", "Franklin Gothic Demi Cond", "Haettenschweiler"
				  , "MV Boli", "System"]

Global colorList := [ "000000", "7F7F7F", "880015", "ED1C24", "620707", "FFF200", "22B14C", "00A2E8"
					, "3F48CC", "A349A4", "FFFFFF", "C3C3C3", "B97A57", "FFAEC9", "FFC90E", "EFE4B0"
					, "B5E61D", "99D9EA", "7092BE", "C8BFE7", "050B0D", "0F0C06", "16120C", "6E6E6E"]

Global obj_YesNo := { 0:"No", 1:"Yes" }

If(!FuckNetmarble) {
	;---------------------------------------------  Gdip stuff  ---------------------------------------------
	;Global GdipObj := CreateLayeredWindow( Smoothing, X, Y, Width, Height, Name, "-ToolWindow +OwnDialogs -Caption" )
	;Gui, -Caption +AlwaysOnTop +ToolWindow +LastFound +OwnDialogs +E0x80000 +HwndCHhwnd ; Create layered window (+E0x80000 is required for UpdateLayeredWindow). +HwndName creates a variable with a name of your choice, containing the Hwnd of the window
	;Gui, Show, NA ; Show window without activating it
	pPenRed := Gdip_CreatePen( "0xff" ColorList[4], 2 )

	Global GDipRect  := { x:110, y:135, w:320, h:55																	; x & y coordinates | width & height
						, pPenMainRect: Gdip_CreatePen( "0x44" ColorList[21], 3 )										; rect outline color
						, pBrushMainRect: Gdip_BrushCreateSolid( "0x7a" ColorList[22] )									; rect background color
						, stringHeadline: "AUTO CONQUEST!"																	; headline string
						, pPenHeadlineOL: Gdip_CreatePen( "0xff" ColorList[5], 2 )										; headline font outline color
						, pBrushHeadline: Gdip_BrushCreateSolid( "0xff" ColorList[2] )									; headline font color
						, pPenMainDataOL: Gdip_CreatePen( "0x88" ColorList[13] , 3 )									; rect-content font outline color
						, pBrushMainData: Gdip_BrushCreateSolid( "0xff" ColorList[11] ) }								; rect-content font color

	;----------------------- building the 3 dimensional array holding the rect-informations  ;---------------
	Global OCR_RECT := {  "availSubQuest":["Sub-quest", "14|611|475|71"]												; String: available [Sub-quest]
						, "Cancel":["Cancel", "1378|934|202|89"]														; Button: Cancel
						, "ClaimReward":["Claim Reward", "1086|659|167|45"]												; Button: Claim Reward (Quest)
						, "Close":["Close", "1365|964|168|77"]															; Button: Close
						, "Exp":["Exp", "377|1378|77|49"]																; String: Exp
						, "FulfillRequest":["Fulfill Request", "2133|1219|258|126"]										; Button: Fulfill Request (Quest)
						, "Inventory":["Inventory", "153|60|195|50"]													; String: Inventory
						, "MoveToRegion":["Move to specific Region", "1431|614|580|64"]									; String: Move to specific Region
						, "mType":["Magical,Dragon,Humanoid,Demon,Undead", "1431|27|402|47"]							; String: Monster Type (declaration)
						, "Netmarble":["Netmarble", "55|55|400|100"]													; String: Netmarble
						, "ProceedQuest":["Proceed Quest", "1303|544|833|187"]											; Button: Proceed Quest
						, "Skip":["Skip", "3188|986|125|67"]															; Button: Skip
						, "SpotRevival":["Spot Revival", "3051|1036|257|54"]											; Button: Spot Revival (Character died)
						, "StartQuest":["Start Quest", "1815|1180|330|100"] 											; Button: Start Quest
						, "TipsAfterDeath":["Try different ways to strengthen your character.", "1142|479|1151|113"]	; String: Try different ways to strengthen your character. (Character died)
						, "WIFI":["WIFI", "109|1381|79|46"]																; String: WIFI
						, "StartConquest":["Start,Continue,Conquest", "1050|650|280|60"]								; String: Start or Continue Conquest
						, "Conquest":["300300", "66|316|132|42"] }														; String: Conquest Control :: "Defeat Cursed Navigator 300 times"
}
;-----------------------------------  image search related stuff  -----------------------------------
Global iSearchConfig := "iS.cfg"
Global iSearchDir := "IMG\imgSearch\"

Global EmuTapCoords  := {  "btnLogin":[3150, 1285]
						 , "btnSkip":[3150, 1285] }

