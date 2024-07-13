#NoEnv
#SingleInstance, Force
OnExit, AppExit
DetectHiddenWindows, On
Global RunningScripts := {}
Global SizeT := A_IsUnicode ? 2 : 1
Global WM_COPYDATA := 0x004A
Params := "NotificationFlag`nRPA_Mode`nVariable4`nShortName`nLongname"
Script2Run := A_ScriptDir . "\Client.ahk"
; To call ChangeWindowMessageFilter is recommended by Microsoft for Win Vista+. Actually, I don't need it on Win 10.
DllCall("ChangeWindowMessageFilter", "UInt", WM_COPYDATA, "UInt", 1)
OnMessage(WM_COPYDATA, "WM_COPYDATA_Receive")
Gui, Margin, 100, 50
Gui, Add, Button, gRunScript, Run Next Client
Gui, Show, , % "Master (" . (A_ScriptHwnd + 0) . ")"
Return
GuiClose:
ExitApp
; ----------------------------------------------------------------------------------------------------------------------
RunScript:
Run, *Open %Script2Run%, , , PID
WinWait, ahk_pid %PID% ahk_class AutoHotkey, , 2
If (ErrorLevel) {
   MsgBox, 16, ERROR, Couldn't run %Script2Run%!
   Return
}
HMSG := WinExist()
If !WM_COPYDATA_Send(HMSG, Params) {
   MsgBox, 16, ERROR, Client %HMSG% refused didn't process WM_COPYDATA!
   WinClose, ahk_id %HMSG%
   Return
}
RunningScripts[HMSG] := PID
Return

AppExit:
   For HWND In RunningScripts
      WinClose, ahk_id %HWND%
ExitApp

Esc::
ExitApp

; ----------------------------------------------------------------------------------------------------------------------
WM_COPYDATA_Receive(W, L) {
   DataType := StrGet(L, "CP0")
   msgSize := NumGet(L + A_PtrSize, "Int")
   DataPtr := NumGet(L + (A_PtrSize * 2), "UPtr")
   If (DataType = "T") { ; we recieved text
      msgData := StrGet(DataPtr, msgSize, "UTF-8")
      msgSize := StrLen(msgData)
      global hWnd_discord := WinExist("ahk_exe Discord.exe")
      ControlSend,, {SHIFT DOWN}7{SHIFT UP}fish catch{ENTER}, % "ahk_id " hWnd
   }
   Else { ; we received binary data
      VarSetCapacity(msgData, msgSize, 0)
      DllCall("RtlMoveMemory", "Ptr", &msgData, "Ptr", DataPtr, "Ptr", msgSize)
   }
   Return True
}
; ----------------------------------------------------------------------------------------------------------------------
WM_COPYDATA_Send(HMSG, ByRef Data, DataSize := 0) {
   If DataSize Is Not Integer
      Return !(ErrorLevel := 1)
   If (DataSize < 1) {
      DataType := Asc("T")
      VarSetCapacity(UTF8, (DataSize := StrPut(Data, "UTF-8")), 0)
      StrPut(Data, &UTF8, "UTF-8")
      DataPtr := &UTF8
   }
   Else {
      DataType := Asc("B")
      DataPtr := &Data
   }
   VarSetCapacity(COPYDATA, 3 * A_PtrSize, 0)
   NumPut(DataType, COPYDATA, 0, "UChar")
   NumPut(DataSize, COPYDATA, A_PtrSize, "Int")
   NumPut(DataPtr, COPYDATA, 2 * A_PtrSize, "Ptr")
   SendMessage, WM_COPYDATA, A_ScriptHwnd, &COPYDATA, , ahk_id %HMSG%, , , , 1000
   Return (ErrorLevel = "FAIL") ? 0 : !!ErrorLevel
}
; ----------------------------------------------------------------------------------------------------------------------
/* http://msdn.microsoft.com/en-us/library/ms649010(VS.85).aspx
   typedef struct tagCOPYDATASTRUCT {
      ULONG_PTR dwData;     The data to be passed to the receiving application.
      DWORD     cbData;     The size, in bytes, of the data pointed to by the lpData member.
      PVOID     lpData;     The data to be passed to the receiving application. This member can be NULL.
   } COPYDATASTRUCT, *PCOPYDATASTRUCT;
*/