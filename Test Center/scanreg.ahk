;ListLargeRegistryValues v1.0.1, March 2022.
;https://pastebin.com/u/jcunews
;https://greasyfork.org/en/users/85671-jcunews
;https://www.reddit.com/u/jcunews1
;
;Scans Windows registry for values which have relatively large data.
;A list text file will be created on the desktop and
;will be automatically opened using Notepad.
;
;An idea based on a Reddit post:
;https://www.reddit.com/r/windows/comments/tfrq2y/ntuserdat_taking_up_100gb_of_space/

getValueSize(hKey, name) {
  global fqueryval
  if (dllcall(fQueryVal, "ptr", hkey, "wstr", name, "ptr", 0, "ptr", 0
    , "ptr", 0, "int*", sz) == 0) {
    return sz
  } else return -1
}

processKey(key, subkey) {
  global fclosekey, fopenkey, keys, acnt, fcnt, tk, mvs, list
    , sortmap, hlbl
  k:= keys[key]
  if (dllcall(fOpenKey, "ptr", k, "wstr", subkey, "int", 0, "int", 1
    , "ptr*", hkey) == 0) {
    p:= subkey ? key "\" subkey : key
    loop reg, %p%
    {
      acnt++
      sz:= getvaluesize(hkey, a_loopregname)
      if (sz >= mvs) {
        fcnt++
        list.push([sz, a_loopregname, p])
        sortmap:= sortmap format("{:011u},{:u}", sz, list.length()) "`n"
      }
      t:= a_tickcount
      if ((t - tk) >= 1000) {
        tk:= t
        controlsettext, , Retrieving values...%acnt%/%fcnt%, ahk_id %hlbl%
      }
    }
    dllcall(fCloseKey, "ptr", hkey)
    loop reg, %key%\%subkey%, k
    {
      processkey(key, subkey ? subkey "\" a_loopregname : a_loopregname)
    }
  }
}

guiclose() {
  return true
}

guisize(hwnd, event, width, height) {
  global hbtn
  if (hbtn != "") {
    controlgetpos, , , a, , , ahk_id %hbtn%
    guicontrol move, % hbtn, % "x" ((width - a) / 2)
  }
}

gcancel() {
  msgbox 36, %a_scriptname%, Cancel operation?
  ifmsgbox yes
    exitapp
}

if (!fileexist(a_windir "\system32\config\systemprofile\*")) {
  if (a_args[1] == "/elevate") {
    a:= "Elevation request has been denied.`n"
      . "Do you want to retry the elevation?"
  } else {
    a:= "This script requires elevation for "
      . "accessing some system registries. Proceed with elevation?"
  }
  msgbox 51, %a_scriptname%, %a%
  ifmsgbox cancel
    exitapp
  ifmsgbox yes
  {
    run *runas "%a_ahkpath%" /restart "%a_scriptfullpath%" /elevate
      , a_workingdir
    exitapp
  }
}

while (true) {
  inputbox a, %a_scriptname%
    , % "Please enter the minimum registry value data size in Bytes.`n`n"
    . "The value should be at least 2048.`n"
    . "Otherwise the list may become too large."
    , , , , , , , , 16384
  if (errorlevel != 0) {
    exitapp
  }
  a:= trim(a) * 1
  if ((a != "") && (floor(a) == a) && (a >= 0)) {
    if (a >= 2048) {
      mvs:= a
      break
    } else {
      msgbox 51, %a_scriptname%
        , % "The data size is too small and the list may become too large.`n"
        . "Do you want to use it anyway?"
      ifmsgbox cancel
        exitapp
      ifmsgbox yes
      {
        mvs:= a
        break
      }
    }
  } else {
    msgbox 16, %a_scriptname%, Data size must be a positive integer number.
  }
}

gui -resize -sysmenu hwndhgui
gui margin, 40, 20
gui font, s12
a:= ""
loop 20
{
  a:= a chr(160)
}
gui add, text, center hwndhlbl, %a%Retrieving values...0/0%a%
gui add, button, ggcancel hwndhbtn y+30, Cancel
gui show

hm:= dllcall("GetModuleHandle", "str", "advapi32.dll", "ptr")
fCloseKey:= dllcall("GetProcAddress", "ptr", hm, "astr", "RegCloseKey", "ptr")
fOpenKey:= dllcall("GetProcAddress", "ptr", hm, "astr", "RegOpenKeyExW", "ptr")
fQueryVal:= dllcall("GetProcAddress", "ptr", hm, "astr", "RegQueryValueExW"
  , "ptr")

keys:= {}
keys.HKEY_CLASSES_ROOT:= 0x80000000
keys.HKEY_CURRENT_USER:= 0x80000001
keys.HKEY_LOCAL_MACHINE:= 0x80000002

list:= [] ;[[size, value, key], ...]
sortMap:= "" ;000size,index
acnt:= 0
fcnt:= 0
tk:= a_tickcount

;%userprofile%\NTUSER.DAT and %localappdata%\Microsoft\Windows\UsrClass.dat
processKey("HKEY_CURRENT_USER", "")

;%systemroot%\ServiceProfiles\LocalService\NTUSER.DAT
processKey("HKEY_USERS", "S-1-5-19")

;%systemroot%\ServiceProfiles\NetworkService\NTUSER.DAT
processKey("HKEY_USERS", "S-1-5-20")

;%systemroot%\system32\config\DEFAULT
processKey("HKEY_USERS", ".default")

;%systemroot%\system32\config\SOFTWARE
processKey("HKEY_LOCAL_MACHINE", "software")

;%systemroot%\system32\config\SYSTEM
processKey("HKEY_LOCAL_MACHINE", "system")

sort sortmap, cr
s:= ""
loop parse, % substr(sortmap, 1, strlen(sortmap) - 1), `n
{
  a:= substr(a_loopfield, instr(a_loopfield, ",", true, 0) + 1)
  b:= ""
  if (list[a][1] >= 10240) {
    b:= b format(" ({:.2f} KB", list[a][1] / 1024)
    if (list[a][1] >= 10485760) {
      b:= b format(" / {:.2f} MB", list[a][1] / 1048576)
      if (list[a][1] >= 10485760) {
        b:= b format(" / {:.2f} GB", list[a][1] / 1073741824)
      }
    }
    b:= b ")"
  }
  s:= s list[a][3] "`n  " list[a][2] " = " list[a][1] " Bytes" b "`n"
}
gui hide

fn:= a_desktop "\" substr(a_scriptname, 1, strlen(a_scriptname) - 3) "txt"
filedelete %fn%
fileappend %s%, %fn%, utf-8
msgbox 32, %a_scriptname%, List has been saved into desktop.
regread a, HKCU\Software\Microsoft\Notepad, fWrap
regwrite REG_DWORD, HKCU\Software\Microsoft\Notepad, fWrap, 0
run notepad.exe "%fn%", %a_desktop%
sleep 1000
regwrite REG_DWORD, HKCU\Software\Microsoft\Notepad, fWrap, %a%
exitapp
