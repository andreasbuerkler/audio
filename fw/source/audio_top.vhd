--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : audio_top.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_top is
port (
    -- clock input
    clk50_000_i  : in    std_logic;
    clk12_288_i  : in    std_logic;

    --debug
    led_n_o      : out   std_logic;

    -- eth
    eth_rst_n_o  : out   std_logic;
    eth_refclk_o : out   std_logic;
    eth_rx_d0_i  : in    std_logic;
    eth_rx_d1_i  : in    std_logic;
    eth_rx_dv_i  : in    std_logic;
    eth_rx_er_i  : in    std_logic; -- not used
    eth_rx_clk_i : in    std_logic; -- not used
    eth_tx_d0_o  : out   std_logic;
    eth_tx_d1_o  : out   std_logic;
    eth_tx_en_o  : out   std_logic;
    eth_mdio_io  : inout std_logic;
    eth_mdc_o    : out   std_logic;

    -- audio codec
    i2s_rst_n_o  : out   std_logic;
    i2c_sda_io   : inout std_logic;
    i2c_scl_io   : inout std_logic;
    i2s_i        : in    std_logic;
    i2s_o        : out   std_logic;
    i2s_mclk_o   : out   std_logic;  -- 12.288 MHz
    i2s_bclk_o   : out   std_logic;  --  3.072 MHz
    i2s_lrclk_o  : out   std_logic); --     48 kHz
end entity audio_top;

architecture rtl of audio_top is

    component i2c_config
    generic (
        I2C_ADDRESS : std_logic_vector(7 downto 0);
        CONFIG      : std_logic_vector;
        FREQ_I      : positive;
        FREQ_O      : positive);
    port (
        clk_i   : in  std_logic;
        reset_i : in  std_logic;
        error_o : out std_logic;
        done_o  : out std_logic;
        scl_o   : out std_logic;
        sda_i   : in  std_logic;
        sda_o   : out std_logic);
    end component i2c_config;

    component i2s_inout
    port (
        m_clk_i       : in  std_logic;
        b_clk_o       : out std_logic;
        lr_clk_o      : out std_logic;
        i2s_i         : in  std_logic;
        i2s_o         : out std_logic;
        right_valid_o : out std_logic;
        left_valid_o  : out std_logic;
        data_o        : out std_logic_vector(23 downto 0);
        right_valid_i : in  std_logic;
        left_valid_i  : in  std_logic;
        data_i        : in  std_logic_vector(23 downto 0));
    end component i2s_inout;

    component eth_mac is
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
    end component eth_mac;

    component eth_subsystem is
    generic (
        mac_address_g  : std_logic_vector(47 downto 0);
        ip_address_g   : std_logic_vector(31 downto 0));
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        -- mac rx
        mac_valid_i : in  std_logic;
        mac_ready_o : out std_logic;
        mac_last_i  : in  std_logic;
        mac_data_i  : in  std_logic_vector(7 downto 0);
        -- mac tx
        mac_valid_o : out std_logic;
        mac_ready_i : in  std_logic;
        mac_last_o  : out std_logic;
        mac_data_o  : out std_logic_vector(7 downto 0));
    end component eth_subsystem;

    constant mac_address_c   : std_logic_vector(47 downto 0) := x"3C8D20040506";
    constant ip_address_c    : std_logic_vector(31 downto 0) := x"C0A80164";
    constant cs4272_addr_c   : std_logic_vector(7 downto 0) := x"11";
    constant cs4272_config_c : std_logic_vector := x"07_03" &
                                                   x"01_01" &
                                                   x"02_80" &
                                                   x"03_29" &
                                                   x"04_00" &
                                                   x"05_00" &
                                                   x"06_10" &
                                                   x"07_02";

    -- reset
    signal reset_counter_r       : unsigned(23 downto 0) := (others => '0');
    signal codec_reset_n_r       : std_logic := '0';
    signal config_reset_r        : std_logic := '1';
    signal config_reset_cc_vec_r : std_logic_vector(2 downto 0) := (others => '1');

    -- status led
    signal blink_counter_r : unsigned(24 downto 0) := (others => '0');
    signal i2c_error       : std_logic;
    signal i2c_done        : std_logic;
    signal led_n_r         : std_logic := '1';

    -- codec
    signal i2c_scl         : std_logic;
    signal i2c_sda         : std_logic;
    signal i2s_bclk        : std_logic;
    signal i2s_lrclk       : std_logic;
    signal i2s_out         : std_logic;
    signal audio_l_valid   : std_logic;
    signal audio_r_valid   : std_logic;
    signal audio_data      : std_logic_vector(23 downto 0);

    -- eth
    signal tx_en : std_logic;
    signal tx_d  : std_logic_vector(1 downto 0);

    signal mac_rx_valid : std_logic;
    signal mac_rx_ready : std_logic;
    signal mac_rx_last  : std_logic;
    signal mac_rx_data  : std_logic_vector(7 downto 0);

    signal mac_tx_valid : std_logic;
    signal mac_tx_ready : std_logic;
    signal mac_tx_last  : std_logic;
    signal mac_tx_data  : std_logic_vector(7 downto 0);

begin

    reset_proc : process (clk12_288_i)
    begin
        if (rising_edge(clk12_288_i)) then
            if (reset_counter_r(reset_counter_r'high) = '0') then
                reset_counter_r <= reset_counter_r + 1;
            end if;
            if (reset_counter_r(reset_counter_r'high-1) = '1') then
                codec_reset_n_r <= '1';
            end if;
            config_reset_cc_vec_r(0) <= not reset_counter_r(reset_counter_r'high);
        end if;
    end process reset_proc;

    cc_proc : process (clk50_000_i)
    begin
        if (rising_edge(clk50_000_i)) then
            config_reset_cc_vec_r(config_reset_cc_vec_r'high downto 1 ) <= config_reset_cc_vec_r(config_reset_cc_vec_r'high -1 downto 0);
            config_reset_r <= config_reset_cc_vec_r(config_reset_cc_vec_r'high);
        end if;
    end process cc_proc;

    led_proc : process (clk50_000_i)
    begin
        if (rising_edge(clk50_000_i)) then
            blink_counter_r <= blink_counter_r + 1;
            led_n_r <= i2c_done and (not i2c_error) and blink_counter_r(blink_counter_r'high);
        end if;
    end process led_proc;

    i_config : i2c_config
    generic map (
        I2C_ADDRESS => cs4272_addr_c,
        CONFIG      => cs4272_config_c,
        FREQ_I      => 50000000,
        FREQ_O      => 100000)
    port map (
        clk_i        => clk50_000_i,
        reset_i      => config_reset_r,
        error_o      => i2c_error,
        done_o       => i2c_done,
        scl_o        => i2c_scl,
        sda_i        => i2c_sda_io,
        sda_o        => i2c_sda);

    i_i2s : i2s_inout
    port map (
        m_clk_i       => clk12_288_i,
        b_clk_o       => i2s_bclk,
        lr_clk_o      => i2s_lrclk,
        i2s_i         => i2s_i,
        i2s_o         => i2s_out,
        right_valid_o => audio_r_valid,
        left_valid_o  => audio_l_valid,
        data_o        => audio_data,
        right_valid_i => audio_r_valid,
        left_valid_i  => audio_l_valid,
        data_i        => audio_data);

    i_mac : eth_mac
    generic map (
        fifo_size_exp_g => 11)
    port map (
        clk_i        => clk50_000_i,
        reset_i      => '0',
        -- tx
        data_valid_i => mac_tx_valid,
        data_ready_o => mac_tx_ready,
        last_i       => mac_tx_last,
        data_i       => mac_tx_data,
        -- rx
        data_valid_o => mac_rx_valid,
        data_ready_i => mac_rx_ready,
        last_o       => mac_rx_last,
        data_o       => mac_rx_data,
        -- rmii
        rx_d_i(0)    => eth_rx_d0_i,
        rx_d_i(1)    => eth_rx_d1_i,
        rx_dv_i      => eth_rx_dv_i,
        tx_d_o       => tx_d,
        tx_en_o      => tx_en);

    i_eth : eth_subsystem
    generic map (
        mac_address_g  => mac_address_c,
        ip_address_g   => ip_address_c)
    port map (
        clk_i       => clk50_000_i,
        reset_i     => '0',
        -- mac rx
        mac_valid_i => mac_rx_valid,
        mac_ready_o => mac_rx_ready,
        mac_last_i  => mac_rx_last,
        mac_data_i  => mac_rx_data,
        -- mac tx
        mac_valid_o => mac_tx_valid,
        mac_ready_i => mac_tx_ready,
        mac_last_o  => mac_tx_last,
        mac_data_o  => mac_tx_data);

    -- output signals
    led_n_o      <= led_n_r;

    eth_rst_n_o  <= '1';
    eth_refclk_o <= clk50_000_i;
    eth_tx_en_o  <= tx_en;
    eth_tx_d0_o  <= tx_d(0);
    eth_tx_d1_o  <= tx_d(1);
    eth_mdio_io  <= 'Z';
    eth_mdc_o    <= '0';

    i2s_rst_n_o  <= codec_reset_n_r;
    i2c_sda_io   <= '0' when (i2c_sda = '0') else 'Z';
    i2c_scl_io   <= '0' when (i2c_scl = '0') else 'Z';

    i2s_o        <= i2s_out;
    i2s_mclk_o   <= clk12_288_i;
    i2s_bclk_o   <= i2s_bclk;
    i2s_lrclk_o  <= i2s_lrclk;

end rtl;
