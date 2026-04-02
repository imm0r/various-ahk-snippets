namespace GameOffsets.Objects.Components
{
    using System;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct LifeOffset
    {
        [FieldOffset(0x000)] public ComponentHeader Header;
        [FieldOffset(0x230)] public VitalStruct Health;
        [FieldOffset(0x1F8)] public VitalStruct Mana;
        [FieldOffset(0x1A8)] public VitalStruct EnergyShield;
    }

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct VitalStruct
    {
        [FieldOffset(0x10)] public int ReservedFlat;
        [FieldOffset(0x14)] public int ReservedFraction;
        [FieldOffset(0x1C)] public int RegenPerMinuteStat;
        [FieldOffset(0x1C)] public int NoRegenStat;  
        [FieldOffset(0x28)] public float Regen;  
        [FieldOffset(0x2C)] public int Max;
        [FieldOffset(0x30)] public int Current;

        
        public int ReservedTotal => (int)Math.Ceiling(this.ReservedFraction / 10000f * this.Max) + this.ReservedFlat;

        
        public int Unreserved => this.Max - this.ReservedTotal;

        
        public int CurrentInPercent()
        {
            if (this.Max == 0)
            {
                return 0;
            }

            return (int)Math.Round(100d * this.Current / this.Unreserved);
        }

        
        public int ReservedInPercent()
        {
            if (this.Max == 0)
            {
                return 0;
            }

            return (int)Math.Round(100d * this.ReservedTotal / this.Max);
        }
    }
}