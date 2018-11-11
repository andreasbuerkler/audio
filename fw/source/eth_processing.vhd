--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 02.11.2018
-- Filename  : eth_processing.vhd
-- Changelog : 02.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_processing is
generic (
    mac_address_g : std_logic_vector(47 downto 0) := x"010203040506");
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
end entity eth_processing;

architecture rtl of eth_processing is

    type tx_fsm_t is (idle_s, destination_s, source_s, type_s, payload_s);

    constant addr_broadcast_c : std_logic_vector(47 downto 0) := x"FFFFFFFFFFFF";
    constant type_vlan_c      : std_logic_vector(15 downto 0) := x"8100";
    constant type_ip_c        : std_logic_vector(15 downto 0) := x"0800";
    constant type_arp_c       : std_logic_vector(15 downto 0) := x"0806";

    signal rx_offset_counter_r     : unsigned(5 downto 0) := (others => '0');
    signal rx_shift_r              : std_logic_vector(47 downto 0) := (others => '0');
    signal rx_type_r               : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_vlan_tag_detected_r  : std_logic := '0';
    signal rx_is_ip_r              : std_logic := '0';
    signal rx_is_arp_r             : std_logic := '0';
    signal rx_address_valid_r      : std_logic := '0';
    signal rx_broadcast_detected_r : std_logic := '0';
    signal rx_last_r               : std_logic := '0';

    signal tx_fsm_r            : tx_fsm_t := idle_s;
    signal payload_r           : std_logic := '0';
    signal tx_offset_counter_r : std_logic_vector(5 downto 0) := (others => '0');
    signal tx_data_r           : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_valid_r          : std_logic := '0';
    signal tx_data_shift_r     : std_logic_vector(47 downto 0) := (others => '0');

begin

    rx_filter_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((rx_last_r = '1') and (((arp_ready_i = '1') and (rx_is_arp_r = '1')) or ((ip_ready_i = '1') and (rx_is_ip_r = '1')))) then
                rx_last_r <= '0';
                rx_is_ip_r <= '0';
                rx_is_arp_r <= '0';
            end if;
            if (rx_last_r = '1') then
                rx_address_valid_r <= '0';
                rx_vlan_tag_detected_r <= '0';
                rx_broadcast_detected_r <= '0';
            end if;
            if ((mac_valid_i = '1') and (arp_ready_i = '1') and (ip_ready_i = '1')) then
                rx_shift_r <= rx_shift_r(rx_shift_r'high-8 downto 0) & mac_data_i;
                rx_last_r <= (rx_is_arp_r or rx_is_ip_r) and mac_last_i;
                if (mac_last_i = '1') then
                    rx_offset_counter_r <= (others => '0');
                elsif (rx_offset_counter_r(rx_offset_counter_r'high) = '0') then
                    rx_offset_counter_r <= rx_offset_counter_r + 1;
                end if;
                if (rx_offset_counter_r = to_unsigned(6, rx_offset_counter_r'length)) then
                    if (rx_shift_r = mac_address_g) then
                        rx_address_valid_r <= '1';
                    elsif (rx_shift_r = addr_broadcast_c) then
                        rx_broadcast_detected_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(14, rx_offset_counter_r'length)) then
                    if (rx_shift_r(15 downto 0) = type_vlan_c) then
                        rx_vlan_tag_detected_r <= rx_address_valid_r or rx_broadcast_detected_r;
                    elsif (rx_shift_r(15 downto 0) = type_ip_c) then
                        rx_is_ip_r <= rx_address_valid_r or rx_broadcast_detected_r;
                    elsif (rx_shift_r(15 downto 0) = type_arp_c) then
                        rx_is_arp_r <= rx_address_valid_r or rx_broadcast_detected_r;
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(18, rx_offset_counter_r'length)) then
                    if (rx_shift_r(15 downto 0) = type_ip_c) then
                        rx_is_ip_r <= rx_vlan_tag_detected_r;
                    elsif (rx_shift_r(15 downto 0) = type_arp_c) then
                        rx_is_arp_r <= rx_vlan_tag_detected_r;
                    end if;
                end if;
            end if;
        end if;
    end process rx_filter_proc;

    tx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            case (tx_fsm_r) is
                when idle_s =>
                    payload_r <= '0';
                    tx_valid_r <= '0';
                    tx_offset_counter_r <= (others => '0');
                    tx_data_shift_r <= mac_i;
                    if (arp_valid_i = '1') then
                        tx_fsm_r <= destination_s;
                    end if;

                when destination_s =>
                    if (mac_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= mac_address_g;
                            tx_fsm_r <= source_s;
                        else
                            tx_valid_r <= '1';
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                        tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not tx_valid_r);
                        tx_data_r <= tx_data_shift_r(47 downto 40);
                    end if;

                when source_s =>
                    if (mac_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= type_arp_c & x"00000000";
                            tx_fsm_r <= type_s;
                        else
                            tx_valid_r <= '1';
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                        tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not tx_valid_r);
                        tx_data_r <= tx_data_shift_r(47 downto 40);
                    end if;

                when type_s =>
                    if (mac_ready_i = '1') then
                        if (tx_offset_counter_r(1) = '1') then
                            tx_valid_r <= '0';
                            tx_fsm_r <= payload_s;
                        else
                            tx_valid_r <= '1';
                        end if;
                        tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not tx_valid_r);
                        tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        tx_data_r <= tx_data_shift_r(47 downto 40);
                    end if;

                when payload_s =>
                    if ((arp_last_i = '1') and (arp_valid_i = '1') and (mac_ready_i = '1')) then
                        payload_r <= '0';
                        tx_fsm_r <= idle_s;
                    else
                        payload_r <= '1';
                    end if;

            end case;

        end if;
    end process tx_proc;

    -- rx output signals
    mac_ready_o <= arp_ready_i and ip_ready_i;
    arp_valid_o <= rx_is_arp_r;
    arp_last_o <= rx_last_r;
    arp_data_o <= rx_shift_r(7 downto 0);
    ip_valid_o <= rx_is_ip_r;
    ip_last_o <= rx_last_r;
    ip_data_o <= rx_shift_r(7 downto 0);

    -- tx output signals
    arp_ready_o <= mac_ready_i when (payload_r = '1') else '0';
    mac_valid_o <= arp_valid_i when (payload_r = '1') else tx_valid_r;
    mac_last_o <= arp_last_i when (payload_r = '1') else '0';
    mac_data_o <= arp_data_i when (payload_r = '1') else tx_data_r;

    ip_addr_o <= x"00000000";
    ip_addr_req_o <= '0';

end rtl;
