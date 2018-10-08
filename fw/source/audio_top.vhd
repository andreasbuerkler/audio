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
    eth_rx_er_i  : in    std_logic;
    eth_rx_clk_i : in    std_logic;
    eth_tx_en_o  : out   std_logic;
    eth_tx_d0_o  : out   std_logic;
    eth_tx_d1_o  : out   std_logic;
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

    constant CS4272_ADDR   : std_logic_vector(7 downto 0) := x"11";
    constant CS4272_CONFIG : std_logic_vector := x"07_03" &
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
        I2C_ADDRESS => CS4272_ADDR,
        CONFIG      => CS4272_CONFIG,
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

    -- output signals
    led_n_o      <= led_n_r;

    eth_rst_n_o  <= '1';
    eth_refclk_o <= clk50_000_i;
    eth_tx_en_o  <= '0';
    eth_tx_d0_o  <= '0';
    eth_tx_d1_o  <= '0';
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
