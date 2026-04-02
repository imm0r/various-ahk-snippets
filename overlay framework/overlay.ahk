; AutoHotkey v1 syntax
#NoEnv
#SingleInstance Force
SetBatchLines, -1
ListLines, Off

#Include <Gdip_All>

; ==========================================================
;  GDI+ INIT
; ==========================================================
if !pToken := Gdip_Startup()
{
    MsgBox, GDI+ konnte nicht gestartet werden
    ExitApp
}

global RunderHudLoop := 0
global A_ScreenW := A_ScreenWidth
global A_ScreenH := A_ScreenHeight
global hdc, hbm, pGraphics, hOverlay, WALeft, WARight, WATop, WABottom, ppvBits

SysGet, WA, MonitorWorkArea
HUDsize := "x" WALeft " y" WATop " w" (WARight - WALeft) " h" (WABottom - WATop)

; Overlay window
Gui, HUD:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20 +E0x80000
Gui, HUD:Show, %HUDsize%
hOverlay := WinExist()


hdc := CreateCompatibleDC()
if !hdc
{
    MsgBox, CreateCompatibleDC fehlgeschlagen
    ExitApp
}

ppvBits := 0
hbm := CreateDIBSection(WARight - WALeft, WABottom - WATop, hdc, 32, ppvBits)
if !hbm
{
    MsgBox, % "CreateDIBSection fehlgeschlagen. hdc=" hdc ", Width=" WARight - WALeft ", Height="WABottom - WATop
    ExitApp
}

obm := SelectObject(hdc, hbm)

pGraphics := Gdip_GraphicsFromImage(hbm)
Gdip_SetSmoothingMode(pGraphics, 4)

global HUD_Dirty := true

; ==========================================================
;  GRID / ZONEN
; ==========================================================
global HUD_Layout := {}

HUD_InitGrid()
{
    global HUD_Layout, A_ScreenW, A_ScreenH

    HUD_Layout := {ScreenW:A_ScreenW,ScreenH:A_ScreenH,TopBar:{x:0.10, y:0.02, w:0.80, h:0.06, padding:8, margin:6, flow:"horizontal", cursor:0},LeftHUD:{x:0.02, y:0.20, w:0.25, h:0.60, padding:6, margin:6, flow:"vertical", cursor:0}}
}

HUD_ResolveZone(name)
{
    global HUD_Layout
    z := HUD_Layout[name]

    return {x:Round(z.x * HUD_Layout.ScreenW),y:Round(z.y * HUD_Layout.ScreenH),w:Round(z.w * HUD_Layout.ScreenW),h:Round(z.h * HUD_Layout.ScreenH),padding:z.padding,margin:z.margin}
}

HUD_ResetZones()
{
    global HUD_Layout
    for k, v in HUD_Layout
        if IsObject(v)
            v.cursor := 0
}

HUD_NextSlot(zone, w := 0, h := 0)
{
    global HUD_Layout
    z := HUD_Layout[zone]
    r := HUD_ResolveZone(zone)

    if (z.flow = "vertical")
    {
        x := r.x + r.padding
        y := r.y + r.padding + z.cursor
        w := w ? w : r.w - r.padding*2
        z.cursor += h + r.margin
    }
    else
    {
        x := r.x + r.padding + z.cursor
        y := r.y + r.padding
        h := h ? h : r.h - r.padding*2
        z.cursor += w + r.margin
    }

    HUD_Layout[zone] := z
    return {x:x, y:y, w:w, h:h}
}

; ==========================================================
;  ANIMATION (ULTRA LEICHT)
; ==========================================================
CreateAnimation(x1,y1,x2,y2,a1,a2,dur)
{
    return {sx:x1, sy:y1, ex:x2, ey:y2,sa:a1, ea:a2,t:A_TickCount, d:dur, active:true}
}

AnimLerp(anim)
{
    now := A_TickCount - anim.t
    if (now >= anim.d)
    {
        anim.active := false
        return {x:anim.ex, y:anim.ey, a:anim.ea}
    }
    p := now / anim.d
    return {x:anim.sx + (anim.ex-anim.sx)*p,y:anim.sy + (anim.ey-anim.sy)*p,a:anim.sa + (anim.ea-anim.sa)*p}
}

; ==========================================================
;  HUD rendern
; ==========================================================
RenderHUD()
{
    global pGraphics, hbm, hOverlay
    global WALeft, WATop, WARight, WABottom

    ; komplett transparent löschen
    Gdip_GraphicsClear(pGraphics, 0x00000000)

    ; === DEMO TEXT ===
    pPath := Gdip_CreatePath()
    Gdip_AddPathStringSimplified(pPath, "Calculator HUD Demo", "Segoe UI", 32, 0, 40, 40, 600, 80, 0)

    ; Outline
    pPen := Gdip_CreatePen(0xFF303030, 4)
    Gdip_DrawPath(pGraphics, pPen, pPath)

    ; Fill
    pBrush := Gdip_BrushCreateSolid(0xFFFFFF00)
    Gdip_FillPath(pGraphics, pBrush, pPath)

    ; Cleanup
    Gdip_DeletePen(pPen)
    Gdip_DeleteBrush(pBrush)
    Gdip_DeletePath(pPath)

    ; === PRESENT ===
    UpdateLayeredWindow(hOverlay, hbm, WALeft, WATop, WARight - WALeft, WABottom - WATop)
}

; ==========================================================
;  WIDGET BASISKLASSE
; ==========================================================
class HUD_Widget
{
    __New(zone, w, h)
    {
        this.zone := zone
        this.w := w
        this.h := h
        this.x := 0
        this.y := 0
        this.bmp := 0
        this.dirty := true
        this.visible := true
        this.anim := ""
    }

    ResolveSlot()
    {
        s := HUD_NextSlot(this.zone, this.w, this.h)
        this.x := s.x
        this.y := s.y
    }

    Invalidate()
    {
        this.dirty := true
        global HUD_Dirty
        HUD_Dirty := true
    }

    BuildBitmap()
    {
        if (!this.dirty)
            return

        if (this.bmp)
            Gdip_DisposeImage(this.bmp)

        this.bmp := CreateWidgetBitmap(this.w, this.h, ObjBindMethod(this,"OnDraw"))
        this.dirty := false
    }

    AnimateIn(dx:=0, dy:=-20, dur:=220)
    {
        this.anim := CreateAnimation(this.x+dx, this.y+dy,this.x, this.y,0, 255,dur)
    }

    Draw(g)
    {
        if (!this.visible)
            return

        this.BuildBitmap()

        if IsObject(this.anim) && this.anim.active
            s := AnimLerp(this.anim)
        else
            s := {x:this.x, y:this.y, a:255}

        Gdip_DrawImageRectAlpha(g, this.bmp, s.x, s.y, this.w, this.h, s.a)
    }
}

; ==========================================================
;  TEXT WIDGET (OUTLINE via Path)
; ==========================================================
class HUD_Widget_Text extends HUD_Widget
{
    __New(zone, text, w:=300, h:=32)
    {
        base.__New(zone, w, h)
        this.text := text
    }

    OnDraw(g,w,h)
    {
        pPath := Gdip_CreatePath()
        Gdip_AddPathStringSimplified(pPath,this.text,"Segoe UI",20,1,0,0,w,h,1,1)

        pen := Gdip_CreatePen(0xFF303030, 3)
        Gdip_DrawPath(g, pen, pPath)
        Gdip_DeletePen(pen)

        brush := Gdip_BrushCreateSolid(0xFFFFFF00)
        Gdip_FillPath(g, brush, pPath)
        Gdip_DeleteBrush(brush)

        Gdip_DeletePath(pPath)
    }
}

; ==========================================================
;  BITMAP HELPER
; ==========================================================
CreateWidgetBitmap(w,h,fn)
{
    bmp := Gdip_CreateBitmap(w,h)
    g := Gdip_GraphicsFromImage(bmp)
    Gdip_SetSmoothingMode(g,4)
    Gdip_GraphicsClear(g,0x00000000)
    fn.Call(g,w,h)
    Gdip_DeleteGraphics(g)
    return bmp
}

; ==========================================================
;  WIDGET MANAGER
; ==========================================================
global HUD_Widgets := []

HUD_AddWidget(w)
{
    global HUD_Widgets
    HUD_Widgets.Push(w)
}

; ==========================================================
;  DEMO SETUP
; ==========================================================
HUD_InitGrid()

txt1 := new HUD_Widget_Text("TopBar","PoE HUD Framework")
txt1.AnimateIn(0,-20,250)
HUD_AddWidget(txt1)

txt2 := new HUD_Widget_Text("LeftHUD","Buff: Onslaught")
txt2.AnimateIn(-20,0,250)
HUD_AddWidget(txt2)

SetTimer, RenderHUD, 16
SetTimer, __HUD_Tick, 16
return

; ==========================================================
;  RENDER LOOP
; ==========================================================
RenderHUD:
    RunderHudLoop++
    force := false
    for i, w in HUD_Widgets
        if IsObject(w.anim) && w.anim.active
            force := true

    if (!HUD_Dirty && !force)
        goto Present

    HUD_Dirty := false
    HUD_ResetZones()
    Gdip_GraphicsClear(pGraphics,0x00000000)

    for i,w in HUD_Widgets
    {
        w.ResolveSlot()
        w.Draw(pGraphics)
    }

Present:
    Gdip_DrawImageRect(pGraphics,hbm,0,0,A_ScreenW,A_ScreenH)

__HUD_Tick:
    RenderHUD()
return

Esc::
ExitApp
