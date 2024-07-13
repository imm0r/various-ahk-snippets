sImage := "captcha.png" ; Replace it!

Gui, +Resize +LastFound
Gui, Show, w1024 h768 Center, OCR
odi := ComObjCreate("MODI.Document")
odi.Create(sImage)
;ovw := Atl_AxCreateControl(WinExist(),"MiDocViewer.MiDocView")
;ovw.Document := odi
odi.OCR
sText := odi.Images(0).Layout.Text
odi.Close
MsgBox % sText
Return

GuiClose:
ExitApp