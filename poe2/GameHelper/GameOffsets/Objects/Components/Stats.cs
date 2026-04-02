namespace GameOffsets.Objects.Components
{
    using System;
    using System.Runtime.InteropServices;
    using GameOffsets.Natives;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct StatsOffsets 
    {
        [FieldOffset(0x000)] public ComponentHeader Header;
        [FieldOffset(0x160)] public IntPtr StatsChangedByItemsPtr; 
        [FieldOffset(0x168)] public int CurrentWeaponIndex; 
        [FieldOffset(0x170)] public IntPtr ShapeshiftFormsRowPtr; 
        [FieldOffset(0x1C8)] public IntPtr StatsChangedByBuffAndActions; 
    }

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct StatsStructInternal
    {
        [FieldOffset(0xF8)] public StdVector Stats; 
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StatArrayStruct
    {
        public int key;
        public int value;
    }
}
