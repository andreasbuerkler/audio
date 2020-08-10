using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    class TextDisplay
    {
        public TextDisplay()
        {
            CharacterFactory characterFactory = new CharacterFactory();
            characterFactory.Build(out _characterList);
            ClearText();
        }

        public bool SetText(string text, int posY, int posX)
        {
            byte[] convertedText = Encoding.UTF8.GetBytes(text);
            int length = convertedText.Length;
            if ((posX < 0) || (posX+length >= _lengthX) || (posY >= _lengthY) || (posY < 0)) {
                return false;
            }
            int offset = 0;
            for (int index=0; index < length; index++) {
                _textArray[posY, posX + index - offset] = convertedText[index];
                // workaround for characters using 2 bytes
                if (convertedText[index] > 0x80)
                {
                    index++;
                    offset++;
                }
            }
            return true;
        }

        public void ClearText()
        {
            string clearCharacter = " ";
            for (int y = 0; y < _lengthY; y++) {
                for (int x = 0; x < _lengthX; x++) {
                    _textArray[y, x] = Encoding.UTF8.GetBytes(clearCharacter)[0];
                }
            }
        }

        public bool GetPixel(int posY, int posX, out bool pixel)
        {
            posY += _verticalPixelOffset;
            if ((posX < 0) || (posY < 0) || (posX >= _horizontalPixelSize) || (posY >= _verticalPixelSize)) {
                pixel = false;
                return false;
            }
            int characterX = posX / _characterWidth;
            int characterY = posY / _characterHeight;
            int offsetX = (_characterWidth-1) - (posX % _characterWidth);
            int offsetY = posY % _characterHeight;
            Character character;
            if (_characterList.TryGetValue(_textArray[characterY, characterX], out character)) {
                byte line = character.GetLine(offsetY, 0);
                pixel = (((line >> offsetX) & 0x01) == 0x01);
                return true;
            } else {
                pixel = false;
                return false;
            }
        }

        private Dictionary<byte, Character> _characterList;
        private const int _verticalPixelOffset = 7;
        private const int _verticalPixelSize = 240;
        private const int _horizontalPixelSize = 320;
        private const int _characterHeight = 15;
        private const int _characterWidth = 8;
        private const int _lengthX = _horizontalPixelSize/ _characterWidth;
        private const int _lengthY = _verticalPixelSize/ _characterHeight;
        private byte[,] _textArray = new byte[_lengthY, _lengthX];

    }
}
