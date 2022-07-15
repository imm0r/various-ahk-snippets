Process, exist   ; the script's own PID is written to errorlevel
hScript := winExist(ahk_pid %errorlevel%)

varSetCapacity(v, 2)
NumPut(2, v, 0, "uChar")
NumPut(2, v, 1, "uChar")
VarSetcapacity(WSAInfo, 1)   ; works
GoAhead? := dllCall("Ws2_32\WSAStartup",uShort,&v,uInt,&WSAInfo)

port := dllCall("Ws2_32\htons", uShort,80)   ; host->netw byte order conv
Host = www.autohotkey.com ; ___.XXXXXXXXX.com as indicated on status bar
Host2IP(Host)
IPinp := dllCall("Ws2_32\inet_addr",str,IP4)   ; 4use in IN_ADDR strucs
Socketref := dllCall("Ws2_32\socket", int,2, int,1, int,6)

VarSetCapacity(sockaddrstrucP, 16)
NumPut(2, sockaddrstrucP, 0, "uShort")
NumPut(port, sockaddrstrucP, 2, "uShort")
NumPut(IPinp, sockaddrstrucP, 4)
Y := dllCall("Ws2_32\connect",uInt,Socketref,uInt,&sockaddrstrucP, int,16)

;dllCall("Ws2_32\WSACleanup")

Onmessage(0xdafeed, "bug")   ; msg# a free choice
;hScript := winExist("Wiretapping ahk_class AutoHotkey")   ; malfn
; winExist("ahk_class AutoHotkey ahk_pid "dllCall("GetCurrentProcessId"))
;;Process, exist   ; the script's own PID is written to errorlevel
;;hScript := winExist(ahk_pid %errorlevel%)
OK? := dllCall("Ws2_32\WSAAsyncSelect",uInt,Socketref,uInt,hScript, uInt
                                            , 0xdafeed, int, 0x1) ;|0x20)

; GoAhead?, Y, OK? ought to be zero
;dllCall("Ws2_32\closesocket",uInt,Socketref)
return

bug(Socketref, netwEvent)   ; netwEvent the low word of a DWORD
{
;    CRITICAL
    GLOBAL a
    a =1
    VarSetCapacity(buffer, 13948, 0)   ; 4096 - work on bufferSz handling
    breadablein1swoop := dllCall("Ws2_32\recv",uInt,Socketref,str,buffer
                                      ,int, 13948, int, 0x2)   ; |MSG_EOR
    if InStr(buffer, 3716) ;"d(12,1,1,")
        Tooltip, Working.
}



Host2IP(Host, value =1)
{
    GLOBAL IP4, IP8
    HostInfostrucP := dllCall("Ws2_32\gethostbyname",str,Host)
    if HostInfostrucP
    {
        AddrListP := NumGet(numGet(HostInfostrucP +12)+0)
        loop 24   ; read in the <=4 meaningful IP addresses <-> loop 16
        {
            IP .= NumGet(AddrListP+0, a_index-1, "uChar") "."
            if mod(a_index, 4) =0
            {
                if a_index >4
                {
                    if (#dot := substr(IP,1, 3) != 4real)
                        break
                }
                else if a_index =4
                    4real := substr(IP,1, 3)
            stringTrimRight, IP,IP, 1   ; alt.: IP := substr(IP,1, -1)
            IP%a_index% = %IP%   ; or IP .= "," coupled with stringSplit
            IP=
            }
        }
    }
    else
        return 0

    if IP8 and value =1
        return x
    else
        return value
}



;__WSA_send(Socketref, __WSA_Data) {   ; look into
;dllCall("Ws2_32\send", uInt,Socketref, str,  WSAInfo, int
;                                              , StrLen(WSAInfo), int, 0)
;}