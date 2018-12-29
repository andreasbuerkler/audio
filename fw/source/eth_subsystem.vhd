--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 10.11.2018
-- Filename  : eth_subsystem.vhd
-- Changelog : 10.11.2018 - file created
--             17.11.2018 - arp table removed
--             24.12.2018 - udp added
--             29.12.2018 - ctrl added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_subsystem is
generic (
    mac_address_g        : std_logic_vector(47 downto 0) := x"010203040506";
    ip_address_g         : std_logic_vector(31 downto 0) := x"01020304";
    ctrl_port_g          : std_logic_vector(15 downto 0) := x"0102";
    ctrl_address_width_g : positive := 16;
    ctrl_data_width_g    : positive := 32);
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
end entity eth_subsystem;

architecture rtl of eth_subsystem is

    component eth_processing is
    generic (
        mac_address_g : std_logic_vector(47 downto 0));
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        -- mac rx
        mac_valid_i : in  std_logic;
        mac_ready_o : out std_logic;
        mac_last_i  : in  std_logic;
        mac_data_i  : in  std_logic_vector(7 downto 0);
        -- arp rx
        arp_valid_o : out std_logic;
        arp_ready_i : in  std_logic;
        arp_last_o  : out std_logic;
        arp_data_o  : out std_logic_vector(7 downto 0);
        -- ip rx
        ip_valid_o  : out std_logic;
        ip_ready_i  : in  std_logic;
        ip_last_o   : out std_logic;
        ip_data_o   : out std_logic_vector(7 downto 0);
        -- mac tx
        mac_valid_o : out std_logic;
        mac_ready_i : in  std_logic;
        mac_last_o  : out std_logic;
        mac_data_o  : out std_logic_vector(7 downto 0);
        -- arp tx
        arp_valid_i : in  std_logic;
        arp_ready_o : out std_logic;
        arp_last_i  : in  std_logic;
        arp_data_i  : in  std_logic_vector(7 downto 0);
        -- ip tx
        ip_valid_i  : in  std_logic;
        ip_ready_o  : out std_logic;
        ip_last_i   : in  std_logic;
        ip_data_i   : in  std_logic_vector(7 downto 0));
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
        data_o  : out std_logic_vector(7 downto 0));
    end component arp_processing;

    component eth_ip is
    generic (
        ip_address_g : std_logic_vector(31 downto 0) := x"01020304");
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- eth rx
        eth_valid_i  : in  std_logic;
        eth_ready_o  : out std_logic;
        eth_last_i   : in  std_logic;
        eth_data_i   : in  std_logic_vector(7 downto 0);
        -- udp rx
        udp_valid_o  : out std_logic;
        udp_ready_i  : in  std_logic;
        udp_last_o   : out std_logic;
        udp_data_o   : out std_logic_vector(7 downto 0);
        -- icmp rx
        icmp_valid_o : out std_logic;
        icmp_ready_i : in  std_logic;
        icmp_last_o  : out std_logic;
        icmp_data_o  : out std_logic_vector(7 downto 0);
        -- eth tx
        eth_valid_o  : out std_logic;
        eth_ready_i  : in  std_logic;
        eth_last_o   : out std_logic;
        eth_data_o   : out std_logic_vector(7 downto 0);
        -- udp tx
        udp_valid_i  : in  std_logic;
        udp_ready_o  : out std_logic;
        udp_last_i   : in  std_logic;
        udp_data_i   : in  std_logic_vector(7 downto 0);
        -- icmp tx
        icmp_valid_i : in  std_logic;
        icmp_ready_o : out std_logic;
        icmp_last_i  : in  std_logic;
        icmp_data_i  : in  std_logic_vector(7 downto 0));
    end component eth_ip;

    component eth_icmp is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- icmp tx
        icmp_valid_o : out std_logic;
        icmp_ready_i : in  std_logic;
        icmp_last_o  : out std_logic;
        icmp_data_o  : out std_logic_vector(7 downto 0);
        -- icmp rx
        icmp_valid_i : in  std_logic;
        icmp_ready_o : out std_logic;
        icmp_last_i  : in  std_logic;
        icmp_data_i  : in  std_logic_vector(7 downto 0));
    end component eth_icmp;

    component eth_udp is
    generic (
        ctrl_port_g : std_logic_vector(15 downto 0));
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- udp rx
        udp_valid_i  : in  std_logic;
        udp_ready_o  : out std_logic;
        udp_last_i   : in  std_logic;
        udp_data_i   : in  std_logic_vector(7 downto 0);
        -- udp tx
        udp_valid_o  : out std_logic;
        udp_ready_i  : in  std_logic;
        udp_last_o   : out std_logic;
        udp_data_o   : out std_logic_vector(7 downto 0);
        -- ctrl rx
        ctrl_valid_o : out std_logic;
        ctrl_ready_i : in  std_logic;
        ctrl_last_o  : out std_logic;
        ctrl_data_o  : out std_logic_vector(7 downto 0);
        -- ctrl tx
        ctrl_valid_i : in  std_logic;
        ctrl_ready_o : out std_logic;
        ctrl_last_i  : in  std_logic;
        ctrl_data_i  : in  std_logic_vector(7 downto 0));
    end component eth_udp;

    component eth_ctrl is
    generic (
        address_width_g : positive;
        data_width_g    : positive);
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        -- udp tx
        udp_valid_o : out std_logic;
        udp_ready_i : in  std_logic;
        udp_last_o  : out std_logic;
        udp_data_o  : out std_logic_vector(7 downto 0);
        -- udp rx
        udp_valid_i : in  std_logic;
        udp_ready_o : out std_logic;
        udp_last_i  : in  std_logic;
        udp_data_i  : in  std_logic_vector(7 downto 0);
        -- ctrl bus
        address_o   : out std_logic_vector(address_width_g-1 downto 0);
        data_o      : out std_logic_vector(data_width_g-1 downto 0);
        data_i      : in  std_logic_vector(data_width_g-1 downto 0);
        strobe_o    : out std_logic;
        write_o     : out std_logic;
        ack_i       : in  std_logic);
    end component eth_ctrl;

    signal arp_rx_valid  : std_logic;
    signal arp_rx_ready  : std_logic;
    signal arp_rx_last   : std_logic;
    signal arp_rx_data   : std_logic_vector(7 downto 0);

    signal arp_tx_valid  : std_logic;
    signal arp_tx_ready  : std_logic;
    signal arp_tx_last   : std_logic;
    signal arp_tx_data   : std_logic_vector(7 downto 0);

    signal ip_rx_valid   : std_logic;
    signal ip_rx_ready   : std_logic;
    signal ip_rx_last    : std_logic;
    signal ip_rx_data    : std_logic_vector(7 downto 0);

    signal udp_rx_valid  : std_logic;
    signal udp_rx_ready  : std_logic;
    signal udp_rx_last   : std_logic;
    signal udp_rx_data   : std_logic_vector(7 downto 0);

    signal ctrl_rx_valid : std_logic;
    signal ctrl_rx_ready : std_logic;
    signal ctrl_rx_last  : std_logic;
    signal ctrl_rx_data  : std_logic_vector(7 downto 0);

    signal ctrl_tx_valid : std_logic;
    signal ctrl_tx_ready : std_logic;
    signal ctrl_tx_last  : std_logic;
    signal ctrl_tx_data  : std_logic_vector(7 downto 0);

    signal udp_tx_valid  : std_logic;
    signal udp_tx_ready  : std_logic;
    signal udp_tx_last   : std_logic;
    signal udp_tx_data   : std_logic_vector(7 downto 0);

    signal ip_tx_valid   : std_logic;
    signal ip_tx_ready   : std_logic;
    signal ip_tx_last    : std_logic;
    signal ip_tx_data    : std_logic_vector(7 downto 0);

    signal icmp_rx_valid : std_logic;
    signal icmp_rx_ready : std_logic;
    signal icmp_rx_last  : std_logic;
    signal icmp_rx_data  : std_logic_vector(7 downto 0);

    signal icmp_tx_valid : std_logic;
    signal icmp_tx_ready : std_logic;
    signal icmp_tx_last  : std_logic;
    signal icmp_tx_data  : std_logic_vector(7 downto 0);

    signal mac_ready     : std_logic;
    signal mac_valid     : std_logic;
    signal mac_last      : std_logic;
    signal mac_data      : std_logic_vector(7 downto 0);

    signal ctrl_address : std_logic_vector(ctrl_address_width_g-1 downto 0);
    signal ctrl_data    : std_logic_vector(ctrl_data_width_g-1 downto 0);
    signal ctrl_strobe  : std_logic;
    signal ctrl_write   : std_logic;

begin

    i_eth : eth_processing
    generic map (
        mac_address_g => mac_address_g)
    port map (
        clk_i       => clk_i,
        reset_i     => reset_i,
        -- mac rx
        mac_valid_i => mac_valid_i,
        mac_ready_o => mac_ready,
        mac_last_i  => mac_last_i,
        mac_data_i  => mac_data_i,
        -- arp rx
        arp_valid_o => arp_rx_valid,
        arp_ready_i => arp_rx_ready,
        arp_last_o  => arp_rx_last,
        arp_data_o  => arp_rx_data,
        -- ip rx
        ip_valid_o  => ip_rx_valid,
        ip_ready_i  => ip_rx_ready,
        ip_last_o   => ip_rx_last,
        ip_data_o   => ip_rx_data,
        -- mac tx
        mac_valid_o => mac_valid,
        mac_ready_i => mac_ready_i,
        mac_last_o  => mac_last,
        mac_data_o  => mac_data,
        -- arp tx
        arp_valid_i => arp_tx_valid,
        arp_ready_o => arp_tx_ready,
        arp_last_i  => arp_tx_last,
        arp_data_i  => arp_tx_data,
        -- ip tx
        ip_valid_i  => ip_tx_valid,
        ip_ready_o  => ip_tx_ready,
        ip_last_i   => ip_tx_last,
        ip_data_i   => ip_tx_data);

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
        data_o  => arp_tx_data);

    i_ip : eth_ip
    generic map (
        ip_address_g => ip_address_g)
    port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        -- eth rx
        eth_valid_i  => ip_rx_valid,
        eth_ready_o  => ip_rx_ready,
        eth_last_i   => ip_rx_last,
        eth_data_i   => ip_rx_data,
        -- udp rx
        udp_valid_o  => udp_rx_valid,
        udp_ready_i  => udp_rx_ready,
        udp_last_o   => udp_rx_last,
        udp_data_o   => udp_rx_data,
        -- icmp rx
        icmp_valid_o => icmp_rx_valid,
        icmp_ready_i => icmp_rx_ready,
        icmp_last_o  => icmp_rx_last,
        icmp_data_o  => icmp_rx_data,
        -- eth tx
        eth_valid_o  => ip_tx_valid,
        eth_ready_i  => ip_tx_ready,
        eth_last_o   => ip_tx_last,
        eth_data_o   => ip_tx_data,
        -- udp tx
        udp_valid_i  => udp_tx_valid,
        udp_ready_o  => udp_tx_ready,
        udp_last_i   => udp_tx_last,
        udp_data_i   => udp_tx_data,
        -- icmp tx
        icmp_valid_i => icmp_tx_valid,
        icmp_ready_o => icmp_tx_ready,
        icmp_last_i  => icmp_tx_last,
        icmp_data_i  => icmp_tx_data);

    i_icmp : eth_icmp
    port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        -- icmp tx
        icmp_valid_o => icmp_tx_valid,
        icmp_ready_i => icmp_tx_ready,
        icmp_last_o  => icmp_tx_last,
        icmp_data_o  => icmp_tx_data,
        -- icmp rx
        icmp_valid_i => icmp_rx_valid,
        icmp_ready_o => icmp_rx_ready,
        icmp_last_i  => icmp_rx_last,
        icmp_data_i  => icmp_rx_data);

    i_udp : eth_udp
    generic map (
        ctrl_port_g => ctrl_port_g)
    port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        -- udp rx
        udp_valid_i  => udp_rx_valid,
        udp_ready_o  => udp_rx_ready,
        udp_last_i   => udp_rx_last,
        udp_data_i   => udp_rx_data,
        -- udp tx
        udp_valid_o  => udp_tx_valid,
        udp_ready_i  => udp_tx_ready,
        udp_last_o   => udp_tx_last,
        udp_data_o   => udp_tx_data,
        -- ctrl rx
        ctrl_valid_o => ctrl_rx_valid,
        ctrl_ready_i => ctrl_rx_ready,
        ctrl_last_o  => ctrl_rx_last,
        ctrl_data_o  => ctrl_rx_data,
        -- ctrl tx
        ctrl_valid_i => ctrl_tx_valid,
        ctrl_ready_o => ctrl_tx_ready,
        ctrl_last_i  => ctrl_tx_last,
        ctrl_data_i  => ctrl_tx_data);

    i_ctrl : eth_ctrl
    generic map (
        address_width_g => ctrl_address_width_g,
        data_width_g    => ctrl_data_width_g)
    port map (
        clk_i       => clk_i,
        reset_i     => reset_i,
        -- udp tx
        udp_valid_o => ctrl_tx_valid,
        udp_ready_i => ctrl_tx_ready,
        udp_last_o  => ctrl_tx_last,
        udp_data_o  => ctrl_tx_data,
        -- udp rx
        udp_valid_i => ctrl_rx_valid,
        udp_ready_o => ctrl_rx_ready,
        udp_last_i  => ctrl_rx_last,
        udp_data_i  => ctrl_rx_data,
        -- ctrl bus
        address_o   => ctrl_address,
        data_o      => ctrl_data,
        data_i      => ctrl_data_i,
        strobe_o    => ctrl_strobe,
        write_o     => ctrl_write,
        ack_i       => ctrl_ack_i);

    mac_ready_o <= mac_ready;
    mac_valid_o <= mac_valid;
    mac_last_o <= mac_last;
    mac_data_o <= mac_data;

    ctrl_address_o <= ctrl_address;
    ctrl_data_o <= ctrl_data;
    ctrl_strobe_o <= ctrl_strobe;
    ctrl_write_o <= ctrl_write;

end rtl;
