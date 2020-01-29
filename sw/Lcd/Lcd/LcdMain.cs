using System;

namespace Lcd
{
    class LcdMain {
        static void Main(string[] args) {
            Console.WriteLine("----------  ----------");
          //  Eth ethInst = new Eth(_iPAddress, _udpPort);
            I2c i2cInst = new I2c(_iPAddress, _udpPort);
            Console.WriteLine("I2C read test");

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

            // read register 8
            address = 0x08;
            i2cInst.Read16(device, address, out data);
            Console.WriteLine("I2C read register 8 = " + data.ToString("X"));

            // toggle bit 5 in register 8
            data = (UInt16)(((int)data & 0xFFEF) | (((int)data & 0x0010) ^ 0x0010));
            i2cInst.Write16(device, address, data);

            // read again register 8
            address = 0x08;
            i2cInst.Read16(device, address, out data);
            Console.WriteLine("I2C read register 8 = " + data.ToString("X"));

            return; // TODO: remove

            if (!(((args.Length == 3) && (Equals(args[0], "W"))) || ((args.Length == 2) && Equals(args[0], "R")))) {
                Console.WriteLine("Usage: Lcd [R/W] [Address] ([Data])");
            } else {
                if (Equals(args[0], "W")) {
                    UInt32 errorCode = 0;
        //            ethInst.Write32(UInt32.Parse(args[1]), UInt32.Parse(args[2]), out errorCode);
                    Console.WriteLine("ErrorCode = " + errorCode);
                } else {
                    UInt32 readData = 0;
                    UInt32 errorCode = 0;
         //           ethInst.Read32(UInt32.Parse(args[1]), out readData, out errorCode);
                    Console.WriteLine("ReadData = " + readData.ToString("X") + " , ErrorCode = " + errorCode);
                }
            }
        }

        private const string _iPAddress = "192.168.0.100";
        private const UInt16 _udpPort = 4660;
    }
}
