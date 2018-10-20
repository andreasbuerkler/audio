--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 20.10.2018
-- Filename  : eth_padder.vhd
-- Changelog : 20.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_padder is
port (
    clk_i        : in  std_logic;
    data_valid_i : in  std_logic;
    data_ready_o : out std_logic;
    last_i       : in  std_logic;
    data_i       : in  std_logic_vector(7 downto 0);
    data_valid_o : out std_logic;
    data_ready_i : in  std_logic;
    last_o       : out std_logic;
    data_o       : out std_logic_vector(7 downto 0));
end entity eth_padder;

architecture rtl of eth_padder is

    constant min_frame_size_c : natural := 60; -- without fcs

    signal length_counter_r : unsigned(log2ceil(min_frame_size_c)-1 downto 0) := (others => '0');
    signal padding_en_r     : std_logic := '0';
    signal last_en_r        : std_logic := '0';
    signal padding_last_r   : std_logic := '0';

begin

    padder_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((data_valid_i = '1') or (padding_en_r = '1')) and (data_ready_i = '1') then
                if ((last_i = '1') and (padding_en_r = '0')) then
                    if (length_counter_r /= to_unsigned(min_frame_size_c-1, length_counter_r'length)) then
                        length_counter_r <= length_counter_r + 1;
                        padding_en_r <= '1';
                    else
                        length_counter_r <= (others => '0');
                    end if;
                    last_en_r <= '0';
                elsif (length_counter_r = to_unsigned(min_frame_size_c-2, length_counter_r'length)) then
                    length_counter_r <= length_counter_r + 1;
                    last_en_r <= '1';
                    padding_last_r <= padding_en_r;
                elsif (length_counter_r /= to_unsigned(min_frame_size_c-1, length_counter_r'length)) then
                    length_counter_r <= length_counter_r + 1;
                else
                    padding_en_r <= '0';
                    padding_last_r <= '0';
                    if (padding_en_r = '1') then
                        last_en_r <= '0';
                        length_counter_r <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process padder_proc;

    data_valid_o <= data_valid_i or padding_en_r;
    last_o <= (last_i and last_en_r) or padding_last_r;
    data_o <= data_i when (padding_en_r = '0') else x"00";
    data_ready_o <= data_ready_i and (not padding_en_r);

end rtl;
