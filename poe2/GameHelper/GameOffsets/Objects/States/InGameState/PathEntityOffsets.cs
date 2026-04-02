namespace GameOffsets.Objects.States.InGameState
{
    using System;
    using System.Runtime.InteropServices;
    using GameOffsets.Natives;

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct PathEntityOffsets
    {
        [FieldOffset(0x08)] public StringPtr Path;  
        [FieldOffset(0x20)] public long Length;
    }
}
