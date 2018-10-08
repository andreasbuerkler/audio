--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : biquad_mult.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity biquad_mult is
generic (
    DATA_W : natural := 24);
port (
    clk_i      : in  std_logic;
    data_a_i   : in  std_logic_vector(DATA_W-1 downto 0);
    data_b_i   : in  std_logic_vector(DATA_W-1 downto 0);
    data_o     : out std_logic_vector(2*DATA_W-1 downto 0));
end entity biquad_mult;

architecture rtl of biquad_mult is

    signal data_r     : std_logic_vector(2*DATA_W-1 downto 0) := (others => '0');

begin

    mult_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            data_r <= std_logic_vector(signed(data_a_i) * signed(data_b_i));
        end if;
    end process mult_proc;

    data_o <= data_r;

end rtl;