/*  this version of class_RichCode is modified for use with Codesearch

	modification date: 28.5.2020 *IXIKO*

	class RichCode({"TabSize": 4     ; Width of a tab in characters
		, "Indent": "`t"             ; What text to insert on indent
		, "FGColor": 0xRRGGBB        ; Foreground (text) color
		, "BGColor": 0xRRGGBB        ; Background color
		, "Font"                     ; Font to use
		: {"Typeface": "Courier New" ; Name of the typeface
			, "Size": 12             ; Font size in points
			, "Bold": False}         ; Bolded (True/False)


		; Whether to use the highlighter, or leave it as plain text
		, "UseHighlighter": True

		; Delay after typing before the highlighter is run
		, "HighlightDelay": 200

		; The highlighter function (FuncObj or name)
		; to generate the highlighted RTF. It will be passed
		; two parameters, the first being this settings array
		; and the second being the code to be highlighted
		, "Highlighter": Func("HighlightAHK")

		; The colors to be used by the highlighter function.
		; This is currently used only by the highlighter, not at all by the
		; RichCode class. As such, the RGB ordering is by convention only.
		; You can add as many colors to this array as you want.
		, "Colors"
		: [0xRRGGBB
			, 0xRRGGBB
			, 0xRRGGBB,
			, 0xRRGGBB]})
*/

class RichCode {

	static Msftedit := DllCall("LoadLibrary", "Str", "Msftedit.dll")
	static IID_ITextDocument := "{8CC497C0-A1DF-11CE-8098-00AA0047BE5D}"
	static MenuItems := ["Copy", "Select All"]           ; CodeSearch is not a editor
	;~ static MenuItems := ["Cut", "Copy", "Paste", "Delete", "", "Select All", "", "UPPERCASE", "lowercase", "TitleCase"]

	_Frozen := False


	; --- Construction, Destruction, Meta-Functions ---
	__New(Settings, Options:="", RButtonMenu:=1)	 {

			static Test
			global REC

			this.Settings := Settings

		; add Gutter
			if this.Settings.Gutter.Width{

				GutterWidth := this.Settings.Gutter.Width

				RegExMatch(Options, "i)x(?<X>\d+)" 	, opt)
				RegExMatch(Options, "i)y(?<Y>\d+)" 	, opt)
				RegExMatch(Options, "i)w(?<W>\d+)"	, opt)
				RegExMatch(Options, "i)h(?<H>\d+)"	, opt)

				Options:= RegExReplace(Options, "i)x\d+" 	, "x"	optX + GutterWidth)
				Options:= RegExReplace(Options, "i)w\d+"	, "w"	optW - GutterWidth)

				this.AddGutter(optX, optY, GutterWidth, optH)

			}

		; add RichEdit Control - for sourcecode
			Gui, Add, Custom, % "ClassRichEdit50W vREC hWndhWnd +0x5031b1c4 -0x100000 " Options
			this.hWnd := hWnd

		; Enable WordWrap in RichEdit control ("WordWrap" : true)
			if this.Settings.WordWrap
				this.SendMsg(0x0448, 0, 0)

		; Register for WM_COMMAND and WM_NOTIFY events
		; NOTE: this prevents garbage collection of the class until the control is destroyed
			this.EventMask := 1                                   		; ENM_CHANGE
			CtrlEvent       	 := this.CtrlEvent.Bind(this)
			GuiControl, +g, % hWnd, % CtrlEvent

		; Set background color
			BGColor := this.BGRFromRGB(this.Settings.BGColor)
			this.SendMsg(0x443, 0, BGColor)			    	; EM_SETBKGNDCOLOR

		; Set character format
			FGColor := this.BGRFromRGB(this.Settings.FGColor)
			VarSetCapacity(CHARFORMAT2, 116, 0)
			NumPut(116,                           	CHARFORMAT2, 0,        	"UInt")       	; cbSize         	= sizeof(CHARFORMAT2)
			NumPut(0xE0000000,              	CHARFORMAT2, 4,        	"UInt")       	; dwMask      	= CFM_COLOR|CFM_FACE|CFM_SIZE
			NumPut(FGColor,                    	CHARFORMAT2, 20,     	"UInt")       	; crTextColor 	= 0xBBGGRR
			NumPut(Settings.Font.Size*20,  	CHARFORMAT2, 12,        	"UInt")       	; yHeight       	= twips
			StrPut(Settings.Font.Typeface, 	&CHARFORMAT2+26, 32,"UTF-16")  	; szFaceName 	= TCHAR
			this.SendMsg(0x444, 0,         	&CHARFORMAT2)                              	; EM_SETCHARFORMAT

		; Set tab size to 4 for non-highlighted code
			VarSetCapacity(TabStops, 4, 0), NumPut(Settings.TabSize*4, TabStops, "UInt")
			this.SendMsg(0x0CB, 1, &TabStops)                                                   	; EM_SETTABSTOPS

		; Change text limit from 32,767 to max
			this.SendMsg(0x435, 0, -1)                                                                  	; EM_EXLIMITTEXT

		; Bind for keyboard events
		; Use a pointer to prevent reference loop
			this.OnMessageBound := this.OnMessage.Bind(&this)
			OnMessage(0x100, this.OnMessageBound)                                        	; WM_KEYDOWN
			OnMessage(0x20A, this.OnMessageBound)                                        	; WM_KEYDOWN
			If RButtonMenu
				OnMessage(0x205, this.OnMessageBound)                                     	; WM_MouseWheel

		; Bind the highlighter
			this.HighlightBound := this.Highlight.Bind(&this)

		; Create the right click menu
			this.MenuName	:= this.__Class . &this
			RCMBound      	:= this.RightClickMenu.Bind(&this)
			for Index, Entry in this.MenuItems
				Menu, % this.MenuName, Add, % Entry, % RCMBound

		; Get the ITextDocument object
			VarSetCapacity(pIRichEditOle, A_PtrSize, 0)
			this.SendMsg(0x43C, 0, &pIRichEditOle)                                               	; EM_GETOLEINTERFACE
			this.pIRichEditOle     	:= NumGet(pIRichEditOle, 0, "UPtr")
			this.IRichEditOle       	:= ComObject(9, this.pIRichEditOle, 1), ObjAddRef(this.pIRichEditOle)
			this.pITextDocument 	:= ComObjQuery(this.IRichEditOle, this.IID_ITextDocument)
			this.ITextDocument 	:= ComObject(9, this.pITextDocument, 1), ObjAddRef(this.pITextDocument)

	}
	RightClickMenu(ItemName, ItemPos, MenuName)	{

		if !IsObject(this)
			this := Object(this)

		if (ItemName == "Cut")
			Clipboard := this.SelectedText, this.SelectedText := ""
		else if (ItemName == "Copy")
			Clipboard := this.SelectedText
		else if (ItemName == "Paste")
			this.SelectedText := Clipboard
		else if (ItemName == "Delete")
			this.SelectedText := ""
		else if (ItemName == "Select All")
			this.Selection := [0, -1]
		else if (ItemName == "UPPERCASE")
			this.SelectedText := Format("{:U}", this.SelectedText)
		else if (ItemName == "lowercase")
			this.SelectedText := Format("{:L}", this.SelectedText)
		else if (ItemName == "TitleCase")
			this.SelectedText := Format("{:T}", this.SelectedText)

	}
	__Delete() 	{
		; Release the ITextDocument object
		this.ITextDocument 	:= "", ObjRelease(this.pITextDocument)
		this.IRichEditOle      	:= "", ObjRelease(this.pIRichEditOle)

		; Release the OnMessage handlers
		OnMessage(0x100, this.OnMessageBound, 0)                                      	; WM_KEYDOWN
		OnMessage(0x205, this.OnMessageBound, 0)                                      	; WM_RBUTTONUP

		; Destroy the right click menu
		Menu, % this.MenuName, Delete

		HighlightBound := this.HighlightBound
		SetTimer, %HighlightBound%, Delete
	}

	; --- line handling
	GetCaretLine() { ; Get the line containing the caret
      ; EM_LINEINDEX = 0xBB, EM_EXLINEFROMCHAR = 0x0436
      SendMessage, 0xBB  	, -1	, 0                	,, % "ahk_id " this.hWnd
      SendMessage, 0x0436, 0	, % ErrorLevel	,, % "ahk_id " this.hWnd
	Return ErrorLevel + 1
   }

	; --- scroll content
	GetScrollPos() {                                   	; Obtains the current scroll position.
      ; Returns on object with keys 'X' and 'Y' containing the scroll position.
      ; EM_GETSCROLLPOS = 0x04DD
      VarSetCapacity(PT, 8, 0)
      SendMessage, 0x04DD, 0, &PT, , % "ahk_id " this.HWND
	return {X: NumGet(PT, 0, "Int"), Y: NumGet(PT, 4, "Int")}
   }
	ScrollCaret() {                                      	; Scrolls the caret into view.
      ; EM_SCROLLCARET = 0x00B7
      SendMessage, 0x00B7, 0, 0, , % "ahk_id " this.HWND
	Return True
   }
	SetScrollPos(X, Y) {                              	; Scrolls the contents of a rich edit control to the specified point.
		; X : x-position to scroll to.
		; Y : y-position to scroll to.
		; EM_SETSCROLLPOS = 0x04DE
		VarSetCapacity(PT, 8, 0)
		NumPut(X, PT, 0, "Int")
		NumPut(Y, PT, 4, "Int")
		SendMessage, 0x04DE, 0, &PT, , % "ahk_id " this.HWND
	Return ErrorLevel
   }
	ScrollToLine(Line) {
		SendMessage, 0x00CE, 0,0 , ,  % "ahk_id " this.hwnd                            	;M_GETFIRSTVISIBLELINE
		firstVisLineNum := ErrorLevel+1
		SendMessage, 0x00B6, 0, % (line-firstVisLineNum),  ,  % "ahk_id " this.HWND  ; EM_LINESCROLL=0x00B6
	}
	ScrollLines(Lines) {
		SendMessage, 0x00B6, 0, % Lines,,  % "ahk_id " this.HWND  ; EM_LINESCROLL=0x00B6
	}
	ShowScrollBar(SB, Mode := True) { 		; Shows or hides one of the scroll bars of a rich edit control.
      ; SB   : Identifies which scroll bar to display: horizontal or vertical.
      ;        This parameter must be 1 (SB_VERT) or 0 (SB_HORZ).
      ; Mode : Specify TRUE to show the scroll bar and FALSE to hide it.
      ; EM_SHOWSCROLLBAR = 0x0460 (WM_USER + 96)
      SendMessage, 0x0460, % SB, % Mode, , % "ahk_id " . This.HWND
      Return True
   }
	GetLine() {
		SendMessage,0x00C9, Pos1 ,0 , ,  % "ahk_id " This.hwnd  ;EM_LINEFROMCHAR
		return ErrorLevel+1
	}
	GetLineCount(){
		static EM_GETLINECOUNT:=0xBA
		SendMessage, EM_GETLINECOUNT,,,, % "ahk_id " This.hWnd
	Return ErrorLevel
	}

	; --- Text and selection
	FindText(Find, Mode := "") {                 	; Finds Unicode text within a rich edit control.
      ; Find : Text to search for.
      ; Mode : Optional array containing one or more of the keys specified in 'FR'.
      ;        For details see http://msdn.microsoft.com/en-us/library/bb788013(v=vs.85).aspx.
      ; Returns True if the text was found; otherwise false.
      ; EM_FINDTEXTEXW = 0x047C, EM_SCROLLCARET = 0x00B7
      Static FR:= {DOWN: 1, WHOLEWORD: 2, MATCHCASE: 4}
      Flags := 0
      For Each, Value In Mode
         If FR.HasKey(Value)
            Flags |= FR[Value]
      Sel := This.GetSel()
      Min := (Flags & FR.DOWN) ? Sel.E : Sel.S
      Max := (Flags & FR.DOWN) ? -1 : 0
      VarSetCapacity(FTX, 16 + A_PtrSize, 0)
      NumPut(Min, FTX, 0, "Int")
      NumPut(Max, FTX, 4, "Int")
      NumPut(&Find, FTX, 8, "Ptr")
      SendMessage, 0x047C, %Flags%, &FTX, , % "ahk_id " . This.HWND
      S := NumGet(FTX, 8 + A_PtrSize, "Int"), E := NumGet(FTX, 12 + A_PtrSize, "Int")
      If (S = -1) && (E = -1)
         Return False
	  This.SetFont({BkColor:"YELLOW", Color:"BLACK"})
      This.SetSel(S, E)
      This.ScrollCaret()
      Return
   }
	GetCharFormat() {                               	; Retrieves the character formatting of the current selection.
		  ; For details see http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx.
		  ; Returns a 'CF2' object containing the formatting settings.
		  ; EM_GETCHARFORMAT = 0x043A
		  CF2 := New This.CF2
		  this.SendMsg(0x043A, 1, CF2.CF2)
		  Return (CF2.Mask ? CF2 : False)
	}
	SetCharFormat(CF2) {                          	; Sets character formatting of the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx.
      ; CF2 : CF2 object like returned by GetCharFormat().
      ; EM_SETCHARFORMAT = 0x0444
      this.SendMsg(0x0444, 1, CF2.CF2)
      Return ErrorLevel
   }
	GetParaFormat() {                              	; Retrieves the paragraph formatting of the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx.
      ; Returns a 'PF2' object containing the formatting settings.
      ; EM_GETPARAFORMAT = 0x043D
      PF2 := New This.PF2
      SendMessage, 0x043D, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return (PF2.Mask ? PF2 : False)
	}
	SetParaFormat(PF2) {                           	; Sets the  paragraph formatting for the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx.
      ; PF2 : PF2 object like returned by GetParaFormat().
      ; EM_SETPARAFORMAT = 0x0447
      SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
	GetSel() {                                             	; Retrieves the starting and ending character positions of the selection in a rich edit control.

		; Returns an object containing the keys S (start of selection) and E (end of selection)).
		; EM_EXGETSEL = 0x0434
		VarSetCapacity(CR, 8, 0)
		SendMessage, 0x0434, 0, &CR, , % "ahk_id " this.hWnd

	Return {S: NumGet(CR, 0, "Int"), E: NumGet(CR, 4, "Int")}
	}
  	SetSel(Start, End) {                                	; Selects a range of characters.
      ; Start : zero-based start index
      ; End   : zero-beased end index (-1 = end of text))
      ; EM_EXSETSEL = 0x0437
      VarSetCapacity(CR, 8, 0)
      NumPut(Start, CR, 0, "Int")
      NumPut(End,   CR, 4, "Int")
      SendMessage, 0x0437, 0, &CR, , % "ahk_id " this.hWnd
      Return ErrorLevel
   }
	SetFont(Font) {                                    	; Set current/default font

      ; Font : Object containing the following keys
      ;        Name    : optional font name
      ;        Size    : optional font size in points
      ;        Style   : optional string of one or more of the following styles
      ;                  B = bold, I = italic, U = underline, S = strikeout, L = subscript
      ;                  H = superschript, P = protected, N = normal
      ;        Color   : optional text color as RGB integer value or HTML color name
      ;                  "Auto" for "automatic" (system's default) color
      ;        BkColor : optional text background color (see Color)
      ;                  "Auto" for "automatic" (system's default) background color
      ;        CharSet : optional font character set
      ;                  1 = DEFAULT_CHARSET, 2 = SYMBOL_CHARSET
      ;        Empty parameters preserve the corresponding properties
      ; EM_SETCHARFORMAT = 0x0444
      ; SCF_DEFAULT = 0, SCF_SELECTION = 1

      CF2 := New This.CF2
      Mask := Effects := 0
      If (Font.Name != "") {
         Mask |= 0x20000000, Effects |= 0x20000000 ; CFM_FACE, CFE_FACE
         CF2.FaceName := Font.Name
      }
      Size := Font.Size
      If (Size != "") {
         If (Size < 161)
            Size *= 20
         Mask |= 0x80000000, Effects |= 0x80000000 ; CFM_SIZE, CFE_SIZE
         CF2.Height := Size
      }
      If (Font.Style != "") {
         Mask |= 0x3001F           ; all font styles
         If InStr(Font.Style, "B")
            Effects |= 1           ; CFE_BOLD
         If InStr(Font.Style, "I")
            Effects |= 2           ; CFE_ITALIC
         If InStr(Font.Style, "U")
            Effects |= 4           ; CFE_UNDERLINE
         If InStr(Font.Style, "S")
            Effects |= 8           ; CFE_STRIKEOUT
         If InStr(Font.Style, "P")
            Effects |= 16          ; CFE_PROTECTED
         If InStr(Font.Style, "L")
            Effects |= 0x10000     ; CFE_SUBSCRIPT
         If InStr(Font.Style, "H")
            Effects |= 0x20000     ; CFE_SUPERSCRIPT
      }
      If (Font.Color != "") {
         Mask |= 0x40000000        ; CFM_COLOR
         If (Font.Color = "Auto")
            Effects |= 0x40000000  ; CFE_AUTOCOLOR
         Else
            CF2.TextColor := This.GetBGR(Font.Color)
      }
      If (Font.BkColor != "") {
         Mask |= 0x04000000        ; CFM_BACKCOLOR
         If (Font.BkColor = "Auto")
            Effects |= 0x04000000  ; CFE_AUTOBACKCOLOR
         Else
            CF2.BackColor := This.GetBGR(Font.BkColor)
      }
      If (Font.CharSet != "") {
         Mask |= 0x08000000, Effects |= 0x08000000 ; CFM_CHARSET, CFE_CHARSET
         CF2.CharSet := Font.CharSet = 2 ? 2 : 1 ; SYMBOL|DEFAULT
      }
      If (Mask != 0) {
         Mode := Font.Default ? 0 : 1
         CF2.Mask := Mask
         CF2.Effects := Effects
         SendMessage, 0x0444, %Mode%, % CF2.CF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
	SetText(ByRef Text := "", Mode := "") { 	; Replaces the selection or the whole content of the control.
      ; Mode : Option flags. It can be any reasonable combination of the keys defined in 'ST'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb774284(v=vs.85).aspx.
      ; EM_SETTEXTEX = 0x0461, CP_UNICODE = 1200
      ; ST_DEFAULT = 0, ST_KEEPUNDO = 1, ST_SELECTION = 2, ST_NEWCHARS = 4 ???
      Static ST := {DEFAULT: 0, KEEPUNDO: 1, SELECTION: 2}
      Flags := 0
      For Each, Value In Mode
         If ST.HasKey(Value)
            Flags |= ST[Value]
      CP := 1200
      BufAddr := &Text
      ; RTF formatted text has to be passed as ANSI!!!
      If (SubStr(Text, 1, 5) = "{\rtf") || (SubStr(Text, 1, 5) = "{urtf") {
         Len := StrPut(Text, "CP0")
         VarSetCapacity(Buf, Len, 0)
         StrPut(Text, &Buf, "CP0")
         BufAddr := &Buf
         CP := 0
      }
      VarSetCapacity(STX, 8, 0)     ; SETTEXTEX structure
      NumPut(Flags, STX, 0, "UInt") ; flags
      NumPut(CP  ,  STX, 4, "UInt") ; codepage
      SendMessage, 0x0461, &STX, BufAddr, , % "ahk_id " . this.hWnd
      Return ErrorLevel
   }
	ToggleFontStyle(Style) { 						; Toggle single font style
      ; Style : one of the following styles
      ;         B = bold, I = italic, U = underline, S = strikeout, L = subscript, H = superschript, P = protected,
      ;         N = normal (reset all other styles)
      ; EM_GETCHARFORMAT = 0x043A, EM_SETCHARFORMAT = 0x0444
      ; CFM_BOLD = 1, CFM_ITALIC = 2, CFM_UNDERLINE = 4, CFM_STRIKEOUT = 8, CFM_PROTECTED = 16, CFM_SUBSCRIPT = 0x30000
      ; CFE_SUBSCRIPT = 0x10000, CFE_SUPERSCRIPT = 0x20000, SCF_SELECTION = 1
      CF2 :=This.GetCharFormat()
      CF2.Mask := 0x3001F ; FontStyles
      If (Style = "N")
         CF2.Effects := 0
      Else
         CF2.Effects ^= Style = "B" ? 1 : Style = "I" ? 2 : Style = "U" ? 4 : Style = "S" ? 8
                      : Style = "H" ? 0x20000 : Style = "L" ? 0x10000 : 0
      this.SendMsg(0x0444, 1, CF2.CF2)
      Return ErrorLevel
   }
	GetKeywordFromCaret()	{

		; https://autohotkey.com/boards/viewtopic.php?p=180369#p180369
		static Buffer
		IsUnicode := !!A_IsUnicode

		sel := This.Selection

		; Get the currently selected line
		LineNum := this.SendMsg(0x436, 0, sel[1]) ; EM_EXLINEFROMCHAR

		; Size a buffer according to the line's length
		Length := this.SendMsg(0xC1, sel[1], 0) ; EM_LINELENGTH
		VarSetCapacity(Buffer, Length << !!A_IsUnicode, 0)
		NumPut(Length, Buffer, "UShort")

		; Get the text from the line
		this.SendMsg(0xC4, LineNum, &Buffer) ; EM_GETLINE
		lineText := StrGet(&Buffer, Length)

		; Parse the line to find the word
		LineIndex := this.SendMsg(0xBB, LineNum, 0) ; EM_LINEINDEX
		RegExMatch(SubStr(lineText, 1, sel[1]-LineIndex), "[#\w]+$" 	, Start)
		RegExMatch(SubStr(lineText, sel[1]-LineIndex+1), "^[#\w]+"	, End)

		return Start . End
	}

	; --- control style
	AddMargins(x:=0, y:=0, w:=0, h:=0, gutter:=false) { 	; add margins in pixel size to RichCode control

      VarSetCapacity(RECT, 16, 0)

      if !DllCall("GetClientRect", "UPtr", (gutter ? this.hgutter : this.hWnd ), "UPtr", &RECT, "UInt")
          throw Exception("Couldn't get RichEdit Client RECT")

      NumPut(x	+ NumGet(RECT,  0	, "Int")	, RECT,     0, "Int")
      NumPut(y 	+ NumGet(RECT,  4	, "Int")	, RECT,     4, "Int")
      NumPut(w	+ NumGet(RECT,  8	, "Int")	, RECT,     8, "Int")
      NumPut(h	+ NumGet(RECT, 12, "Int")	, RECT,   12, "Int")

      this.SendMsg(0xB3, 0, &RECT, gutter)
	}
	AddGutter(X,Y,W,H)	{

		f 	:= this.Settings.Font

		; Add the RichEdit control for the gutter
		Gui, Add, Custom, % "ClassRichEdit50W hWndhGutter +0x5031b1c6 -HScroll -VScroll x" X " y" Y " w" W " h" H
		this.hGutter := hGutter

		; Set the background and font settings
		FGColor := this.BGRFromRGB(this.Settings.Gutter.FGColor)
		BGColor := this.BGRFromRGB(this.Settings.Gutter.BGColor)

		VarSetCapacity(CF2, 116, 0)
		NumPut(116,     	     &CF2+ 0, "UInt")              	; cbSize          	= sizeof(CF2)
		NumPut(0xE<<28,    &CF2+ 4, "UInt")              	; dwMask          = CFM_COLOR|CFM_FACE|CFM_SIZE
		NumPut(f.Size*20,  	&CF2+12, "UInt")              	; yHeight         	= twips
		NumPut(FGColor,    	&CF2+20, "UInt")              	; crTextColor 	= 0xBBGGRR
		StrPut(f.Typeface, &CF2+26, 32, "UTF-16")         	; szFaceName 	= TCHAR

		this.SendMsg(0x444, 0, &CF2    	, true)        	; EM_SETCHARFORMAT
		this.SendMsg(0x443, 0, BGColor	, true)        	; EM_SETBKGNDCOLOR

		this.AddMargins(3, 3, -3, 0, true)

	}
	SyncGutter()	{

		static BUFF, _ := VarSetCapacity(BUFF, 16, 0)

		if !this.Settings.Gutter.Width
			return

		this.SendMsg(0x4E0, &BUFF, &BUFF+4) 	; EM_GETZOOM
		this.SendMsg(0x4DD, 0, &BUFF+8) 	    	; EM_GETSCROLLPOS

		; Don't update the gutter unnecessarily
		State := NumGet(BUFF, 0, "UInt") . NumGet(BUFF, 4, "UInt") . NumGet(BUFF, 8, "UInt") . NumGet(BUFF, 12, "UInt")
		if (State == this.GutterState)
			return

		NumPut(-1, BUFF, 8, "UInt") ; Don't sync horizontal position
		Zoom := [NumGet(BUFF, "UInt"), NumGet(BUFF, 4, "UInt")]
		this.PostMsg(0x4E1, Zoom[1], Zoom[2]	, true)     	; EM_SETZOOM
		this.PostMsg(0x4DE, 0, &BUFF+8       	, true)		; EM_SETSCROLLPOS
		this.ZoomLevel := Zoom[1] / Zoom[2]
		;if (this.ZoomLevel != this.LastZoomLevel)
		;	SetTimer(this.Bound.GuiSize, -0), this.LastZoomLevel := this.ZoomLevel

		this.GutterState := State
	}


	; --- Event Handlers ---
	OnMessage(wParam, lParam, Msg, hWnd)	{
		if !IsObject(this)
			this := Object(this)
		if (hWnd != this.hWnd)
			return

		if (Msg == 0x100) {                                                                              	; WM_KEYDOWN
				if (wParam == GetKeyVK("Tab")) 	{
						; Indentation
						Selection := this.Selection
						if GetKeyState("Shift")
							this.IndentSelection(True)                                               	; Reverse
						else if (Selection[2] - Selection[1])                                       	; Something is selected
							this.IndentSelection()
						else
						{
							; TODO: Trim to size needed to reach next TabSize
							this.SelectedText := this.Settings.Indent
							this.Selection[1] := this.Selection[2]                                	; Place cursor after
						}
						return False
				}
				else if (wParam == GetKeyVK("Escape"))                                     	; Normally closes the window
						return False
				else if (wParam == GetKeyVK("v") && GetKeyState("Ctrl"))
				{
						this.SelectedText := Clipboard                                             	; Strips formatting
						this.Selection[1] := this.Selection[2]                                    	; Place cursor after
						return False
			}
		}
		else if (Msg == 0x205)       {                                                                   	; WM_RBUTTONUP
			Menu, % this.MenuName, Show
			return False
		}
		else if (Msg == 0x20A)       {                                                                   	; WM_MouseWheel
			;~ SendInput, % (wParam = 0x780000 ? "{Up}" : "{Down}")
		}
	}
	CtrlEvent(CtrlHwnd, GuiEvent, EventInfo, _ErrorLevel:="")	{
		if (GuiEvent == "Normal" && EventInfo == 0x300)     {                       	; EN_CHANGE
			; Delay until the user is finished changing the document
			HighlightBound := this.HighlightBound
			SetTimer, %HighlightBound%, % -Abs(this.Settings.HighlightDelay)
		}

		RCHandler( A_GuiControlEvent, A_GuiEvent, A_EventInfo, this.GetCaretLine())

	}
	Highlight(NewVal*)	{

		; --- Methods ---
		; First parameter is taken as a replacement value
		; Variadic form is used to detect when a parameter is given,
		; regardless of content

		if !IsObject(this)
			this := Object(this)
		if !(this.Settings.UseHighlighter && this.Settings.Highlighter)		{
			if NewVal.Length()
				GuiControl,, % this.hWnd, % NewVal[1]
			return
		}

		; Freeze the control while it is being modified, stop change event
		; generation, suspend the undo buffer, buffer any input events
		PrevFrozen := this.Frozen, this.Frozen := True
		PrevEventMask := this.EventMask, this.EventMask := 0 ; ENM_NONE
		PrevUndoSuspended := this.UndoSuspended, this.UndoSuspended := True
		PrevCritical := A_IsCritical
		Critical, 1000

		; Run the highlighter
		Highlighter := this.Settings.Highlighter
		RTF := %Highlighter%(this.Settings, NewVal.Length() ? NewVal[1] : this.Value)

		; "TRichEdit suspend/resume undo function",  https://stackoverflow.com/a/21206620

		; Save the rich text to a UTF-8 buffer
		VarSetCapacity(Buf, StrPut(RTF, "UTF-8"), 0)
		StrPut(RTF, &Buf, "UTF-8")

		; Set up the necessary structs
		VarSetCapacity(ZOOM,         	8, 0) 	; Zoom Level
		VarSetCapacity(POINT,        	8, 0) 	; Scroll Pos
		VarSetCapacity(CHARRANGE, 8, 0) 	; Selection
		VarSetCapacity(SETTEXTEX, 	8, 0) 	; SetText Settings
		NumPut(1,   	 SETTEXTEX, 0, "UInt") ; flags = ST_KEEPUNDO

		; Save the scroll and cursor positions, update the text,
		; then restore the scroll and cursor positions
		MODIFY := this.SendMsg(0xB8, 0, 0)           	; EM_GETMODIFY
		this.SendMsg(0x4E0, 	&ZOOM, &ZOOM+4)	; EM_GETZOOM
		this.SendMsg(0x4DD, 	0, &POINT)               	; EM_GETSCROLLPOS
		this.SendMsg(0x434, 	0, &CHARRANGE)     	; EM_EXGETSEL
		this.SendMsg(0x461, 	&SETTEXTEX, &Buf)   	; EM_SETTEXTEX
		this.SendMsg(0x437, 	0, &CHARRANGE)     	; EM_EXSETSEL
		this.SendMsg(0x4DE, 	0, &POINT)                	; EM_SETSCROLLPOS
		this.SendMsg(0x4E1, 	NumGet(ZOOM, "UInt")
			, NumGet(ZOOM, 4, "UInt"))                    	; EM_SETZOOM
		this.SendMsg(0xB9, MODIFY, 0)                    	; EM_SETMODIFY

		; Restore previous settings
		Critical, %PrevCritical%
		this.UndoSuspended := PrevUndoSuspended
		this.EventMask := PrevEventMask
		this.Frozen := PrevFrozen
	}
	IndentSelection(Reverse:=False, Indent:="")	{

		; Freeze the control while it is being modified, stop change event
		; generation, buffer any input events
			PrevFrozen := this.Frozen, this.Frozen := True
			PrevEventMask := this.EventMask, this.EventMask := 0 ; ENM_NONE
			PrevCritical := A_IsCritical
			Critical, 1000

			if (Indent == "")
				Indent := this.Settings.Indent
			IndentLen := StrLen(Indent)

		; Select back to the start of the first line
			Min := this.Selection[1]
			Top := this.SendMsg(0x436, 0, Min) ; EM_EXLINEFROMCHAR
			TopLineIndex := this.SendMsg(0xBB, Top, 0) ; EM_LINEINDEX
			this.Selection[1] := TopLineIndex

		; TODO: Insert newlines using SetSel/ReplaceSel to avoid having to call
		; the highlighter again
			Text := this.SelectedText
			if Reverse 	{

				; Remove indentation appropriately
					Loop, Parse, Text, `n, `r
					{

							if (InStr(A_LoopField, Indent) == 1) 	{

									Out .= "`n" SubStr(A_LoopField, 1+IndentLen)
									if (A_Index == 1)
										Min -= IndentLen

							} else
									Out .= "`n" A_LoopField

					}

					this.SelectedText := SubStr(Out, 2)

				; Move the selection start back, but never onto the previous line
					this.Selection[1] := Min < TopLineIndex ? TopLineIndex : Min

			} else  {

				; Add indentation appropriately
					Trailing := (SubStr(Text, 0) == "`n")
					Temp := Trailing ? SubStr(Text, 1, -1) : Text
					Loop, Parse, Temp, `n, `r
						Out .= "`n" Indent . A_LoopField
					this.SelectedText := SubStr(Out, 2) . (Trailing ? "`n" : "")

				; Move the selection start forward
					this.Selection[1] := Min + IndentLen

		}

			this.Highlight()

		; Restore previous settings
			Critical, %PrevCritical%
			this.EventMask := PrevEventMask

		; When content changes cause the horizontal scrollbar to disappear,
		; unfreezing causes the scrollbar to jump. To solve this, jump back
		; after unfreezing. This will cause a flicker when that edge case
		; occurs, but it's better than the alternative.
			VarSetCapacity(POINT, 8, 0)
			this.SendMsg(0x4DD, 0, &POINT) ; EM_GETSCROLLPOS
			this.Frozen := PrevFrozen
			this.SendMsg(0x4DE, 0, &POINT) ; EM_SETSCROLLPOS

	}


	; --- document object of the specified RichEdit control
	GetDocObj(interface) {
		; interface is for example IID_ITextDocument

		Static IID_ITextDocument 	:= "{8CC497C0-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextRange       	:= "{8CC497C2-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextSelection  	:= "{8CC497C1-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextFont          	:= "{8CC497C3-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextPara          	:= "{8CC497C4-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextStoryRanges	:= "{8CC497C5-A1DF-11CE-8098-00AA0047BE5D}"
		Static IID_ITextDocument2	:= "{01C25500-4268-11D1-883A-3C8B00C10000}"
		Static IID_ITextMsgFilter  	:= "{A3787420-4267-11D1-883A-3C8B00C10000}"

	   DocObj := 0
	   If DllCall("SendMessage", "Ptr", this.hWnd, "UInt", 0x043C, "Ptr", 0, "PtrP", IRichEditOle, "UInt") { ; EM_GETOLEINTERFACE
		  DocObj := ComObject(9, ComObjQuery(IRichEditOle, %interface%), 1) ; ITextDocument
		  ObjRelease(IRichEditOle)
	   }
   Return DocObj
	}


	; --- Helper/Convenience Methods ---
	SendMsg(Msg	, wParam, lParam, gutter:=false)	{
		;SciTEOutput("sendmessage: " msg " to " (gutter ? "Gutter" : "Code"))
		SendMessage, Msg, wParam, lParam,, % "ahk_id" (gutter ? this.hGutter : this.hWnd)
		return ErrorLevel
	}
	PostMsg(Msg 	, wParam, lParam, gutter:=false)	{
	PostMessage, Msg, wParam, lParam,, % "ahk_id " (gutter ? this.hGutter : this.hWnd)
	return ErrorLevel
}

		; --- Static Methods ---
	BGRFromRGB(RGB)	{
		return RGB>>16&0xFF | RGB&0xFF00 | RGB<<16&0xFF0000
	}
	Value[]	{                                       	; --- Properties ---
		get {
			GuiControlGet, Code,, % this.hWnd
			return Code
		}

		set {
			this.Highlight(Value)
			return Value
		}
	}
	Selection[i:=0]	{                           	; TODO: reserve and reuse memory
		get {
			VarSetCapacity(CHARRANGE, 8, 0)
			this.SendMsg(0x434, 0, &CHARRANGE) ; EM_EXGETSEL
			Out := [NumGet(CHARRANGE, 0, "Int"), NumGet(CHARRANGE, 4, "Int")]
			return i ? Out[i] : Out
		}

		set {
			if i
				Temp := this.Selection, Temp[i] := Value, Value := Temp
			VarSetCapacity(CHARRANGE, 8, 0)
			NumPut(Value[1], &CHARRANGE, 0, "Int") ; cpMin
			NumPut(Value[2], &CHARRANGE, 4, "Int") ; cpMax
			this.SendMsg(0x437, 0, &CHARRANGE) ; EM_EXSETSEL
			return Value
		}
	}
	SelectedText[]	{
		get {
			Selection := this.Selection, Length := Selection[2] - Selection[1]
			VarSetCapacity(Buffer, (Length + 1) * 2) ; +1 for null terminator
			if (this.SendMsg(0x43E, 0, &Buffer) > Length) ; EM_GETSELTEXT
				throw Exception("Text larger than selection! Buffer overflow!")
			Text := StrGet(&Buffer, Selection[2]-Selection[1], "UTF-16")
			return StrReplace(Text, "`r", "`n")
		}

		set {
			this.SendMsg(0xC2, 1, &Value) ; EM_REPLACESEL
			this.Selection[1] -= StrLen(Value)
			return Value
		}
	}
	EventMask[]	{
		get {
			return this._EventMask
		}

		set {
			this._EventMask := Value
			this.SendMsg(0x445, 0, Value) ; EM_SETEVENTMASK
			return Value
		}
	}
	UndoSuspended[]	{
		get {
			return this._UndoSuspended
		}

		set {
			try ; ITextDocument is not implemented in WINE
			{
				if Value
					this.ITextDocument.Undo(-9999995) ; tomSuspend
				else
					this.ITextDocument.Undo(-9999994) ; tomResume
			}
			return this._UndoSuspended := !!Value
		}
	}
	Frozen[]	{
		get {
			return this._Frozen
		}

		set {
			if (Value && !this._Frozen)
			{
				try ; ITextDocument is not implemented in WINE
					this.ITextDocument.Freeze()
				catch
					GuiControl, -Redraw, % this.hWnd
			}
			else if (!Value && this._Frozen)
			{
				try ; ITextDocument is not implemented in WINE
					this.ITextDocument.Unfreeze()
				catch
					GuiControl, +Redraw, % this.hWnd
			}
			return this._Frozen := !!Value
		}
	}
	Modified[]	{
		get {
			return this.SendMsg(0xB8, 0, 0) ; EM_GETMODIFY
		}

		set {
			this.SendMsg(0xB9, Value, 0) ; EM_SETMODIFY
			return Value
		}
	}


  ; INTERNAL CLASSES ===================================================================================
   ; =============================================================================================
   ; ============================================================================================
   Class CF2 { ; CHARFORMAT2 structure -> http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx
      __New() {
         Static CF2_Size := 116
         This.Insert(":", {Mask: {O: 4, T: "UInt"}, Effects: {O: 8, T: "UInt"}
                         , Height: {O: 12, T: "Int"}, Offset: {O: 16, T: "Int"}
                         , TextColor: {O: 20, T: "Int"}, CharSet: {O: 24, T: "UChar"}
                         , PitchAndFamily: {O: 25, T: "UChar"}, FaceName: {O: 26, T: "Str32"}
                         , Weight: {O: 90, T: "UShort"}, Spacing: {O: 92, T: "Short"}
                         , BackColor: {O: 96, T: "UInt"}, LCID: {O: 100, T: "UInt"}
                         , Cookie: {O: 104, T: "UInt"}, Style: {O: 108, T: "Short"}
                         , Kerning: {O: 110, T: "UShort"}, UnderlineType: {O: 112, T: "UChar"}
                         , Animation: {O: 113, T: "UChar"}, RevAuthor: {O: 114, T: "UChar"}
                         , UnderlineColor: {O: 115, T: "UChar"}})
         This.Insert(".")
         This.SetCapacity(".", CF2_Size)
         Addr :=  This.GetAddress(".")
         DllCall("Kernel32.dll\RtlZeroMemory", "Ptr", Addr, "Ptr", CF2_Size)
         NumPut(CF2_Size, Addr + 0, 0, "UInt")
      }
      __Get(Name) {
         Addr := This.GetAddress(".")
         If (Name = "CF2")
            Return Addr
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "FaceName")
            Return NumGet(Addr + 0, Attr.O, Attr.T)
         Return StrGet(Addr + Attr.O, 32)
      }
      __Set(Name, Value) {
         Addr := This.GetAddress(".")
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "FaceName")
            NumPut(Value, Addr + 0, Attr.O, Attr.T)
         Else
            StrPut(Value, Addr + Attr.O, 32)
         Return Value
      }
   }

   Class PF2 { ; PARAFORMAT2 structure -> http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx
      __New() {
         Static PF2_Size := 188
         This.Insert(":", {Mask: {O: 4, T: "UInt"}, Numbering: {O: 8, T: "UShort"}
                         , StartIndent: {O: 12, T: "Int"}, RightIndent: {O: 16, T: "Int"}
                         , Offset: {O: 20, T: "Int"}, Alignment: {O: 24, T: "UShort"}
                         , TabCount: {O: 26, T: "UShort"}, Tabs: {O: 28, T: "UInt"}
                         , SpaceBefore: {O: 156, T: "Int"}, SpaceAfter: {O: 160, T: "Int"}
                         , LineSpacing: {O: 164, T: "Int"}, Style: {O: 168, T: "Short"}
                         , LineSpacingRule: {O: 170, T: "UChar"}, OutlineLevel: {O: 171, T: "UChar"}
                         , ShadingWeight: {O: 172, T: "UShort"}, ShadingStyle: {O: 174, T: "UShort"}
                         , NumberingStart: {O: 176, T: "UShort"}, NumberingStyle: {O: 178, T: "UShort"}
                         , NumberingTab: {O: 180, T: "UShort"}, BorderSpace: {O: 182, T: "UShort"}
                         , BorderWidth: {O: 184, T: "UShort"}, Borders: {O: 186, T: "UShort"}})
         This.Insert(".")
         This.SetCapacity(".", PF2_Size)
         Addr :=  This.GetAddress(".")
         DllCall("Kernel32.dll\RtlZeroMemory", "Ptr", Addr, "Ptr", PF2_Size)
         NumPut(PF2_Size, Addr + 0, 0, "UInt")
      }
      __Get(Name) {
         Addr := This.GetAddress(".")
         If (Name = "PF2")
            Return Addr
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "Tabs")
            Return NumGet(Addr + 0, Attr.O, Attr.T)
         Tabs := []
         Offset := Attr.O - 4
         Loop, 32
            Tabs[A_Index] := NumGet(Addr + 0, Offset += 4, "UInt")
         Return Tabs
      }
      __Set(Name, Value) {
         Addr := This.GetAddress(".")
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "Tabs") {
            NumPut(Value, Addr + 0, Attr.O, Attr.T)
            Return Value
         }
         If !IsObject(Value)
            Return ""
         Offset := Attr.O - 4
         For Each, Tab In Value
            NumPut(Tab, Addr + 0, Offset += 4, "UInt")
         Return Tabs
      }
   }

}
