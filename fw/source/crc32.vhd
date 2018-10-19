--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 13.10.2018
-- Filename  : crc32.vhd
-- Changelog : 13.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc32 is
port (
    clk_i        : in  std_logic;
    clear_i      : in  std_logic;
    data_valid_i : in  std_logic;
    data_i       : in  std_logic_vector(7 downto 0);
    crc_o        : out std_logic_vector(31 downto 0));
end entity crc32;

architecture rtl of crc32 is

    -- polynomial function: x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 + x8 + x7 + x5 + x4 + x2 + x + 1
    constant polynome_c : std_logic_vector(31 downto 0) := "00000100110000010001110110110111";

    signal crc_r : std_logic_vector(31 downto 0) := (others => '1');

begin

    crc_proc : process (clk_i)
        variable feedback_v : std_logic;
        variable crc_v      : std_logic_vector(31 downto 0);
    begin
        if (rising_edge(clk_i)) then
            if (clear_i = '1') then
                crc_r <= (others => '1');
            elsif (data_valid_i = '1') then
                crc_v := crc_r;
                for i in 0 to 7 loop
                    feedback_v := data_i(i) xor crc_v(crc_v'high);
                    for j in 31 downto 1 loop
                        if (polynome_c(j) = '1') then
                            crc_v(j) := crc_v(j-1) xor feedback_v;
                        else
                            crc_v(j) := crc_v(j-1);
                        end if;
                    end loop;
                    crc_v(0) := feedback_v;
                end loop;
                crc_r <= crc_v;
            end if;
        end if;
    end process crc_proc;

    crc_o <= crc_r;

end rtl;
