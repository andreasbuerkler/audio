using System;

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
                    bool top = (verticalIndex == 0) ? false : _bg[verticalIndex, horizontalIndex] == _bg[verticalIndex - 1, horizontalIndex];
                    bool bottom = (verticalIndex == _numberOfVerticalTiles - 1) ? false : _bg[verticalIndex, horizontalIndex] == _bg[verticalIndex + 1, horizontalIndex];
                    bool left = (horizontalIndex == 0) ? false : _bg[verticalIndex, horizontalIndex] == _bg[verticalIndex, horizontalIndex - 1];
                    bool right = (horizontalIndex == _numberOfHorizontalTiles - 1) ? false : _bg[verticalIndex, horizontalIndex] == _bg[verticalIndex, horizontalIndex + 1];

                    int color = _color[_bg[verticalIndex, horizontalIndex]];
                    AddTile(verticalIndex, horizontalIndex, top, bottom, left, right, color, ref background);
                }
            }
        }

        public void SetColor(int index, byte color)
        {
            if ((index < _color.Length) && (index >= 0))
            {
                _color[index] = color;
            }
        }

        private void AddTile(UInt32 verticalTileNr, UInt32 horizontalTileNr, bool top, bool bottom, bool left, bool right, int colorCode, ref UInt32[] background)
        {
            UInt32 color = Colors._black;
            UInt32 colorBright = Colors._black;
            UInt32 colorDark = Colors._black;
            switch (colorCode)
            {
                case Colors.ColorIndex.Blue:
                    color = Colors._blue;
                    colorBright = Colors._blueBright;
                    colorDark = Colors._blueDark;
                    break;
                case Colors.ColorIndex.Yellow:
                    color = Colors._yellow;
                    colorBright = Colors._yellowBright;
                    colorDark = Colors._yellowDark;
                    break;
                case Colors.ColorIndex.White:
                    color = Colors._black;
                    colorBright = Colors._white;
                    colorDark = Colors._grey;
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
                    background[verticalOffset * totalWidth + horizontalOffset] = Colors._black;
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
                    background[verticalOffset * totalWidth + horizontalOffset] = Colors._black;
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
                    background[verticalOffset * totalWidth + horizontalOffset] = Colors._black;
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
                    background[verticalOffset * totalWidth + horizontalOffset] = Colors._black;
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

        private const int _tileWidth = 32;
        private const int _tileHeight = 30;
        private const int _numberOfHorizontalTiles = 10;
        private const int _numberOfVerticalTiles = 8;
        private const int _bufferSize = _numberOfHorizontalTiles * _tileWidth * _numberOfVerticalTiles * _tileHeight;

        private byte[] _color = { Colors.ColorIndex.Black,  // 0x00
                                  Colors.ColorIndex.Blue,   // 0x01
                                  Colors.ColorIndex.White,  // 0x02
                                  Colors.ColorIndex.Blue,   // 0x03
                                  Colors.ColorIndex.Blue,   // 0x04
                                  Colors.ColorIndex.White,  // 0x05
                                  Colors.ColorIndex.Blue,   // 0x06
                                  Colors.ColorIndex.Blue,   // 0x07
                                  Colors.ColorIndex.Blue,   // 0x08
                                  Colors.ColorIndex.Blue,   // 0x09
                                  Colors.ColorIndex.Blue,   // 0x0A
                                  Colors.ColorIndex.Blue,   // 0x0B
                                  Colors.ColorIndex.Blue,   // 0x0C
                                  Colors.ColorIndex.Blue,   // 0x0D
                                  Colors.ColorIndex.Blue,   // 0x0E
                                  Colors.ColorIndex.Blue,   // 0x0F
                                  Colors.ColorIndex.Blue,   // 0x10
                                  Colors.ColorIndex.Blue,   // 0x11
                                  Colors.ColorIndex.Blue,   // 0x12
                                  Colors.ColorIndex.Blue,   // 0x13
                                  Colors.ColorIndex.White}; // 0x14

        private byte[,] _bg = {{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                               {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                               {0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03},
                               {0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06},
                               {0x00, 0x07, 0x07, 0x07, 0x14, 0x14, 0x08, 0x08, 0x08, 0x00},
                               {0x00, 0x09, 0x09, 0x09, 0x14, 0x14, 0x0A, 0x0A, 0x0A, 0x00},
                               {0x0B, 0x0B, 0x0C, 0x0C, 0x14, 0x14, 0x0D, 0x0D, 0x0E, 0x0E},
                               {0x0F, 0x0F, 0x10, 0x10, 0x11, 0x11, 0x12, 0x12, 0x12, 0x13}};

    }
}
