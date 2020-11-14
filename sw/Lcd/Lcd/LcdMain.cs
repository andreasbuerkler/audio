using System;

namespace Lcd
{
    class LcdMain {

        static void Main(string[] args) {
            Console.WriteLine("---------- Test ----------");

            Eth ethInst = new Eth(_ipAddress, _udpPort);
            I2c i2cInst = new I2c(ethInst);
            Monitor monitorInst = new Monitor(i2cInst);

            // args = new string[] {"Q"};

            if (!(((args.Length == 3) && (Equals(args[0], "W"))) ||
                  ((args.Length == 2) && Equals(args[0], "R")) ||
                  ((args.Length == 1) && Equals(args[0], "I")) ||
                  ((args.Length == 1) && Equals(args[0], "T")) ||
                  ((args.Length == 1) && Equals(args[0], "Q")) ||
                  (args.Length == 0))) {
                Console.WriteLine("Usage: Lcd [R/W] [Address] ([Data]) <memory r/w>");
                Console.WriteLine("       Lcd [I]                      <I2C test>");
                Console.WriteLine("       Lcd [T]                      <memory test>");
                Console.WriteLine("       Lcd [Q]                      <video>");
            }
            else
            {
                if (args.Length == 0)
                {
                    // enable video output
                    UInt32 errorCode = 0;
                    ethInst.Write32(0x04, 0x07, out errorCode);
                    if (errorCode != Eth._errorSuccess)
                    {
                        Console.WriteLine("ErrorCode = " + errorCode);
                        return;
                    }
                    else
                    {
                        VideoHandler handle = new VideoHandler(ethInst, monitorInst);
                        while (true);
                    }
                }
                if (Equals(args[0], "Q"))
                {
                    // video output
                    VideoHandler handle = new VideoHandler(ethInst, monitorInst);
                    while (true);
                }
                else if (Equals(args[0], "W"))
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
                    HwTest.i2cTest(i2cInst, monitorInst);
                }
                else if (Equals(args[0], "T"))
                {
                    // memory test
                    HwTest.memTest(ethInst, true);
                }
                else
                {
                    Console.WriteLine("Unknown argument (R,W,I,T,Q)");
                }
            }
        }

        private const string _ipAddress = "192.168.0.100";
        private const UInt16 _udpPort = 4660;
    }
}
