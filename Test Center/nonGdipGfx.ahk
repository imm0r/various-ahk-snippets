#NoEnv
#SingleInstance force
DetectHiddenWindows On
SetBatchLines -1

If( !A_IsAdmin )
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"

oG := ComObjCreate("GflAx.GflAx") ; create GflAx object
oG.SaveFormatName := "tiff"       ; save image in Tagged Image File Format

w :=	600, h :=	420                ; set width and height of new image
oG.NewBitmap(w, h, 0x0)           ; create new bitmap 

oG.LineWidth :=	4                 ; set linewidth to 4
oG.LineColor :=	0xB0CD7D          ; set linecolor to 0xB0CD7D (BGR-Format)

; Vertex contains a list of x\y-coordinates for use with AddVertex, DrawPolyLine and FreeVertex.
; Of course this list can be created dynamically in practical use.
Vertex :=	"0,240|25,240|29,210|42,269|56,225|62,240|117,240|137,190|158,269|167,217|170,240|233,240|"
 . "248,179|267,270|281,218|288,240|354,240|372,176|390,259|402,220|408,240|458,240|487,118|530,319|552,185|"
 . "565,240|600,240"

Loop, parse, Vertex, |            
{
	StringSplit, v, A_LoopField, `,
	oG.AddVertex(v1, v2)            ; add separate coordinates to the vertex list
} 

oG.DrawPolyLine                   ; draw a polyline from the vertex list
oG.FreeVertex                     ; free the vertex list

oG.FillColor :=	0xB0CD7D          ; set fillcolor to 0xB0CD7D (BGR-Format)
oG.DrawFillCircle(598, 240, 3)    ; draw a filled cricle
oG.GaussianBlur(0.6)              ; blur image
oG.SaveBitmap("Line")             ; save image

r1 :=	30, r2 :=	15                ; define width\height for columns\rows of grid
oG.NewBitmap(w, h, 0x004037)      ; create new bitmap with background-color
                                  ; 0x004037 (BGR-Format)

oG.LineWidth :=	1                 ; set linewidth to 1
oG.LineColor :=	0x054D3F          ; set linecolor to 0x054D3F (BGR-Format)
xy :=	0
Loop, %	w/r2 - 1
	xy +=	r2, oG.DrawLine(xy, 0, xy, h), oG.DrawLine(0, xy, w, xy)  ; Draw grid

oG.LineWidth := 1                 ; set linewidth to 1
oG.LineColor := 0x32824D          ; set linecolor to 0x32824D (BGR-Format)
xy :=	0
Loop, % w/r1 - 1
  xy += r1, oG.DrawLine(xy, 0, xy, h), oG.DrawLine(0, xy, w, xy) ; Draw grid

oG.SaveBitmap("Grid")             ; save image

; Merge Grid.tif and Line.tif                                                                         
oG.MergeAddFile("Grid.tif", 50, 0 ,0)
oG.MergeAddFile("Line.tif", 50, 0 ,0)
oG.Merge
oG.MergeClear

; set font properties
oG.FontName := "Arial"
oG.FontSize := 24
oG.FontBold := true

; draw the text
oG.TextOut("AHK_L", 30, 30, 0x0000ff)
oG.SaveBitmap(A_ScriptName)

ObjRelease(oG)                    ; release object