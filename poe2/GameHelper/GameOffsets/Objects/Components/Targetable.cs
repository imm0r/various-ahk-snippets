namespace GameOffsets.Objects.Components
{
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct TargetableOffsets
    {
        
        
        [FieldOffset(0x00)] public ComponentHeader Header;
        [FieldOffset(0x51)] public bool IsTargetable; 
        [FieldOffset(0x52)] public bool IsHighlightable; 
        [FieldOffset(0x53)] public bool IsTargettedByPlayer;
        [FieldOffset(0x56)] public bool MeetsQuestState; 
        [FieldOffset(0x58)] public bool NeedsTrue; 
        [FieldOffset(0x59)] public bool HiddenfromPlayer; 
        [FieldOffset(0x5A)] public bool NeedsFalse; 
    }
}
