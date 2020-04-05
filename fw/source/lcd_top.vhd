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
    clk50_000_i  : in    std_logic;

    --debug
    led0_n_o     : out   std_logic;
    led1_n_o     : out   std_logic;
    led2_n_o     : out   std_logic;

    -- i2c
    i2c_scl_o    : out   std_logic;
    i2c_sda_io   : inout std_logic;

    -- eth
    eth_rst_n_o  : out   std_logic;
    eth_refclk_o : out   std_logic;
    eth_rx_d0_i  : in    std_logic;
    eth_rx_d1_i  : in    std_logic;
    eth_rx_dv_i  : in    std_logic;
    eth_tx_d0_o  : out   std_logic;
    eth_tx_d1_o  : out   std_logic;
    eth_tx_en_o  : out   std_logic;
    eth_mdio_io  : inout std_logic;
    eth_mdc_o    : out   std_logic;

    -- hyper ram
    ram_rst_n_o  : out   std_logic;
    ram_cs_n_o   : out   std_logic;
    ram_clk_o    : out   std_logic;
    ram_rwds_o   : inout std_logic;
    ram_d0_io    : inout std_logic;
    ram_d1_io    : inout std_logic;
    ram_d2_io    : inout std_logic;
    ram_d3_io    : inout std_logic;
    ram_d4_io    : inout std_logic;
    ram_d5_io    : inout std_logic;
    ram_d6_io    : inout std_logic;
    ram_d7_io    : inout std_logic;

    -- lcd
    lcd00_io     : inout std_logic;
    lcd01_io     : inout std_logic;
    lcd02_io     : inout std_logic;
    lcd03_io     : inout std_logic;
    lcd04_io     : inout std_logic;
    lcd05_io     : inout std_logic;
    lcd06_io     : inout std_logic;
    lcd07_io     : inout std_logic;
    lcd08_io     : inout std_logic;
    lcd09_io     : inout std_logic;
    lcd10_io     : inout std_logic;
    lcd11_io     : inout std_logic;
    lcd12_io     : inout std_logic;
    lcd13_io     : inout std_logic;
    lcd14_io     : inout std_logic;
    lcd15_io     : inout std_logic;
    lcd16_io     : inout std_logic;
    lcd17_io     : inout std_logic;
    lcd18_io     : inout std_logic;
    lcd19_io     : inout std_logic
);
end entity lcd_top;

architecture rtl of lcd_top is

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
        ctrl_data_width_g    : positive);
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        -- mac rx
        mac_valid_i    : in  std_logic;
        mac_ready_o    : out std_logic;
        mac_last_i     : in  std_logic;
        mac_data_i     : in  std_logic_vector(7 downto 0);
        -- mac tx
        mac_valid_o    : out std_logic;
        mac_ready_i    : in  std_logic;
        mac_last_o     : out std_logic;
        mac_data_o     : out std_logic_vector(7 downto 0);
        -- ctrl
        ctrl_address_o : out std_logic_vector(ctrl_address_width_g-1 downto 0);
        ctrl_data_o    : out std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_data_i    : in  std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_strobe_o  : out std_logic;
        ctrl_write_o   : out std_logic;
        ctrl_ack_i     : in  std_logic);
    end component eth_subsystem;

    component registerbank is
    generic (
        register_count_g : positive;
        register_init_g  : std_logic_array_32;
        register_mask_g  : std_logic_array_32;
        read_only_g      : std_logic_vector;
        data_width_g     : positive;
        address_width_g  : positive);
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        -- register
        data_i         : in  std_logic_array_32(register_count_g-1 downto 0);
        data_strb_i    : in  std_logic_vector(register_count_g-1 downto 0);
        data_o         : out std_logic_array_32(register_count_g-1 downto 0);
        data_strb_o    : out std_logic_vector(register_count_g-1 downto 0);
        read_strb_o    : out std_logic_vector(register_count_g-1 downto 0);
        -- ctrl bus
        ctrl_address_i : in  std_logic_vector(address_width_g-1 downto 0);
        ctrl_data_i    : in  std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o    : out std_logic_vector(data_width_g-1 downto 0);
        ctrl_strobe_i  : in  std_logic;
        ctrl_write_i   : in  std_logic;
        ctrl_ack_o     : out std_logic);
    end component registerbank;

    component interconnect is
    generic (
        address_map_g          : std_logic_array;
        master_data_width_g    : positive;
        master_address_width_g : positive);
    port (
        clk_i            : in std_logic;
        reset_i          : in std_logic;
        -- master
        master_address_i : in  std_logic_vector(master_address_width_g-1 downto 0);
        master_data_i    : in  std_logic_vector(master_data_width_g-1 downto 0);
        master_data_o    : out std_logic_vector(master_data_width_g-1 downto 0);
        master_strobe_i  : in  std_logic;
        master_write_i   : in  std_logic;
        master_ack_o     : out std_logic;
        -- slave
        slave_address_o : out std_logic_array;
        slave_data_i    : in  std_logic_array;
        slave_data_o    : out std_logic_array;
        slave_strobe_o  : out std_logic_vector;
        slave_write_o   : out std_logic_vector;
        slave_ack_i     : in  std_logic_vector);
    end component interconnect;

    component i2c_master is
    generic (
        freq_in_g  : positive;
        freq_out_g : positive);
    port (
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        scl_o     : out std_logic;
        sda_i     : in  std_logic;
        sda_o     : out std_logic;
        -- ctrl bus
        address_i : in  std_logic_vector(9 downto 0);
        data_i    : in  std_logic_vector(31 downto 0);
        data_o    : out std_logic_vector(31 downto 0);
        strobe_i  : in  std_logic;
        write_i   : in  std_logic;
        ack_o     : out std_logic);
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

    constant main_clock_frequency_c : positive := 50000000;
    constant i2c_clock_frequency_c  : positive := 100000;

    constant ctrl_address_width_c : positive := 24;
    constant ctrl_data_width_c    : positive := 32;

    constant mac_address_c   : std_logic_vector(47 downto 0) := x"3C8D20040506";
    constant ip_address_c    : std_logic_vector(31 downto 0) := x"C0A80064";
    constant ctrl_port_c     : std_logic_vector(15 downto 0) := x"1234";

    constant number_of_slaves_c   : positive := 3;
    constant slave_registerbank_c : natural := 0;
    constant slave_i2c_master_c   : natural := 1;
    constant slave_hyper_ram_c    : natural := 2;
    constant address_map_c : std_logic_array := (slave_registerbank_c => "00----------------------",
                                                 slave_i2c_master_c   => "01----------------------",
                                                 slave_hyper_ram_c    => "10----------------------");

    constant register_count_c                : positive := 4;
    constant register_address_version_c      : natural  := 0;
    constant register_address_test_c         : natural  := 1;

    constant register_init_c      : std_logic_array_32(register_count_c-1 downto 0) :=
                                   (register_address_version_c    => x"BEEF0123",
                                    others => x"00000000");
    constant register_read_only_c : std_logic_vector(register_count_c-1 downto 0) :=
                                   (register_address_version_c      => '1',
                                    register_address_test_c         => '0',
                                    others                          => '0');
    constant register_mask_c      : std_logic_array_32(register_count_c-1 downto 0) :=
                                   (register_address_version_c      => x"ffffffff",
                                    register_address_test_c         => x"000000ff",
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

    -- ctrl bus
    signal ctrl_address  : std_logic_vector(ctrl_address_width_c-1 downto 0);
    signal ctrl_data_in  : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal ctrl_data_out : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal ctrl_strobe   : std_logic;
    signal ctrl_write    : std_logic;
    signal ctrl_ack      : std_logic;

    -- ctrl interconnect
    signal slave_address         : std_logic_array(number_of_slaves_c-1 downto 0, ctrl_address_width_c-3 downto 0);
    signal slave_read_data       : std_logic_array(number_of_slaves_c-1 downto 0, ctrl_data_width_c-1 downto 0);
    signal slave_write_data      : std_logic_array(number_of_slaves_c-1 downto 0, ctrl_data_width_c-1 downto 0);
    signal slave_strobe          : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave_write           : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave_ack             : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal registerbank_readdata : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal i2c_master_readdata   : std_logic_vector(ctrl_data_width_c-1 downto 0);
    signal hyper_ram_readdata    : std_logic_vector(ctrl_data_width_c-1 downto 0);

    -- registerbank
    signal register_read_data  : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_read_strb  : std_logic_vector(register_count_c-1 downto 0) := (others => '0');
    signal register_was_read   : std_logic_vector(register_count_c-1 downto 0);
    signal register_write_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_write_strb : std_logic_vector(register_count_c-1 downto 0);

    signal led_vec_r   : unsigned(24 downto 0) := (others => '0');
    signal reset_vec_r : unsigned(24 downto 0) := (others => '0');
    signal reset       : std_logic;
    signal reset_n     : std_logic;

begin

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
        mac_address_g        => mac_address_c,
        ip_address_g         => ip_address_c,
        ctrl_port_g          => ctrl_port_c,
        ctrl_address_width_g => ctrl_address_width_c,
        ctrl_data_width_g    => ctrl_data_width_c)
    port map (
        clk_i          => clk50_000_i,
        reset_i        => '0',
        -- mac rx
        mac_valid_i    => mac_rx_valid,
        mac_ready_o    => mac_rx_ready,
        mac_last_i     => mac_rx_last,
        mac_data_i     => mac_rx_data,
        -- mac tx
        mac_valid_o    => mac_tx_valid,
        mac_ready_i    => mac_tx_ready,
        mac_last_o     => mac_tx_last,
        mac_data_o     => mac_tx_data,
        -- ctrl
        ctrl_address_o => ctrl_address,
        ctrl_data_o    => ctrl_data_out,
        ctrl_data_i    => ctrl_data_in,
        ctrl_strobe_o  => ctrl_strobe,
        ctrl_write_o   => ctrl_write,
        ctrl_ack_i     => ctrl_ack);

    i_interconnect : interconnect
    generic map (
        address_map_g          => address_map_c,
        master_data_width_g    => ctrl_data_width_c,
        master_address_width_g => ctrl_address_width_c)
    port map (
        clk_i            => clk50_000_i,
        reset_i          => '0',
        -- master
        master_address_i => ctrl_address,
        master_data_i    => ctrl_data_out,
        master_data_o    => ctrl_data_in,
        master_strobe_i  => ctrl_strobe,
        master_write_i   => ctrl_write,
        master_ack_o     => ctrl_ack,
        -- slave
        slave_address_o => slave_address,
        slave_data_i    => slave_read_data,
        slave_data_o    => slave_write_data,
        slave_strobe_o  => slave_strobe,
        slave_write_o   => slave_write,
        slave_ack_i     => slave_ack);

    registerbank_read_data_gen : for i in ctrl_data_width_c-1 downto 0 generate
        slave_read_data(slave_registerbank_c, i) <= registerbank_readdata(i);
    end generate registerbank_read_data_gen;

    i2c_master_read_data_gen : for i in ctrl_data_width_c-1 downto 0 generate
        slave_read_data(slave_i2c_master_c, i) <= i2c_master_readdata(i);
    end generate i2c_master_read_data_gen;

    hyper_ram_read_data_gen : for i in ctrl_data_width_c-1 downto 0 generate
        slave_read_data(slave_hyper_ram_c, i) <= hyper_ram_readdata(i);
    end generate hyper_ram_read_data_gen;

    i_registerbank : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => register_read_only_c,
        data_width_g     => ctrl_data_width_c,
        address_width_g  => ctrl_address_width_c-6)
    port map (
        clk_i          => clk50_000_i,
        reset_i        => '0',
        -- register
        data_i         => register_read_data,
        data_strb_i    => register_read_strb,
        data_o         => register_write_data,
        data_strb_o    => register_write_strb,
        read_strb_o    => register_was_read,
        -- ctrl bus
        ctrl_address_i => array_extract(slave_registerbank_c, slave_address)(ctrl_address_width_c-5 downto 2),
        ctrl_data_i    => array_extract(slave_registerbank_c ,slave_write_data),
        ctrl_data_o    => registerbank_readdata,
        ctrl_strobe_i  => slave_strobe(slave_registerbank_c),
        ctrl_write_i   => slave_write(slave_registerbank_c),
        ctrl_ack_o     => slave_ack(slave_registerbank_c));

    i_i2c_master : i2c_master
    generic map (
        freq_in_g  => main_clock_frequency_c,
        freq_out_g => i2c_clock_frequency_c)
    port map (
        clk_i     => clk50_000_i,
        reset_i   => '0',
        scl_o     => i2c_scl,
        sda_i     => i2c_sda_io,
        sda_o     => i2c_sda,
        -- ctrl bus
        address_i => array_extract(slave_i2c_master_c, slave_address)(9 downto 0),
        data_i    => array_extract(slave_i2c_master_c ,slave_write_data),
        data_o    => i2c_master_readdata,
        strobe_i  => slave_strobe(slave_i2c_master_c),
        write_i   => slave_write(slave_i2c_master_c),
        ack_o     => slave_ack(slave_i2c_master_c));

    i_hyper_ram : hyper_ram_controller
    generic map (
        clock_period_ns_g      => 20,
        config0_register_g     => x"8FEC",
        latency_cycles_g       => 6,
        max_burst_size_g       => 32,
        data_width_g           => ctrl_data_width_c,
        row_address_width_g    => 13,
        column_address_width_g => 9)
    port map (
        clk_i             => clk50_000_i,
        reset_i           => reset,
        -- hyper bus
        hyper_rst_n_o     => ram_rst_n_o,
        hyper_cs_n_o      => ram_cs_n_o,
        hyper_clk_o       => ram_clk_o,
        hyper_rwds_io     => ram_rwds_o,
        hyper_data_io(0)  => ram_d0_io,
        hyper_data_io(1)  => ram_d1_io,
        hyper_data_io(2)  => ram_d2_io,
        hyper_data_io(3)  => ram_d3_io,
        hyper_data_io(4)  => ram_d4_io,
        hyper_data_io(5)  => ram_d5_io,
        hyper_data_io(6)  => ram_d6_io,
        hyper_data_io(7)  => ram_d7_io,
        -- ctrl bus
        ctrl_address_i => array_extract(slave_hyper_ram_c, slave_address)(21 downto 0),
        ctrl_data_i    => array_extract(slave_hyper_ram_c ,slave_write_data),
        ctrl_data_o    => hyper_ram_readdata,
        ctrl_burst_size_i => "00000",
        ctrl_strobe_i  => slave_strobe(slave_hyper_ram_c),
        ctrl_write_i   => slave_write(slave_hyper_ram_c),
        ctrl_ack_o     => slave_ack(slave_hyper_ram_c));

    -- register bank read
    register_read_data(register_address_test_c) <= x"12345678";
    register_read_strb(register_address_test_c) <= '0';

    reset_proc : process (clk50_000_i)
    begin
        if (rising_edge(clk50_000_i)) then
            if (reset_vec_r(reset_vec_r'high) = '0') then
                reset_vec_r <= reset_vec_r + 1;
            end if;
        end if;
    end process reset_proc;

    reset <= not reset_vec_r(reset_vec_r'high);
    reset_n <= reset_vec_r(reset_vec_r'high);

    -- output signals
    led_proc : process (clk50_000_i)
    begin
        if (rising_edge(clk50_000_i)) then
            led_vec_r <= led_vec_r + 1;
        end if;
    end process;

    led0_n_o     <= led_vec_r(led_vec_r'high);
    led1_n_o     <= led_vec_r(led_vec_r'high-1);
    led2_n_o     <= led_vec_r(led_vec_r'high-2);

    eth_rst_n_o  <= reset_n;
    eth_refclk_o <= clk50_000_i;
    eth_tx_en_o  <= tx_en;
    eth_tx_d0_o  <= tx_d(0);
    eth_tx_d1_o  <= tx_d(1);

    eth_mdio_io  <= 'Z';
    eth_mdc_o    <= '1';

    i2c_sda_io   <= '0' when (i2c_sda = '0') else 'Z';
    i2c_scl_o    <= i2c_scl;

end rtl;
