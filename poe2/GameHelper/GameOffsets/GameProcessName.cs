namespace GameOffsets
{
    using System.Collections.Generic;

    public struct GameProcessDetails
    {
        
        
        public static readonly Dictionary<string, string> ProcessName = new()
        {
            { "PathOfExile", "Path of Exile 2".ToLower() }, 
            { "PathOfExile_KG", "Path of Exile 2".ToLower() },
            { "PathOfExileSteam", "Path of Exile 2".ToLower() },
            { "PathOfExile_x64", "Path of Exile 2".ToLower() },
            { "PathOfExileEGS", "Path of Exile 2".ToLower() }
        };
    }
}
