namespace GameOffsets.Objects.States.InGameState
{
    using System;
    using System.Runtime.InteropServices;
    using Natives;

    
    [Flags]
    public enum EntityFlags : byte
    {
        Valid = 1
    }

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct ObjectHeaderOffsets
    {
        [FieldOffset(0x00)] public long MainObject;
        [FieldOffset(0x08)] public long Name;
        [FieldOffset(0x28)] public long ComponentLookUpPtr;
    }

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct ItemStruct
    {
        [FieldOffset(0x00)] public long VTablePtr;
        [FieldOffset(0x08)] public long EntityDetailsPtr;
        [FieldOffset(0x10)] public StdVector ComponentListPtr;
    }

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct EntityOffsets
    {
        [FieldOffset(0x08)] public ObjectHeaderOffsets Head;  
        [FieldOffset(0x08)] public long EntityDetailsPtr;    
        [FieldOffset(0x10)] public StdVector ComponentList;  
        
        [FieldOffset(0x80)] public uint Id;                   
        [FieldOffset(0x84)] public EntityFlags Flags;        
    }

    public static class EntityHelper
    {
        
        
        public static Func<byte, bool> IsValidEntity = param => { return !Util.isBitSetByte(param, 0); };

        public static Func<byte, bool> IsFriendly = param => { return (param & 0x7F) == 0x01; };
    }

    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct EntityDetails
    {
        [FieldOffset(0x08)] public StdWString name;
        [FieldOffset(0x28)] public long ComponentLookUpPtr;
    }

    
    [StructLayout(LayoutKind.Explicit, Pack = 1)]
    public struct ComponentLookUpStruct
    {
        [FieldOffset(0x00)] public long Unknown0;
        [FieldOffset(0x08)] public long Unknown1;
        [FieldOffset(0x10)] public StdVector Unknown2;
        [FieldOffset(0x28)] public StdBucket ComponentsNameAndIndex;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct ComponentNameAndIndexStruct
    {
        public long NamePtr;
        public int Index;
        public int PAD_0xC;
    }
}
