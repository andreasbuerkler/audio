using System;
using System.Collections.Generic;
using System.Threading;

namespace Lcd
{
    static class HwTest
    {
        public static void memTest(Eth ethInst, bool useRandomData)
        {
            Console.Write("\n");
            const UInt32 memorySize = 8388608; // 8 MByte
            const UInt16 bytesPerPacket = 1024; // number of bytes per eth packet
            UInt32[] testData = new uint[8388608 / 4];

            // create random test data
            if (useRandomData)
            {
                var rand = new Random();
                for (int wordIndex = 0; wordIndex < memorySize / 4; wordIndex++)
                {
                    testData[wordIndex] = (UInt32)rand.Next(-2147483648, 2147483647);
                }
            }

            // write complete memory
            for (UInt32 addressOffset = 0; addressOffset < memorySize; addressOffset += bytesPerPacket)
            {
                UInt32 errorCode = 0;
                UInt32 address = 0x00800000 + addressOffset;
                List<UInt32> writeData = new List<UInt32>();
                for (UInt32 index = 0; index < bytesPerPacket; index += 4)
                {
                    if (useRandomData)
                    {
                        writeData.Add(testData[(addressOffset + index) / 4]);
                    }
                    else
                    {
                        writeData.Add(addressOffset + index);
                    }
                }
                ethInst.Write(address, writeData, out errorCode, bytesPerPacket);
                if (errorCode != Eth._errorSuccess)
                {
                    Console.WriteLine("\nErrorCode = " + errorCode);
                }
                // prevent from FIFO overflow
                if (addressOffset % 4096 == 0)
                {
                    Thread.Sleep(1);
                }
                Console.Write("\r -> write to address  0x" + addressOffset.ToString("X"));
            }
            Console.Write("\n");

            // read complete memory
            for (UInt32 addressOffset = 0; addressOffset < memorySize; addressOffset += bytesPerPacket)
            {
                UInt32 errorCode = 0;
                List<UInt32> dataArray;
                UInt32 address = 0x00800000 + addressOffset;

                ethInst.Read(address, out dataArray, out errorCode, bytesPerPacket);

                if (errorCode != Eth._errorSuccess)
                {
                    Console.WriteLine("\nErrorCode = " + errorCode + " at address " + addressOffset.ToString("X"));
                    break;
                }
                if (dataArray.Count != bytesPerPacket / 4)
                {
                    Console.WriteLine("\nReceived number of words wrong = " + dataArray.Count);
                    break;
                }
                for (UInt32 wordIndex = 0; wordIndex < bytesPerPacket / 4; wordIndex++)
                {
                    UInt32 expectedData;
                    if (useRandomData)
                    {
                        expectedData = testData[addressOffset / 4 + wordIndex];
                    }
                    else
                    {
                        expectedData = addressOffset + (wordIndex * 4);
                    }
                    if (dataArray[(int)wordIndex] != expectedData)
                    {
                        UInt32 diff = dataArray[(int)wordIndex] ^ expectedData;
                        Console.WriteLine("\nRead data wrong at address 0x" + addressOffset.ToString("X") + " diff 0x" + diff.ToString("X"));
                        break;
                    }
                }
                Console.Write("\r -> read from address 0x" + addressOffset.ToString("X"));
            }
        }
        public static void i2cTest(I2c i2cInst, Monitor monitorInst)
        {
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
    }
}
