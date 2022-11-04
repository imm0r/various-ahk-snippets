GetProcList(pName)
{
	local a_PID := []
	s := 4096

	Process, Exist
	h := DllCall("OpenProcess", "UInt", 0x0400, "Int", false, "UInt", ErrorLevel, "Ptr")
	DllCall("Advapi32.dll\OpenProcessToken", "Ptr", h, "UInt", 32, "PtrP", t)
	VarSetCapacity(ti, 16, 0), NumPut(1, ti, 0, "UInt")
	DllCall("Advapi32.dll\LookupPrivilegeValue", "Ptr", 0, "Str", "SeDebugPrivilege", "Int64P", luid)
	NumPut(luid, ti, 4, "Int64"), NumPut(2, ti, 12, "UInt")
	r := DllCall("Advapi32.dll\AdjustTokenPrivileges", "Ptr", t, "Int", false, "Ptr", &ti, "UInt", 0, "Ptr", 0, "Ptr", 0)
	DllCall("CloseHandle", "Ptr", t), DllCall("CloseHandle", "Ptr", h)

	hModule := DllCall("LoadLibrary", "Str", "Psapi.dll")
	s := VarSetCapacity(a, s)
	DllCall("Psapi.dll\EnumProcesses", "Ptr", &a, "UInt", s, "UIntP", r)
	Loop, % r // 4  ; Parst das Array mit Identifikatoren als DWORDs (32 Bit):
	{
		id := NumGet(a, A_Index * 4, "UInt")
		h := DllCall("OpenProcess", "UInt", 0x0010 | 0x0400, "Int", false, "UInt", id, "Ptr")
		if !h
			continue
		VarSetCapacity(n, s, 0)  ; Ein Pufferspeicher für den Basisnamen des Moduls:
		e := DllCall("Psapi.dll\GetModuleBaseName", "Ptr", h, "Ptr", 0, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
		if !e    ; Fallback-Methode für 64-Bit-Prozesse, wenn sie im 32-Bit-Modus sind:
			if e := DllCall("Psapi.dll\GetProcessImageFileName", "Ptr", h, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
				SplitPath n, n
		DllCall("CloseHandle", "Ptr", h)
		if (n && e)
			if( IsObject( pName ) )
				Loop, % pName.MaxIndex( )
					if( n = pName[A_Index] )
						a_PID.Push(id)
			else
				if( n = pName )
					a_PID.Push(id)
	}
	DllCall("FreeLibrary", "Ptr", hModule)
	return a_PID
}