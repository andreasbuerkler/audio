using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    class Background
    {

        public void GetBackground(out UInt32[] background)
        {
            
            background = new uint[_bufferSize];
            for (UInt32 verticalIndex = 0; verticalIndex < _numberOfVerticalTiles; verticalIndex++)
            {
                for (UInt32 horizontalIndex = 0; horizontalIndex < _numberOfHorizontalTiles; horizontalIndex++)
                {
                    bool top = (verticalIndex == 0) ? false : (_bg[verticalIndex, horizontalIndex] & 0xF) == (_bg[verticalIndex - 1, horizontalIndex] & 0xF);
                    bool bottom = (verticalIndex == _numberOfVerticalTiles - 1) ? false : (_bg[verticalIndex, horizontalIndex] & 0xF) == (_bg[verticalIndex + 1, horizontalIndex] & 0xF);
                    bool left = (horizontalIndex == 0) ? false : (_bg[verticalIndex, horizontalIndex] & 0xF) == (_bg[verticalIndex, horizontalIndex - 1] & 0xF);
                    bool right = (horizontalIndex == _numberOfHorizontalTiles - 1) ? false : (_bg[verticalIndex, horizontalIndex] & 0xF) == (_bg[verticalIndex, horizontalIndex + 1] & 0xF);
                    int color = _bg[verticalIndex, horizontalIndex] >> 4;
                    AddTile(verticalIndex, horizontalIndex, top, bottom, left, right, color, ref background);
                }
            }
        }

        private void AddTile(UInt32 verticalTileNr, UInt32 horizontalTileNr, bool top, bool bottom, bool left, bool right, int colorCode, ref UInt32[] background)
        {
            UInt32 color = _colorBlack;
            UInt32 colorBright = _colorBlack;
            UInt32 colorDark = _colorBlack;
            switch (colorCode)
            {
                case _colorIndexBlue:
                    color = _colorBlue;
                    colorBright = _colorBlueBright;
                    colorDark = _colorBlueDark;
                    break;
                case _colorIndexYellow:
                    color = _colorYellow;
                    colorBright = _colorYellowBright;
                    colorDark = _colorYellowDark;
                    break;
                case _colorIndexWhite:
                    color = _colorBlack;
                    colorBright = _colorWhite;
                    colorDark = _colorGrey;
                    break;
                default:
                    break;
            }

            // fill tile with solid color
            UInt32 totalWidth = _tileWidth * _numberOfHorizontalTiles;
            for (UInt32 verticalIndex = 0; verticalIndex < _tileHeight; verticalIndex++)
            {
                for (UInt32 horizontalIndex = 0; horizontalIndex < _tileWidth; horizontalIndex++)
                {
                    UInt32 verticalOffset = verticalTileNr * _tileHeight + verticalIndex;
                    UInt32 horizontalOffset = horizontalTileNr * _tileWidth + horizontalIndex;
                    background[verticalOffset * totalWidth + horizontalOffset] = color;
                }
            }

            // draw top frame
            if (!top)
            {
                for (UInt32 offset = 0; offset < _tileWidth; offset++)
                {
                    UInt32 verticalOffset = verticalTileNr * _tileHeight;
                    UInt32 horizontalOffset = horizontalTileNr * _tileWidth + offset;
                    background[verticalOffset * totalWidth + horizontalOffset] = _colorBlack;
                    verticalOffset += 1;
                    if ((left ? (offset >= 0) : (offset >= 1)) && (right ? (offset < _tileWidth) : (offset < (_tileWidth - 1))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorDark;
                    }
                    verticalOffset += 1;
                    if ((left ? (offset >= 0) : (offset >= 2)) && (right ? (offset < _tileWidth) : (offset < (_tileWidth - 2))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorBright;
                    }
                }
            }

            // draw bottom frame
            if (!bottom)
            {
                for (UInt32 offset = 0; offset < _tileWidth; offset++)
                {
                    UInt32 verticalOffset = verticalTileNr * _tileHeight + _tileHeight - 1;
                    UInt32 horizontalOffset = horizontalTileNr * _tileWidth + offset;
                    background[verticalOffset * totalWidth + horizontalOffset] = _colorBlack;
                    verticalOffset -= 1;
                    if ((left ? (offset >= 0) : (offset >= 1)) && (right ? (offset < _tileWidth) : (offset < (_tileWidth - 1))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorDark;
                    }
                    verticalOffset -= 1;
                    if ((left ? (offset >= 0) : (offset >= 2)) && (right ? (offset < _tileWidth) : (offset < (_tileWidth - 2))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorBright;
                    }
                }
            }

            // draw left frame
            if (!left)
            {
                for (UInt32 offset = 0; offset < _tileHeight; offset++)
                {
                    UInt32 verticalOffset = verticalTileNr * _tileHeight + offset;
                    UInt32 horizontalOffset = horizontalTileNr * _tileWidth;
                    background[verticalOffset * totalWidth + horizontalOffset] = _colorBlack;
                    horizontalOffset += 1;
                    if ((top ? (offset >= 0) : (offset >= 1)) && (bottom ? (offset < _tileHeight) : (offset < (_tileHeight - 1))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorDark;
                    }
                    horizontalOffset += 1;
                    if ((top ? (offset >= 0) : (offset >= 2)) && (bottom ? (offset < _tileHeight) : (offset < (_tileHeight - 2))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorBright;
                    }
                }
            }

            // draw right frame
            if (!right)
            {
                for (UInt32 offset = 0; offset < _tileHeight; offset++)
                {
                    UInt32 verticalOffset = verticalTileNr * _tileHeight + offset;
                    UInt32 horizontalOffset = horizontalTileNr * _tileWidth + _tileWidth - 1;
                    background[verticalOffset * totalWidth + horizontalOffset] = _colorBlack;
                    horizontalOffset -= 1;
                    if ((top ? (offset >= 0) : (offset >= 1)) && (bottom ? (offset < _tileHeight) : (offset < (_tileHeight - 1))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorDark;
                    }
                    horizontalOffset -= 1;
                    if ((top ? (offset >= 0) : (offset >= 2)) && (bottom ? (offset < _tileHeight) : (offset < (_tileHeight - 2))))
                    {
                        background[verticalOffset * totalWidth + horizontalOffset] = colorBright;
                    }
                }
            }
        }

        private const UInt32 _colorBlack = 0x000;
        private const UInt32 _colorGrey = 0xCCC;
        private const UInt32 _colorWhite = 0xFFF;

        private const UInt32 _colorBlue = 0x58A;
        private const UInt32 _colorBlueDark = 0x456;
        private const UInt32 _colorBlueBright = 0x79C;

        private const UInt32 _colorYellow = 0xCB6;
        private const UInt32 _colorYellowDark = 0x663;
        private const UInt32 _colorYellowBright = 0x985;

        private const int _tileWidth = 32;
        private const int _tileHeight = 30;
        private const int _numberOfHorizontalTiles = 10;
        private const int _numberOfVerticalTiles = 8;
        private const int _bufferSize = _numberOfHorizontalTiles * _tileWidth * _numberOfVerticalTiles * _tileHeight;

        private const byte _colorIndexBlack = 0;
        private const byte _colorIndexBlue = 1;
        private const byte _colorIndexYellow = 2;
        private const byte _colorIndexWhite = 3;

        private byte[,] _bg = {{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                               {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                               {0x11, 0x11, 0x11, 0x32, 0x32, 0x32, 0x32, 0x11, 0x11, 0x11},
                               {0x12, 0x12, 0x12, 0x31, 0x31, 0x31, 0x31, 0x12, 0x12, 0x12},
                               {0x00, 0x14, 0x14, 0x14, 0x32, 0x32, 0x14, 0x14, 0x14, 0x00},
                               {0x00, 0x15, 0x15, 0x15, 0x32, 0x32, 0x15, 0x15, 0x15, 0x00},
                               {0x11, 0x11, 0x13, 0x13, 0x32, 0x32, 0x13, 0x13, 0x24, 0x24},
                               {0x12, 0x12, 0x14, 0x14, 0x15, 0x15, 0x16, 0x16, 0x16, 0x17}};
    }
}
