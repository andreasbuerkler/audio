﻿using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    public class I2c
    {
        public I2c(string ipAddress, UInt16 udpPort) {
            _ethInst = new Eth(ipAddress, udpPort);
            _iPAddress = ipAddress;
            _udpPort = udpPort;
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
            UInt32 memoryAddress = ADDRESS_OFFSET | (UInt32)((size << 8) & 0xFF00) | (UInt32)(device & 0x7F);
            UInt32 memoryData = (UInt32)((int)address << 24) | (UInt32)((int)data << 8);
            bool status;
            status = _ethInst.Write32(memoryAddress, memoryData, out errorCode);
            if (!status)
            {
                Console.WriteLine("Write address failed: ErrorCode = " + errorCode);
                return false;
            }

            // read error bit
            memoryAddress = ADDRESS_OFFSET | 0x80;
            UInt32 errorBit;
            status = _ethInst.Read32(memoryAddress, out errorBit, out errorCode);
            if (!status)
            {
                Console.WriteLine("Read error failed: ErrorCode = " + errorCode);
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
            UInt32 memoryAddress = ADDRESS_OFFSET | (UInt32)((size<<8) & 0xFF00) | (UInt32)(device & 0x7F);
            UInt32 memoryData = (UInt32)((int)address << 24);
            bool status;
            status = _ethInst.Write32(memoryAddress, memoryData, out errorCode);
            if (!status) {
                Console.WriteLine("Write address failed: ErrorCode = " + errorCode);
                data = 0x00;
                return false;
            }

            size = 1; // Read 2 byte
            memoryAddress = ADDRESS_OFFSET | (UInt32)((size << 8) & 0xFF00) | (UInt32)(device & 0x7F);
            status = _ethInst.Read32(memoryAddress, out memoryData, out errorCode);
            if (!status) {
                Console.WriteLine("Read data failed: ErrorCode = " + errorCode);
                data = 0x00;
                return false;
            }

            // read error bit
            memoryAddress = ADDRESS_OFFSET | 0x80;
            UInt32 errorBit;
            status = _ethInst.Read32(memoryAddress, out errorBit, out errorCode);
            if (!status) {
                Console.WriteLine("Read error failed: ErrorCode = " + errorCode);
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

        private string _iPAddress;
        private UInt16 _udpPort;
        private Eth _ethInst;
        private const UInt32 ADDRESS_OFFSET = 0x00001000;
    }
}