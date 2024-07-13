F12::
	loop, 550
	{
		traytip, % "loop: " A_Index, % "by immo"
		WinActivate, ahk_exe Discord.exe
		if A_Index = 10, 11, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500
			Send /fish sell all
		else
			Send /fish catch {Enter}
		sleep 2750
	}
return