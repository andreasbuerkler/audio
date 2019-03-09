--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 24.02.2019
-- Filename  : step_response_pkg.vhd
-- Changelog : 24.02.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

package step_response_pkg is

    constant step_response_c : std_logic_array(511 downto 0, 23 downto 0) := (
        0   => x"060FCD", 
        1   => x"11FDA5", 
        2   => x"1A4F17", 
        3   => x"1D13E4", 
        4   => x"1C2DF2", 
        5   => x"13F046", 
        6   => x"073DD5", 
        7   => x"FD1982", 
        8   => x"F5CBB1", 
        9   => x"F2B04B", 
        10  => x"F65138", 
        11  => x"FCF2C3", 
        12  => x"01B24F", 
        13  => x"04FB2C", 
        14  => x"0732B9", 
        15  => x"06BE7F", 
        16  => x"044E82", 
        17  => x"02AB33", 
        18  => x"029E98", 
        19  => x"035DBD", 
        20  => x"04A7AA", 
        21  => x"05C645", 
        22  => x"054D8B", 
        23  => x"03D483", 
        24  => x"023402", 
        25  => x"00C34B", 
        26  => x"0064C7", 
        27  => x"00C867", 
        28  => x"01C1B1", 
        29  => x"02C792", 
        30  => x"0299EA", 
        31  => x"0100A9", 
        32  => x"003720", 
        33  => x"006186", 
        34  => x"FFDFFA", 
        35  => x"FF4D94", 
        36  => x"0001E4", 
        37  => x"0134F6", 
        38  => x"01EF01", 
        39  => x"02B713", 
        40  => x"036DAB", 
        41  => x"0397F9", 
        42  => x"02FD0B", 
        43  => x"01C0F1", 
        44  => x"009144", 
        45  => x"003664", 
        46  => x"FFF56D", 
        47  => x"FF6157", 
        48  => x"FF2DCA", 
        49  => x"FF0476", 
        50  => x"FECDBA", 
        51  => x"FEFC81", 
        52  => x"FF6390", 
        53  => x"00061F", 
        54  => x"00C9DF", 
        55  => x"0141B6", 
        56  => x"01777F", 
        57  => x"016E2B", 
        58  => x"010C5F", 
        59  => x"0070DC", 
        60  => x"001DF6", 
        61  => x"FFD807", 
        62  => x"FF7667", 
        63  => x"FF3338", 
        64  => x"FECA60", 
        65  => x"FE1CC1", 
        66  => x"FDB003", 
        67  => x"FDDCC1", 
        68  => x"FE9BB9", 
        69  => x"FF9B46", 
        70  => x"0068E5", 
        71  => x"00A1F7", 
        72  => x"0082CD", 
        73  => x"00445C", 
        74  => x"FFA400", 
        75  => x"FECDFC", 
        76  => x"FE0D32", 
        77  => x"FD82B9", 
        78  => x"FD7A2D", 
        79  => x"FDDC8A", 
        80  => x"FE9FA3", 
        81  => x"FF8159", 
        82  => x"000AA4", 
        83  => x"002124", 
        84  => x"FFE62D", 
        85  => x"FFA7A4", 
        86  => x"FF6E17", 
        87  => x"FF0CC9", 
        88  => x"FEA3CD", 
        89  => x"FE2699", 
        90  => x"FD567B", 
        91  => x"FC4C85", 
        92  => x"FB8569", 
        93  => x"FB2AF4", 
        94  => x"FB39CA", 
        95  => x"FBD06D", 
        96  => x"FCB891", 
        97  => x"FD88C2", 
        98  => x"FE6A10", 
        99  => x"FF5212", 
        100 => x"FFDFBC", 
        101 => x"FFF4BD", 
        102 => x"FFC55C", 
        103 => x"FF616D", 
        104 => x"FF18A8", 
        105 => x"FF2E0B", 
        106 => x"FF6FC0", 
        107 => x"FFAF90", 
        108 => x"FFDF97", 
        109 => x"FFABA3", 
        110 => x"FEEF4F", 
        111 => x"FDE4C8", 
        112 => x"FCE1F0", 
        113 => x"FC31D7", 
        114 => x"FBE4F3", 
        115 => x"FBF9B6", 
        116 => x"FC7F41", 
        117 => x"FD743A", 
        118 => x"FEA2EE", 
        119 => x"FFC02C", 
        120 => x"0078EE", 
        121 => x"0089C6", 
        122 => x"0023C8", 
        123 => x"FF813B", 
        124 => x"FEC5B4", 
        125 => x"FE2527", 
        126 => x"FDC297", 
        127 => x"FD9ACD", 
        128 => x"FDB0EE", 
        129 => x"FDD821", 
        130 => x"FDF9BF", 
        131 => x"FE07BE", 
        132 => x"FE0BCE", 
        133 => x"FDFBC3", 
        134 => x"FDE663", 
        135 => x"FDFD12", 
        136 => x"FE405E", 
        137 => x"FE951D", 
        138 => x"FEF993", 
        139 => x"FF4F8C", 
        140 => x"FF752F", 
        141 => x"FF50E0", 
        142 => x"FEF7FE", 
        143 => x"FE874B", 
        144 => x"FE26B8", 
        145 => x"FDF8A2", 
        146 => x"FDE6FA", 
        147 => x"FDD2E7", 
        148 => x"FDC91B", 
        149 => x"FDBB83", 
        150 => x"FD9A07", 
        151 => x"FD81FB", 
        152 => x"FD885E", 
        153 => x"FD8E41", 
        154 => x"FD942D", 
        155 => x"FDAE41", 
        156 => x"FDD698", 
        157 => x"FDFD01", 
        158 => x"FE1C25", 
        159 => x"FE1AA2", 
        160 => x"FDF8FF", 
        161 => x"FDD302", 
        162 => x"FDB65E", 
        163 => x"FD94BF", 
        164 => x"FD8276", 
        165 => x"FD7FCB", 
        166 => x"FD7EC6", 
        167 => x"FD8BA2", 
        168 => x"FDB71C", 
        169 => x"FDDE31", 
        170 => x"FDF6E7", 
        171 => x"FE13C7", 
        172 => x"FE4010", 
        173 => x"FE7254", 
        174 => x"FEA3BF", 
        175 => x"FEC154", 
        176 => x"FECAFF", 
        177 => x"FEC6B2", 
        178 => x"FEC504", 
        179 => x"FEBE9A", 
        180 => x"FEC2BA", 
        181 => x"FEDF32", 
        182 => x"FF0881", 
        183 => x"FF39BF", 
        184 => x"FF70F7", 
        185 => x"FF951F", 
        186 => x"FF9D5D", 
        187 => x"FF8A17", 
        188 => x"FF66B2", 
        189 => x"FF3FCE", 
        190 => x"FF1BA6", 
        191 => x"FEFDB2", 
        192 => x"FEF3E9", 
        193 => x"FEF72D", 
        194 => x"FEFD31", 
        195 => x"FEEF7A", 
        196 => x"FEC695", 
        197 => x"FE8C9D", 
        198 => x"FE6304", 
        199 => x"FE5DEA", 
        200 => x"FE80DC", 
        201 => x"FEB47E", 
        202 => x"FEE98F", 
        203 => x"FF1521", 
        204 => x"FF38A2", 
        205 => x"FF5369", 
        206 => x"FF679E", 
        207 => x"FF754A", 
        208 => x"FF839E", 
        209 => x"FF8754", 
        210 => x"FF83B8", 
        211 => x"FF7E6A", 
        212 => x"FF72BB", 
        213 => x"FF5BA5", 
        214 => x"FF4B55", 
        215 => x"FF49C2", 
        216 => x"FF5CDD", 
        217 => x"FF7CCF", 
        218 => x"FF9C47", 
        219 => x"FFB058", 
        220 => x"FFB6B0", 
        221 => x"FFB0C6", 
        222 => x"FFAD88", 
        223 => x"FFA9AD", 
        224 => x"FF9CA9", 
        225 => x"FF8524", 
        226 => x"FF71EE", 
        227 => x"FF681C", 
        228 => x"FF6BC8", 
        229 => x"FF793D", 
        230 => x"FF8EBF", 
        231 => x"FFA2E6", 
        232 => x"FFB99A", 
        233 => x"FFCAF7", 
        234 => x"FFC785", 
        235 => x"FFA599", 
        236 => x"FF7A8B", 
        237 => x"FF54CA", 
        238 => x"FF42AD", 
        239 => x"FF4616", 
        240 => x"FF54BA", 
        241 => x"FF66C3", 
        242 => x"FF7D51", 
        243 => x"FF8E70", 
        244 => x"FF9EE5", 
        245 => x"FFB182", 
        246 => x"FFC413", 
        247 => x"FFD357", 
        248 => x"FFED13", 
        249 => x"001792", 
        250 => x"004E18", 
        251 => x"007D5A", 
        252 => x"009AE9", 
        253 => x"009EB0", 
        254 => x"009A29", 
        255 => x"00998A", 
        256 => x"0099D0", 
        257 => x"0093B2", 
        258 => x"008FFC", 
        259 => x"0093CE", 
        260 => x"00AAD0", 
        261 => x"00D62D", 
        262 => x"0105FF", 
        263 => x"011D30", 
        264 => x"0118BF", 
        265 => x"010A03", 
        266 => x"01030E", 
        267 => x"00FEEE", 
        268 => x"00F405", 
        269 => x"00D57D", 
        270 => x"00AB9F", 
        271 => x"00854B", 
        272 => x"00733C", 
        273 => x"0078BC", 
        274 => x"0092B8", 
        275 => x"00B001", 
        276 => x"00CBED", 
        277 => x"00E9F6", 
        278 => x"0109A4", 
        279 => x"0120A3", 
        280 => x"0126A4", 
        281 => x"0114F3", 
        282 => x"00FB82", 
        283 => x"00E795", 
        284 => x"00E0C6", 
        285 => x"00DBC1", 
        286 => x"00CF3B", 
        287 => x"00BB71", 
        288 => x"00AA18", 
        289 => x"009C3D", 
        290 => x"009A46", 
        291 => x"00A0CD", 
        292 => x"00A2F1", 
        293 => x"009B0A", 
        294 => x"0099AE", 
        295 => x"00A399", 
        296 => x"00B76C", 
        297 => x"00CCCA", 
        298 => x"00E499", 
        299 => x"00F65F", 
        300 => x"00F7FB", 
        301 => x"00E433", 
        302 => x"00C581", 
        303 => x"00A57B", 
        304 => x"0093A0", 
        305 => x"008FFB", 
        306 => x"0096F1", 
        307 => x"00A27F", 
        308 => x"00B24E", 
        309 => x"00C6A2", 
        310 => x"00E3BF", 
        311 => x"00FFCE", 
        312 => x"011A53", 
        313 => x"0134C3", 
        314 => x"014ABD", 
        315 => x"015107", 
        316 => x"0144FF", 
        317 => x"012391", 
        318 => x"00FC4B", 
        319 => x"00DBAF", 
        320 => x"00D343", 
        321 => x"00F067", 
        322 => x"0123E1", 
        323 => x"014598", 
        324 => x"0143C2", 
        325 => x"012537", 
        326 => x"010588", 
        327 => x"00F3E0", 
        328 => x"00ECFA", 
        329 => x"00EA03", 
        330 => x"00ECED", 
        331 => x"00EF3A", 
        332 => x"00F2F7", 
        333 => x"00F43A", 
        334 => x"00F556", 
        335 => x"00F8CA", 
        336 => x"0103BD", 
        337 => x"0119D7", 
        338 => x"014009", 
        339 => x"016D6D", 
        340 => x"0195F9", 
        341 => x"01A2B8", 
        342 => x"019308", 
        343 => x"017643", 
        344 => x"01625D", 
        345 => x"015DFC", 
        346 => x"0165E7", 
        347 => x"016EC9", 
        348 => x"01746A", 
        349 => x"016F33", 
        350 => x"015F57", 
        351 => x"01448D", 
        352 => x"0125B4", 
        353 => x"0107B3", 
        354 => x"00F4E7", 
        355 => x"00EB96", 
        356 => x"00E9D6", 
        357 => x"00EFA3", 
        358 => x"00FD62", 
        359 => x"010A15", 
        360 => x"011126", 
        361 => x"011865", 
        362 => x"012C59", 
        363 => x"0140F4", 
        364 => x"0146A5", 
        365 => x"01369E", 
        366 => x"011548", 
        367 => x"00E858", 
        368 => x"00BA90", 
        369 => x"0094ED", 
        370 => x"00828B", 
        371 => x"00802C", 
        372 => x"00861A", 
        373 => x"008B54", 
        374 => x"009666", 
        375 => x"00AC38", 
        376 => x"00C7FA", 
        377 => x"00D839", 
        378 => x"00DC30", 
        379 => x"00DB51", 
        380 => x"00DFF4", 
        381 => x"00E825", 
        382 => x"00F452", 
        383 => x"0103AE", 
        384 => x"0118B8", 
        385 => x"012B83", 
        386 => x"013DF8", 
        387 => x"014E91", 
        388 => x"01555B", 
        389 => x"014809", 
        390 => x"012EFC", 
        391 => x"011864", 
        392 => x"0112D7", 
        393 => x"011F2F", 
        394 => x"0133AA", 
        395 => x"013B9E", 
        396 => x"012FD0", 
        397 => x"01166D", 
        398 => x"00FD67", 
        399 => x"00E682", 
        400 => x"00D34B", 
        401 => x"00C50E", 
        402 => x"00BEC2", 
        403 => x"00BFD0", 
        404 => x"00CFBA", 
        405 => x"00E622", 
        406 => x"00F7D7", 
        407 => x"00FDFC", 
        408 => x"00FB97", 
        409 => x"00F55E", 
        410 => x"00F464", 
        411 => x"00F7BF", 
        412 => x"00FAB5", 
        413 => x"00F608", 
        414 => x"00E906", 
        415 => x"00CF35", 
        416 => x"00B464", 
        417 => x"00A418", 
        418 => x"00A08F", 
        419 => x"00A3D8", 
        420 => x"00A934", 
        421 => x"00AEBF", 
        422 => x"00B76F", 
        423 => x"00BF43", 
        424 => x"00C85F", 
        425 => x"00D13A", 
        426 => x"00D6FE", 
        427 => x"00D746", 
        428 => x"00D863", 
        429 => x"00DCE8", 
        430 => x"00E92D", 
        431 => x"00F664", 
        432 => x"00FEFC", 
        433 => x"00FDD9", 
        434 => x"00F275", 
        435 => x"00D8A8", 
        436 => x"00B349", 
        437 => x"008ADF", 
        438 => x"006EB4", 
        439 => x"0062C3", 
        440 => x"006459", 
        441 => x"006ABF", 
        442 => x"007539", 
        443 => x"008588", 
        444 => x"009648", 
        445 => x"009AD1", 
        446 => x"009830", 
        447 => x"009755", 
        448 => x"009E92", 
        449 => x"00A948", 
        450 => x"00B815", 
        451 => x"00C8C6", 
        452 => x"00D2D5", 
        453 => x"00D0B2", 
        454 => x"00CD4A", 
        455 => x"00CCDD", 
        456 => x"00CBF8", 
        457 => x"00C3CA", 
        458 => x"00B3F4", 
        459 => x"0096D3",
        others => x"000000");

end step_response_pkg;
