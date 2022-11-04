  
#SingleInstance, off
verDate := "2014-7-7"

bDebug := 1  ; // Gibt an , ob die eigene Version verwendet werden soll

if bDebug
{
	developADB := "C:\Program Files (x86)\BlueStacks\HD-Adb.exe"
	LocList := "C:\etc\|S:\|E:\|B:\etc\|D:\tmp\"
} else {
	developADB := "adb.exe"
	FileInstall, D:\bin\Java\Android\adb_cn\adb.exe, %A_scriptdir%\adb.exe, 0
	LocList := "D:\|E:\"
}

	; Setzen Sie die Umgebungsvariable PATH, um nicht zurück zu werfen
	EnvGet, Paths, PATH
	EnvSet, PATH, D:\bin\Java\Android\adb_cn`;D:\bin\Java\Android\sdk\platform-tools`;C:\bin\bin32`;D:\bin\bin32`;%A_scriptdir%\bin32`;%A_scriptdir%`;%Paths%

;bOutUTF8 := false
bOutUTF8 := true

	Gui,Add,Groupbox,x14 y10 w730 h390 cBlue vTip, das distale Ende der lokalen und Remote - Verzeichnis - Listen:
	Gui,Add,checkbox,x640 y8 w730 h20 cBlue vbClickDown checked, doppelklicken Sie auf Download (&C)
	Gui,Add,Button,x654 y30 w80 h20 gNewShell vNewShell, Shell
	Gui,Add,Button,x454 y30 w80 h20 vShowDir gShowDir, Display (&S)
	Gui,Add,ComboBox,x24 y30 w430 choose1 vDevDir, /sdcard/|/mnt/shell/emulated/0/|/Removable/MicroSD/

	Gui,Add,ComboBox,x544 y30 w100 vLocDir Choose1, %LocList%

	Gui, Font, S12
	Gui,Add,ListView,x24 y60 w710 h330 -ReadOnly AltSubmit gLVClick vFoxLV, Name|Size|Time
	Gui, Font
	LV_ModifyCol(1, 460) , LV_ModifyCol(2, 80) , LV_ModifyCol(3, 145)
		LV_Add("", "..", "D", "")

	Gui,Show,w751 h410 , ADB Push Pull von Irish Fox http://linpinger.github.io Ver: %verDate%

	onmessage(0x100, "FoxInput")  ; Reaktion auf das Drücken von Sondertasten in speziellen Steuerelementen

	process, Exist, adb.exe
	if ( ErrorLevel = 0 ) {
		guicontrol, Disable, ShowDir
		runwait, %developADB% shell ls /, , Min
		guicontrol, Enable, ShowDir
	}
	gosub, menuinit
	Guicontrol, focus, ShowDir
	gosub, ShowDir
return

menuinit: ; Initialisierungsmenü
	Menu, LVMenu, Add, Herunterladen zu local (&F), FoxMenuAct
	Menu, LVMenu, Add
	Menu, LVMenu, Add, Mobil (&M), FoxMenuAct
	Menu, LVMenu, Add, Neuer Ordner (&N), FoxMenuAct
	Menu, LVMenu, Add
	Menu, LVMenu, Add, Löschen (&D), FoxMenuAct
return

FoxMenuAct: ; entsprechendes Menü
	guicontrolget, DevDir
	LV_GetText(nowName, MenuRowNum, 1)
	If ( A_ThisMenuItem = "Mobil (&M)" ) {
		oldPath := DevDir . nowName
		inputbox, newPath, verschieben / umbenennen, geben Sie den zu verschiebenden Zielpfad ein,,300, 150, , , , , %oldPath%
		if ( (oldPath = newPath) or newPath = "")
				return
		runwait, adb shell mv "%oldPath%" "%newPath%"
	}
	If ( A_ThisMenuItem = "Neuer Ordner (&N)" ) {
		inputbox, newDirName, neuer Ordner, geben Sie den Namen des zu erstellenden Ordners ein,,300, 150
		if ( newDirName = "" )
			return
		runwait, adb shell mkdir %DevDir%%newDirName%
	}
	If ( A_ThisMenuItem = "Download auf lokal (&F)" ) {
		guicontrolget, DevDir
		guicontrolget, LocDir
		NowRow := 1
		DownNameList := ""
		loop {
			NowRow := LV_GetNext(NowRow)
			if ! NowRow
					break
			LV_GetText(nowName, NowRow, 1)
			LV_GetText(nowSize, NowRow, 2)
			if ( nowSize = "D" )
				continue
			DownNameList .= nowName . "`n"
		} ; Liste der Namen abrufen
		loop, parse, DownNameList, `n, `r
		{
				if ( A_LoopField = "" )
						continue
				nowName := A_LoopField
				if ( bOutUTF8 )
					runwait, adb pull "%DevDir%%nowName%" %nowName%, %LocDir%
				else
					runwait, adb pull "%DevDir%%nowName%" ., %LocDir%
		}
	}
	
	
	If ( A_ThisMenuItem = "Delete (&D)" ) {
		if ( MenuRowNum < 2 )
			return
		LV_GetText(nowSize, MenuRowNum, 2)
		if ( nowSize = "D" ) {
			msgbox, 260, 确认, bestätigen Sie, ob das Verzeichnis gelöscht werden soll:`n`n%nowName%
			ifmsgbox, Yes
				runwait, adb shell rm -r "%DevDir%%nowName%"
			else
				return
		}
		runwait, adb shell rm "%DevDir%%nowName%"
	}
	lsDir(DevDir, bOutUTF8)
return


NewShell:
	run, adb shell
return

LVClick: ; Doppelklicken Sie auf den Eintrag
	nItem := A_EventInfo
	if ( A_GuiEvent == "E" ) { ; Vor F2
		LV_GetText(nEditBefore, nItem, 1)
	}
	if ( A_GuiEvent == "e" ) { ; nach F2
		LV_GetText(nEditAfter, nItem, 1)
		if ( (nEditBefore = nEditAfter) or nEditAfter = "")
				return
		guicontrolget, DevDir
		runwait, adb shell mv "%DevDir%%nEditBefore%" "%DevDir%%nEditAfter%"
	}
	if ( A_GuiEvent = "DoubleClick" ) {
		gosub, DClickItem
	}
return

DClickItem: ;  Notwendigkeit nItem
		LV_GetText(nowName, nItem, 1)
		LV_GetText(nowSize, nItem, 2)
		guicontrolget, DevDir
		if ( nowSize = "D" ) { ; Verzeichnis
			if ( nowName = ".." ) { ; übergeordnetes Verzeichnis
				gosub, goUP
			} else { ; untergeordnetes Verzeichnis
				subDir := DevDir . nowName . "/"
				guicontrol, Text, DevDir, %subDir%
				lsDir(subDir, bOutUTF8)
			}
		} else if ( nowSize = "L" ) { ; link
			xx_1 := "" , xx_2 := ""
			; etc -> /system/etc
			regexmatch(nowName, "i)^(.*) -> (.*)", xx_)
			if ( xx_1 != "" ) {
				subDir := DevDir . xx_1 . "/"
				guicontrol, Text, DevDir, %subDir%
				lsDir(subDir, bOutUTF8)
			}
		} else { ; 普通文件
			GuiControlGet, bClickDown
			if ( 1 = bClickDown ) { ; Doppelklicken Sie zum Herunterladen
				if ( nItem < 2 )
					return
				if ( nowSize = "D" )
					return
				guicontrolget, LocDir
				if ( bOutUTF8 )
					runwait, adb.exe pull "%DevDir%%nowName%" %nowName%, %LocDir%
				else
					runwait, adb pull "%DevDir%%nowName%" ., %LocDir%
			} else {
				remoteFilePath := DevDir . nowName
				guicontrol, , Tip, distale lokale und Remote - Verzeichnisliste: %remoteFilePath%
				clipboard = %remoteFilePath%
			}
		}
return

goUP: ; otwendigkeit DEVDIR
	guicontrolget, DevDir
	xx_1 := ""
	regexmatch(DevDir, "i)^([/]?.*/).+/$", xx_)
	if ( xx_1 != "" ) {
		guicontrol, Text, DevDir, %xx_1%
		lsDir(xx_1, bOutUTF8)
	}
return

ShowDir: ; Anzeigeverzeichnisinhalt
	guicontrolget, DevDir
	lsDir(DevDir, bOutUTF8)
	Guicontrol, focus, FoxLV
return


GuiContextMenu:     ; 菜单:Menü: Kontextmenü - Anzeige
	If ( A_guicontrol = "FoxLV") {
		MenuRowNum := A_EventInfo
		Menu, LVMenu, Show, %A_GuiX%, %A_GuiY%
	}
return

GuiDropFiles:  ; drag Veranstaltungen
	File_full_path := A_GuiEvent
	if ( A_guicontrol = "FoxLV" ) {
		GuiControlGet, DevDir
		loop, parse, File_full_path, `n, `r
		{
			if ( A_loopfield = "" )
					continue
			FileGetSize, pushSize, %A_LoopField%, K
			sTime := A_TickCount
			runwait, adb push "%A_LoopField%" "%DevDir%"
			eTime := ( A_TickCount - sTime ) / 1000
			TrayTip, Push速度:, % pushSize / eTime . " K/s"
			lsDir(DevDir, bOutUTF8)
		}
	} else {
		TrayTip, Tipp, Zum Ziehen der Datei in das Listenfeld
	}
return

GuiEscape:
GuiClose:
	ExitApp
return


#IfWinActive, ahk_class AutoHotkeyGUI
^esc::reload
+esc::Edit
!esc::ExitApp
!UP::gosub, goUP
^\::
^0::
	guicontrol, Text, DevDir, /sdcard/
	lsDir("/sdcard/", bOutUTF8)
return
^1::
	guicontrol, Text, DevDir, /sdcard/99_sync/
	lsDir("/sdcard/99_sync/", bOutUTF8)
return
!1::CopyInfo2Clip(1)
!2::CopyInfo2Clip(2)
!3::CopyInfo2Clip(3)
#IfWinActive

CopyInfo2Clip(Num=1) {
	LV_GetText(NowVar, LV_GetNext(0), Num)
	Clipboard = %NowVar%
	TrayTip, 剪贴板:, %NowVar%
}

lsDir(DevDir="/sdcard/", bUTF8=false)
{
	tmpFilePath := "C:\DevDir.lst"
	runwait, cmd /c adb shell ls -l "%DevDir%" > %tmpFilePath%, , Min
	if ( bUTF8 ) {
		fileread, nr, *P65001 %tmpFilePath%  ; UTF-8
	} else {
		fileread, nr, %tmpFilePath%
	}
	filedelete, %tmpFilePath%
	LV_Delete()
	LV_Add("", "..", "D")
	loop, parse, nr, `n, `r  ; 目录
	{	 ; drwxrwxr-x root     sdcard_rw          2014-03-25 21:56 aa
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := ""
		regexmatch(A_loopfield, "Ui)^d[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+[0-9]*([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_2 = "" )
			continue
		LV_Add("", xx_2, "D", xx_1)
	}
	loop, parse, nr, `n, `r  ; 链接
	{	 ; lrwxrwxrwx root     root              1970-01-01 08:00 emmc@android -> /dev/block/mmcblk0p5
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := ""
		regexmatch(A_loopfield, "Ui)^l[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+[0-9]*([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_2 = "" )
			continue
		LV_Add("", xx_2, "L", xx_1)
	}

	loop, parse, nr, `n, `r  ; 文件
	{	 ; -rw-rw-r-- root     sdcard_rw  2130142 2014-03-27 21:49 novel.zip
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := "", xx_3 := ""
		regexmatch(A_loopfield, "Ui)^[^dl].[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+([0-9]*) +([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_1 = "" )
			continue
		LV_Add("", xx_3, xx_1, xx_2)
	}
}

FoxInput(wParam, lParam, msg, hwnd)  ; Reaktion auf das Drücken von Sondertasten in speziellen Steuerelementen
{ 
	Global
	; tooltip, <%wParam%>`n<%lParam%>`n<%msg%>`n<%hwnd%>`n%A_GuiControl%
	If ( A_GuiControl = "FoxLV" and wParam = 13 ) {
		nItem := LV_GetNext()
		gosub, DClickItem
	}
}