namespace GameOffsets.Objects.States.InGameState
{
    using System;
    using System.Runtime.InteropServices;
    using Natives;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct PreInventoryStruct
    {
        [FieldOffset(0x10)] public IntPtr ptr;
    }

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct InventoryStruct
    {
        
        
        [FieldOffset(0x14C)] public StdTuple2D<int> TotalBoxes; 

        
        [FieldOffset(0x170)] public StdVector ItemList;

        
        [FieldOffset(0x1E8)] public int ServerRequestCounter;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct ItemHashKey
    {
        public int ServerRequestCounterSnapShot;
        public int PAD_8;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct ItemHashValue
    {
        public IntPtr InventoryItemStructPtr;
        public IntPtr UselessItemPtr;
    }

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct InventoryItemStruct
    {
        [FieldOffset(0x00)] public IntPtr Item; 
        [FieldOffset(0x08)] public StdTuple2D<int> SlotStart;
        [FieldOffset(0x10)] public StdTuple2D<int> SlotEnd;
        [FieldOffset(0x18)] public int ServerRequestCounterSnapShot;
    }
}