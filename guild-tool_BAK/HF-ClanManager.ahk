#noenv
#singleinstance, force

#include <core>
#include helper.ahk
#include gui.ahk

core.benchmark(true)
; Shows us com errors.
ComObjError(true)

; setting up base variables
global aColLetter := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
global xlFile := "F:\ahk\guild tool\HellenicsForces-ClanManager.xlsm"

aCols_membersTable := ["A","B","C","D","E","F","G"]
Data := {}, aCellValueFromLocation := {}

; running excel app as comObject
; if an instance already exists it uses this one instead opening another new one.
try global xlApp := ComObjActive("Excel.Application")
catch
	global xlApp := ComObjCreate("Excel.Application")

; Open an existing excel file as Workbook
global xlWB := xlApp.WorkBooks.Open(xlFile)

; set excel visible or invisible
xlApp.Visible := true

; setting up the used WorkSheets
global xlWS_cMembers := xlWB.Sheets("ClanMembers")	; xlWB.Worksheets("ClanMembers")
global xlWS_hDataTotal := xlWB.Sheets("hDataTotal")	; xlWB.Worksheets("hDataTotal")
global xlWS_hClasses := xlWB.Sheets("hClasses")		; xlWB.Worksheets("hClasses")

; setting up needed ranges
global xlRNG_listMembers := xlWS_cMembers.Range("Table_ClanMembers[Member]")
aList_ClanMembersMain := GetClanMembersFromRange(xlRNG_listMembers)

global xlRNG_colToDaFull := xlWS_hDataTotal.Range("Tbl_TotalDonations")
global xlRNG_colToDaMembers := xlWS_hDataTotal.Range("Tbl_TotalDonations[Member]")
aList_ClanMembersTotal := GetClanMembersFromRange(xlRNG_colToDaMembers)

global xlRNG_colThisDonat := xlWS_cMembers.Range("col_thisWeeksDonations")
global xlRNG_listClassIDs := xlWS_hClasses.Range("A2:A97")

createGui()

return

F8::
return

F9::reload
/*
; activating a specific WorkSheet
xlWS_hClasses.Activate()

; Get all cell values in aCols_membersTable and put in an array
for Index, Column in aCols_membersTable
	for xlCell in xlWS_cMembers.UsedRange.Columns(Column).Cells
	{
		Data[Column, A_Index] := fixFalseFloat(xlCell.Value)
		aCellValueFromLocation[Column, A_Index] := Column A_Index
	}

f_sVerweis := AHK_SVerweis(72, xlRNG_listClassIDs, 1)
msgbox, % "sVerweis für class ID: 72 lautet: " f_sVerweis
msgbox, % "Wir lesen aus der Zelle`t: " aCellValueFromLocation["B", 4] "`nDer Zellinhalt lautet`t: " Data["B", 4]
		. "`n`nWir lesen aus der Zelle`t: " aCellValueFromLocation["C", 4] "`nDer Zellinhalt lautet`t: " Data["C", 4]
		. "`n`nWir lesen aus der Zelle`t: " aCellValueFromLocation["F", 4] "`nDer Zellinhalt lautet`t: " Data["F", 4]
*/

; xlWS.Range("G4").Value := 1337

; msgbox, % "Cell G4 was changed from " Format("{:d}", oldValue) " to " Format("{:d}", xlWS.Range("G4").Value)

; wechselt in die zweite tabelle
;; xlWS := workBook.Worksheets[2] ;// tab 2
;; xlWS.Activate()


