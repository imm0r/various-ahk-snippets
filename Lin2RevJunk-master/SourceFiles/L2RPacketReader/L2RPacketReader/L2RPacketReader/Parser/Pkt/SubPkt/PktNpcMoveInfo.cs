using System;
using System.IO;

namespace L2RPacketReader.Parser.Pkt
{
    class PktNpcMoveInfo
    {

        // 1.04.16

        public static void Packet(PacketReader packet)
        {
            //PktVector
            float DestinationXPos = packet.ReadSingle();
            float DestinationYPos = packet.ReadSingle();
        }
    }
}