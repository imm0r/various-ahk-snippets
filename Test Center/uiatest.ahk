FishAgain := WinExist("#lustig-lustig-trallala | ZORN - Discord ahk_exe Discord.exe ahk_class Chrome_WidgetWin_1")
WinActivate, ahk_id %FishAgain%
WinWaitActive, ahk_id %FishAgain%
FishAgain := UIA.ElementFromHandle(FishAgain)

FishAgain.FindFirstBy("ControlType=Button AND Name='Alle Einbettungen entfernen'").Click()

FishAgain.WaitElementExist("ControlType=Button AND Name='Alle Einbettungen entfernen'").Click()

FishAgain.FindFirstBy("ControlType=Button AND Name='fb_goldenrod Fish Again'").Click()