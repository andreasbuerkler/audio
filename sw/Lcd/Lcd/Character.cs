namespace Lcd
{
    class Character
    {

        public Character(byte[] byteArray, int width, int height)
        {
            _width = width;
            _height = height;
            _size = _height * _width;
            _byteArray = new byte[_size];

            if (byteArray.Length == _size) {
                _byteArray = byteArray;
            } else {
                for (int index = 0; index < _size; index++) {
                    _byteArray[index] = 0x00;
                }
            }
        }

        public byte GetLine(int posY, int posX)
        {
            int index = (posY * _width) + posX;
            if ((index >= 0) && (index < _size)) {
                return _byteArray[index];
            } else {
                return 0x00;
            }
        }

        private int _width;
        private int _height;
        private int _size;
        private byte[] _byteArray;

    }
}
