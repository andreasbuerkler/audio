using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    class Framebuffer
    {
        public Framebuffer()
        {
            _bufferDisplay = new UInt32[_bufferSize / 4];
            _text = new TextDisplay();
            _background = new Background();
            _speedBar = new SpeedBar();

            // create gear character
            _gear = Encoding.UTF8.GetBytes("N")[0];
            BigCharacterFactory bigCharacterFactory = new BigCharacterFactory();
            bigCharacterFactory.Build(out _gearCharacterList);

            // init background
            _background.GetBackground(out _bufferBackground);

            // init buffer with unused color to force update whole image
            Array.Fill(_bufferDisplay, Colors._green);
        }

        public bool SetText(string text, int posY, int posX)
        {
            return _text.SetText(text, posY, posX);
        }

        public void SetSpeed(int speed)
        {
            _speedBar.SetSpeed(speed);
        }

        public void SetGear(byte gear)
        {
            _gear = gear;
        }

        public void SetBgColor(int index, byte color)
        {
            _background.SetColor(index, color);
            _background.GetBackground(out _bufferBackground);
        }

        private void CreateBuffer(out UInt32[] buffer)
        {
            buffer = new uint[_bufferSize / 4];
            for (int y = 0; y < _imageHeight; y++)
            {
                for (int x = 0; x < _imageWidth; x++)
                {
                    int wordIndex = x + y * _imageWidth;

                    if (y < 45)
                    {
                        // write speed bar to buffer
                        UInt32 pixel = 0;
                        _speedBar.GetPixel(y, x, out pixel);
                        buffer[wordIndex] = pixel;
                    }
                    else if ((y > 127) && (y < 187) && (x > 136) && (x < 184))
                    {
                        // write gear to buffer
                        Character character;
                        if (_gearCharacterList.TryGetValue(_gear, out character))
                        {
                            int offsetX = 7 - ((x-136) % 8);
                            byte line = character.GetLine(y - 127, (x - 136)/(8));
                            bool pixel = (((line >> offsetX) & 0x01) == 0x01);
                            if (pixel)
                            {
                                buffer[wordIndex] = Colors._white;
                            }
                            else
                            {
                                buffer[wordIndex] = Colors._black;
                            }
                        }
                        else
                        {
                            buffer[wordIndex] = Colors._black;
                        }
                    }
                    else
                    {
                        // write text to buffer
                        bool pixel = false;
                        _text.GetPixel(y, x, out pixel);
                        if (pixel)
                        {
                            buffer[wordIndex] = Colors._white;
                        }
                        else
                        {
                            buffer[wordIndex] = _bufferBackground[wordIndex];
                        }
                    }
                }
            }
        }

        private bool CheckIfUpdateNeeded(UInt32[] buffer, UInt32 addressOffset)
        {
            for (UInt32 index = 0; index < _maxBytesPerPacket; index += 4)
            {
                UInt32 pixelIndex = 0;
                if (_flipImage)
                {
                    // flip image
                    pixelIndex = ((_bufferSize - 1) - (addressOffset + index)) / 4;
                }
                else
                {
                    pixelIndex = (addressOffset + index) / 4;
                }
                if (buffer[pixelIndex] != _bufferDisplay[pixelIndex])
                {
                    return true;
                }
            }
            return false;
        }

        public bool UpdateBuffer(Eth ethInst)
        {
            UInt32[] bufferNext;
            CreateBuffer(out bufferNext);

            // compare new buffer and write difference
            for (UInt32 addressOffset = 0; addressOffset < _bufferSize; addressOffset += _maxBytesPerPacket)
            {
                // check buffer for changes
                bool updateBuffer = CheckIfUpdateNeeded(bufferNext, addressOffset);

                // write buffer
                if (updateBuffer)
                {
                    UInt32 errorCode = 0;
                    UInt32 address = _bufferAddress + addressOffset;
                    List<UInt32> writeData = new List<UInt32>();
                    for (UInt32 index = 0; index < _maxBytesPerPacket; index += 4)
                    {
                        if (_flipImage)
                        {
                            // flip image
                            writeData.Add(bufferNext[((_bufferSize - 1) - (addressOffset + index)) / 4]);
                        }
                        else
                        {
                            writeData.Add(bufferNext[(addressOffset + index) / 4]);
                        }
                    }
                    ethInst.Write(address, writeData, out errorCode, _maxBytesPerPacket);
                    if (errorCode != Eth._errorSuccess)
                    {
                        Console.WriteLine("\nErrorCode = " + errorCode);
                        return false;
                    }
                    // workaround to handle 100mbit receiver (read id)
                    _sentBytes += _maxBytesPerPacket;
                    if (_sentBytes >= 10000)
                    {
                        _sentBytes = 0;
                        UInt32 receiveData;
                        if ((!ethInst.Read32(0, out receiveData, out errorCode)) ||
                           (errorCode != Eth._errorSuccess) || (receiveData != 0xBEEF0123))
                        {
                            Console.WriteLine("\nRead failed");
                        }
                    }
                }
            }

            // update buffer
            bufferNext.CopyTo(_bufferDisplay, 0);
            return true;
        }

        private const UInt32 _bufferAddress = 0x00800000;
        private const int _imageWidth = 320;
        private const int _imageHeight = 240;
        private const UInt32 _bufferSize = _imageWidth * _imageHeight * 4; // image data
        private const UInt16 _maxBytesPerPacket = 256; // number of bytes per eth packet
        private TextDisplay _text;
        private Background _background;
        private SpeedBar _speedBar;
        private byte _gear;
        private Dictionary<byte, Character> _gearCharacterList;
        private UInt32[] _bufferDisplay;
        private UInt32[] _bufferBackground;
        private UInt32 _sentBytes = 0;
        private const bool _flipImage = true;
    }
}
