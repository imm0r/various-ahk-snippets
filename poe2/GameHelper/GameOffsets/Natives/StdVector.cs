namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdVector
    {
        public long First;
        public long Last;
        public long End;

        
        public long TotalElements(int elementSize)
        {
            return (this.Last - this.First) / elementSize;
        }

        public override string ToString()
        {
            return $"First: {this.First:X} - " +
                   $"Last: {this.Last:X} - " +
                   $"Size (bytes): {this.TotalElements(1)}";
        }
    }
}