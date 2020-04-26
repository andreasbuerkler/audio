﻿using System;
using System.Threading;
using System.Collections.Generic;

namespace Lcd
{
    class LcdMain {

        static void memTest(Eth ethInst, bool useRandomData) {
            Console.Write("\n");
            const UInt32 memorySize = 8388608; // 8 MByte
            const Byte burstSize = 128; // number of bytes per eth packet
            UInt32[] testData = new uint[8388608 / 4];

            // create random test data
            if (useRandomData) {
                var rand = new Random();
                for (int wordIndex = 0; wordIndex < memorySize / 4; wordIndex++) {
                    testData[wordIndex] = (UInt32)rand.Next(-2147483648, 2147483647);
                }
            }

            // write complete memory
            for (UInt32 addressOffset = 0; addressOffset < memorySize; addressOffset += burstSize) {
                UInt32 errorCode = 0;
                UInt32 address = 0x00800000 + addressOffset;
                List<UInt32> writeData = new List<UInt32>();
                for (UInt32 index = 0; index < burstSize; index += 4) {
                    if (useRandomData) {
                        writeData.Add(testData[(addressOffset+index)/4]);
                    } else {
                        writeData.Add(addressOffset + index);
                    }
                }
                ethInst.Write(address, writeData, out errorCode, burstSize);
                if (errorCode != Eth._ERROR_SUCCESS) {
                    Console.WriteLine("ErrorCode = " + errorCode);
                }
                // prevent from FIFO overflow
                if (addressOffset % 4096 == 0) {
                    Thread.Sleep(1);
                }
                Console.Write("\r -> write to address 0x" + addressOffset.ToString("X"));
            }
            Console.Write("\n");

            // read complete memory
            for (UInt32 addressOffset = 0; addressOffset < memorySize; addressOffset += burstSize) {
                UInt32 errorCode = 0;
                List<UInt32> dataArray;
                UInt32 address = 0x00800000 + addressOffset;

                ethInst.Read(address, out dataArray, out errorCode, burstSize);

                if (errorCode != Eth._ERROR_SUCCESS) {
                    Console.WriteLine("ErrorCode = " + errorCode);
                }
                if (dataArray.Count != burstSize / 4) {
                    Console.WriteLine("Received number of words wrong = " + dataArray.Count);
                    break;
                }
                for (UInt32 wordIndex = 0; wordIndex < burstSize / 4; wordIndex++) {
                    UInt32 expectedData;
                    if (useRandomData) {
                        expectedData = testData[addressOffset/4+wordIndex];
                    } else {
                        expectedData = addressOffset + (wordIndex * 4);
                    }
                    if (dataArray[(int)wordIndex] != expectedData) {
                        UInt32 diff = dataArray[(int)wordIndex] ^ expectedData;
                        Console.WriteLine("Read data wrong at address 0x" + expectedData.ToString("X") + " diff 0x" + diff.ToString("X"));
                    }
                }
                Console.Write("\r -> read from address 0x" + addressOffset.ToString("X"));
            }
        }

        static void i2cTest(I2c i2cInst, Monitor monitorInst) {
            // read INA3221 Manufacturer ID
            Byte device = 0x40;
            Byte address = 0xfe;
            UInt16 data;
            i2cInst.Read16(device, address, out data);
            Console.WriteLine("I2C read Manufacturer ID = " + data.ToString("X"));

            // read INA3221 Die ID
            address = 0xff;
            i2cInst.Read16(device, address, out data);
            Console.WriteLine("I2C read Die ID = " + data.ToString("X"));

            // read status
            Monitor.MonitorStatus status;
            monitorInst.GetStatus(out status);
            Console.WriteLine(String.Format("CH0: {0,6:0.00}V, {1,6:0.00}mA", status.ch0.voltage, status.ch0.current));
            Console.WriteLine(String.Format("CH1: {0,6:0.00}V, {1,6:0.00}mA", status.ch1.voltage, status.ch1.current));
            Console.WriteLine(String.Format("CH2: {0,6:0.00}V, {1,6:0.00}mA", status.ch2.voltage, status.ch2.current));
        }
        static void Main(string[] args) {
            Console.WriteLine("---------- I2C read test ----------");
        //    Acc test = new Acc();
        //    test.PrintPhysics();
        //    return;

            Eth ethInst = new Eth(_ipAddress, _udpPort);
            I2c i2cInst = new I2c(ethInst);
            Monitor monitorInst = new Monitor(i2cInst);

            if (!(((args.Length == 3) && (Equals(args[0], "W"))) ||
                  ((args.Length == 2) && Equals(args[0], "R")) ||
                  ((args.Length == 1) && Equals(args[0], "I")) ||
                  ((args.Length == 1) && Equals(args[0], "T")))) {
                Console.WriteLine("Usage: Lcd [R/W] [Address] ([Data])");
            }
            else
            {
                if (Equals(args[0], "W"))
                {
                    // write word
                    UInt32 errorCode = 0;
                    ethInst.Write32(Convert.ToUInt32(args[1], 16), Convert.ToUInt32(args[2], 16), out errorCode);
                    Console.WriteLine("ErrorCode = " + errorCode);
                }
                else if (Equals(args[0], "R"))
                {
                    // read word
                    UInt32 readData = 0;
                    UInt32 errorCode = 0;
                    ethInst.Read32(Convert.ToUInt32(args[1], 16), out readData, out errorCode);
                    Console.WriteLine("ReadData = " + readData.ToString("X") + " , ErrorCode = " + errorCode);
                }
                else if (Equals(args[0], "I"))
                {
                    // I2C test
                    i2cTest(i2cInst, monitorInst);
                } else if (Equals(args[0], "T")) {
                    // memory test
                    memTest(ethInst, true);
                }
                else {
                    Console.WriteLine("Unknown argument (R,W,I,T)");
                }
            }
        }

        private const string _ipAddress = "192.168.0.100";
        private const UInt16 _udpPort = 4660;
    }
}
