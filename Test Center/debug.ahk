#SingleInstance,Force
checkfiles()
rxml:=new xml("recv")
v:=[]
global hwnd,v,rxml
gui()
load("small.ahk")
v.hwnd:=hwnd,v.msg:=[]
return
class Socket{
	static __eventMsg:=0x9987,list:=[],number:=""
	__New(s=-1){
		static init
		if (!init){
			DllCall("LoadLibrary","str","ws2_32","ptr")
			VarSetCapacity(wsadata,394+A_PtrSize)
			DllCall("ws2_32\WSAStartup","ushort",0x0000,"ptr",&wsadata)
			DllCall("ws2_32\WSAStartup","ushort",NumGet(wsadata,2,"ushort"),"ptr",&wsadata)
			OnMessage(Socket.__eventMsg,"SocketEventProc")
			init := 1
		}
		this.socket:=s
		if s>0
		this.list[s]:=this
		
	}
	bind(host,port){
		if ((this.socket!=-1)||(!(faddr:=next:=this.AddrInfo(host,port))))
		return 0
		while (next){
			sockaddrlen := NumGet(next+0, 16, "uint")
			sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
			if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int",1, "int",6,"ptr"))!=-1){
				if (DllCall("ws2_32\bind", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "int")=0){
					socket.list[this.socket]:=this
					DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
					return Socket.__eventProcRegister(this, 0x29)
				}
				this.disconnect()
			}
			next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
		}
		this.lastError := DllCall("ws2_32\WSAGetLastError")
		return 0
	}
	listen(backlog=32){
		flan:=DllCall("ws2_32\listen", "ptr", this.socket, "int", backlog)
		return flan
	}
	AddrInfo(host,port){
		VarSetCapacity(hints,8*A_PtrSize,0)
		for a,b in {6:8,1:12}
		NumPut(a,hints,b)
		DllCall("ws2_32\getaddrinfo",astr,host,astr,port,"uptr",hints,"ptr*",results)
		return results
	}
	__eventProcRegister(obj,msg){
		a:=SocketEventProc([1])
		a[obj.socket]:=obj
		socket.number:=obj.socket
		return (DllCall("ws2_32\WSAAsyncSelect","ptr",obj.socket,"ptr",A_ScriptHwnd,"uint",Socket.__eventMsg,"uint",msg)=0)?1:0
	}
	__Delete(){
		this.disconnect()
	}
	accept(){
		if ((s := DllCall("ws2_32\accept", "ptr", this.socket, "ptr", 0, "int", 0, "ptr"))!=-1){
			newsock:=new Socket(s)
			newsock.__protocolId := 6
			newsock.__socketType := 1
			Socket.__eventProcRegister(newsock, 0x21)
			return newsock
		}
		return 0
	}
	disconnect(){
		a:=SocketEventProc([1])
		a.remove(this.socket)
		DllCall("ws2_32\WSAAsyncSelect","ptr",this.socket,"ptr",A_ScriptHwnd,"uint",0,"uint",0)=0
		DllCall("ws2_32\closesocket","ptr",this.socket,"int")
		this.socket:=-1
		return 1
	}
	onrecv(sock){
		;Thank you Lexikos and fincs http://hkscript.org/download/tools/DBGP.ahk
		Critical
		VarSetCapacity(buffer,length)
		while,DllCall("ws2_32\recv","ptr",sock.socket,"char*",c,"int",1,"int",0){
			if c=0
			break
			length.=chr(c)
		}
		VarSetCapacity(packet,++length)
		received:=0
		While(received<length){
			r:=DllCall("ws2_32\recv","ptr",sock.socket,"ptr",&packet+received,"int",length-received,"int",0)
			if r = -1
			return m("An error occured")
			if r = 0
			return m("An error occured")
			received += r
			sleep,100
		}
		if info:=StrGet(&packet,"utf-8")
		display(info)
	}
}
;---------------------------------------end socket--------------
SocketEventProc(info*){
	Critical
	static count:=0
	global id
	static a:=[]
	if info.1.1
	return a
	if (info.3=socket.__eventmsg){
		if (info.2&0xFFFF=1){
			a[info.1].onrecv(a[info.1])
		}
		if (info.2&0xffff=8){
			sock:=socket.list[info.1]
			ss:=sock.accept()
		}			
		if (info.2&0xFFFF=32)
		return a[info.1].disconnect()
	}
}
m(x*){
	for a,b in x
	list.=b "`n"
	MsgBox,% list
}
t(x*){
	for a,b in x
	list.=b "`n"
	Tooltip,% list
}
class xml{
	keep:=[]
	__New(param*){
		root:=param.1
		file:=file?file:root ".xml"
		temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		this.xml:=this.CreateElement(temp,root)
		xml.keep[root]:=this
	}
	CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}
	ssn(node){
		return this.xml.SelectSingleNode(node)
	}
	sn(node){
		return this.xml.SelectNodes(node)
	}
	__Get(x=""){
		return this.xml.xml
	}
	ea(ph){
		list:=[]
		if IsObject(ph)
		nodes:=ph.SelectNodes("@*")
		else
		nodes:=this.sn(ph "/@*")
		while,n:=nodes.item(A_Index-1)
		list[n.nodename]:=n.text
		return list
	}
	
}
ssn(node,path){
	return node.SelectSingleNode(path)
}
gui(){
	Gui,+hwndhwnd
	hwnd(1,hwnd)
	IfWinActive,% hwnd([1])
	Hotkey,Escape,GuiEscape,On
	DllCall("LoadLibrary","str","scilexer.dll")
	v.sc:=new s(1,"xm ym w800 h400")
	Gui,Add,TreeView,w300 h200 Section AltSubmit gset Disabled
	Gui,Add,Button,grun x+10 ys Disabled,Run
	Gui,Add,Button,gload,Load File
	Gui,Add,Button,x320 y+10 gkill,Kill Process
	for a,b in ["Feature","Property"]
	v.tv[b]:=TV_Add(b)
	for a,b in ["max_children","max_data","max_depth"]
	TV_Add(b,v.tv.feature)
	for a,b in ["property_set"]
	v.tv.propertyset:=TV_Add("property_set",v.tv.property)
	for a,b in v.tv
	if b is number
	TV_Modify(b,"Expand")
	v.getvl:=TV_Add("Variable List",0,"bold")
	v.getvar:=TV_Add("Variable/Object Info",0,"bold")
	Gui,Show
	ControlFocus,Edit1,% hwnd([1])
}
set:
if (A_GuiEvent="S"||A_GuiEvent="Normal"){
	if (A_GuiEvent="S"&&A_EventInfo=lev)
	return
	if (TV_GetParent(A_EventInfo)=v.tv.feature){
		TV_GetText(feature,A_EventInfo)
		InputBox,value,Value,Input a number for %feature%,,,,,,,,20
		if ErrorLevel
		return
		send("feature_set -n " feature " -v" value)
	}
	if (A_EventInfo=v.tv.propertyset){
		InputBox,property,Property,Property Name
		if ErrorLevel
		return
		InputBox,value,Property Value,Porperty Value
		if ErrorLevel
		return
		send("property_set -n " property " -- " Base64UTF8Encode(value))
		
	}
	if (A_EventInfo=v.getvl){
		send("context_get -c 1")
	}
	if (A_EventInfo=v.getvar){
		InputBox,vv,Inspect Variable/Object,Enter a variable name
		if ErrorLevel
		return
		send("property_get -n " vv)
	}
	lev:=A_EventInfo
}
return
setrange:
ControlGetText,range,Edit2,% "ahk_id" v.hwnd
send("feature_set -n max_children -v" range)
return
load(file){
	load:
	if !(file){
		FileSelectFile,file,,,,*.ahk
		if ErrorLevel
		return
	}
	sock:=new socket()
	sock.bind("127.0.0.1",9000)
	sock.listen("127.0.0.1",9000)
	SplitPath,file,,dir
	Run,"%A_AhkPath%" /Debug "%file%",%dir%
	WinSetTitle,ahk_id%hwnd%,,File Opened %file%
	file:=""
	return
}
run(){
	Run:
	send("run")
	GuiControl,+Disabled,Button1
	return
}
send(message){
	sock:=socket.current.socket
	sock:=socket.number
	message.=Chr(0)
	len:=strlen(message)
	VarSetCapacity(buffer,len)
	ll:=StrPut(message,&buffer,"utf-8")
	flan:=DllCall("ws2_32\send",uint,sock,uptr,&buffer,"int",ll, "int", 0, "cdecl")	
}
BinaryToString(ByRef bin, sz=0, fmt=12) {
	n := sz>0 ? sz : VarSetCapacity(bin)
	DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&bin, "uint",n, "uint",fmt, "ptr",0, "uint*",cp:=0) ; get size
	VarSetCapacity(str, cp*(A_IsUnicode ? 2:1))
	DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&bin, "uint",n, "uint",fmt, "str",str, "uint*",cp)
	return str
}
Base64UTF8Encode(ByRef textdata) {
	if (textdata = "")
	return
	VarSetCapacity(rawdata, StrPut(textdata, "utf-8")), sz := StrPut(textdata, &rawdata, "utf-8") - 1
	return BinaryToString(rawdata, sz, 0x40000001)
}
;http://www.autohotkey.com/forum/viewtopic.php?p=238120#238120
Base64UTF8Decode(ByRef base64){
	if (base64 = "")
	return
	cp := StringToBinary(result, base64, 1)
	return StrGet(&result, cp, "utf-8")
}
StringToBinary(ByRef bin, hex, fmt=12) {
	DllCall("Crypt32.dll\CryptStringToBinary", "ptr",&hex, "uint",StrLen(hex), "uint",fmt, "ptr",0, "uint*",cp:=0, "ptr",0,"ptr",0) ; get size
	VarSetCapacity(bin, cp)
	DllCall("Crypt32.dll\CryptStringToBinary", "ptr",&hex, "uint",StrLen(hex), "uint",fmt, "ptr",&bin, "uint*",cp, "ptr",0,"ptr",0)
	return cp
}
exit(){
	GuiClose:
	GuiEscape:
	send("stop")
	ExitApp
	return
}
class s{
	static ctrl:=[],lc:=""
	__New(window="",pos=""){
		win:=window?window:1
		Gui,%win%:Add,edit, hwndsc w500 h400 %pos% +1387331584 gnotify
		this.sc:=sc,s.ctrl[sc]:=this,t:=[]
		for a,b in {fn:2184,ptr:2185}
		this[a]:=DllCall("SendMessageA","UInt",sc,"int",b,int,0,int,0)
		v.focus:=sc
		this.2660(1)
		for a,b in [[2563,1],[2565,1],[2614,1],[2402,0x15,75],[2051,32,0xaaaaaa],[2052,32,0],[2050],[2051,22,0x0000ff],[2409,22,1],[2242,1,0],[2059,22,1]]{
			b.2:=b.2?b.2:0,b.3:=b.3?b.3:0
			this[b.1](b.2,b.3)
		}
		this.2077(0,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.0123456789")
		return this
	}
	__Delete(){
		m("should not happen")
	}
	__Get(x*){
		return DllCall(this.fn,"Ptr",this.ptr,"UInt",x.1,int,0,int,0,"Cdecl")
	}
	__Call(code,lparam=0,wparam=0){
		if (code="getseltext"){
			VarSetCapacity(text,this.2161),length:=this.2161(0,&text)
			return StrGet(&text,length,"cp0")
		}
		if (code="textrange"){
			VarSetCapacity(text,abs(lparam-wparam)),VarSetCapacity(textrange,12,0),NumPut(lparam,textrange,0),NumPut(wparam,textrange,4),NumPut(&text,textrange,8)
			this.2162(0,&textrange)
			return strget(&text,"","cp0")
		}
		if (code="gettext"){
			cap:=VarSetCapacity(text,vv:=this.2182),this.2182(vv,&text),t:=strget(&text,vv,"cp0")
			return t
		}
		wp:=(wparam+0)!=""?"Int":"AStr"
		if wparam.1
		wp:="AStr"
		if wparam=0
		wp:="int"
		return DllCall(this.fn,"Ptr",this.ptr,"UInt",code,int,lparam,wp,wparam,"Cdecl")
	}
}
checkfiles(){
	if !FileExist("scilexer.dll")
	urldownloadtofile,http://www.maestrith.com/files/AHKStudio/SciLexer.dll,SciLexer.dll
}
notify(){
	notify:
	sc:=v.sc
	fn:=[],info:=A_EventInfo
	for a,b in {0:"Obj",2:"Code",4:"ch",7:"text",6:"modType",9:"linesadded",8:"length",3:"position"}
	fn[b]:=NumGet(Info+(A_PtrSize*a))
	if (fn.code=2027){
		find:=sc.textrange(sc.2266(fn.position,0),sc.2267(fn.position,0))
		send("property_get -n " find)
	}
	return
}
display(store){
	start:=1
	sc:=v.sc
	if !store
	return
	rxml.xml.loadxml(store)
	if info:=rxml.ssn("//stream[@type='stderr']"){
		sc.2003(sc.2006,"`r`n" Base64UTF8Decode(info.text))
		return send("stop")
	}
	if init:=rxml.ssn("//init"){
		GuiControl,-Disabled,Button1
		GuiControl,+Disabled,Button2
		GuiControl,-Disabled,SysTreeView321
		ea:=rxml.ea(init)
		for a,b in ea
		if (a="appid"||a="thread")
		disp.=a " = " Chr(34) b Chr(34) "`r`n"
		v.pid:=ea.thread
		disp:=sc.2006?"`r`n" disp:disp
		sc.2003(sc.2006,disp)
		send("stderr -c 1")
		;send("run")
		;GuiControl,+Disabled,Button1
		return send("feature_set -n max_children -v 30")
	}
	if rxml.ssn("//property"){
		if property:=rxml.sn("//property"){
			sc.2003(sc.2006,"`r`n`r`nVariable/Object List`r`n")
			end:=sc.2006,hlt:=[]
			if property.length>1000
			ToolTip,Compiling List Please Wait...,350,150
			while,pp:=property.item[A_Index-1]{
				type:=ssn(pp,"@type").text,fullname:=ssn(pp,"@fullname").text
				if (type="object"){
					disp.="`r`nObject: " fullname
					hlt.Insert({name:fullname,type:"object"})
				}
				else
				disp.="`r`n" ssn(pp,"@type").text ": " fullname " = " Base64UTF8Decode(pp.text)
			}
			sc.2003(sc.2006,disp),start:=1
			for a,b in hlt{
				start:=RegExMatch(disp,b.name,found)
				;if there are multiple types
				;style:=colors[b.type]
				sc.2032(start+end-1,255),sc.2033(StrLen(found),22)
				t()
			}
		}
	}else if command:=rxml.ssn("//response"){
		ea:=rxml.ea(command)
		for a,b in ea
		if (a&&b)
		disp.=a " = " Chr(34) b Chr(34) " "
		disp:=sc.2006?"`r`n" disp:disp
		sc.2003(sc.2006,disp)
	}else{
		disp:=sc.2006?"`r`n" rxml[]:rxml[]
		sc.2003(sc.2006,disp)
	}
	/*
		disp:=sc.2006?"`r`n" rxml[]:rxml[]
		sc.2003(sc.2006,disp)
	*/
	sleep,100
	if InStr(store,"stopped"){
		GuiControl,+Disabled,SysTreeView321
		GuiControl,-Disabled,Button2
		WinSetTitle,% "ahk_id" v.hwnd,,Job Complete
	}
	sc.2629
	return
	disp:=rxml[]
	store:=disp?disp:store
	return sock	
}
hwnd(win,hwnd=""){
	static window:=[]
	if (win.rem){
		Gui,% win.rem ":Destroy"
		window.remove[win.rem]
	}
	if IsObject(win)
	return "ahk_id" window[win.1]
	if !hwnd
	return window[win]
	window[win]:=hwnd
}
kill(){
	kill:
	send("stop")
	return
}