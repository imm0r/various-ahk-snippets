; List of all available flags () for KNOWN_FOLDER_FLAG:
; (https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/ne-shlobj_core-known_folder_flag)
     KF_FLAG_DEFAULT = 0x00000000
     KF_FLAG_FORCE_APP_DATA_REDIRECTION = 0x00080000
     KF_FLAG_RETURN_FILTER_REDIRECTION_TARGET = 0x00040000
     KF_FLAG_FORCE_PACKAGE_REDIRECTION = 0x00020000
     KF_FLAG_NO_PACKAGE_REDIRECTION = 0x00010000
     KF_FLAG_FORCE_APPCONTAINER_REDIRECTION = 0x00020000
     KF_FLAG_NO_APPCONTAINER_REDIRECTION = 0x00010000
     KF_FLAG_CREATE = 0x00008000
     KF_FLAG_DONT_VERIFY = 0x00004000
     KF_FLAG_DONT_UNEXPAND = 0x00002000
     KF_FLAG_NO_ALIAS = 0x00001000
     KF_FLAG_INIT = 0x00000800
     KF_FLAG_DEFAULT_PATH = 0x00000400
     KF_FLAG_NOT_PARENT_RELATIVE = 0x00000200
     KF_FLAG_SIMPLE_IDLIST = 0x00000100
     KF_FLAG_ALIAS_ONLY = 0x80000000

SHGetKnownFolderPath(REFKNOWNFOLDERID, KNOWN_FOLDER_FLAG:=0, hToken:=0) {                  ; By SKAN on D356 @ tiny.cc/t-75602 
Local CLSID, pPath:=""                                        ; Thanks teadrinker @ tiny.cc/p286094
Return Format("{4:}", VarSetCapacity(CLSID, 16, 0)
     , DllCall("ole32\CLSIDFromString", "Str", REFKNOWNFOLDERID, "Ptr", &CLSID)
     , DllCall("shell32\SHGetKnownFolderPath", "Ptr", &CLSID, "UInt", KNOWN_FOLDER_FLAG, "Ptr", hToken, "PtrP", pPath)
     , StrGet(pPath, "utf-16")
     , DllCall("ole32\CoTaskMemFree", "Ptr", pPath))
}