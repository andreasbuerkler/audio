using System;

namespace Lcd
{
    public class I2c
    {
        public I2c(Eth ethInst) {
            _ethInst = ethInst;
        }

        public bool Write16(Byte device, Byte address, UInt16 data) {
            if (device > 127)
            {
                Console.WriteLine("Device address invalid");
                data = 0x00;
                return false;
            }

            UInt32 errorCode;
            UInt32 size = 2; // Write address + 16 bytes (3 byte)
            UInt32 memoryAddress = _addressOffset | (UInt32)((size << 8) & 0xFF00) | (UInt32)(device & 0x7F);
            UInt32 memoryData = (UInt32)((int)address << 24) | (UInt32)((int)data << 8);
            bool status;
            status = _ethInst.Write32(memoryAddress, memoryData, out errorCode);
            if (!status)
            {
                Console.WriteLine("Write address failed: ErrorCode = " + errorCode + " " + GetErrorString(errorCode));
                return false;
            }

            // read error bit
            memoryAddress = _addressOffset | 0x80;
            UInt32 errorBit;
            status = _ethInst.Read32(memoryAddress, out errorBit, out errorCode);
            if (!status)
            {
                Console.WriteLine("Read error failed: ErrorCode = " + errorCode + " " + GetErrorString(errorCode));
                return false;
            }
            if (errorBit != 0x00000000)
            {
                Console.WriteLine("Error bit set");
                return false;
            }

            return true;
        }

        public bool Read16(Byte device, Byte address, out UInt16 data) {
            if (device > 127) {
                Console.WriteLine("Device address invalid");
                data = 0x00;
                return false;
            }

            UInt32 errorCode;
            UInt32 size = 0; // Write address (1 byte)
            UInt32 memoryAddress = _addressOffset | (UInt32)((size<<8) & 0xFF00) | (UInt32)(device & 0x7F);
            UInt32 memoryData = (UInt32)((int)address << 24);
            bool status;
            status = _ethInst.Write32(memoryAddress, memoryData, out errorCode);
            if (!status) {
                Console.WriteLine("Write address failed: ErrorCode = " + errorCode + " " + GetErrorString(errorCode));
                data = 0x00;
                return false;
            }

            size = 1; // Read 2 byte
            memoryAddress = _addressOffset | (UInt32)((size << 8) & 0xFF00) | (UInt32)(device & 0x7F);
            status = _ethInst.Read32(memoryAddress, out memoryData, out errorCode);
            if (!status) {
                Console.WriteLine("Read data failed: ErrorCode = " + errorCode + " " + GetErrorString(errorCode));
                data = 0x00;
                return false;
            }

            // read error bit
            memoryAddress = _addressOffset | 0x80;
            UInt32 errorBit;
            status = _ethInst.Read32(memoryAddress, out errorBit, out errorCode);
            if (!status) {
                Console.WriteLine("Read error failed: ErrorCode = " + errorCode + " " + GetErrorString(errorCode));
                data = 0x00;
                return false;
            }
            if (errorBit != 0x00000000) {
                Console.WriteLine("Error bit set");
                data = 0x00;
                return false;
            }

            data = (UInt16)(memoryData & 0xFFFF);
            return true;
        }

        private string GetErrorString(UInt32 Error) {
            switch (Error) {
                case Eth._errorSuccess:        return "success";
                case Eth._errorUdpTimeout:     return "udp timeout";
                case Eth._errorType:           return "type";
                case Eth._errorReceivedLength: return "received length";
                case Eth._errorPacketLength:   return "packet length";
                case Eth._errorSend:           return "send";
                case Eth._errorException:      return "exception";
                case Eth._errorPacketId:       return "wrong packet id";
                case Eth._errorReadTimeout:    return "read timeout";
                default:                       return "unknown";
            }
        }

        private Eth _ethInst;
        private const UInt32 _addressOffset = 0x00400000;
    }
}
