using System;
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

        public bool GetData(out PhysikInfo pInfo, out GraphicInfo gInfo)
        {
            try
            {
                if (!GetPhysics(out pInfo))
                {
                    gInfo = new GraphicInfo();

                    _physicsFile.Dispose();
                    _graphicsFile.Dispose();
                    return false;
                }
                if (!GetGraphics(out gInfo))
                {
                    _physicsFile.Dispose();
                    _graphicsFile.Dispose();
                    return false;
                }
                return true;
            }
            catch
            {
                pInfo = new PhysikInfo();
                gInfo = new GraphicInfo();
                return false;
            }
        }

        private bool GetInt(MemoryMappedViewStream stream, UInt32 offset, out Int32 result)
        {
            byte[] buffer = new byte[4];
            stream.Position = offset;
            int length = stream.Read(buffer, 0, 4);
            if (length != 4)
            {
                result = 0;
                return false;
            }
            result = BitConverter.ToInt32(buffer, 0);
            return true;
        }

        private bool GetFloat(MemoryMappedViewStream stream, UInt32 offset, out float result)
        {
            byte[] buffer = new byte[4];
            stream.Position = offset;
            int length = stream.Read(buffer, 0, 4);
            if (length != 4)
            {
                result = 0.0f;
                return false;
            }
            result = BitConverter.ToSingle(buffer, 0);
            return true;
        }

        private bool GetFloatArray(MemoryMappedViewStream stream, UInt32 offset, UInt32 arrayLength, out float[] result)
        {
            result = new float[arrayLength];
            int lengthBytes = (int)(4 * arrayLength);
            byte[] buffer = new byte[lengthBytes];
            stream.Position = offset;
            int length = stream.Read(buffer, 0, lengthBytes);
            if (length != lengthBytes)
            {
                return false;
            }
            for (int index = 0; index < arrayLength; index++)
            {
                result[index] = BitConverter.ToSingle(buffer, index*4);
            }
            return true;
        }

        private bool GetPhysics(out PhysikInfo info)
        {
            info = new PhysikInfo();
            if (!GetFloat(_physicsStream, 0x0C, out info.fuel))
                return false;
            if (!GetInt(_physicsStream, 0x10, out info.gear))
                return false;
            if (!GetInt(_physicsStream, 0x14, out info.rpm))
                return false;
            if (!GetFloat(_physicsStream, 0x1C, out info.speedKmh))
                return false;
            if (!GetFloatArray(_physicsStream, 0x58, 4, out info.wheelPressure))
                return false;
            if (!GetFloatArray(_physicsStream, 0x98, 4, out info.tyreCoreTemp))
                return false;
            if (!GetFloatArray(_physicsStream, 0xE0, 5, out info.carDamage))
                return false;
            if (!GetFloat(_physicsStream, 0xCC, out info.tcInAction))
                return false;
            if (!GetFloat(_physicsStream, 0xFC, out info.absInAction))
                return false;
            if (!GetFloatArray(_physicsStream, 0x15C, 4, out info.brakeTemp))
                return false;
            if (!GetFloat(_physicsStream, 0x234, out info.brakeBias))
                return false;
            return true;
        }

        private bool GetGraphics(out GraphicInfo info)
        {
            info = new GraphicInfo();
            if (!GetInt(_graphicsStream, 0x88, out info.position))
                return false;
            if (!GetInt(_graphicsStream, 0x8C, out info.iCurrentTime))
                return false;
            if (!GetInt(_graphicsStream, 0x90, out info.iLastTime))
                return false;
            if (!GetInt(_graphicsStream, 0x94, out info.iBestTime))
                return false;
            if (!GetInt(_graphicsStream, 0xAC, out info.numberOfLaps))
                return false;
            if (!GetInt(_graphicsStream, 0x4F4, out info.tc))
                return false;
            if (!GetInt(_graphicsStream, 0x500, out info.abs))
                return false;
            if (!GetInt(_graphicsStream, 0x54E, out info.iDeltaLapTime))
                return false;
            if (!GetInt(_graphicsStream, 0x578, out info.isDeltaPositive))
                return false;
            if (!GetInt(_graphicsStream, 0x580, out info.isValidLap))
                return false;
            return true;
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