using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    public class Monitor {
        public Monitor(I2c i2cDevice) {
            _i2cInst = i2cDevice;
        }

        public void GetStatus(out MonitorStatus status) {
            UInt16 readData;

            // read voltage
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_0_VOLTAGE, out readData);
            status.ch0.voltage = ConvertVoltage(readData);
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_1_VOLTAGE, out readData);
            status.ch1.voltage = ConvertVoltage(readData);
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_2_VOLTAGE, out readData);
            status.ch2.voltage = ConvertVoltage(readData);

            // read current
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_0_CURRENT, out readData);
            status.ch0.current = ConvertCurrent(_SHUNT_0_OHM, readData);
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_1_CURRENT, out readData);
            status.ch1.current = ConvertCurrent(_SHUNT_1_OHM, readData);
            _i2cInst.Read16(_I2C_ADDRESS, _CHANNEL_2_CURRENT, out readData);
            status.ch2.current = ConvertCurrent(_SHUNT_2_OHM, readData);
        }

        private float ConvertVoltage(UInt16 data) { 
            float voltage = ((float)((Int16)data) / 1000f) + _VOLTAGE_OFFSET;
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
        private const Byte _I2C_ADDRESS = 0x40;
        private const float _VOLTAGE_OFFSET = -6.6f;
        private const float _SHUNT_0_OHM = 0.1f;
        private const float _SHUNT_1_OHM = 0.1f;
        private const float _SHUNT_2_OHM = 0.1f;
        private const Byte _CHANNEL_0_VOLTAGE = 0x02;
        private const Byte _CHANNEL_0_CURRENT = 0x01;
        private const Byte _CHANNEL_1_VOLTAGE = 0x04; // always 0
        private const Byte _CHANNEL_1_CURRENT = 0x03;
        private const Byte _CHANNEL_2_VOLTAGE = 0x06;
        private const Byte _CHANNEL_2_CURRENT = 0x05;

    }
}
