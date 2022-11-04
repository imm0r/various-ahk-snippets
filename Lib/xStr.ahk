; xStr v0.97 by SKAN on D1AL/D343 @ tiny.cc/xstr
xStr(ByRef H, C:=0, B:="", E:="",ByRef BO:=1, EO:="", BI:=1, EI:=1, BT:="", ET:="") {                           
    Local L, LB, LE, P1, P2, Q, N:="", F:=0
    Return SubStr(H,!(ErrorLevel:=!((P1:=(L:=StrLen(H))?(LB:=StrLen(B))?(F:=InStr(H,B,C&1,BO,BI))?F+(BT=N?LB
    :BT):0:(Q:=(BO=1&&BT>0?BT+1:BO>0?BO:L+BO))>1?Q:1:0)&&(P2:=P1?(LE:=StrLen(E))?(F:=InStr(H,E,C>>1,EO=N?(F
    ?F+LB:P1):EO,EI))?F+LE-(ET=N?LE:ET):0:EO=N?(ET>0?L-ET+1:L+1):P1+EO:0)>=P1))?P1:L+1,(BO:=Min(P2,L+1))-P1)  
}