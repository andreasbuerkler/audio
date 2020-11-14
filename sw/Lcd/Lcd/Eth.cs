using System;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;
using System.Threading;

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
                _udpClient.Client.SendTimeout = 500;
                _udpClient.Client.ReceiveTimeout = 500;
                _mutex = new Mutex();
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
            }
        }

        public bool Read32(UInt32 address, out UInt32 data, out UInt32 errorCode)
        {
            _mutex.WaitOne();
            bool success = SendReadRequest(address, _packetId, 4);
            List<UInt32> readData;
            if (success) {
                success = GetReadData(out readData, out errorCode, _packetId, 4);
                _packetId++;
                if (success) {
                    data = readData[0];
                    _mutex.ReleaseMutex();
                    return true;
                }
            } else {
                errorCode = _errorSend;
            }
            _packetId++;
            data = 0x0;
            _mutex.ReleaseMutex();
            return false;
        }

        public bool Read(UInt32 address, out List<UInt32> data, out UInt32 errorCode, UInt16 NumberOfBytes)
        {
            _mutex.WaitOne();
            bool success = SendReadRequest(address, _packetId, NumberOfBytes);
            if (success)
            {
                success = GetReadData(out data, out errorCode, _packetId, NumberOfBytes);
                _packetId++;
                if (success)
                {
                    _mutex.ReleaseMutex();
                    return true;
                }
            }
            else
            {
                errorCode = _errorSend;
            }
            _packetId++;
            data = new List<UInt32>();
            _mutex.ReleaseMutex();
            return false;
        }

        public bool Write32(UInt32 address, UInt32 data, out UInt32 errorCode) {
            try
            {
                _mutex.WaitOne();
                List<Byte> byteList = new List<Byte>();
                byteList.Add(_packetId);
                _packetId++;
                byteList.Add(_udpWrite);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add(0x00); // data length MSB
                byteList.Add(0x04); // data length LSB
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)data >> (8 * dataByte)) & 0xff));
                }
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
                errorCode = _errorException;
                _mutex.ReleaseMutex();
                return false;
            }
            errorCode = _errorSuccess;
            _mutex.ReleaseMutex();
            return true;
        }

        public bool Write(UInt32 address, List<UInt32> data, out UInt32 errorCode, UInt16 NumberOfBytes)
        {
            try
            {
                _mutex.WaitOne();
                List<Byte> byteList = new List<Byte>();
                byteList.Add(_packetId);
                _packetId++;
                byteList.Add(_udpWrite);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add((Byte)((NumberOfBytes >> 8) & 0xFF)); // data length MSB
                byteList.Add((Byte)(NumberOfBytes & 0xFF)); // data length LSB
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
                errorCode = _errorException;
                _mutex.ReleaseMutex();
                return false;
            }
            errorCode = _errorSuccess;
            _mutex.ReleaseMutex();
            return true;
        }

        private bool SendReadRequest(UInt32 address, Byte packetId, UInt16 NumberOfBytes) {
            try {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(packetId);
                byteList.Add(_udpRead);
                byteList.Add(0x04); // address length
                for (int dataByte = 3; dataByte >= 0; dataByte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * dataByte)) & 0xff));
                }
                byteList.Add((Byte)((NumberOfBytes >> 8) & 0xFF)); // data length MSB
                byteList.Add((Byte)(NumberOfBytes & 0xFF)); // data length LSB
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
                return false;
            }
            return true;
        }

        private bool GetReadData(out List<UInt32> data, out UInt32 errorCode, Byte packetId, UInt16 NumberOfBytes) {
            data = new List<UInt32>();
            try {
                Byte[] receiveBytes = _udpClient.Receive(ref _remoteIpEndPoint);
                if (receiveBytes.Length < 7)
                {
                    errorCode = _errorUdpTimeout;
                    return false;
                }
                if (receiveBytes[0] != packetId) {
                    errorCode = _errorPacketId;
                    return false;
                }
                if (receiveBytes[1] == _udpReadTimeout) {
                    errorCode = _errorReadTimeout;
                    return false;
                }
                if (receiveBytes[1] != _udpReadResponse) {
                    errorCode = _errorType;
                    return false;
                }
                if (( (((UInt16)receiveBytes[2]) << 8) | receiveBytes[3]) != NumberOfBytes) { // length
                    errorCode = _errorReceivedLength;
                    return false;
                }
                if (receiveBytes.Length != (4+NumberOfBytes)) {
                    errorCode = _errorPacketLength;
                    return false;
                }

                for (int dataword = 0; dataword < NumberOfBytes; dataword += 4) {
                    UInt32 receivedData = 0;
                    for (int databyte = 3; databyte >= 0; databyte--) {
                        receivedData |= Convert.ToUInt32((int)(receiveBytes[dataword + databyte + 4] << ((3 - databyte) * 8)) & 0xFFFFFFFF);
                    }
                    data.Add(receivedData);
                }
                errorCode = _errorSuccess;
                return true;
            }
            catch (Exception e) {
                Console.WriteLine(e.ToString());
                errorCode = _errorException;
                return false;
            }
        }

        private UdpClient _udpClient;
        private Byte _packetId;
        IPEndPoint _remoteIpEndPoint;
        private static Mutex _mutex;
        private const Byte _udpRead = 0x01;
        private const Byte _udpWrite = 0x02;
        private const Byte _udpReadResponse = 0x04;
        private const Byte _udpReadTimeout = 0x08;

        public const UInt32 _errorSuccess = 0x00;
        public const UInt32 _errorUdpTimeout = 0x01;
        public const UInt32 _errorType = 0x02;
        public const UInt32 _errorReceivedLength = 0x03;
        public const UInt32 _errorPacketLength = 0x04;
        public const UInt32 _errorSend = 0x05;
        public const UInt32 _errorException = 0x07;
        public const UInt32 _errorPacketId = 0x08;
        public const UInt32 _errorReadTimeout = 0x09;
    }
}
