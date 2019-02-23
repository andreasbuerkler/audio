--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : clock_converter.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity clock_converter is
generic (
    data_width_g : natural := 24;
    channels_g   : natural := 2);
port (
    in_clk_i      : in  std_logic;
    valid_i       : in  std_logic_vector(channels_g-1 downto 0);
    data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    out_clk_i     : in  std_logic;
    valid_o       : out std_logic_vector(channels_g-1 downto 0);
    data_o        : out std_logic_vector(data_width_g-1 downto 0));
end entity clock_converter;

architecture rtl of clock_converter is

    signal data_r              : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal channel_r           : std_logic_vector(channels_g-1 downto 0);
    signal valid_toggle_r      : std_logic := '0';

    signal valid_toggle_vec_r  : std_logic_vector(2 downto 0) := (others => '0');
    signal valid_toggle_copy_r : std_logic := '0';
    signal valid_copy_r        : std_logic := '0';

    signal data_out_r          : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal valid_r             : std_logic_vector(channels_g-1 downto 0) := (others => '0');

begin

    in_proc : process (in_clk_i)
    begin
        if (rising_edge(in_clk_i)) then
            if (vector_or(valid_i) = '1') then
                data_r <= data_i;
                channel_r <= valid_i;
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
                valid_r <= channel_r;
            else
                valid_r <= (others => '0');
            end if;
        end if;
    end process out_proc;  

    valid_o <= valid_r;
    data_o <= data_out_r;

end rtl;