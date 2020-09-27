using System;

namespace Lcd
{
    public static class Colors
    {
        public readonly struct ColorIndex
        {
            public const byte Black = 0;
            public const byte Blue = 1;
            public const byte Yellow = 2;
            public const byte White = 3;
        }

        public const UInt32 _black = 0x000;
        public const UInt32 _grey = 0xCCC;
        public const UInt32 _white = 0xFFF;

        public const UInt32 _blue = 0x58A;
        public const UInt32 _blueDark = 0x456;
        public const UInt32 _blueBright = 0x79C;

        public const UInt32 _yellow = 0xCB6;
        public const UInt32 _yellowDark = 0x663;
        public const UInt32 _yellowBright = 0x985;

        public const UInt32 _green = 0x0F0;
    }
}
