namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdList
    {
        public IntPtr Head;
        public int Size; 
        public int PAD_C;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdListNode<TValue>
        where TValue : struct
    {
        public IntPtr Next;
        public IntPtr Previous;
        public TValue Data;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdListNode
    {
        public IntPtr Next;
        public IntPtr Previous;
    }
}