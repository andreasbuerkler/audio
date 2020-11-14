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
                pixel = Colors._grey;
                return true;
            }
            if ((posY == 1) || (posY == _totalHeight - 2) || (posX == 1) || (posX == _totalWidth - 2) || ((posX % 40) == 0))
            {
                pixel = Colors._white;
                return true;
            }
            int barRight = _speed * _totalWidth / _maxSpeed;
            if (posX > barRight)
            {
                pixel = Colors._black;
            }
            else
            {
                if (_speed > 7500) {
                    pixel = Colors._red;
                }
                else if (_speed > 7000) {
                    pixel = Colors._yellow;
                }
                else {
                    pixel = Colors._blueBright;
                }
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

        private const int _totalWidth = 320;
        private const int _totalHeight = 45;
        private const int _minSpeed = 0;
        private const int _maxSpeed = 8000;
        private int _speed = 0;
    }
}
