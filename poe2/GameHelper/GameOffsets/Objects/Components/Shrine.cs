namespace GameOffsets.Objects.Components
{
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct ShrineOffsets
    {
        [FieldOffset(0x0000)] public ComponentHeader Header;

        
        [FieldOffset(0x0024)] public bool IsUsed;
        
    }

    
}