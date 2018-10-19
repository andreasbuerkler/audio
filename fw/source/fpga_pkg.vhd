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
    function reverse (n : std_logic_vector) return std_logic_vector;
    function vector_or (n : std_logic_vector) return std_logic;

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

    function reverse (n : std_logic_vector) return std_logic_vector is
        variable n_reverse : std_logic_vector(n'length-1 downto 0);
    begin
        for i in n'length-1 downto 0 loop
            n_reverse(i) := n(n'high-i);
        end loop;
        return n_reverse;
    end reverse;

    function vector_or (n : std_logic_vector) return std_logic is
        variable n_or : std_logic;
    begin
        n_or := '0';
        for i in n'high downto n'low loop
            n_or := n_or or n(i);
        end loop;
        return n_or;
    end vector_or;

end fpga_pkg;