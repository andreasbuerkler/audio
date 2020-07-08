using System;
using System.Collections.Generic;
using System.Threading;

namespace Lcd
{
    class Framebuffer
    {
        public  Framebuffer()
        {
            _bufferNext = new uint[_bufferSize / 4];
            _bufferDisplay = new uint[_bufferSize / 4];
            _text = new TextDisplay();
        }

        public void ClearBuffer()
        {
            for (int wordIndex = 0; wordIndex < _bufferSize / 4; wordIndex++)
            {
                _bufferNext[wordIndex] = 0x000;
            }
            _text.ClearText();
        }

        public bool SetText(string text, int posX, int posY)
        {
            return _text.SetText(text, posX, posY);
        }

        public bool UpdateBuffer(Eth ethInst)
        {
            bool pixel = false;
            // write text to buffer
            for (int y = 0; y < _imageHeight; y++)
            {
                for (int x = 0; x < _imageWidth; x++)
                {
                    int wordIndex = x + y * _imageWidth;
                    _text.GetPixel(x, y, out pixel);
                    if (pixel)
                    {
                        _bufferNext[wordIndex] = 0xFFF;
                    }
                    else
                    {
                        _bufferNext[wordIndex] = 0x00F;
                    }
                }
            }

            // write complete memory
            for (UInt32 addressOffset = 0; addressOffset < _bufferSize; addressOffset += _bytesPerPacket)
            {
                UInt32 errorCode = 0;
                UInt32 address = _bufferAddress + addressOffset;
                List<UInt32> writeData = new List<UInt32>();
                for (UInt32 index = 0; index < _bytesPerPacket; index += 4)
                {
                    writeData.Add(_bufferNext[(addressOffset + index) / 4]);
                }
                ethInst.Write(address, writeData, out errorCode, _bytesPerPacket);
                if (errorCode != Eth._ERROR_SUCCESS)
                {
                    Console.WriteLine("\nErrorCode = " + errorCode);
                    return false;
                }
                // prevent from FIFO overflow
                if (addressOffset % 4096 == 0)
                {
                    Thread.Sleep(1);
                }
            }
            return true;
        }

        private const UInt32 _bufferAddress = 0x00800000;
        private const int _imageWidth = 320;
        private const int _imageHeight = 240;
        private const UInt32 _bufferSize = _imageWidth * _imageHeight * 4; // image data
        private const UInt16 _bytesPerPacket = 1024; // number of bytes per eth packet
        private TextDisplay _text;
        private UInt32[] _bufferNext;
        private UInt32[] _bufferDisplay;
    }
}
