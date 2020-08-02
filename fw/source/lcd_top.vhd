--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 22.12.2019
-- Filename  : lcd_top.vhd
-- Changelog : 22.12.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity lcd_top is
port (
    -- clock input
    clk50_000_i    : in    std_logic;

    --debug
    led0_o         : out   std_logic;
    led1_o         : out   std_logic;
    led2_o         : out   std_logic;

    -- i2c
    i2c_scl_o      : out   std_logic;
    i2c_sda_io     : inout std_logic;

    -- eth
    eth_rst_n_o    : out   std_logic;
    eth_refclk_o   : out   std_logic;
    eth_rx_d0_i    : in    std_logic;
    eth_rx_d1_i    : in    std_logic;
    eth_rx_dv_i    : in    std_logic;
    eth_tx_d0_o    : out   std_logic;
    eth_tx_d1_o    : out   std_logic;
    eth_tx_en_o    : out   std_logic;
    eth_mdio_io    : inout std_logic;
    eth_mdc_o      : out   std_logic;

    -- hyper ram
    ram_rst_n_o    : out   std_logic;
    ram_cs_n_o     : out   std_logic;
    ram_clk_o      : out   std_logic;
    ram_rwds_io    : inout std_logic;
    ram_d0_io      : inout std_logic;
    ram_d1_io      : inout std_logic;
    ram_d2_io      : inout std_logic;
    ram_d3_io      : inout std_logic;
    ram_d4_io      : inout std_logic;
    ram_d5_io      : inout std_logic;
    ram_d6_io      : inout std_logic;
    ram_d7_io      : inout std_logic;

    -- lcd
    lcd_red_0_o    : out   std_logic;
    lcd_red_1_o    : out   std_logic;
    lcd_red_2_o    : out   std_logic;
    lcd_red_3_o    : out   std_logic;
    lcd_green_0_o  : out   std_logic;
    lcd_green_1_o  : out   std_logic;
    lcd_green_2_o  : out   std_logic;
    lcd_green_3_o  : out   std_logic;
    lcd_blue_0_o   : out   std_logic;
    lcd_blue_1_o   : out   std_logic;
    lcd_blue_2_o   : out   std_logic;
    lcd_blue_3_o   : out   std_logic;
    lcd_clk_o      : out   std_logic;
    lcd_de_o       : out   std_logic;
    lcd_vsync_o    : out   std_logic;
    lcd_hsync_o    : out   std_logic;
    lcd_disp_o     : out   std_logic;
    lcd_back_led_o : out   std_logic
);
end entity lcd_top;

architecture rtl of lcd_top is

    component main_pll is
    port (
        rst_i       : in  std_logic;
        clk_i       : in  std_logic;
        clk_o       : out std_logic;
        clk_90_o    : out std_logic;
        video_clk_o : out std_logic;
        locked_o    : out std_logic);
    end component main_pll;

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
        mac_address_g        : std_logic_vector(47 downto 0);
        ip_address_g         : std_logic_vector(31 downto 0);
        ctrl_port_g          : std_logic_vector(15 downto 0);
        ctrl_address_width_g : positive;
        ctrl_data_width_g    : positive;
        ctrl_burst_size_g    : positive);
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        -- mac rx
        mac_valid_i       : in  std_logic;
        mac_ready_o       : out std_logic;
        mac_last_i        : in  std_logic;
        mac_data_i        : in  std_logic_vector(7 downto 0);
        -- mac tx
        mac_valid_o       : out std_logic;
        mac_ready_i       : in  std_logic;
        mac_last_o        : out std_logic;
        mac_data_o        : out std_logic_vector(7 downto 0);
        -- ctrl
        ctrl_address_o    : out std_logic_vector(ctrl_address_width_g-1 downto 0);
        ctrl_data_o       : out std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_burst_size_o : out std_logic_vector(log2ceil(ctrl_burst_size_g)-1 downto 0);
        ctrl_strobe_o     : out std_logic;
        ctrl_write_o      : out std_logic;
        ctrl_ack_i        : in  std_logic);
    end component eth_subsystem;

    component registerbank is
    generic (
        register_count_g : positive;
        register_init_g  : std_logic_array_32;
        register_mask_g  : std_logic_array_32;
        read_only_g      : std_logic_vector;
        data_width_g     : positive;
        address_width_g  : positive;
        burst_size_g     : positive);
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        -- register
        data_i            : in  std_logic_array_32(register_count_g-1 downto 0);
        data_strb_i       : in  std_logic_vector(register_count_g-1 downto 0);
        data_o            : out std_logic_array_32(register_count_g-1 downto 0);
        data_strb_o       : out std_logic_vector(register_count_g-1 downto 0);
        read_strb_o       : out std_logic_vector(register_count_g-1 downto 0);
        -- ctrl bus
        ctrl_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        ctrl_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        ctrl_strobe_i     : in  std_logic;
        ctrl_write_i      : in  std_logic;
        ctrl_ack_o        : out std_logic);
    end component registerbank;

    component interconnect is
    generic (
        data_width_g    : positive;
        address_width_g : positive;
        burst_size_g    : positive);
    port (
        clk_i                : in std_logic;
        reset_i              : in std_logic;
        -- master 0
        master0_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        master0_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        master0_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        master0_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        master0_strobe_i     : in  std_logic;
        master0_write_i      : in  std_logic;
        master0_ack_o        : out std_logic;
        -- master 1
        master1_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        master1_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        master1_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        master1_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        master1_strobe_i     : in  std_logic;
        master1_write_i      : in  std_logic;
        master1_ack_o        : out std_logic;
        -- slave 0
        slave0_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave0_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave0_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave0_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave0_strobe_o      : out std_logic;
        slave0_write_o       : out std_logic;
        slave0_ack_i         : in  std_logic;
        -- slave 1
        slave1_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave1_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave1_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave1_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave1_strobe_o      : out std_logic;
        slave1_write_o       : out std_logic;
        slave1_ack_i         : in  std_logic;
        -- slave 2
        slave2_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave2_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave2_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave2_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave2_strobe_o      : out std_logic;
        slave2_write_o       : out std_logic;
        slave2_ack_i         : in  std_logic);
    end component interconnect;

    component i2c_master is
    generic (
        freq_in_g    : positive;
        freq_out_g   : positive;
        burst_size_g : positive);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        scl_o        : out std_logic;
        sda_i        : in  std_logic;
        sda_o        : out std_logic;
        -- ctrl bus
        address_i    : in  std_logic_vector(9 downto 0);
        data_i       : in  std_logic_vector(31 downto 0);
        data_o       : out std_logic_vector(31 downto 0);
        burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        strobe_i     : in  std_logic;
        write_i      : in  std_logic;
        ack_o        : out std_logic);
    end component i2c_master;

    component hyper_ram_controller is
    generic (
        clock_period_ns_g      : positive;
        config0_register_g     : std_logic_vector(15 downto 0);
        latency_cycles_g       : positive;
        max_burst_size_g       : positive;
        data_width_g           : positive;
        row_address_width_g    : positive;
        column_address_width_g : positive);
    port (
        clk_i             : in    std_logic;
        clk_shifted_i     : in    std_logic;
        reset_i           : in    std_logic;
        -- hyper bus
        hyper_rst_n_o     : out   std_logic;
        hyper_cs_n_o      : out   std_logic;
        hyper_clk_o       : out   std_logic;
        hyper_rwds_io     : inout std_logic;
        hyper_data_io     : inout std_logic_vector(7 downto 0);
        -- ctrl bus
        ctrl_address_i    : in    std_logic_vector(row_address_width_g+column_address_width_g-1 downto 0);
        ctrl_data_i       : in    std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o       : out   std_logic_vector(data_width_g-1 downto 0);
        ctrl_burst_size_i : in    std_logic_vector(log2ceil(max_burst_size_g)-1 downto 0);
        ctrl_strobe_i     : in    std_logic;
        ctrl_write_i      : in    std_logic;
        ctrl_ack_o        : out   std_logic);
    end component hyper_ram_controller;

    component lcd_controller is
    generic (
        buffer0_address_g        : std_logic_vector;
        buffer1_address_g        : std_logic_vector;
        ctrl_data_width_g        : positive;
        ctrl_address_width_g     : positive;
        ctrl_max_burst_size_g    : positive;
        color_bits_g             : positive;
        image_width_g            : positive;
        image_height_g           : positive;
        vertical_front_porch_g   : positive;
        vertical_back_porch_g    : positive;
        vertical_pulse_g         : positive;
        horizontal_front_porch_g : positive;
        horizontal_back_porch_g  : positive;
        horizontal_pulse_g       : positive);
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        enable_i          : in  std_logic;
        video_clk_i       : in  std_logic;
        -- lcd
        red_o             : out std_logic_vector(color_bits_g-1 downto 0);
        blue_o            : out std_logic_vector(color_bits_g-1 downto 0);
        green_o           : out std_logic_vector(color_bits_g-1 downto 0);
        hsync_o           : out std_logic;
        vsync_o           : out std_logic;
        de_o              : out std_logic;
        pclk_o            : out std_logic;
        -- frame buffer
        buffer_sel_i      : in  std_logic;
        ctrl_address_o    : out std_logic_vector(ctrl_address_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_data_o       : out std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_burst_size_o : out std_logic_vector(log2ceil(ctrl_max_burst_size_g)-1 downto 0);
        ctrl_strobe_o     : out std_logic;
        ctrl_write_o      : out std_logic;
        ctrl_ack_i        : in  std_logic);
    end component lcd_controller;

    constant main_clock_frequency_c : positive := 50000000;
    constant i2c_clock_frequency_c  : positive := 100000;

    constant ctrl_address_width_c  : positive := 24;
    constant ctrl_data_width_c     : positive := 32;
    constant ctrl_max_burst_size_c : positive := 32;

    constant mac_address_c   : std_logic_vector(47 downto 0) := x"3C8D20040506";
    constant ip_address_c    : std_logic_vector(31 downto 0) := x"C0A80064";
    constant ctrl_port_c     : std_logic_vector(15 downto 0) := x"1234";

    constant register_count_c                : positive := 4;
    constant register_address_version_c      : natural  := 0;
    constant register_address_test_c         : natural  := 1;
    constant register_address_reset_c        : natural  := 2;

    constant register_init_c      : std_logic_array_32(register_count_c-1 downto 0) :=
                                   (register_address_version_c    => x"BEEF0123",
                                    register_address_test_c       => x"00000000",
                                    register_address_reset_c      => x"00000000",
                                    others => x"00000000");
    constant register_read_only_c : std_logic_vector(register_count_c-1 downto 0) :=
                                   (register_address_version_c      => '1',
                                    register_address_test_c         => '0',
                                    register_address_reset_c        => '0',
                                    others                          => '0');
    constant register_mask_c      : std_logic_array_32(register_count_c-1 downto 0) :=
                                   (register_address_version_c      => x"ffffffff",
                                    register_address_test_c         => x"0000000f",
                                    register_address_reset_c        => x"00000003",
                                    others                          => x"ffffffff");

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

    -- i2c 
    signal i2c_sda  : std_logic;
    signal i2c_scl  : std_logic;

    -- ctrl bus eth master
    signal eth_address    : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal eth_read_data  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal eth_write_data : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal eth_burst_size : std_logic_vector(log2ceil(ctrl_max_burst_size_c)-1 downto 0);
    signal eth_strobe     : std_logic;
    signal eth_write      : std_logic;
    signal eth_ack        : std_logic;

    -- ctrl bus lcd controller dma master
    signal lcd_address    : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal lcd_read_data  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal lcd_write_data : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal lcd_burst_size : std_logic_vector(log2ceil(ctrl_max_burst_size_c)-1 downto 0);
    signal lcd_strobe     : std_logic;
    signal lcd_write      : std_logic;
    signal lcd_ack        : std_logic;

    -- ctrl bus register bank slave
    signal reg_address    : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal reg_read_data  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal reg_write_data : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal reg_burst_size : std_logic_vector(log2ceil(ctrl_max_burst_size_c)-1 downto 0);
    signal reg_strobe     : std_logic;
    signal reg_write      : std_logic;
    signal reg_ack        : std_logic;

    -- ctrl bus i2c slave
    signal i2c_address    : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal i2c_read_data  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal i2c_write_data : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal i2c_burst_size : std_logic_vector(log2ceil(ctrl_max_burst_size_c)-1 downto 0);
    signal i2c_strobe     : std_logic;
    signal i2c_write      : std_logic;
    signal i2c_ack        : std_logic;

    -- ctrl bus ram slave
    signal ram_address    : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal ram_read_data  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal ram_write_data : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal ram_burst_size : std_logic_vector(log2ceil(ctrl_max_burst_size_c)-1 downto 0);
    signal ram_strobe     : std_logic;
    signal ram_write      : std_logic;
    signal ram_ack        : std_logic;

    -- registerbank
    signal register_read_data  : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_read_strb  : std_logic_vector(register_count_c-1 downto 0) := (others => '0');
    signal register_was_read   : std_logic_vector(register_count_c-1 downto 0);
    signal register_write_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_write_strb : std_logic_vector(register_count_c-1 downto 0);

    signal led_vec_r          : unsigned(24 downto 0) := (others => '0');
    signal reset_vec_r        : unsigned(26 downto 0) := (others => '0');
    signal reset_eth_vec_r    : unsigned(24 downto 0) := (others => '1');
    signal reset              : std_logic;
    signal reset_n            : std_logic;
    signal clk_pll_50         : std_logic;
    signal clk_pll_50_shifted : std_logic;
    signal clk_video          : std_logic;
    signal main_pll_locked    : std_logic;

begin

    i_main_pll : main_pll
    port map (
        rst_i       => '0',
        clk_i       => clk50_000_i,
        clk_o       => clk_pll_50,
        clk_90_o    => clk_pll_50_shifted,
        video_clk_o => clk_video,
        locked_o    => main_pll_locked);

    i_mac : eth_mac
    generic map (
        fifo_size_exp_g => 11)
    port map (
        clk_i        => clk_pll_50,
        reset_i      => reset,
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
        mac_address_g        => mac_address_c,
        ip_address_g         => ip_address_c,
        ctrl_port_g          => ctrl_port_c,
        ctrl_address_width_g => ctrl_address_width_c,
        ctrl_data_width_g    => ctrl_data_width_c,
        ctrl_burst_size_g    => ctrl_max_burst_size_c)
    port map (
        clk_i             => clk_pll_50,
        reset_i           => reset,
        -- mac rx
        mac_valid_i       => mac_rx_valid,
        mac_ready_o       => mac_rx_ready,
        mac_last_i        => mac_rx_last,
        mac_data_i        => mac_rx_data,
        -- mac tx
        mac_valid_o       => mac_tx_valid,
        mac_ready_i       => mac_tx_ready,
        mac_last_o        => mac_tx_last,
        mac_data_o        => mac_tx_data,
        -- ctrl
        ctrl_address_o    => eth_address,
        ctrl_data_o       => eth_write_data,
        ctrl_data_i       => eth_read_data,
        ctrl_burst_size_o => eth_burst_size,
        ctrl_strobe_o     => eth_strobe,
        ctrl_write_o      => eth_write,
        ctrl_ack_i        => eth_ack);

    i_interconnect : interconnect
    generic map (
        data_width_g    => ctrl_data_width_c,
        address_width_g => ctrl_address_width_c,
        burst_size_g    => ctrl_max_burst_size_c)
    port map (
        clk_i                => clk_pll_50,
        reset_i              => reset,
        -- master 0
        master0_address_i    => eth_address,
        master0_data_i       => eth_write_data,
        master0_data_o       => eth_read_data,
        master0_burst_size_i => eth_burst_size,
        master0_strobe_i     => eth_strobe,
        master0_write_i      => eth_write,
        master0_ack_o        => eth_ack,
        -- master 1
        master1_address_i    => lcd_address,
        master1_data_i       => lcd_write_data,
        master1_data_o       => lcd_read_data,
        master1_burst_size_i => lcd_burst_size,
        master1_strobe_i     => lcd_strobe,
        master1_write_i      => lcd_write,
        master1_ack_o        => lcd_ack,    
        -- slave 0
        slave0_address_o     => reg_address,
        slave0_data_i        => reg_read_data,
        slave0_data_o        => reg_write_data,
        slave0_burst_size_o  => reg_burst_size,
        slave0_strobe_o      => reg_strobe,
        slave0_write_o       => reg_write,
        slave0_ack_i         => reg_ack,
        -- slave 1
        slave1_address_o     => i2c_address,
        slave1_data_i        => i2c_read_data,
        slave1_data_o        => i2c_write_data,
        slave1_burst_size_o  => i2c_burst_size,
        slave1_strobe_o      => i2c_strobe,
        slave1_write_o       => i2c_write,
        slave1_ack_i         => i2c_ack,
        -- slave 2
        slave2_address_o     => ram_address,
        slave2_data_i        => ram_read_data,
        slave2_data_o        => ram_write_data,
        slave2_burst_size_o  => ram_burst_size,
        slave2_strobe_o      => ram_strobe,
        slave2_write_o       => ram_write,
        slave2_ack_i         => ram_ack);

    i_registerbank : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => register_read_only_c,
        data_width_g     => ctrl_data_width_c,
        address_width_g  => ctrl_address_width_c-6,
        burst_size_g     => ctrl_max_burst_size_c)
    port map (
        clk_i             => clk_pll_50,
        reset_i           => reset,
        -- register
        data_i            => register_read_data,
        data_strb_i       => register_read_strb,
        data_o            => register_write_data,
        data_strb_o       => register_write_strb,
        read_strb_o       => register_was_read,
        -- ctrl bus
        ctrl_address_i    => reg_address(ctrl_address_width_c-5 downto 2),
        ctrl_data_i       => reg_write_data,
        ctrl_data_o       => reg_read_data,
        ctrl_burst_size_i => reg_burst_size,
        ctrl_strobe_i     => reg_strobe,
        ctrl_write_i      => reg_write,
        ctrl_ack_o        => reg_ack);

    i_i2c_master : i2c_master
    generic map (
        freq_in_g    => main_clock_frequency_c,
        freq_out_g   => i2c_clock_frequency_c,
        burst_size_g => ctrl_max_burst_size_c)
    port map (
        clk_i        => clk_pll_50,
        reset_i      => reset,
        scl_o        => i2c_scl,
        sda_i        => i2c_sda_io,
        sda_o        => i2c_sda,
        -- ctrl bus
        address_i    => i2c_address(9 downto 0),
        data_i       => i2c_write_data,
        data_o       => i2c_read_data,
        burst_size_i => i2c_burst_size,
        strobe_i     => i2c_strobe,
        write_i      => i2c_write,
        ack_o        => i2c_ack);

    i_hyper_ram : hyper_ram_controller
    generic map (
        clock_period_ns_g      => 20,
        config0_register_g     => x"8FEC",
        latency_cycles_g       => 6,
        max_burst_size_g       => ctrl_max_burst_size_c,
        data_width_g           => ctrl_data_width_c,
        row_address_width_g    => 13,
        column_address_width_g => 9)
    port map (
        clk_i             => clk_pll_50,
        clk_shifted_i     => clk_pll_50_shifted,
        reset_i           => reset,
        -- hyper bus
        hyper_rst_n_o     => ram_rst_n_o,
        hyper_cs_n_o      => ram_cs_n_o,
        hyper_clk_o       => ram_clk_o,
        hyper_rwds_io     => ram_rwds_io,
        hyper_data_io(0)  => ram_d0_io,
        hyper_data_io(1)  => ram_d1_io,
        hyper_data_io(2)  => ram_d2_io,
        hyper_data_io(3)  => ram_d3_io,
        hyper_data_io(4)  => ram_d4_io,
        hyper_data_io(5)  => ram_d5_io,
        hyper_data_io(6)  => ram_d6_io,
        hyper_data_io(7)  => ram_d7_io,
        -- ctrl bus
        ctrl_address_i    => ram_address(22 downto 1),
        ctrl_data_i       => ram_write_data,
        ctrl_data_o       => ram_read_data,
        ctrl_burst_size_i => ram_burst_size,
        ctrl_strobe_i     => ram_strobe,
        ctrl_write_i      => ram_write,
        ctrl_ack_o        => ram_ack);

    i_lcd : lcd_controller
    generic map (
        buffer0_address_g        => x"800000",
        buffer1_address_g        => x"880000",
        ctrl_data_width_g        => ctrl_data_width_c,
        ctrl_address_width_g     => ctrl_address_width_c,
        ctrl_max_burst_size_g    => ctrl_max_burst_size_c,
        color_bits_g             => 4,
        image_width_g            => 320,
        image_height_g           => 240,
        vertical_front_porch_g   => 4,
        vertical_back_porch_g    => 16,
        vertical_pulse_g         => 2,
        horizontal_front_porch_g => 20,
        horizontal_back_porch_g  => 66,
        horizontal_pulse_g       => 2)
    port map (
        clk_i             => clk_pll_50,
        reset_i           => reset,
        enable_i          => register_write_data(register_address_test_c)(2),
        video_clk_i       => clk_video,
        -- lcd
        red_o(0)          => lcd_red_0_o,
        red_o(1)          => lcd_red_1_o,
        red_o(2)          => lcd_red_2_o,
        red_o(3)          => lcd_red_3_o,
        blue_o(0)         => lcd_blue_0_o,
        blue_o(1)         => lcd_blue_1_o,
        blue_o(2)         => lcd_blue_2_o,
        blue_o(3)         => lcd_blue_3_o,
        green_o(0)        => lcd_green_0_o,
        green_o(1)        => lcd_green_1_o,
        green_o(2)        => lcd_green_2_o,
        green_o(3)        => lcd_green_3_o,
        hsync_o           => lcd_hsync_o,
        vsync_o           => lcd_vsync_o,
        de_o              => lcd_de_o,
        pclk_o            => lcd_clk_o,
        -- frame buffer
        buffer_sel_i      => register_write_data(register_address_test_c)(3),
        ctrl_address_o    => lcd_address,
        ctrl_data_i       => lcd_read_data,
        ctrl_data_o       => lcd_write_data,
        ctrl_burst_size_o => lcd_burst_size,
        ctrl_strobe_o     => lcd_strobe,
        ctrl_write_o      => lcd_write,
        ctrl_ack_i        => lcd_ack);

    lcd_disp_o  <= register_write_data(register_address_test_c)(1);
    lcd_back_led_o  <= register_write_data(register_address_test_c)(0);

    reset_proc : process (clk_pll_50, main_pll_locked, register_write_data)
    begin
        if ((main_pll_locked = '0') or (register_write_data(register_address_reset_c)(0) = '1')) then
            reset_vec_r <= (others => '0');
        elsif (rising_edge(clk_pll_50)) then
            if (reset_vec_r(reset_vec_r'high) = '0') then
                reset_vec_r <= reset_vec_r + 1;
            end if;
            -- reset ethernet phy
            if (((register_write_data(register_address_reset_c)(1) = '1') and (register_write_strb(register_address_reset_c) = '1')) or (reset = '1')) then
                reset_eth_vec_r <= (others => '0');
            elsif (reset_eth_vec_r(reset_eth_vec_r'high) = '0') then
                reset_eth_vec_r <= reset_eth_vec_r + 1;
            end if;
        end if;
    end process reset_proc;

    reset <= not reset_vec_r(reset_vec_r'high);
    reset_n <= reset_vec_r(reset_vec_r'high);

    -- counter for blinking LEDs
    led_proc : process (clk_pll_50)
    begin
        if (rising_edge(clk_pll_50)) then
            led_vec_r <= led_vec_r + 1;
        end if;
    end process;

    -- output signals
    led0_o       <= led_vec_r(led_vec_r'high-3) when (reset = '1') else
                    '1' when (led_vec_r(led_vec_r'high downto led_vec_r'high-1) = "00") else
                    '0';
    led1_o       <= led_vec_r(led_vec_r'high-3) when (reset = '1') else
                    '1' when (led_vec_r(led_vec_r'high downto led_vec_r'high-1) = "01") or (led_vec_r(led_vec_r'high downto led_vec_r'high-1) = "11") else
                    '0';
    led2_o       <= led_vec_r(led_vec_r'high-3) when (reset = '1') else
                    '1' when (led_vec_r(led_vec_r'high downto led_vec_r'high-1) = "10") else
                    '0';

    eth_rst_n_o  <= reset_n and reset_eth_vec_r(reset_eth_vec_r'high);
    eth_refclk_o <= clk_pll_50;
    eth_tx_en_o  <= tx_en;
    eth_tx_d0_o  <= tx_d(0);
    eth_tx_d1_o  <= tx_d(1);

    eth_mdio_io  <= 'Z';
    eth_mdc_o    <= '1';

    i2c_sda_io   <= '0' when (i2c_sda = '0') else 'Z';
    i2c_scl_o    <= i2c_scl;

end rtl;
