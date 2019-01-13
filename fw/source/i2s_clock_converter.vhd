--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2s_clock_converter.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s_clock_converter is
generic (
    DATA_W : natural := 24);
port (
    in_clk_i      : in  std_logic;
    right_valid_i : in  std_logic;
    left_valid_i  : in  std_logic;
    data_i        : in  std_logic_vector(DATA_W-1 downto 0);
    out_clk_i     : in  std_logic;
    right_valid_o : out std_logic;
    left_valid_o  : out std_logic;
    data_o        : out std_logic_vector(DATA_W-1 downto 0));
end entity i2s_clock_converter;

architecture rtl of i2s_clock_converter is

    signal data_r              : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal left_r              : std_logic := '0';
    signal right_r             : std_logic := '0';
    signal valid_toggle_r      : std_logic := '0';

    signal valid_toggle_vec_r  : std_logic_vector(2 downto 0) := (others => '0');
    signal valid_toggle_copy_r : std_logic := '0';
    signal valid_copy_r        : std_logic := '0';

    signal data_out_r          : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal left_valid_r        : std_logic := '0';
    signal right_valid_r       : std_logic := '0';

begin

    in_proc : process (in_clk_i)
    begin
        if (rising_edge(in_clk_i)) then
            if ((right_valid_i = '1') or (left_valid_i = '1')) then
                data_r <= data_i;
                left_r <= left_valid_i;
                right_r <= right_valid_i;
                valid_toggle_r <= not valid_toggle_r;
            end if;
        end if;
    end process in_proc;

    sync_proc : process (out_clk_i)
    begin
        if (rising_edge(out_clk_i)) then
            valid_toggle_vec_r <= valid_toggle_vec_r(valid_toggle_vec_r'high-1 downto 0) & valid_toggle_r;
            valid_toggle_copy_r <= valid_toggle_vec_r(valid_toggle_vec_r'high);
            valid_copy_r <= valid_toggle_copy_r xor valid_toggle_vec_r(valid_toggle_vec_r'high);
        end if;
    end process sync_proc;

    out_proc : process (out_clk_i)
    begin
        if (rising_edge(out_clk_i)) then
            if (valid_copy_r = '1') then
                data_out_r <= data_r;
                left_valid_r <= left_r;
                right_valid_r <= right_r;
            else
                left_valid_r <= '0';
                right_valid_r <= '0';
            end if;
        end if;
    end process out_proc;  

    right_valid_o <= right_valid_r;
    left_valid_o  <= left_valid_r;
    data_o        <= data_out_r;

end rtl;