using System;

namespace Lcd
{
    class LcdMain {
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
                    UInt32 errorCode = 0;
                    ethInst.Write32(Convert.ToUInt32(args[1], 16), Convert.ToUInt32(args[2], 16), out errorCode);
                    Console.WriteLine("ErrorCode = " + errorCode);
                }
                else if (Equals(args[0], "R"))
                {
                    UInt32 readData = 0;
                    UInt32 errorCode = 0;
                    ethInst.Read32(Convert.ToUInt32(args[1], 16), out readData, out errorCode);
                    Console.WriteLine("ReadData = " + readData.ToString("X") + " , ErrorCode = " + errorCode);
                }
                else if (Equals(args[0], "I"))
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
                } else if (Equals(args[0], "T")) {
                    // write complete memory
                    for (UInt32 i =0; i<1000; i+=4) {
                        UInt32 errorCode = 0;
                        UInt32 address = 0x00800000 + i;
                        ethInst.Write32(address, i, out errorCode);
                        if (errorCode != Eth._ERROR_SUCCESS) {
                            Console.WriteLine("ErrorCode = " + errorCode);
                        }
                    }
                    // read complete memory
                    for (UInt32 i = 0; i < 1000; i += 4) {
                        UInt32 errorCode = 0;
                        UInt32 readData = 0;
                        UInt32 address = 0x00800000 + i;
                        ethInst.Read32(address, out readData, out errorCode);
                        if (errorCode != Eth._ERROR_SUCCESS) {
                            Console.WriteLine("ErrorCode = " + errorCode);
                        }
                        if (readData != i) {
                            Console.WriteLine("Read data wrong at address 0x" + i.ToString("X"));
                        }
                    }
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
