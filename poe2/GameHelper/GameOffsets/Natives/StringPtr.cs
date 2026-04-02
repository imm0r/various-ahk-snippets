namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct StringPtr
    {
        [FieldOffset(0x0)]
        public long Ptr;
    }
}

