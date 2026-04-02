namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdMap
    {
        public IntPtr Head;
        public int Size; 
        public int PAD_C;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdMapNode<TKey, TValue>
        where TKey : struct
        where TValue : struct
    {
        public IntPtr Left; 
        public IntPtr Parent; 
        public IntPtr Right; 
        public byte Color; 
        public bool IsNil; 
        public byte pad_1A;
        public byte pad_1B;
        public uint pad_1C;
        public StdMapNodeData<TKey, TValue> Data; 
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdMapNodeData<TKey, TValue>
        where TKey : struct
        where TValue : struct
    {
        public TKey Key;
        public TValue Value;
    }
}