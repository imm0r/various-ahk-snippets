namespace GameOffsets.Objects.Components
{
    using System;
    using System.Runtime.InteropServices;
    using GameOffsets.Natives;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct StateMachineComponentOffsets
    {
        [FieldOffset(0x000)]
        public ComponentHeader Header;

        
        [FieldOffset(0x158)]
        public IntPtr StatesPtr;

        
        [FieldOffset(0x160)]
        public StdVector StatesValues;
    }

    
}