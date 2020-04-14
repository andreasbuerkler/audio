using System;
using System.Threading;
using System.IO;
using System.IO.MemoryMappedFiles;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    public class Acc {
        public Acc() {
            _physicsFile = MemoryMappedFile.OpenExisting("Local\\acpmf_physics", MemoryMappedFileRights.Read, HandleInheritability.None);
            _graphicsFile = MemoryMappedFile.OpenExisting("Local\\acpmf_graphics", MemoryMappedFileRights.Read, HandleInheritability.None);
            _physicsStream = _physicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
            _graphicsStream = _graphicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
        }

        public void PrintPhysics () {
            while (true) {
                PhysikInfo info = GetPhysics();

                Console.WriteLine("fuel: " + info.fuel);
                Console.WriteLine("gear: " + info.gear);
                Console.WriteLine("rpm: " + info.rpm);
                Console.WriteLine("speedKmh: " + info.speedKmh);

                Console.WriteLine("wheelPressure[0]: " + info.wheelPressure[0]);
                Console.WriteLine("wheelPressure[1]: " + info.wheelPressure[1]);
                Console.WriteLine("wheelPressure[2]: " + info.wheelPressure[2]);
                Console.WriteLine("wheelPressure[3]: " + info.wheelPressure[3]);

                Console.WriteLine("tyreCoreTemp[0]: " + info.tyreCoreTemp[0]);
                Console.WriteLine("tyreCoreTemp[1]: " + info.tyreCoreTemp[1]);
                Console.WriteLine("tyreCoreTemp[2]: " + info.tyreCoreTemp[2]);
                Console.WriteLine("tyreCoreTemp[3]: " + info.tyreCoreTemp[3]);

                Console.WriteLine("brakeBias: " + info.brakeBias);

                Thread.Sleep(1000);
            }
        }

        public PhysikInfo GetPhysics() {
            PhysikInfo info;
            byte[] _buffer = new byte[20];

            _physicsStream.Position = 0x0C;
            _physicsStream.Read(_buffer, 0, 4);
            info.fuel = BitConverter.ToSingle(_buffer, 0);

            _physicsStream.Position = 0x10;
            _physicsStream.Read(_buffer, 0, 4);
            info.gear = BitConverter.ToInt32(_buffer, 0);

            _physicsStream.Position = 0x14;
            _physicsStream.Read(_buffer, 0, 4);
            info.rpm = BitConverter.ToInt32(_buffer, 0);

            _physicsStream.Position = 0x1C;
            _physicsStream.Read(_buffer, 0, 4);
            info.speedKmh = BitConverter.ToSingle(_buffer, 0);

            _physicsStream.Position = 0x38;
            _physicsStream.Read(_buffer, 0, 16);
            info.wheelSlip = new float[4];
            info.wheelSlip[0] = BitConverter.ToSingle(_buffer, 0);
            info.wheelSlip[1] = BitConverter.ToSingle(_buffer, 4);
            info.wheelSlip[2] = BitConverter.ToSingle(_buffer, 8);
            info.wheelSlip[3] = BitConverter.ToSingle(_buffer, 12);

            _physicsStream.Position = 0x58;
            _physicsStream.Read(_buffer, 0, 16);
            info.wheelPressure = new float[4];
            info.wheelPressure[0] = BitConverter.ToSingle(_buffer, 0);
            info.wheelPressure[1] = BitConverter.ToSingle(_buffer, 4);
            info.wheelPressure[2] = BitConverter.ToSingle(_buffer, 8);
            info.wheelPressure[3] = BitConverter.ToSingle(_buffer, 12);


            _physicsStream.Position = 0x98;
            _physicsStream.Read(_buffer, 0, 16);
            info.tyreCoreTemp = new float[4];
            info.tyreCoreTemp[0] = BitConverter.ToSingle(_buffer, 0);
            info.tyreCoreTemp[1] = BitConverter.ToSingle(_buffer, 4);
            info.tyreCoreTemp[2] = BitConverter.ToSingle(_buffer, 8);
            info.tyreCoreTemp[3] = BitConverter.ToSingle(_buffer, 12);

            _physicsStream.Position = 0xD4;
            _physicsStream.Read(_buffer, 0, 20);
            info.carDamage = new float[5];
            info.carDamage[0] = BitConverter.ToSingle(_buffer, 0);
            info.carDamage[1] = BitConverter.ToSingle(_buffer, 4);
            info.carDamage[2] = BitConverter.ToSingle(_buffer, 8);
            info.carDamage[3] = BitConverter.ToSingle(_buffer, 12);
            info.carDamage[4] = BitConverter.ToSingle(_buffer, 16);

            _physicsStream.Position = 0xC0;
            _physicsStream.Read(_buffer, 0, 4);
            info.tcInAction = BitConverter.ToSingle(_buffer, 0);

            _physicsStream.Position = 0xF4;
            _physicsStream.Read(_buffer, 0, 4);
            info.absInAction = BitConverter.ToSingle(_buffer, 0);

            _physicsStream.Position = 0x154;
            _physicsStream.Read(_buffer, 0, 16);
            info.brakeTemp = new float[4];
            info.brakeTemp[0] = BitConverter.ToSingle(_buffer, 0);
            info.brakeTemp[1] = BitConverter.ToSingle(_buffer, 4);
            info.brakeTemp[2] = BitConverter.ToSingle(_buffer, 8);
            info.brakeTemp[3] = BitConverter.ToSingle(_buffer, 12);

            _physicsStream.Position = 0x224; // TODO: wrong offset
            _physicsStream.Read(_buffer, 0, 4);
            info.brakeBias = BitConverter.ToSingle(_buffer, 0);

            return info;
        }

        public struct PhysikInfo {
            public float fuel;
            public int gear;
            public int rpm;
            public float speedKmh;
            public float[] wheelSlip; //4
            public float[] wheelPressure;//4
            public float[] tyreCoreTemp;//4
            public float[] carDamage;//4
            public float tcInAction;
            public float absInAction;
            public float[] brakeTemp;//4
            public float brakeBias;
        }

        public struct GraphicInfo
        {
            public int position;
            public int iCurrentTime;
            public int iLastTime;
            public int iBestTime;
            public int numberOfLaps;
            public int Tc;
            public int Abs;
            public int iDeltaLapTime;
            public int isDeltaPositive;
            public int isValidLap;
            public int missingMandatoryPits;
        }

        private MemoryMappedFile _physicsFile;
        private MemoryMappedFile _graphicsFile;
        private MemoryMappedViewStream _physicsStream;
        private MemoryMappedViewStream _graphicsStream;
    }
}