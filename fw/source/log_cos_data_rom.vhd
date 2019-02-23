--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 15.02.2019
-- Filename  : log_cos_data_rom.vhd
-- Changelog : 15.02.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity log_cos_data_rom is
generic (
    data_width_g : natural := 24);
port (
    clk_i     : in  std_logic;
    address_i : in  std_logic_vector(7 downto 0);
    data_o    : out std_logic_vector(data_width_g-1 downto 0));
end entity log_cos_data_rom;

architecture rtl of log_cos_data_rom is

    type lookup_array_t   is array (natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    function init_lookup_table_f
        return lookup_array_t is
        variable lookup_array_v : lookup_array_t(255 downto 0);
    begin
        -- first part is dB lookup table 0dB - 100dB in 0.5 dB steps
        for i in 0 to 199 loop
            lookup_array_v(i) := std_logic_vector(to_unsigned(integer(round((10.0**(real(-i)/40.0))*((2.0**(data_width_g-1))-1.0))), data_width_g));
        end loop;
        -- second part is cosinus lookup table
        for i in 200 to 255 loop
            lookup_array_v(i) := std_logic_vector(to_unsigned(integer(round((2.0-(1.0+cos(MATH_PI*real(i-200)/55.0 )))*((2.0**(data_width_g-2))-1.0))), data_width_g));
        end loop;
        return lookup_array_v;
    end init_lookup_table_f;

    constant lookup_db_c : lookup_array_t(255 downto 0) := init_lookup_table_f;

    signal lookup_value_r : std_logic_vector(data_width_g-1 downto 0) := lookup_db_c(0);

begin

    rom_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            lookup_value_r <= lookup_db_c(to_integer(unsigned(address_i)));
        end if;
    end process rom_proc;

    data_o <= lookup_value_r;

end rtl;
