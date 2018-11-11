--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 10.11.2018
-- Filename  : eth_subsystem.vhd
-- Changelog : 10.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_subsystem is
generic (
    mac_address_g  : std_logic_vector(47 downto 0) := x"010203040506";
    ip_address_g   : std_logic_vector(31 downto 0) := x"01020304";
    arp_size_exp_g : positive := 3);
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
end entity eth_subsystem;

architecture rtl of eth_subsystem is

    component eth_processing is
    generic (
        mac_address_g : std_logic_vector(47 downto 0));
    port (
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        -- mac rx
        mac_valid_i      : in  std_logic;
        mac_ready_o      : out std_logic;
        mac_last_i       : in  std_logic;
        mac_data_i       : in  std_logic_vector(7 downto 0);
        -- arp rx
        arp_valid_o      : out std_logic;
        arp_ready_i      : in  std_logic;
        arp_last_o       : out std_logic;
        arp_data_o       : out std_logic_vector(7 downto 0);
        -- ip rx
        ip_valid_o       : out std_logic;
        ip_ready_i       : in  std_logic;
        ip_last_o        : out std_logic;
        ip_data_o        : out std_logic_vector(7 downto 0);
        -- mac tx
        mac_valid_o      : out std_logic;
        mac_ready_i      : in  std_logic;
        mac_last_o       : out std_logic;
        mac_data_o       : out std_logic_vector(7 downto 0);
        -- arp tx
        arp_valid_i      : in  std_logic;
        arp_ready_o      : out std_logic;
        arp_last_i       : in  std_logic;
        arp_data_i       : in  std_logic_vector(7 downto 0);
        mac_i            : in  std_logic_vector(47 downto 0);
        -- ip tx
        ip_valid_i       : in  std_logic;
        ip_ready_o       : out std_logic;
        ip_last_i        : in  std_logic;
        ip_data_i        : in  std_logic_vector(7 downto 0);
        -- arp address request
        ip_addr_o        : out std_logic_vector(31 downto 0);
        ip_addr_req_o    : out std_logic;
        mac_addr_i       : in  std_logic_vector(47 downto 0);
        mac_addr_valid_i : in  std_logic);
    end component eth_processing;

    component arp_processing is
    generic (
        mac_address_g : std_logic_vector(47 downto 0);
        ip_address_g  : std_logic_vector(31 downto 0));
    port (
        clk_i   : in  std_logic;
        reset_i : in  std_logic;
        -- arp rx
        valid_i : in  std_logic;
        ready_o : out std_logic;
        last_i  : in  std_logic;
        data_i  : in  std_logic_vector(7 downto 0);
        -- arp tx
        valid_o : out std_logic;
        ready_i : in  std_logic;
        last_o  : out std_logic;
        data_o  : out std_logic_vector(7 downto 0);
        -- arp table
        mac_o   : out std_logic_vector(47 downto 0);
        ip_o    : out std_logic_vector(31 downto 0);
        store_o : out std_logic;
        done_i  : in  std_logic);
    end component arp_processing;

    component arp_table is
    generic (
        size_exp_g : positive);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- write
        mac_i        : in  std_logic_vector(47 downto 0);
        store_ip_i   : in  std_logic_vector(31 downto 0);
        store_i      : in  std_logic;
        done_o       : out std_logic;
        -- read
        request_ip_i : in  std_logic_vector(31 downto 0);
        request_i    : in  std_logic;
        mac_o        : out std_logic_vector(47 downto 0);
        mac_valid_o  : out std_logic);
    end component arp_table;

    signal arp_rx_valid     : std_logic;
    signal arp_rx_ready     : std_logic;
    signal arp_rx_last      : std_logic;
    signal arp_rx_data      : std_logic_vector(7 downto 0);

    signal arp_tx_valid     : std_logic;
    signal arp_tx_ready     : std_logic;
    signal arp_tx_last      : std_logic;
    signal arp_tx_data      : std_logic_vector(7 downto 0);

    signal arp_write_mac    : std_logic_vector(47 downto 0);
    signal arp_write_ip     : std_logic_vector(31 downto 0);
    signal arp_write_store  : std_logic;
    signal arp_write_done   : std_logic;

    signal arp_read_ip      : std_logic_vector(31 downto 0);
    signal arp_read_request : std_logic;
    signal arp_read_mac     : std_logic_vector(47 downto 0);
    signal arp_read_valid   : std_logic;

    signal mac_ready        : std_logic;
    signal mac_valid        : std_logic;
    signal mac_last         : std_logic;
    signal mac_data         : std_logic_vector(7 downto 0);

begin

    i_eth : eth_processing
    generic map (
        mac_address_g => mac_address_g)
    port map (
        clk_i            => clk_i,
        reset_i          => reset_i,
        -- mac rx
        mac_valid_i      => mac_valid_i,
        mac_ready_o      => mac_ready,
        mac_last_i       => mac_last_i,
        mac_data_i       => mac_data_i,
        -- arp rx
        arp_valid_o      => arp_rx_valid,
        arp_ready_i      => arp_rx_ready,
        arp_last_o       => arp_rx_last,
        arp_data_o       => arp_rx_data,
        -- ip rx
        ip_valid_o       => open,
        ip_ready_i       => '1',
        ip_last_o        => open,
        ip_data_o        => open,
        -- mac tx
        mac_valid_o      => mac_valid,
        mac_ready_i      => mac_ready_i,
        mac_last_o       => mac_last,
        mac_data_o       => mac_data,
        -- arp tx
        arp_valid_i      => arp_tx_valid,
        arp_ready_o      => arp_tx_ready,
        arp_last_i       => arp_tx_last,
        arp_data_i       => arp_tx_data,
        mac_i            => arp_write_mac,
        -- ip tx
        ip_valid_i       => '0',
        ip_ready_o       => open,
        ip_last_i        => '0',
        ip_data_i        => x"00",
        -- arp address request
        ip_addr_o        => arp_read_ip,
        ip_addr_req_o    => arp_read_request,
        mac_addr_i       => arp_read_mac,
        mac_addr_valid_i => arp_read_valid);

    i_arp : arp_processing
    generic map (
        mac_address_g => mac_address_g,
        ip_address_g  => ip_address_g)
    port map (
        clk_i   => clk_i,
        reset_i => reset_i,
        -- arp rx
        valid_i => arp_rx_valid,
        ready_o => arp_rx_ready,
        last_i  => arp_rx_last,
        data_i  => arp_rx_data,
        -- arp tx
        valid_o => arp_tx_valid,
        ready_i => arp_tx_ready,
        last_o  => arp_tx_last,
        data_o  => arp_tx_data,
        -- arp table
        mac_o   => arp_write_mac,
        ip_o    => arp_write_ip,
        store_o => arp_write_store,
        done_i  => arp_write_done);

    i_arp_table : arp_table
    generic map (
        size_exp_g => 3)
    port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        -- write
        mac_i        => arp_write_mac,
        store_ip_i   => arp_write_ip,
        store_i      => arp_write_store,
        done_o       => arp_write_done,
        -- read
        request_ip_i => arp_read_ip,
        request_i    => arp_read_request,
        mac_o        => arp_read_mac,
        mac_valid_o  => arp_read_valid);

    mac_ready_o <= mac_ready;
    mac_valid_o <= mac_valid;
    mac_last_o <= mac_last;
    mac_data_o <= mac_data;

end rtl;
