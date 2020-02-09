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

    type std_logic_array_24 is array (natural range <>) of std_logic_vector(23 downto 0);
    type std_logic_array_32 is array (natural range <>) of std_logic_vector(31 downto 0);
    type std_logic_array    is array (natural range <>, natural range <>) of std_logic;

    function log2ceil (n : natural) return natural;
    function reverse (n : std_logic_vector) return std_logic_vector;
    function vector_or (n : std_logic_vector) return std_logic;
    function vector_and (n : std_logic_vector) return std_logic;
    function checksum_add (n, u : std_logic_vector) return std_logic_vector;
    function resize_left_aligned (n : unsigned; u : positive) return unsigned;
    function resize_left_aligned (n : signed; u : positive) return signed;
    function array_extract(index : natural; in_array : std_logic_array) return std_logic_vector;
    function bin_to_gray (b : unsigned) return unsigned;
    function gray_to_bin (b : unsigned) return unsigned;

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

    function vector_and (n : std_logic_vector) return std_logic is
        variable n_and : std_logic;
    begin
        n_and := '1';
        for i in n'high downto n'low loop
            n_and := n_and and n(i);
        end loop;
        return n_and;
    end vector_and;

    function checksum_add (n, u : std_logic_vector) return std_logic_vector is
        variable n_sum  : unsigned((n'length+u'length)-1 downto 0);
        variable retval : unsigned(n'range);
    begin
        n_sum := resize(unsigned(n), n_sum'length);
        n_sum := n_sum + resize(unsigned(u), n_sum'length);
        retval := n_sum(n'length-1 downto 0) + resize(n_sum(n_sum'high downto n'length), retval'length);
        return std_logic_vector(retval);
    end checksum_add;

    function resize_left_aligned (n : unsigned; u : positive) return unsigned is
        variable retval : unsigned(u-1 downto 0);
    begin
        if (n'length > u) then
            for i in 0 to u-1 loop
                retval(i) := n((n'length-u)+i);
            end loop;
        else
            retval := n & to_unsigned(0, u-n'length);
        end if;
        return retval;
    end resize_left_aligned;

    function resize_left_aligned (n : signed; u : positive) return signed is
        variable retval : signed(u-1 downto 0);
    begin
        if (n'length > u) then
            for i in 0 to u-1 loop
                retval(i) := n((n'length-u)+i);
            end loop;
        else
            retval := n & to_signed(0, u-n'length);
        end if;
        return retval;
    end resize_left_aligned;

    function array_extract(index : natural; in_array : std_logic_array) return std_logic_vector is
        variable out_vector_v : std_logic_vector(in_array'range(2));
    begin
        for i in out_vector_v'range loop
            out_vector_v(i) := in_array(index, i);
        end loop;
        return out_vector_v;
    end function array_extract;

    function bin_to_gray (b : unsigned) return unsigned is
        variable retval : unsigned(b'range);
    begin
        for i in b'high downto b'low loop
            if (i = b'high) then
                retval(i) := b(i);
            else
                retval(i) := b(i) xor b(i+1);
            end if;
        end loop;
        return retval;
    end bin_to_gray;

    function gray_to_bin (b : unsigned) return unsigned is
        variable retval : unsigned(b'range);
    begin
        for i in b'high downto b'low loop
            if (i = b'high) then
                retval(i) := b(i);
            else
                retval(i) := b(i) xor retval(i+1);
            end if;
        end loop;
        return retval;
    end gray_to_bin;

end fpga_pkg;
