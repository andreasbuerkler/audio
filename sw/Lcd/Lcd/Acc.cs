using System;
using System.Threading;
using System.IO;
using System.IO.MemoryMappedFiles;

namespace Lcd
{
    public class Acc
    {
        public Acc()
        {
            _physicsFile = MemoryMappedFile.OpenExisting("Local\\acpmf_physics", MemoryMappedFileRights.Read, HandleInheritability.None);
            _graphicsFile = MemoryMappedFile.OpenExisting("Local\\acpmf_graphics", MemoryMappedFileRights.Read, HandleInheritability.None);
            _physicsStream = _physicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
            _graphicsStream = _graphicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
        }

        public void PrintPhysics ()
        {
            while (true) {
                PhysikInfo pInfo = GetPhysics();
                GraphicInfo gInfo = GetGraphics();

                Console.WriteLine("fuel: " + pInfo.fuel);
                Console.WriteLine("gear: " + pInfo.gear);
                Console.WriteLine("rpm: " + pInfo.rpm);
                Console.WriteLine("speedKmh: " + pInfo.speedKmh);

                Console.WriteLine("wheelPressure[0]: " + pInfo.wheelPressure[0]);
                Console.WriteLine("wheelPressure[1]: " + pInfo.wheelPressure[1]);
                Console.WriteLine("wheelPressure[2]: " + pInfo.wheelPressure[2]);
                Console.WriteLine("wheelPressure[3]: " + pInfo.wheelPressure[3]);

                Console.WriteLine("tyreCoreTemp[0]: " + pInfo.tyreCoreTemp[0]);
                Console.WriteLine("tyreCoreTemp[1]: " + pInfo.tyreCoreTemp[1]);
                Console.WriteLine("tyreCoreTemp[2]: " + pInfo.tyreCoreTemp[2]);
                Console.WriteLine("tyreCoreTemp[3]: " + pInfo.tyreCoreTemp[3]);

                Console.WriteLine("brakeTemp[0]: " + pInfo.brakeTemp[0]);
                Console.WriteLine("brakeTemp[1]: " + pInfo.brakeTemp[1]);
                Console.WriteLine("brakeTemp[2]: " + pInfo.brakeTemp[2]);
                Console.WriteLine("brakeTemp[3]: " + pInfo.brakeTemp[3]);

                Console.WriteLine("carDamage[0]: " + pInfo.carDamage[0]);
                Console.WriteLine("carDamage[1]: " + pInfo.carDamage[1]);
                Console.WriteLine("carDamage[2]: " + pInfo.carDamage[2]);
                Console.WriteLine("carDamage[3]: " + pInfo.carDamage[3]);
                Console.WriteLine("carDamage[4]: " + pInfo.carDamage[4]);

                Console.WriteLine("brakeBias: " + pInfo.brakeBias);
                Console.WriteLine("tcInAction: " + pInfo.tcInAction);
                Console.WriteLine("absInAction: " + pInfo.absInAction);

                Console.WriteLine("position: " + gInfo.position);
                Console.WriteLine("iCurrentTime: " + gInfo.iCurrentTime);
                Console.WriteLine("iLastTime: " + gInfo.iLastTime);
                Console.WriteLine("iBestTime: " + gInfo.iBestTime);
                Console.WriteLine("numberOfLaps: " + gInfo.numberOfLaps);
                Console.WriteLine("Tc: " + gInfo.Tc);
                Console.WriteLine("Abs: " + gInfo.Abs);
                Console.WriteLine("iDeltaLapTime: " + gInfo.iDeltaLapTime);
                Console.WriteLine("isDeltaPositive: " + gInfo.isDeltaPositive);
                Console.WriteLine("isValidLap: " + gInfo.isValidLap);

                Thread.Sleep(1000);
            }
        }

        private Int32 GetInt(MemoryMappedViewStream stream, UInt32 offset)
        {
            byte[] buffer = new byte[4];
            stream.Position = offset;
            stream.Read(buffer, 0, 4);
            return BitConverter.ToInt32(buffer, 0);
        }

        private float GetFloat(MemoryMappedViewStream stream, UInt32 offset)
        {
            byte[] buffer = new byte[4];
            stream.Position = offset;
            stream.Read(buffer, 0, 4);
            return BitConverter.ToSingle(buffer, 0);
        }

        private float[] GetFloatArray(MemoryMappedViewStream stream, UInt32 offset, UInt32 arrayLength)
        {
            float[] array = new float[arrayLength];
            int lengthBytes = (int)(4 * arrayLength);
            byte[] buffer = new byte[lengthBytes];
            stream.Position = offset;
            stream.Read(buffer, 0, lengthBytes);

            for (int index = 0; index < arrayLength; index++)
            {
                array[index] = BitConverter.ToSingle(buffer, index*4);
            }
            return array;
        }

        public PhysikInfo GetPhysics()
        {
            PhysikInfo info;
            info.fuel = GetFloat(_physicsStream, 0x0C);
            info.gear = GetInt(_physicsStream, 0x10);
            info.rpm = GetInt(_physicsStream, 0x14);
            info.speedKmh = GetFloat(_physicsStream, 0x1C);
            info.wheelPressure = GetFloatArray(_physicsStream, 0x58, 4);
            info.tyreCoreTemp = GetFloatArray(_physicsStream, 0x98, 4);
            info.carDamage = GetFloatArray(_physicsStream, 0xE0, 5);
            info.tcInAction = GetFloat(_physicsStream, 0x2A0);
            info.absInAction = GetFloat(_physicsStream, 0x2A4);
            info.brakeTemp = GetFloatArray(_physicsStream, 0x15C, 4);
            info.brakeBias = GetFloat(_physicsStream, 0x234);
            return info;
        }

        public GraphicInfo GetGraphics()
        {
            GraphicInfo info;
            info.position = GetInt(_graphicsStream, 0x88);
            info.iCurrentTime = GetInt(_graphicsStream, 0x8C);
            info.iLastTime = GetInt(_graphicsStream, 0x90);
            info.iBestTime = GetInt(_graphicsStream, 0x94);
            info.numberOfLaps = GetInt(_graphicsStream, 0xAC);
            info.Tc = GetInt(_graphicsStream, 0x4F4);
            info.Abs = GetInt(_graphicsStream, 0x500);
            info.iDeltaLapTime = GetInt(_graphicsStream, 0x54E);
            info.isDeltaPositive = GetInt(_graphicsStream, 0x578);
            info.isValidLap = GetInt(_graphicsStream, 0x580);
            return info;
        }

        public struct PhysikInfo {
            public float fuel;
            public int gear;
            public int rpm;
            public float speedKmh;
            public float[] wheelPressure;//4
            public float[] tyreCoreTemp;//4
            public float[] carDamage;//5
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
        }

        private MemoryMappedFile _physicsFile;
        private MemoryMappedFile _graphicsFile;
        private MemoryMappedViewStream _physicsStream;
        private MemoryMappedViewStream _graphicsStream;
    }
}