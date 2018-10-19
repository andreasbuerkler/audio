--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 16.10.2018
-- Filename  : eth_fcs.vhd
-- Changelog : 16.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_fcs is
port (
    clk_i              : in  std_logic;
    -- rx data
    rx_valid_i         : in  std_logic;
    rx_data_i          : in  std_logic_vector(7 downto 0);
    rx_valid_o         : out std_logic;
    rx_data_o          : out std_logic_vector(7 downto 0);
    rx_crc_fail_o      : out std_logic;
    rx_crc_ok_o        : out std_logic;
    -- tx data
    tx_valid_i         : in  std_logic;
    tx_ready_o         : out std_logic;
    tx_last_i          : in  std_logic;
    tx_data_i          : in  std_logic_vector(7 downto 0);
    tx_valid_o         : out std_logic;
    tx_ready_i         : in  std_logic;
    tx_data_o          : out std_logic_vector(7 downto 0);
    -- rx crc32
    rx_crc_clear_o     : out std_logic;
    rx_crc_valid_o     : out std_logic;
    rx_crc_data_o      : out std_logic_vector(7 downto 0);
    rx_crc_checksum_i  : in  std_logic_vector(31 downto 0);
    -- tx crc32
    tx_crc_clear_o     : out std_logic;
    tx_crc_valid_o     : out std_logic;
    tx_crc_data_o      : out std_logic_vector(7 downto 0);
    tx_crc_checksum_i  : in  std_logic_vector(31 downto 0));
end entity eth_fcs;

architecture rtl of eth_fcs is

    signal data_vector_r   : std_logic_vector(31 downto 0) := (others => '0');
    signal valid_vector_r  : std_logic_vector(3 downto 0) := (others => '0');
    signal rx_valid_r      : std_logic := '0';
    signal calc_done_r     : std_logic := '0';
    signal data_mux_a      : std_logic_vector(7 downto 0);
    signal valid_mux_a     : std_logic;
    signal rx_received_crc : std_logic_vector(31 downto 0);
    signal rx_crc          : std_logic_vector(31 downto 0);
    signal rx_crc_fail_r   : std_logic := '0';
    signal rx_crc_ok_r     : std_logic := '0';
    signal rx_crc_data_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_crc_valid_r  : std_logic := '0';

    signal crc_vec_r  : std_logic_vector(3 downto 0) := (others => '0');
    signal tx_crc     : std_logic_vector(31 downto 0);
    signal crc_en_r   : std_logic := '0';

begin

    -- invert and bit reordering
    crc_conv_gen : for i in 0 to 3 generate
        rx_crc((i*8)+7 downto i*8) <= not reverse(data_vector_r((i*8)+7 downto i*8));
        tx_crc((i*8)+7 downto i*8) <= not reverse(tx_crc_checksum_i((i*8)+7 downto i*8));
    end generate;

    rx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then

            if (rx_valid_i = '1') then
                data_vector_r <= data_vector_r(data_vector_r'high-8 downto 0) & rx_data_i;
            end if;

            if (rx_valid_i = '1') then
                valid_vector_r <= valid_vector_r(valid_vector_r'high-1 downto 0) & rx_valid_i;
            elsif (calc_done_r = '1') then
                valid_vector_r <= (others => '0');
            end if;

            if (rx_crc = rx_crc_checksum_i) then
                rx_crc_ok_r <= calc_done_r;
                rx_crc_fail_r <= '0';
            else
                rx_crc_ok_r <= '0';
                rx_crc_fail_r <= calc_done_r;
            end if;

            rx_valid_r <= rx_valid_i;
            calc_done_r <= (not rx_valid_i) and rx_valid_r;

            rx_crc_data_r <= data_vector_r(data_vector_r'high downto data_vector_r'high-7);
            rx_crc_valid_r <= (valid_vector_r(valid_vector_r'high) and rx_valid_i);

        end if;
    end process rx_proc;

    tx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((tx_last_i = '1') and (tx_valid_i = '1') and (tx_ready_i = '1')) then
                crc_en_r <= '1';
                crc_vec_r <= x"8";
            elsif (tx_ready_i = '1') then
                crc_vec_r <= '0' & crc_vec_r(crc_vec_r'high downto 1);
                if (crc_vec_r(0) = '1') then
                    crc_en_r <= '0';
                end if;
            end if;
        end if;
    end process tx_proc;

    rx_valid_o <= rx_crc_valid_r;
    rx_data_o <= rx_crc_data_r;
    rx_crc_fail_o <= rx_crc_fail_r;
    rx_crc_ok_o <= rx_crc_ok_r;

    rx_crc_clear_o <= calc_done_r;
    rx_crc_valid_o <= rx_crc_valid_r;
    rx_crc_data_o <= rx_crc_data_r;

    tx_ready_o <= tx_ready_i and (not crc_en_r);
    tx_valid_o <= tx_valid_i or vector_or(crc_vec_r);
    tx_data_o <= tx_crc(31 downto 24) when (crc_vec_r(3) = '1') else
                 tx_crc(23 downto 16) when (crc_vec_r(2) = '1') else
                 tx_crc(15 downto 8) when (crc_vec_r(1) = '1') else
                 tx_crc(7 downto 0) when (crc_vec_r(0) = '1') else
                 tx_data_i;

    tx_crc_clear_o <= crc_vec_r(0) and tx_ready_i;
    tx_crc_valid_o <= tx_valid_i and tx_ready_i and (not crc_en_r);
    tx_crc_data_o <= tx_data_i;

end rtl;
