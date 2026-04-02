#Requires AutoHotkey v2.0
path := A_ScriptDir "\QuickWriteTest.txt"
outFile := FileOpen(path, "w", "UTF-8")
outFile.WriteLine("ok")
outFile.Close()
ExitApp
