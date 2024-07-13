using System;
using System.IO;

namespace L2RPacketReader.Parser.Pkt
{
    class pktPartyEmblem
    {
        public static void Packet(PacketReader packet)
        {

            // 1.04.16

            string PartyName = packet.ReadString();
            byte Bool = packet.ReadByte();
 
        }
    }
}