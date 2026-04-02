namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdBucket
    {
        public StdVector Data; 
        public long UnknownPtr; 
        public int Capacity; 
        public int PAD_0x24; 
        public int Unknown1;
        public int PAD_0x2C;
        public int Unknown2;
        public int Unknown3;
    }
}