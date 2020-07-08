namespace Lcd
{
    class Character
    {

        public Character(byte[] byteArray)
        {
            if (byteArray.Length == _size) {
                _byteArray = byteArray;
            } else {
                for (int index = 0; index < _size; index++) {
                    _byteArray[index] = 0x00;
                }
            }
        }

        public byte GetLine(int index)
        {
            if ((index >= 0) && (index < _size)) {
                return _byteArray[index];
            } else {
                return 0x00;
            }
        }

        private const int _size = 15;
        private byte[] _byteArray = new byte[_size];

    }
}
