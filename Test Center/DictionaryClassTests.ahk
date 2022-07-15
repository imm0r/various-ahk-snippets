#NoEnv
#SingleInstance force
SetWorkingDir %A_ScriptDir%

#Include <dict>
 
Try
{
    exampleDict := new dict()
    exampleDict.map(["top", 403, 404], ["OK", "Access forbidden", "File not found"])
    exampleDict.set(666, "Number of the beast")

    ;exampleDict.map(666, "Number of the beast")
    for k, v in exampleDict.data
        FullDictData .= "Dictionary entry: " A_Index " of " exampleDict.Size ":`n`tkey`t: " k "`n`tValue`t: " v "`n`n"
    msgbox, % FullDictData

    msgbox, % exampleDict.get("top")
    exampleDict.remove(666)
    dictClone := exampleDict.clone()
    msgbox, % "Entry 666 is no longer available in the dictionary! > " dictClone.has(666) "`nNew Dictionary Size: " exampleDict.size
}
catch e
    MsgBox % "Error in " e.What ", which was called at line " e.Line

Hex2Str(x) {                ; Convert hex stream, starting with #, to string
   Loop % StrLen(x)//2      ; 2-digit blocks, 1st digit at is pos 2, after #
      str .= Chr("0x" SubStr(x,2*A_Index,2))
   Return str
}