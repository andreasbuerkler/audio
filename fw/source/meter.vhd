--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : meter.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity meter is
generic (
    INTERFACE_DATA_W : natural := 24);
port (
    clk_i         : in  std_logic;
    left_valid_i  : in  std_logic;
    right_valid_i : in  std_logic;
    data_i        : in  std_logic_vector(INTERFACE_DATA_W-1 downto 0);
    data_read_l_i : in  std_logic;
    data_read_r_i : in  std_logic;
    level_l_o     : out std_logic_vector(7 downto 0);
    level_r_o     : out std_logic_vector(7 downto 0));
end entity meter;

architecture rtl of meter is

    type level_array_t   is array (natural range <>) of unsigned(INTERFACE_DATA_W-1 downto 0);

    function init_db_table_f
        return level_array_t is
        variable db_array_v : level_array_t(255 downto 0);
    begin
        for i in 0 to 255 loop
            -- 0.5 db steps
            db_array_v(i) := to_unsigned(integer(round((10.0**(real(-i)/40.0))*((2.0**(INTERFACE_DATA_W-1))-1.0))), INTERFACE_DATA_W);
        end loop;
        return db_array_v;
    end init_db_table_f;

    constant lookup_db_c : level_array_t(255 downto 0) := init_db_table_f;

    signal data_in_abs_r  : signed(INTERFACE_DATA_W-1 downto 0) := (others => '0');
    signal data_in_abs_l_valid_r : std_logic := '0';
    signal data_in_abs_r_valid_r : std_logic := '0';

    signal left_max_r       : unsigned(INTERFACE_DATA_W-1 downto 0) := (others => '0');
    signal right_max_r      : unsigned(INTERFACE_DATA_W-1 downto 0) := (others => '0');
    signal lookup_address_r : unsigned(7 downto 0) := (others => '0');
    signal compare_value_r  : unsigned(INTERFACE_DATA_W-1 downto 0) := (others => '0');
    signal compare_level_r  : unsigned(7 downto 0) := (others => '0');
    signal level_l_r        : unsigned(7 downto 0) := (others => '0');
    signal level_r_r        : unsigned(7 downto 0) := (others => '0');
    signal level_out_l_r    : unsigned(7 downto 0) := (others => '0');
    signal level_out_r_r    : unsigned(7 downto 0) := (others => '0');

begin

    abs_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (data_i(data_i'high) = '1') then
                data_in_abs_r <= - signed(data_i);
            else
                data_in_abs_r <= signed(data_i);
            end if;
            data_in_abs_l_valid_r <= left_valid_i;
            data_in_abs_r_valid_r <= right_valid_i;
        end if;
    end process abs_proc;

    input_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
        
            if (data_read_l_i = '1') then
                left_max_r <= (others => '0');
            elsif (data_in_abs_l_valid_r = '1') then
                if (signed(std_logic_vector(left_max_r)) < data_in_abs_r) then
                    left_max_r <= unsigned(std_logic_vector(data_in_abs_r));
                end if;
            end if;
            
            if (data_read_r_i = '1') then
                right_max_r <= (others => '0');
            elsif (data_in_abs_r_valid_r = '1') then
                if (signed(std_logic_vector(right_max_r)) < data_in_abs_r) then
                    right_max_r <= unsigned(std_logic_vector(data_in_abs_r));
                end if;
            end if;

        end if;
    end process input_proc;

    rom_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            compare_value_r <= lookup_db_c(to_integer(lookup_address_r));
            compare_level_r <= lookup_address_r;
        end if;
    end process rom_proc;
    
    compare_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            lookup_address_r <= lookup_address_r + 1;
            if (compare_level_r = to_unsigned(255, compare_level_r'length)) then
                level_l_r <= (others => '0');
                level_r_r <= (others => '0');
                level_out_l_r <= level_l_r;
                level_out_r_r <= level_r_r;
            else
                if (compare_value_r > left_max_r) then
                    level_l_r <= compare_level_r;
                end if;
                if (compare_value_r > right_max_r) then
                    level_r_r <= compare_level_r;
                end if;
            end if;
        
        end if;
    end process compare_proc;

    level_l_o <= std_logic_vector(level_out_l_r);
    level_r_o <= std_logic_vector(level_out_r_r);

end rtl;
