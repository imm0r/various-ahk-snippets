Pics := []
; Find some pictures to display.
Loop, Files, C:\Users\m0nsu\OneDrive\Desktop\ahk\L2R_ADB\misc\img\*.png, R
{
    ; Load each picture and add it to the array.
    msgbox, % A_LoopFileFullPath
    Pics.Push(LoadPicture(A_LoopFileFullPath))
}
if !Pics.Length()
{
    ; If this happens, edit the path on the Loop line above.
    MsgBox, No pictures found!  Try a different directory.
    ExitApp
}
; Add the picture control, preserving the aspect ratio of the first picture.
Gui, Add, Pic, w600 h-1 vPic +Border, % "HBITMAP:*" Pics.1
Gui, Show
Loop 
{
    ; Switch pictures!
    GuiControl, , Pic, % "HBITMAP:*" Pics[Mod(A_Index, Pics.Length())+1]
    Sleep 3000
}
return
GuiClose:
GuiEscape:
ExitApp