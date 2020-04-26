using System;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;
using System.Threading;
using System.Text;

namespace Lcd
{
    public class Eth {

        public Eth(string ipAddressString, UInt16 port) {
            try {
                _packetId = 0x00;
                _udpClient = new UdpClient(port);
                IPAddress ipAddress;
                if (!IPAddress.TryParse(ipAddressString, out ipAddress)) {
                    Console.WriteLine("IP address not valid :" + ipAddressString);
                    return;
                }
                _udpClient.Connect(ipAddress, port);
                _remoteIpEndPoint = new IPEndPoint(ipAddress, port);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
            }
        }

        public bool Read32(UInt32 address, out UInt32 data, out UInt32 errorCode)
        {
            bool success = SendReadRequest(address, _packetId, 4);
            List<UInt32> readData;
            if (success) {
                success = GetReadData(out readData, out errorCode, _packetId, 4);
                _packetId++;
                if (success) {
                    data = readData[0];
                    return true;
                }
            } else {
                errorCode = _ERROR_SEND;
            }
            _packetId++;
            data = 0x0;
            return false;
        }

        public bool Read(UInt32 address, out List<UInt32> data, out UInt32 errorCode, Byte NumberOfBytes)
        {
            bool success = SendReadRequest(address, _packetId, NumberOfBytes);
            if (success)
            {
                success = GetReadData(out data, out errorCode, _packetId, NumberOfBytes);
                _packetId++;
                if (success)
                {
                    return true;
                }
            }
            else
            {
                errorCode = _ERROR_SEND;
            }
            _packetId++;
            data = new List<UInt32>();
            return false;
        }

        public bool Write32(UInt32 address, UInt32 data, out UInt32 errorCode) {
            try {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(_packetId);
                _packetId++;
                byteList.Add(_UDP_WRITE);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add(0x04); // data length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)data >> (8 * dataByte)) & 0xff));
                }
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
                errorCode = _ERROR_EXCEPTION;
                return false;
            }
            errorCode = _ERROR_SUCCESS;
            return true;
        }

        public bool Write(UInt32 address, List<UInt32> data, out UInt32 errorCode, Byte NumberOfBytes)
        {
            try
            {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(_packetId);
                _packetId++;
                byteList.Add(_UDP_WRITE);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add(NumberOfBytes); // data length
                for (int dataWord = 0; dataWord < NumberOfBytes/4; dataWord++) {
                    for (int dataByte = 3; dataByte >= 0; dataByte--) {
                        byteList.Add(Convert.ToByte(((int)data[dataWord] >> (8 * dataByte)) & 0xff));
                    }
                }
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
                errorCode = _ERROR_EXCEPTION;
                return false;
            }
            errorCode = _ERROR_SUCCESS;
            return true;
        }

        private bool SendReadRequest(UInt32 address, Byte packetId, Byte NumberOfBytes) {
            try {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(packetId);
                byteList.Add(_UDP_READ);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add(NumberOfBytes); // data length
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
                return false;
            }
            return true;
        }

        private bool GetReadData(out List<UInt32> data, out UInt32 errorCode, Byte packetId, Byte NumberOfBytes) {
            data = new List<UInt32>();
            try {
                int timeout = _TIMEOUT_MS;
                while (timeout > 0) {
                    if (_udpClient.Available >= 7) {
                        Byte[] receiveBytes = _udpClient.Receive(ref _remoteIpEndPoint);
                        if (receiveBytes[0] != packetId) {
                            errorCode = _ERROR_PACKET_ID;
                            return false;
                        }
                        if (receiveBytes[1] == _UDP_READ_TIMEOUT) {
                            errorCode = _ERROR_READ_TIMEOUT;
                            return false;
                        }
                        if (receiveBytes[1] != _UDP_READ_RESPONSE) {
                            errorCode = _ERROR_TYPE;
                            return false;
                        }
                        if (receiveBytes[2] != NumberOfBytes) { // length
                            errorCode = _ERROR_RECEIVED_LENGTH;
                            return false;
                        }
                        if (receiveBytes.Length != (3+ NumberOfBytes)) {
                            errorCode = _ERROR_PACKET_LENGTH;
                            return false;
                        }

                        for (int dataword = 0; dataword < NumberOfBytes; dataword += 4) {
                            UInt32 receivedData = 0;
                            for (int databyte = 3; databyte >= 0; databyte--) {
                                receivedData |= Convert.ToUInt32((int)(receiveBytes[dataword + databyte + 3] << ((3 - databyte) * 8)) & 0xFFFFFFFF);
                            }
                            data.Add(receivedData);
                        }
                        errorCode = _ERROR_SUCCESS;
                        return true;
                    }
                    Thread.Sleep(1);
                    timeout--;
                }
                errorCode = _ERROR_UDP_TIMEOUT;
                return false;
            }
            catch (Exception e) {
                Console.WriteLine(e.ToString());
                errorCode = _ERROR_EXCEPTION;
                return false;
            }
        }

        private UdpClient _udpClient;
        private Byte _packetId;
        IPEndPoint _remoteIpEndPoint;
        private const Byte _UDP_READ = 0x01;
        private const Byte _UDP_WRITE = 0x02;
        private const Byte _UDP_READ_RESPONSE = 0x04;
        private const Byte _UDP_READ_TIMEOUT = 0x08;
        private const int _TIMEOUT_MS = 100;

        public const UInt32 _ERROR_SUCCESS = 0x00;
        public const UInt32 _ERROR_UDP_TIMEOUT = 0x01;
        public const UInt32 _ERROR_TYPE = 0x02;
        public const UInt32 _ERROR_RECEIVED_LENGTH = 0x03;
        public const UInt32 _ERROR_PACKET_LENGTH = 0x04;
        public const UInt32 _ERROR_SEND = 0x05;
        public const UInt32 _ERROR_RECEIVE = 0x06;
        public const UInt32 _ERROR_EXCEPTION = 0x07;
        public const UInt32 _ERROR_PACKET_ID = 0x08;
        public const UInt32 _ERROR_READ_TIMEOUT = 0x09;
    }
}
