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
            bool success = SendRead32Request(address, _packetId);
            if (success) {
                success = GetRead32Data(out data, out errorCode, _packetId);
                _packetId++;
                if (success) {
                    return true;
                } else {
                    Console.WriteLine("Get read data failed: ErrorCode = " + errorCode);
                }
            }
            _packetId++;
            data = 0x0;
            errorCode = _ERROR_SEND;
            return false;
        }

        public bool Write32(UInt32 address, UInt32 data, out UInt32 errorCode) {
            try {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(_packetId);
                _packetId++;
                byteList.Add(_UDP_WRITE);
                byteList.Add(0x04); // address length
                for (int databyte = 3; databyte >= 0; databyte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * databyte)) & 0xff));
                }
                byteList.Add(0x04); // data length
                for (int databyte = 3; databyte >= 0; databyte--)
                {
                    byteList.Add(Convert.ToByte(((int)data >> (8 * databyte)) & 0xff));
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

        private bool SendRead32Request(UInt32 address, Byte packetId) {
            try {
                List<Byte> byteList = new List<Byte>();
                byteList.Add(packetId);
                byteList.Add(_UDP_READ);
                byteList.Add(0x04); // address length
                for (int databyte = 3; databyte >= 0; databyte--)
                {
                    byteList.Add(Convert.ToByte(((int)address >> (8 * databyte)) & 0xff));
                }
                byteList.Add(0x04); // data length
                Byte[] sendBytes = byteList.ToArray();
                _udpClient.Send(sendBytes, sendBytes.Length);
            } catch (Exception e) {
                Console.WriteLine(e.ToString());
                return false;
            }
            return true;
        }


        private bool GetRead32Data(out UInt32 data, out UInt32 errorCode, Byte packetId) {
            try {
                int timeout = _TIMEOUT_MS;
                while (timeout > 0) {
                    if (_udpClient.Available > 0) {
                        Byte[] receiveBytes = _udpClient.Receive(ref _remoteIpEndPoint);
                        if (receiveBytes[1] != _UDP_READ_RESPONSE) {
                            errorCode = _ERROR_TYPE;
                            data = 0x0;
                            return false;
                        }
                        if (receiveBytes[2] != 4) { // length
                            errorCode = _ERROR_RECEIVED_LENGTH;
                            data = 0x0;
                            return false;
                        }
                        if (receiveBytes.Length != 7) {
                            errorCode = _ERROR_PACKET_LENGTH;
                            data = 0x0;
                            return false;
                        }

                        UInt32 receivedData = 0;
                        for (int databyte = 3; databyte >= 0; databyte--)
                        {
                            receivedData |= Convert.ToUInt32((int)(receiveBytes[databyte+3] << ((3-databyte)*8)) & 0xFFFFFFFF);
                        }
                        errorCode = _ERROR_SUCCESS;
                        data = receivedData;
                        return true;
                    }
                    Thread.Sleep(1);
                    timeout--;
                }
                errorCode = _ERROR_UDP_TIMEOUT;
                data = 0x0;
                return false;
            }
            catch (Exception e) {
                Console.WriteLine(e.ToString());
                errorCode = _ERROR_EXCEPTION;
                data = 0x0;
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
        private const Byte _TIMEOUT_MS = 100;

        public const UInt32 _ERROR_SUCCESS = 0x00;
        public const UInt32 _ERROR_UDP_TIMEOUT = 0x01;
        public const UInt32 _ERROR_TYPE = 0x02;
        public const UInt32 _ERROR_RECEIVED_LENGTH = 0x03;
        public const UInt32 _ERROR_PACKET_LENGTH = 0x04;
        public const UInt32 _ERROR_SEND = 0x05;
        public const UInt32 _ERROR_EXCEPTION = 0x06;
    }
}
