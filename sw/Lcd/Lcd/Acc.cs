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
        }

        public bool TryOpen()
        {
            try
            {
                _physicsFile = MemoryMappedFile.OpenExisting(_physicsFileName, MemoryMappedFileRights.Read, HandleInheritability.None);
            }
            catch
            {
                return false;
            }
            try
            {
                _graphicsFile = MemoryMappedFile.OpenExisting(_graphicsFileName, MemoryMappedFileRights.Read, HandleInheritability.None);
            }
            catch
            {
                _physicsFile.Dispose();
                return false;
            }
            try
            {
                _physicsStream = _physicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
                _graphicsStream = _graphicsFile.CreateViewStream(0L, 0L, MemoryMappedFileAccess.Read);
            }
            catch
            {
                _physicsFile.Dispose();
                _graphicsFile.Dispose();
                return false;
            }
            return true;
        }

        public bool GetData (out PhysikInfo pInfo, out GraphicInfo gInfo)
        {
            try
            {
                pInfo = GetPhysics();
                gInfo = GetGraphics();
                return true;
            }
            catch
            {
                pInfo = new PhysikInfo();
                gInfo = new GraphicInfo();
                return false;
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
            info.tc = GetInt(_graphicsStream, 0x4F4);
            info.abs = GetInt(_graphicsStream, 0x500);
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
            public int tc;
            public int abs;
            public int iDeltaLapTime;
            public int isDeltaPositive;
            public int isValidLap;
        }

        private const string _physicsFileName = "Local\\acpmf_physics";
        private const string _graphicsFileName = "Local\\acpmf_graphics";
        private MemoryMappedFile _physicsFile;
        private MemoryMappedFile _graphicsFile;
        private MemoryMappedViewStream _physicsStream;
        private MemoryMappedViewStream _graphicsStream;
    }
}