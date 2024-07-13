
#noenv
#singleinstance, force

ComObjError(true) ; Zeige uns COM Fehler an


global aColLetter := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

global xlFile := "J:\FileExchange\immo\Privat\commingFromSurface\L2R\guild tool\HellenicsForces-ClanManager2.xlsm"

try global xlApp := ComObjActive("Excel.Application")
catch
	global xlApp := ComObjCreate("Excel.Application")
global xlWB := xlApp.WorkBooks.Open(xlFile) ;open an existing file

xlApp.Visible := true

global xlWS_cMembers1 := xlWB.Worksheets("ClanMembers")
global xlWS_cMembers := xlWB.Sheets("ClanMembers")

global xlWS_cStr1 := xlWB.Worksheets("hClasses")
global xlWS_cStr := xlWB.Sheets("hClasses")

xlWS_cMembers.Activate()
xlRNG_listMembers := xlWS_cMembers.Range("A3:G51")

Columns := ["A","B","C","D","E","F","G"]
Data := {}, CellLocation := {}
; Get all cell values in columns and put in an array
for Index, Column in Columns
	for xlCell in xlWS_cMembers.UsedRange.Columns(Column).Cells
	{
		Data[Column, A_Index] := fixFalseFloat(xlCell.Value)
		CellLocation[Column, A_Index] := Column A_Index
	}

msgbox, % "Wir lesen aus der Zelle`t: " CellLocation["B", 4] "`nDer Zellinhalt lautet`t: " Data["B", 4]
		. "`n`nWir lesen aus der Zelle`t: " CellLocation["C", 4] "`nDer Zellinhalt lautet`t: " Data["C", 4]
		. "`n`nWir lesen aus der Zelle`t: " CellLocation["F", 4] "`nDer Zellinhalt lautet`t: " Data["F", 4]

AHK_SVerweis( searchStr, tRow)
{
	for Index, Value in Data.A
		If( Value = searchStr )
			msgbox, % "Class ID is: " Data.A[A_Index] " and corresponding class name is: " Data.B[A_Index]
}

for CurrentCell, in xlRNG_listMembers  ; For each item (cell/range) in 'MyRange'...
{
    MsgBox, 65, Cell Info, % "Current Cells.Address: " CurrentCell.Address
						 . "`nCells value: " CurrentCell.Value
						 . "`nCells format: " CurrentCell.NumberFormat ".`n`nContinue?"
    IfMsgBox, Cancel
        break
}

msgbox, % "firstrow := " xlGetRowNr(xlWS_cMembers, "B", "Clan Members")
msgbox, % "lastrow := " xlGetRowNr(xlWS_cMembers)

F6::
; xlWS.Range("G4").Value := 1337

; msgbox, % "Cell G4 was changed from " Format("{:d}", oldValue) " to " Format("{:d}", xlWS.Range("G4").Value)

; wechselt in die zweite tabelle
;; xlWS := workBook.Worksheets[2] ;// tab 2
;; xlWS.Activate()


; Save the excel workbook, close it & remove the Excel Object
;; xlWB.Save
;: xlWB.Close(0)
;; xlApp.Quit
;; xlApp := ""
return

return

xlGetRowNr(ws, col := "A", needle := "") {
	return, % ws.Columns(col).Find[needle].Row
}

; msgbox, % "D = " xlLetterToNumber("D")
xlLetterToNumber(letter)
{
	Loop, % aColLetter.MaxIndex()
	{
		if (inStr(xlWS_cMembers.Columns(A_Index).Address, letter))
			return A_Index
	}
	return 0
}

isNum(v, t := "number") {
	if v is %t%
		return true
	return false
}

IsNum2(v) {
	local
	try t := v + 0
	catch
		return 0
	return !(t = "")
}

fixFalseFloat(v) {
	if isNum2(v)
		return, % Format("{:d}", v)
	return v
}