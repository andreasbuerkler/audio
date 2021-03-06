﻿using System;
using System.Collections.Generic;
using System.Text;

namespace Lcd
{
    class CharacterFactory
    {
        public void Build(out Dictionary<byte, Character> characterList)
        {
            characterList = new Dictionary<byte, Character>();
            characterList.Add(Encoding.UTF8.GetBytes(" ")[0], new Character(_character_,  _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("0")[0], new Character(_character_0, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("1")[0], new Character(_character_1, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("2")[0], new Character(_character_2, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("3")[0], new Character(_character_3, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("4")[0], new Character(_character_4, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("5")[0], new Character(_character_5, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("6")[0], new Character(_character_6, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("7")[0], new Character(_character_7, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("8")[0], new Character(_character_8, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("9")[0], new Character(_character_9, _characterWidth, _characterHeight));

            characterList.Add(Encoding.UTF8.GetBytes("a")[0], new Character(_character_a, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("b")[0], new Character(_character_b, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("c")[0], new Character(_character_c, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("d")[0], new Character(_character_d, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("e")[0], new Character(_character_e, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("f")[0], new Character(_character_f, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("g")[0], new Character(_character_g, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("h")[0], new Character(_character_h, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("i")[0], new Character(_character_i, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("j")[0], new Character(_character_j, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("k")[0], new Character(_character_k, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("l")[0], new Character(_character_l, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("m")[0], new Character(_character_m, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("n")[0], new Character(_character_n, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("o")[0], new Character(_character_o, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("p")[0], new Character(_character_p, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("q")[0], new Character(_character_q, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("r")[0], new Character(_character_r, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("s")[0], new Character(_character_s, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("t")[0], new Character(_character_t, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("u")[0], new Character(_character_u, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("v")[0], new Character(_character_v, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("w")[0], new Character(_character_w, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("x")[0], new Character(_character_x, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("y")[0], new Character(_character_y, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("z")[0], new Character(_character_z, _characterWidth, _characterHeight));

            characterList.Add(Encoding.UTF8.GetBytes("%")[0], new Character(_character_s0, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("°")[0], new Character(_character_s1, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes(":")[0], new Character(_character_s2, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes(".")[0], new Character(_character_s3, _characterWidth, _characterHeight));
            characterList.Add(Encoding.UTF8.GetBytes("-")[0], new Character(_character_s4, _characterWidth, _characterHeight));
        }

        // one bit for each pixel / one byte for each line
        // e.g. 7 is encoded as follows:
        //
        // 00000000 0x00
        // 01111110 0x7E
        // 00000110 0x06
        // 00001100 0x0C
        // 00001100 0x0C
        // 00011000 0x18
        // 00011000 0x18
        // 00011000 0x18
        // 00110000 0x30
        // 00110000 0x30
        // 00110000 0x30
        // 00000000 0x00
        // 00000000 0x00
        // 00000000 0x00
        // 00000000 0x00

        private const int _characterWidth = 1;
        private const int _characterHeight = 15;

        private Byte[] _character_  = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_0 = {0x00, 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_1 = {0x00, 0x18, 0x78, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_2 = {0x00, 0x3C, 0x66, 0x66, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x60, 0x7E, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_3 = {0x00, 0x3C, 0x66, 0x06, 0x06, 0x1C, 0x06, 0x06, 0x06, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_4 = {0x00, 0x06, 0x0E, 0x1E, 0x1E, 0x36, 0x36, 0x66, 0x7E, 0x06, 0x06, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_5 = {0x00, 0x7E, 0x60, 0x60, 0x60, 0x7C, 0x66, 0x06, 0x06, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_6 = {0x00, 0x3C, 0x66, 0x60, 0x60, 0x7C, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_7 = {0x00, 0x7E, 0x06, 0x0C, 0x0C, 0x18, 0x18, 0x18, 0x30, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_8 = {0x00, 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_9 = {0x00, 0x3C, 0x66, 0x66, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};

        private Byte[] _character_a = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x1E, 0x36, 0x66, 0x66, 0x3E, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_b = {0x00, 0x60, 0x60, 0x60, 0x7C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x7C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_c = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x60, 0x60, 0x60, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_d = {0x00, 0x06, 0x06, 0x06, 0x3E, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3E, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_e = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x7E, 0x60, 0x60, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_f = {0x00, 0x0C, 0x18, 0x18, 0x3C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_g = {0x00, 0x00, 0x00, 0x00, 0x3E, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3E, 0x06, 0x66, 0x3C, 0x00};
        private Byte[] _character_h = {0x00, 0x60, 0x60, 0x60, 0x7C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_i = {0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_j = {0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x30, 0x00};
        private Byte[] _character_k = {0x00, 0x60, 0x60, 0x60, 0x66, 0x6C, 0x78, 0x70, 0x78, 0x6C, 0x66, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_l = {0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_m = {0x00, 0x00, 0x00, 0x00, 0x7E, 0x5A, 0x5A, 0x5A, 0x5A, 0x5A, 0x5A, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_n = {0x00, 0x00, 0x00, 0x00, 0x7C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_o = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_p = {0x00, 0x00, 0x00, 0x00, 0x7C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x7C, 0x60, 0x60, 0x60, 0x00};
        private Byte[] _character_q = {0x00, 0x00, 0x00, 0x00, 0x3E, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x06, 0x00};
        private Byte[] _character_r = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x38, 0x30, 0x30, 0x30, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_s = {0x00, 0x00, 0x00, 0x00, 0x3C, 0x66, 0x60, 0x3C, 0x06, 0x66, 0x3C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_t = {0x00, 0x00, 0x18, 0x18, 0x3C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x0C, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_u = {0x00, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3E, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_v = {0x00, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_w = {0x00, 0x00, 0x00, 0x00, 0x42, 0x5A, 0x5A, 0x5A, 0x7E, 0x24, 0x24, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_x = {0x00, 0x00, 0x00, 0x00, 0x42, 0x66, 0x3C, 0x18, 0x3C, 0x66, 0x42, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_y = {0x00, 0x00, 0x00, 0x00, 0x42, 0x42, 0x66, 0x66, 0x3C, 0x3C, 0x18, 0x18, 0x30, 0x60, 0x00};
        private Byte[] _character_z = {0x00, 0x00, 0x00, 0x00, 0x7E, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x7E, 0x00, 0x00, 0x00, 0x00};

        private Byte[] _character_s0 = {0x00, 0x72, 0x56, 0x54, 0x58, 0x78, 0x1E, 0x1A, 0x2A, 0x6A, 0x4E, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_s1 = {0x00, 0x38, 0x28, 0x28, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_s2 = {0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_s3 = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
        private Byte[] _character_s4 = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    }
}
