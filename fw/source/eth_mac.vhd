--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 27.10.2018
-- Filename  : eth_mac.vhd
-- Changelog : 27.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_mac is
generic (
    fifo_size_exp_g : positive := 10);
port (
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    -- tx
    data_valid_i : in  std_logic;
    data_ready_o : out std_logic;
    last_i       : in  std_logic;
    data_i       : in  std_logic_vector(7 downto 0);
    -- rx
    data_valid_o : out std_logic;
    data_ready_i : in  std_logic;
    last_o       : out std_logic;
    data_o       : out std_logic_vector(7 downto 0);
    -- rmii
    rx_d_i       : in  std_logic_vector(1 downto 0);
    rx_dv_i      : in  std_logic;
    tx_d_o       : out std_logic_vector(1 downto 0);
    tx_en_o      : out std_logic);
end entity eth_mac;

architecture rtl of eth_mac is

    component fifo is
    generic (
        size_exp_g     : positive := 10;
        data_width_g   : positive := 8;
        use_reject_g   : boolean  := false;
        invert_full_g  : boolean  := false;
        invert_empty_g : boolean  := false);
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        -- write port
        data_i   : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i     : in  std_logic;
        store_i  : in  std_logic;
        reject_i : in  std_logic;
        full_o   : out std_logic;
        -- read port
        data_o   : out std_logic_vector(data_width_g-1 downto 0);
        rd_i     : in  std_logic;
        empty_o  : out std_logic);
    end component fifo;

    component eth_padder is
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
    end component eth_padder;

    component crc32 is
    port (
        clk_i        : in  std_logic;
        clear_i      : in  std_logic;
        data_valid_i : in  std_logic;
        data_i       : in  std_logic_vector(7 downto 0);
        crc_o        : out std_logic_vector(31 downto 0));
    end component crc32;

    component eth_fcs is
    port (
        clk_i             : in  std_logic;
        -- rx data
        rx_valid_i        : in  std_logic;
        rx_data_i         : in  std_logic_vector(7 downto 0);
        rx_fifo_full_i    : in  std_logic;
        rx_valid_o        : out std_logic;
        rx_last_o         : out std_logic;
        rx_data_o         : out std_logic_vector(7 downto 0);
        rx_crc_fail_o     : out std_logic;
        rx_crc_ok_o       : out std_logic;
        -- tx data
        tx_valid_i        : in  std_logic;
        tx_ready_o        : out std_logic;
        tx_last_i         : in  std_logic;
        tx_data_i         : in  std_logic_vector(7 downto 0);
        tx_valid_o        : out std_logic;
        tx_ready_i        : in  std_logic;
        tx_last_o         : out std_logic;
        tx_data_o         : out std_logic_vector(7 downto 0);
        -- rx crc32
        rx_crc_clear_o    : out std_logic;
        rx_crc_valid_o    : out std_logic;
        rx_crc_data_o     : out std_logic_vector(7 downto 0);
        rx_crc_checksum_i : in  std_logic_vector(31 downto 0);
        -- tx crc32
        tx_crc_clear_o    : out std_logic;
        tx_crc_valid_o    : out std_logic;
        tx_crc_data_o     : out std_logic_vector(7 downto 0);
        tx_crc_checksum_i : in  std_logic_vector(31 downto 0));
    end component eth_fcs;

    component rmii_interface is
    port (
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        -- rmii
        rx_d_i           : in  std_logic_vector(1 downto 0);
        rx_dv_i          : in  std_logic;
        tx_d_o           : out std_logic_vector(1 downto 0);
        tx_en_o          : out std_logic;
        -- data stream
        data_out_o       : out std_logic_vector(7 downto 0);
        data_out_valid_o : out std_logic;
        data_in_i        : in  std_logic_vector(7 downto 0);
        data_in_last_i   : in  std_logic;
        data_in_valid_i  : in  std_logic;
        data_in_ready_o  : out std_logic);
    end component rmii_interface;

    signal tx_fifo_empty   : std_logic;
    signal tx_fifo_full    : std_logic;
    signal tx_fifo_wr_data : std_logic_vector(8 downto 0);
    signal tx_fifo_rd_data : std_logic_vector(8 downto 0);
    signal tx_fifo_rd_en   : std_logic;
    signal rx_fifo_empty   : std_logic;
    signal rx_fifo_full    : std_logic;
    signal rx_fifo_wr_data : std_logic_vector(8 downto 0);
    signal rx_fifo_rd_data : std_logic_vector(8 downto 0);
    signal rx_fifo_wr_en   : std_logic;
    signal rx_fifo_store   : std_logic;
    signal rx_fifo_reject  : std_logic;
    signal padder_valid    : std_logic;
    signal padder_ready    : std_logic;
    signal padder_last     : std_logic;
    signal padder_data     : std_logic_vector(7 downto 0);
    signal tx_crc_clear    : std_logic;
    signal tx_crc_valid    : std_logic;
    signal tx_crc_data     : std_logic_vector(7 downto 0);
    signal tx_crc_checksum : std_logic_vector(31 downto 0);
    signal rx_crc_clear    : std_logic;
    signal rx_crc_valid    : std_logic;
    signal rx_crc_data     : std_logic_vector(7 downto 0);
    signal rx_crc_checksum : std_logic_vector(31 downto 0);
    signal fcs_tx_valid    : std_logic;
    signal fcs_tx_ready    : std_logic;
    signal fcs_tx_last     : std_logic;
    signal fcs_tx_data     : std_logic_vector(7 downto 0);
    signal fcs_rx_valid    : std_logic;
    signal fcs_rx_data     : std_logic_vector(7 downto 0);
    signal rmii_tx_en      : std_logic;
    signal rmii_tx_d       : std_logic_vector(1 downto 0);

begin

    tx_fifo_wr_data <= last_i & data_i;

    i_tx_fifo : fifo
    generic map (
        size_exp_g     => fifo_size_exp_g,
        data_width_g   => 9,
        use_reject_g   => false,
        invert_full_g  => true,
        invert_empty_g => true)
    port map (
        clk_i    => clk_i,
        reset_i  => reset_i,
        -- write port
        data_i   => tx_fifo_wr_data,
        wr_i     => data_valid_i,
        store_i  => '0',
        reject_i => '0',
        full_o   => tx_fifo_full,
        -- read port
        data_o   => tx_fifo_rd_data,
        rd_i     => tx_fifo_rd_en,
        empty_o  => tx_fifo_empty);

    i_rx_fifo : fifo
    generic map (
        size_exp_g     => fifo_size_exp_g,
        data_width_g   => 9,
        use_reject_g   => true,
        invert_full_g  => false,
        invert_empty_g => true)
    port map (
        clk_i    => clk_i,
        reset_i  => reset_i,
        -- write port
        data_i   => rx_fifo_wr_data,
        wr_i     => rx_fifo_wr_en,
        store_i  => rx_fifo_store,
        reject_i => rx_fifo_reject,
        full_o   => rx_fifo_full,
        -- read port
        data_o   => rx_fifo_rd_data,
        rd_i     => data_ready_i,
        empty_o  => rx_fifo_empty);

    i_padder : eth_padder
    port map (
        clk_i        => clk_i,
        data_valid_i => tx_fifo_empty,
        data_ready_o => tx_fifo_rd_en,
        last_i       => tx_fifo_rd_data(tx_fifo_rd_data'high),
        data_i       => tx_fifo_rd_data(tx_fifo_rd_data'high-1 downto 0),
        data_valid_o => padder_valid,
        data_ready_i => padder_ready,
        last_o       => padder_last,
        data_o       => padder_data);

    i_tx_crc : crc32
    port map (
        clk_i        => clk_i,
        clear_i      => tx_crc_clear,
        data_valid_i => tx_crc_valid,
        data_i       => tx_crc_data,
        crc_o        => tx_crc_checksum);

    i_rx_crc : crc32
    port map (
        clk_i        => clk_i,
        clear_i      => rx_crc_clear,
        data_valid_i => rx_crc_valid,
        data_i       => rx_crc_data,
        crc_o        => rx_crc_checksum);

    i_fcs : eth_fcs
    port map (
        clk_i             => clk_i,
        -- rx data
        rx_valid_i        => fcs_rx_valid,
        rx_data_i         => fcs_rx_data,
        rx_fifo_full_i    => rx_fifo_full,
        rx_valid_o        => rx_fifo_wr_en,
        rx_last_o         => rx_fifo_wr_data(rx_fifo_wr_data'high),
        rx_data_o         => rx_fifo_wr_data(rx_fifo_wr_data'high-1 downto 0),
        rx_crc_fail_o     => rx_fifo_reject,
        rx_crc_ok_o       => rx_fifo_store,
        -- tx data
        tx_valid_i        => padder_valid,
        tx_ready_o        => padder_ready,
        tx_last_i         => padder_last,
        tx_data_i         => padder_data,
        tx_valid_o        => fcs_tx_valid,
        tx_ready_i        => fcs_tx_ready,
        tx_last_o         => fcs_tx_last,
        tx_data_o         => fcs_tx_data,
        -- rx crc32
        rx_crc_clear_o    => rx_crc_clear,
        rx_crc_valid_o    => rx_crc_valid,
        rx_crc_data_o     => rx_crc_data,
        rx_crc_checksum_i => rx_crc_checksum,
        -- tx crc32
        tx_crc_clear_o    => tx_crc_clear,
        tx_crc_valid_o    => tx_crc_valid,
        tx_crc_data_o     => tx_crc_data,
        tx_crc_checksum_i => tx_crc_checksum);

    i_rmii : rmii_interface
    port map (
        clk_i            => clk_i,
        reset_i          => reset_i,
        -- rmii
        rx_d_i           => rx_d_i,
        rx_dv_i          => rx_dv_i,
        tx_d_o           => rmii_tx_d,
        tx_en_o          => rmii_tx_en,
        -- data stream
        data_out_o       => fcs_rx_data,
        data_out_valid_o => fcs_rx_valid,
        data_in_i        => fcs_tx_data,
        data_in_last_i   => fcs_tx_last,
        data_in_valid_i  => fcs_tx_valid,
        data_in_ready_o  => fcs_tx_ready);

    -- output
    data_ready_o <= tx_fifo_full;
    data_valid_o <= rx_fifo_empty;
    last_o <= rx_fifo_rd_data(rx_fifo_rd_data'high);
    data_o <= rx_fifo_rd_data(rx_fifo_rd_data'high-1 downto 0);
    tx_d_o <= rmii_tx_d;
    tx_en_o <= rmii_tx_en;

end rtl;
