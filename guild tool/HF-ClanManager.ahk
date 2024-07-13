#noenv
#singleinstance, force

; Setting up used directories
fld_excel := "excel\"
fld_wR := "webRequest\"
global fld_archive := "archive\"

; including needed libs
#include <core>
#include lib\helper.ahk
#include lib\gui.ahk

; DBG starting benchmark timer
core.benchmark(true)

; Shows us com errors.
ComObjError(true)

; setting up full path for important files
global xlFile := fld_excel . "HF-ClanManager.xlsm"
global pwsh_script := fld_wR . "GetMembers.exe"
global json_members := fld_wR . "list_Members.json"
global json_classes := fld_wR . "list_Classes.json"

; initializing arrays
Data := {}, aCellValueFromLocation := {}
global aColLetter := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
aCols_membersTable := ["A","B","C","D","E","F","G"]

; running excel app as comObject
; if an instance already exists it uses this one instead opening another new one.
try global xlApp := ComObjActive("Excel.Application")
catch
	global xlApp := ComObjCreate("Excel.Application")

; Open an existing excel file as Workbook
global xlWB := xlApp.WorkBooks.Open(xlFile)

; set excel visible or invisible
xlApp.Visible := true

; setting up WorkSheets
global xlWS_cMembers := xlWB.Sheets("ClanMembers")	; xlWB.Worksheets("ClanMembers")
global xlWS_hDataTotal := xlWB.Sheets("hDataTotal")	; xlWB.Worksheets("hDataTotal")
global xlWS_hClasses := xlWB.Sheets("hClasses")		; xlWB.Worksheets("hClasses")

; setting up ranges
global xlRNG_colThisDonat := xlWS_cMembers.Range("col_thisWeeksDonations")
global xlRNG_colToDaFull := xlWS_hDataTotal.Range("Tbl_TotalDonations")
global xlRNG_colToDaMembers := xlWS_hDataTotal.Range("Tbl_TotalDonations[Member]")
global xlRNG_listMembers := xlWS_cMembers.Range("Table_ClanMembers[Member]")
global xlRNG_listClassIDs := xlWS_hClasses.Range("A2:A97")

; creating arrays from ranges
aList_ClanMembersMain := GetClanMembersFromRange(xlRNG_listMembers)
aList_ClanMembersTotal := GetClanMembersFromRange(xlRNG_colToDaMembers)

; creating the user interface
createGui()

return

F9::reload
/*
; activating a specific WorkSheet
xlWS_hClasses.Activate()

; Get all cell values in aCols_membersTable and put in an array
for Index, Column in aCols_membersTable
{
	for xlCell in xlWS_cMembers.UsedRange.Columns(Column).Cells
	{
		Data[Column, A_Index] := fixFalseFloat(xlCell.Value)
		aCellValueFromLocation[Column, A_Index] := Column A_Index
	}
	msgbox, % "CellValue: " aCellValueFromLocation["F", 4] "`nCellAddress: " Data["F", 4]
}

; xlWS.Range("G4").Value := 1337
; msgbox, % "Cell G4 was changed from " Format("{:d}", oldValue) " to " Format("{:d}", xlWS.Range("G4").Value)
; wechselt in die zweite tabelle
;; xlWS := workBook.Worksheets[2] ;// tab 2
;; xlWS.Activate()
*/
