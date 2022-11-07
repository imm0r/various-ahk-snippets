#NoEnv
#SingleInstance force
DetectHiddenWindows On
SetBatchLines -1

If( !A_IsAdmin )
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"

; Creating a hidden Console Window
Run, %comspec% /k, , hide, pid
while !( hConsole := WinExist( "ahk_pid" pid ) )
	Sleep 10
DllCall( "AttachConsole", "UInt", pid )
DllCall( "AllocConsole" )
WinHide % "ahk_id " DllCall( "GetConsoleWindow", "ptr" )

Gui, +AlwaysOnTop +Caption +LastFound +OwnDialogs +ToolWindow +Border +E0x40000
Gui, Margin, 5, 5
Gui, Font, s11 w400, % "Bahnschrift SemiCondensed"

SetTimer, ProcessCheck, 100

; Grouping part 1: Setup
Gui, Add, GroupBox, x5 y5 w340 h110 c800800, Jetzt beschleunigen!
	Gui, Font, s10 w400, % "Bahnschrift SemiCondensed"
	Gui, Add, text, x15 y30 w270, Nur auf den Knopf druecken und los geht's!
	Gui, Add, Button, x251 y24 w80 hWndhDLLProvider vRunL2R gRunL2R, L2R Starten
	DDL_SETCUEBANNER( hDLLProvider, "Klick mich!" )
	Gui, Add, Progress, x15 y55 w315 cRed Background808080 vpProgress, 0
	Gui, Add, text, x15 y82, Status:
	Gui, Add, edit, x60 y80 w270 disabled vStatus, bla
Gui, Show, % "x" A_ScreenWidth / 2 " y" A_ScreenHeight / 2, L2R auf Steroiden
GUI_ID:=WinExist("A")
return

RunL2R:
	SetTimer, ProcessCheck, off
	s_shell := ComObjCreate( "WScript.shell" )
	If( s_shell ) {
		GuiControl disabled, RunL2R, 
		objExec := s_shell.Exec( "dnconsole.exe globalsetting --fps 60 --audio 1 --fastplay 1" )
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
		loop, 33 {
			GuiControl,, pProgress, +1
			GuiControlGet, varProg ,, pProgress
			GuiControl,, Status, % "Optimierung in Gange! ( " varProg "% abgeschlossen )"
			sleep, 30
		}

		objExec := s_shell.Exec( "dnconsole.exe downcpu --index 0 --rate 50" )
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
		GuiControl +cYellow, pProgress, 
		loop, 34 {
			GuiControl,, pProgress, +1
			GuiControlGet, varProg ,, pProgress
			GuiControl,, Status, % "Optimierung in Gange! ( " varProg "% abgeschlossen )"
			sleep, 30
		}
		
		objExec := s_shell.Exec( "dnconsole.exe action --index 0 --key call.reboot --value com.netmarble.lin2ws" )
		while, !objExec.StdOut.AtEndOfStream
			strStdOut := objExec.StdOut.ReadAll( )
		GuiControl +cGreen, pProgress, 
		loop, 34 {
			GuiControl,, pProgress, +1
			GuiControlGet, varProg ,, pProgress
			GuiControl,, Status, % "Optimierung in Gange! ( " varProg "% abgeschlossen )"
			sleep, 30
		}
		GuiControl,, Status, % "Optimierung ageschlossen, L2R wird gestertet!"
		SetTimer, CloseTool, -5000
	}
return

ProcessCheck:
	wTitle := ""
	WinGetTitle, wTitle, % "ahk_class LDPlayerMainFrame"
	if( wTitle ) {
		GuiControl enabled, RunL2R, 
		GuiControl,, Status, % "LDPlayer gefunden, kannst loslegen!"
	} else {
		GuiControl disabled, RunL2R, 
		GuiControl,, Status, % "LDPlayer nicht gefunden, bitte zuerst LDP starten!"
	}
return

CloseTool:
	exitapp
return