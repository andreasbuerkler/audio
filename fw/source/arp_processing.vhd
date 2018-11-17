--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 02.11.2018
-- Filename  : arp_processing.vhd
-- Changelog : 02.11.2018 - file created
--           : 17.11.2018 - arp table interface removed / packet_nr added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arp_processing is
generic (
    mac_address_g : std_logic_vector(47 downto 0) := x"010203040506";
    ip_address_g  : std_logic_vector(31 downto 0) := x"01020304");
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
end entity arp_processing;

architecture rtl of arp_processing is

    type tx_fsm_t is (idle_s, type_s, size_s, own_mac_s, own_ip_s, target_mac_s, target_ip_s);

    constant expected_hw_type_c   : std_logic_vector(15 downto 0) := x"0001";
    constant expected_protocol_c  : std_logic_vector(15 downto 0) := x"0800";
    constant expected_size_c      : std_logic_vector(15 downto 0) := x"0604";
    constant expected_operation_c : std_logic_vector(15 downto 0) := x"0001";
    constant response_operation_c : std_logic_vector(15 downto 0) := x"0002";

    signal rx_ready_r                : std_logic := '1';
    signal shift_r                   : std_logic_vector(47 downto 0) := (others => '0');
    signal rx_offset_counter_r       : unsigned(5 downto 0) := (others => '0');
    signal packet_nr_r               : std_logic_vector(7 downto 0) := (others => '0');
    signal hw_type_ok_r              : std_logic := '0';
    signal protocol_ok_r             : std_logic := '0';
    signal size_ok_r                 : std_logic := '0';
    signal send_request_r            : std_logic := '0';
    signal ip_matches_r              : std_logic := '0';
    signal sender_ip_r               : std_logic_vector(31 downto 0) := (others => '0');
    signal sender_mac_r              : std_logic_vector(47 downto 0) := (others => '0');
    signal send_response_r           : std_logic := '0';
    signal tx_offset_counter_r       : unsigned(5 downto 0) := (others => '0');
    signal tx_valid_r                : std_logic := '0';
    signal tx_last_r                 : std_logic := '0';

    signal tx_fsm_r        : tx_fsm_t := idle_s;
    signal tx_data_shift_r : std_logic_vector(47 downto 0) := (others => '0');

begin

    rx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then

            if ((valid_i = '1') and (rx_ready_r = '1')) then
                shift_r <= shift_r(shift_r'high-8 downto 0) & data_i;
                if (rx_offset_counter_r(rx_offset_counter_r'high) = '0') then
                    rx_offset_counter_r <= rx_offset_counter_r + 1;
                end if;
                if (rx_offset_counter_r = to_unsigned(1, rx_offset_counter_r'length)) then
                    packet_nr_r <= shift_r(7 downto 0);
                end if;
                if (rx_offset_counter_r = to_unsigned(3, rx_offset_counter_r'length)) then
                    if (shift_r(15 downto 0) = expected_hw_type_c) then
                        hw_type_ok_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(5, rx_offset_counter_r'length)) then
                    if (shift_r(15 downto 0) = expected_protocol_c) then
                        protocol_ok_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(7, rx_offset_counter_r'length)) then
                    if (shift_r(15 downto 0) = expected_size_c) then
                        size_ok_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(9, rx_offset_counter_r'length)) then
                    if (shift_r(15 downto 0) = expected_operation_c) then
                        send_request_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(15, rx_offset_counter_r'length)) then
                    sender_mac_r <= shift_r;
                end if;
                if (rx_offset_counter_r = to_unsigned(19, rx_offset_counter_r'length)) then
                    sender_ip_r <= shift_r(31 downto 0);
                end if;
                if (rx_offset_counter_r = to_unsigned(29, rx_offset_counter_r'length)) then
                    if (shift_r(31 downto 0) = ip_address_g) then
                        ip_matches_r <= '1';
                    end if;
                end if;
                if (last_i = '1') then
                    if (send_response_r = '1') then
                        rx_ready_r <= '0';
                    end if;
                    rx_offset_counter_r <= (others => '0');
                    hw_type_ok_r <= '0';
                    protocol_ok_r <= '0';
                    size_ok_r <= '0';
                    send_request_r <= '0';
                    ip_matches_r <= '0';
                end if;
            end if;

            if (tx_last_r = '1') then
                rx_ready_r <= '1';
                send_request_r <= '0';
            end if;

        end if;
    end process rx_proc;

    tx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((send_request_r and ip_matches_r and size_ok_r and protocol_ok_r and hw_type_ok_r) = '1') then
                send_response_r <= '1';
            end if;

            if ((tx_last_r = '1') and (ready_i = '1')) then
                send_response_r <= '0';
            end if;

            if ((ready_i = '1') and (tx_valid_r = '1')) then
                tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & '0';
            elsif (tx_valid_r = '0') then
                tx_offset_counter_r <= "000001";
            end if;

            if ((tx_fsm_r /= idle_s) and (tx_valid_r = '0')) then
                tx_valid_r <= '1';
            end if;

            case (tx_fsm_r) is
                when idle_s =>
                    tx_valid_r <= '0';
                    tx_last_r <= '0';
                    tx_data_shift_r <= packet_nr_r & expected_hw_type_c & expected_protocol_c & x"00";
                    if (send_response_r = '1') then
                        tx_fsm_r <= type_s;
                    end if;

                when type_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(4) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= expected_size_c & response_operation_c & x"0000";
                            tx_fsm_r <= size_s;
                        else
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    else
                        tx_valid_r <= '1';
                    end if;

                when size_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(3) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= mac_address_g;
                            tx_fsm_r <= own_mac_s;
                        else
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    else
                        tx_valid_r <= '1';
                    end if;

                when own_mac_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= ip_address_g & x"0000";
                            tx_fsm_r <= own_ip_s;
                        else
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    else
                        tx_valid_r <= '1';
                    end if;

                when own_ip_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(3) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= sender_mac_r;
                            tx_fsm_r <= target_mac_s;
                        else
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    else
                        tx_valid_r <= '1';
                    end if;

                when target_mac_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= sender_ip_r & x"0000";
                            tx_fsm_r <= target_ip_s;
                        else
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    else
                        tx_valid_r <= '1';
                    end if;

                when target_ip_s =>
                    if ((ready_i = '1') and (tx_valid_r = '1')) then
                        if (tx_offset_counter_r(3) = '1') then
                            tx_valid_r <= '0';
                            tx_fsm_r <= idle_s;
                        end if;
                        if (tx_offset_counter_r(2) = '1') then
                            tx_last_r <= '1';
                        else
                            tx_last_r <= '0';
                        end if;
                        tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                    else
                        tx_valid_r <= '1';
                    end if;

            end case;

        end if;
    end process tx_proc;

    ready_o <= rx_ready_r;

    valid_o <= tx_valid_r;
    last_o <= tx_last_r;
    data_o <= tx_data_shift_r(47 downto 40);

end rtl;
