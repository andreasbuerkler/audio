using System;

namespace Lcd
{
    class SpeedBar
    {
        public bool GetPixel(int posY, int posX, out UInt32 pixel)
        {
            if ((posY < 0) || (posY >= _totalHeight) || (posX < 0) || (posX >= _totalWidth))
            {
                pixel = 0;
                return false;
            }
            if ((posY == 0) || (posY == _totalHeight - 1) || (posX == 0) || (posX == _totalWidth - 1))
            {
                pixel = _colorGrey;
                return true;
            }
            if ((posY == 1) || (posY == _totalHeight - 2) || (posX == 1) || (posX == _totalWidth - 2) || ((posX % 40) == 0))
            {
                pixel = _colorWhite;
                return true;
            }
            int barRight = _speed * _totalWidth / _maxSpeed;
            if (posX > barRight)
            {
                pixel = _colorBlack;
            }
            else
            {
                pixel = _colorBlueBright;
            }
            return true;
        }

        public void SetSpeed(int speed)
        {
            if (speed > _maxSpeed)
            {
                _speed = _maxSpeed;
            }
            else if (speed < _minSpeed)
            {
                _speed = _minSpeed;
            }
            else
            {
                _speed = speed;
            }
        }

        private const UInt32 _colorBlack = 0x000;
        private const UInt32 _colorGrey = 0xCCC;
        private const UInt32 _colorWhite = 0xFFF;
        private const UInt32 _colorBlueBright = 0x79C;
        private const int _totalWidth = 320;
        private const int _totalHeight = 45;
        private const int _minSpeed = 0;
        private const int _maxSpeed = 8000;
        private int _speed = 0;
    }
}
