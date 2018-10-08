--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : fpga_pkg.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fpga_pkg is
    function log2ceil (n : natural) return natural;

    constant ALL_ZEROS : std_logic_vector(1023 downto 0) := (others => '0');
    constant ALL_ONES  : std_logic_vector(1023 downto 0) := (others => '1');

end fpga_pkg;

package body fpga_pkg is

    function log2ceil (n : natural) return natural is
        variable n_bit : unsigned(31 downto 0);
    begin
        if n = 0 then
            return 0;
        end if;
        n_bit := to_unsigned(n-1,32);
        for i in 31 downto 0 loop
            if n_bit(i) = '1' then
                return i+1;
            end if;
        end loop;
        return 1;
    end log2ceil;

end fpga_pkg;