namespace GameOffsets.Natives
{
    using System;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct StdString
    {
        public IntPtr Buffer;
        public IntPtr ReservedBytes;
        public int Length;
        public int PAD_14;
        public int Capacity;
        public int PAD_1C;

        public override string ToString()
        {
            return $"Buffer: {this.Buffer.ToInt64():X}, ReservedBytes: {this.ReservedBytes.ToInt64():X}, " +
                   $"Length: {this.Length}, Capacity: {this.Capacity}";
        }
    }
}
