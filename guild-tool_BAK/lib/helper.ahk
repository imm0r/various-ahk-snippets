;https://docs.microsoft.com/en-us/office/vba/api/excel.range.pastespecial
xlPasteAll :=  -4104                      ; Everything will be pasted.
xlPasteAllExceptBorders := 7              ; Everything except borders will be pasted.
xlPasteAllMergingConditionalFormats := 14 ; Everything will be pasted and conditional formats will be merged.
xlPasteAllUsingSourceTheme := 13          ; Everything will be pasted using the source theme.
xlPasteColumnWidths := 8                  ; Copied column width is pasted.
xlPasteComments := -4144                  ; Comments are pasted.
xlPasteFormats := -4122                   ; Copied source format is pasted.
xlPasteFormulas := -4123                  ; Formulas are pasted.
xlPasteFormulasAndNumberFormats := 11     ; Formulas and Number formats are pasted.
xlPasteValidation := 6                    ; Validations are pasted.
xlPasteValues := -4163                    ; Values are pasted.
xlPasteValuesAndNumberFormats := 12       ; Values and Number formats are pasted.

; Save the excel workbook, close it & remove the Excel Object
xlSaveAndQuit()
{
	xlWB.Save
	xlWB.Close(0)
	xlApp.Quit
	xlApp := ""
}

; msgbox, % "firstrow := " xlGetRowNr(xlWS_cMembers, "B", "Clan Members")
; msgbox, % "lastrow := " xlGetRowNr(xlWS_cMembers)
xlGetRowNr(ws, col := "A", needle := "") {
	return, % ws.Columns(col).Find[needle].Row
}
xlGetColNr(ws, row := "1", needle := "") {
	return, % xlNumberToLetter(ws.Rows(row).Find[needle].Column)
}

; msgbox, % "D = " xlLetterToNumber("D")
xlLetterToNumber(letter) {
	Loop, % aColLetter.MaxIndex()
		if (inStr(xlWS_cMembers.Columns(A_Index).Address, letter))
			return A_Index
	return 0
}

; msgbox, % "D = " xlNumberToLetter(4)
xlNumberToLetter(num) {
	Loop, % aColLetter.MaxIndex()
		if (A_Index = Num)
			return, % aColLetter[A_Index]
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

GetClanMembersFromRange(sRng)
{
	aTmp := array()
	for xlCell in sRng.Cells
	{
		tName := xlCell.value
		aTmp.push(tName)
	}
	return, % aTmp
}

AHK_SVerweis(searchStr, sRng, sOffset, RetVal := 1)
{
	for xlCell in sRng.Cells
	{
		if (fixFalseFloat(xlCell.Value) = searchStr)
			if (RetVal = 2)
				return, % xlCell.offset(0, sOffset).address
			else
				return, % fixFalseFloat(xlCell.offset(0, sOffset).value)
	}

		; msgbox, % "sourceCell`t: " xlCell.address ": " fixFalseFloat(xlCell.Value) "`n"
		;		. "targetCell`t: " xlCell.offset(0, sOffset).address ": " fixFalseFloat(xlCell.offset(0, sOffset).value)
}