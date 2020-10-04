using System;

namespace Lcd
{
    public class Monitor {
        public Monitor(I2c i2cDevice) {
            _i2cInst = i2cDevice;
        }

        public void GetStatus(out MonitorStatus status) {
            UInt16 readData;

            // read voltage
            _i2cInst.Read16(_i2cAddress, _channel0Voltage, out readData);
            status.ch0.voltage = ConvertVoltage(readData);
            _i2cInst.Read16(_i2cAddress, _channel1Voltage, out readData);
            status.ch1.voltage = ConvertVoltage(readData);
            _i2cInst.Read16(_i2cAddress, _channel2Voltage, out readData);
            status.ch2.voltage = ConvertVoltage(readData);

            // read current
            _i2cInst.Read16(_i2cAddress, _channel0Current, out readData);
            status.ch0.current = ConvertCurrent(_shunt0Ohm, readData);
            _i2cInst.Read16(_i2cAddress, _channel1Current, out readData);
            status.ch1.current = ConvertCurrent(_shunt1Ohm, readData);
            _i2cInst.Read16(_i2cAddress, _channel2Current, out readData);
            status.ch2.current = ConvertCurrent(_shunt2Ohm, readData);
        }

        private float ConvertVoltage(UInt16 data) { 
            float voltage = ((float)((Int16)data) / 1000f) + _voltageOffset;
            return voltage;
        }

        private float ConvertCurrent(float shunt, UInt16 data) {
            float current = ((float)((Int16)data) / 200f) / shunt;
            return current;
        }

        public struct MonitorStatus {
            public Channel ch0;
            public Channel ch1;
            public Channel ch2;
        }

        public struct Channel {
            public float voltage;
            public float current;
        }

        private I2c _i2cInst;
        private const Byte _i2cAddress = 0x40;
        private const float _voltageOffset = -6.6f;
        private const float _shunt0Ohm = 0.1f;
        private const float _shunt1Ohm = 0.1f;
        private const float _shunt2Ohm = 0.1f;
        private const Byte _channel0Voltage = 0x02;
        private const Byte _channel0Current = 0x01;
        private const Byte _channel1Voltage = 0x04; // always 0
        private const Byte _channel1Current = 0x03;
        private const Byte _channel2Voltage = 0x06;
        private const Byte _channel2Current = 0x05;

    }
}
