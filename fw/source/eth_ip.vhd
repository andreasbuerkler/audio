--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 11.11.2018
-- Filename  : eth_ip.vhd
-- Changelog : 11.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_ip is
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
end entity eth_ip;

architecture rtl of eth_ip is

    component ram is
    generic (
        addr_width_g   : positive;
        data_width_g   : positive);
    port (
        clk_i     : in  std_logic;
        -- write port
        wr_data_i : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i      : in  std_logic;
        wr_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
        -- read port
        rd_data_o : out std_logic_vector(data_width_g-1 downto 0);
        rd_i      : in  std_logic;
        rd_addr_i : in  std_logic_vector(addr_width_g-1 downto 0));
    end component ram;

    constant type_udp_c        : std_logic_vector(7 downto 0) := x"11";
    constant type_icmp_c       : std_logic_vector(7 downto 0) := x"01";
    constant ip_version_c      : std_logic_vector(3 downto 0) := x"4";
    constant header_length_c   : std_logic_vector(3 downto 0) := x"5";
    constant type_of_service_c : std_logic_vector(7 downto 0) := x"00";
    constant ttl_c             : std_logic_vector(7 downto 0) := x"FF";

    function checksum_init return std_logic_vector is
        variable retval : std_logic_vector(15 downto 0);
    begin
        retval := checksum_add(ip_address_g(31 downto 16), ip_address_g(15 downto 0));
        retval := checksum_add(retval, ip_version_c & header_length_c & type_of_service_c);
        retval := checksum_add(retval, ttl_c & x"00");
        return std_logic_vector(retval);
    end checksum_init;

    constant checksum_load_icmp_c : std_logic_vector(15 downto 0) := checksum_add(checksum_init, type_icmp_c);
    constant checksum_load_udp_c  : std_logic_vector(15 downto 0) := checksum_add(checksum_init, type_udp_c);

    type tx_fsm_t is (idle_s, size_icmp_s, size_udp_s, checksum_calc_s, packet_nr_s, length_s,
                      flags_s, checksum_s, source_address_s, destination_address_s, payload_s);

    signal rx_packet_nr_r         : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_write_en_r          : std_logic := '0';
    signal rx_write_addr          : std_logic_vector(9 downto 0);
    signal rx_offset_counter_r    : unsigned(5 downto 0) := (others => '0');
    signal rx_shift_r             : std_logic_vector(23 downto 0) := (others => '0');
    signal rx_address_valid_r     : std_logic := '0';
    signal rx_is_udp_r            : std_logic := '0';
    signal rx_is_icmp_r           : std_logic := '0';
    signal rx_header_length_r     : std_logic_vector(5 downto 0) := (others => '0');
    signal rx_version_4_r         : std_logic := '0';
    signal rx_add_en_r            : std_logic := '0';
    signal rx_checksum_r          : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_last_r              : std_logic := '0';
    signal rx_transmit_packet_r   : std_logic := '0';
    signal rx_send_nr_r           : std_logic := '0';
    signal rx_total_length_r      : unsigned(15 downto 0) := (others => '0');
    signal rx_remove_padding_en_r : std_logic := '0';

    signal tx_fsm_r               : tx_fsm_t := idle_s;
    signal tx_length_r            : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_offset_counter_r    : std_logic_vector(3 downto 0) := (others => '0');
    signal tx_icmp_ready_r        : std_logic := '0';
    signal tx_udp_ready_r         : std_logic := '0';
    signal tx_packet_nr_r         : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_read_addr           : std_logic_vector(9 downto 0);
    signal tx_read_en             : std_logic;
    signal tx_data_shift_r        : std_logic_vector(31 downto 0) := (others => '0');
    signal payload_icmp_r         : std_logic := '0';
    signal payload_udp_r          : std_logic := '0';
    signal tx_valid_r             : std_logic := '0';
    signal tx_data_r              : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_ip                  : std_logic_vector(7 downto 0);
    signal tx_ip_counter_r        : unsigned(1 downto 0) := (others => '0');
    signal tx_identification_r    : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_checksum_r          : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_ip_read_en_r        : std_logic := '0';
    signal tx_ip_r                : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_is_icmp_r           : std_logic := '0';
    signal tx_offset_counter_en_r : std_logic_vector(3 downto 0) := (others => '0');
    signal tx_data_mux_ctrl_r     : std_logic := '0';
    signal tx_ip_counter_en_r     : std_logic := '0';
    signal tx_data_mux_ip_sel_r   : std_logic := '0';

begin

    rx_write_addr <= rx_packet_nr_r & std_logic_vector(rx_offset_counter_r(1 downto 0));
    tx_read_addr <= tx_packet_nr_r & std_logic_vector(tx_ip_counter_r);
    tx_read_en <= (eth_ready_i and tx_valid_r) or tx_ip_read_en_r;

    i_ram : ram
    generic map (
        addr_width_g => 10,
        data_width_g => 8)
    port map (
        clk_i     => clk_i,
        -- write port
        wr_data_i => rx_shift_r(7 downto 0),
        wr_i      => rx_write_en_r,
        wr_addr_i => rx_write_addr,
        -- read port
        rd_data_o => tx_ip,
        rd_i      => tx_read_en,
        rd_addr_i => tx_read_addr);

    rx_checksum_proc : process (clk_i)
        variable rx_checksum_v : unsigned(16 downto 0);
    begin
        if (rising_edge(clk_i)) then
            if ((eth_valid_i = '1') and (udp_ready_i = '1') and (icmp_ready_i = '1')) then
                if (eth_last_i = '1') then
                    rx_checksum_r <= (others => '0');
                elsif ((rx_add_en_r = '1') and (rx_offset_counter_r(0) = '0')) then
                    rx_checksum_v := resize(unsigned(rx_checksum_r), 17) + (unsigned(rx_shift_r(7 downto 0)) & unsigned(eth_data_i));
                    if (rx_checksum_v(rx_checksum_v'high) = '1') then
                        rx_checksum_r <= std_logic_vector(rx_checksum_v(rx_checksum_r'range) + 1);
                    else
                        rx_checksum_r <= std_logic_vector(rx_checksum_v(rx_checksum_r'range));
                    end if;
                end if;
            end if;
        end if;
    end process rx_checksum_proc;

    rx_filter_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then

            if (((udp_ready_i = '1') and (rx_is_udp_r = '1')) or ((icmp_ready_i = '1') and (rx_is_icmp_r = '1'))) then
                rx_send_nr_r <= '0';
                if (rx_last_r = '1') then
                    rx_last_r <= '0';
                    rx_is_udp_r <= '0';
                    rx_is_icmp_r <= '0';
                    rx_transmit_packet_r <= '0';
                end if;
            end if;
            if (rx_last_r = '1') then
                rx_address_valid_r <= '0';
                rx_version_4_r <= '0';
            end if;
            if (eth_last_i = '1') then
                rx_remove_padding_en_r <= '0';
            end if;

            if ((eth_valid_i = '1') and (udp_ready_i = '1') and (icmp_ready_i = '1') and (rx_send_nr_r = '0')) then
                if (eth_last_i = '1') then
                    rx_offset_counter_r <= (others => '0');
                elsif (rx_offset_counter_r(rx_offset_counter_r'high) = '0') then
                    rx_offset_counter_r <= rx_offset_counter_r + 1;
                end if;
            end if;

            if ((eth_valid_i = '1') and (udp_ready_i = '1') and (icmp_ready_i = '1') and (rx_send_nr_r = '0')) then
                if (eth_last_i = '1') then
                    rx_total_length_r <= (others => '0');
                elsif (rx_offset_counter_r = to_unsigned(5, rx_offset_counter_r'length)) then
                    rx_total_length_r <= unsigned(rx_shift_r(15 downto 0));
                else
                    rx_total_length_r <= rx_total_length_r - 1;
                end if;
            end if;

            if ((eth_valid_i = '1') and (udp_ready_i = '1') and (icmp_ready_i = '1') and (rx_send_nr_r = '0')) then
                rx_shift_r <= rx_shift_r(rx_shift_r'high-8 downto 0) & eth_data_i;
                rx_last_r <= (rx_is_udp_r or rx_is_icmp_r) and eth_last_i;
                if (rx_total_length_r = to_unsigned(6, rx_total_length_r'length)) then
                    rx_remove_padding_en_r <= not eth_last_i;
                    rx_last_r <= '1';
                end if;
                if (rx_offset_counter_r = to_unsigned(1, rx_offset_counter_r'length)) then
                    rx_packet_nr_r <= rx_shift_r(7 downto 0);
                    rx_add_en_r <= '1';
                end if;
                if (rx_offset_counter_r = to_unsigned(2, rx_offset_counter_r'length)) then
                    rx_header_length_r <= rx_shift_r(3 downto 0) & "00";
                    if (rx_shift_r(7 downto 4) = x"4") then
                        rx_version_4_r <= '1';
                    end if;
                elsif (unsigned(rx_header_length_r) /= to_unsigned(0, rx_header_length_r'length)) then
                    rx_header_length_r <= std_logic_vector(unsigned(rx_header_length_r) - 1);
                end if;
                if (rx_offset_counter_r = to_unsigned(11, rx_offset_counter_r'length)) then
                    if (rx_shift_r(7 downto 0) = type_udp_c) then
                        rx_is_udp_r <= '1';
                    elsif (rx_shift_r(7 downto 0) = type_icmp_c) then
                        rx_is_icmp_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(13, rx_offset_counter_r'length)) then
                    rx_write_en_r <= '1';
                end if;
                if (rx_offset_counter_r = to_unsigned(17, rx_offset_counter_r'length)) then
                    rx_write_en_r <= '0';
                end if;
                if (rx_offset_counter_r = to_unsigned(20, rx_offset_counter_r'length)) then
                    if ((rx_shift_r & eth_data_i) = ip_address_g) then
                        rx_address_valid_r <= '1';
                    end if;
                end if;
                if (unsigned(rx_header_length_r) = to_unsigned(3, rx_header_length_r'length)) then
                    rx_add_en_r <= '0';
                end if;
                if (unsigned(rx_header_length_r) = to_unsigned(2, rx_header_length_r'length)) then
                    if ((rx_checksum_r = x"FFFF") and (rx_version_4_r = '1') and (rx_address_valid_r = '1')) then
                        rx_transmit_packet_r <= '1';
                        rx_send_nr_r <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process rx_filter_proc;

    tx_packet_gen_proc : process (clk_i)
        variable packet_length_v : unsigned(15 downto 0);
    begin
        if (rising_edge(clk_i)) then
            tx_icmp_ready_r <= '0';
            tx_ip_r <= tx_ip;

            case (tx_fsm_r) is
                when idle_s =>
                    payload_icmp_r <= '0';
                    payload_udp_r <= '0';
                    tx_valid_r <= '0';
                    tx_data_mux_ctrl_r <= '0';

                    if (icmp_valid_i = '1') then
                        tx_is_icmp_r <= '1';
                        tx_icmp_ready_r <= '1';
                        tx_checksum_r <= checksum_add(checksum_load_icmp_c, tx_identification_r);
                        tx_packet_nr_r <= icmp_data_i;
                        tx_offset_counter_en_r(0) <= '1';
                        tx_fsm_r <= size_icmp_s;
                    elsif (udp_valid_i = '1') then
                        tx_is_icmp_r <= '0';
                        tx_udp_ready_r <= '1';
                        tx_checksum_r <= checksum_add(checksum_load_udp_c, tx_identification_r);
                        tx_packet_nr_r <= udp_data_i;
                        tx_offset_counter_en_r(1) <= '1';
                        tx_fsm_r <= size_udp_s;
                    end if;

                when size_icmp_s =>
                    if (icmp_valid_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            packet_length_v := (unsigned(tx_length_r) & unsigned(icmp_data_i)) + (unsigned(header_length_c) & to_unsigned(0, 2));
                            tx_data_shift_r <= ip_version_c & header_length_c & type_of_service_c & std_logic_vector(packet_length_v);
                            tx_icmp_ready_r <= '0';
                            tx_ip_read_en_r <= '1';
                            tx_offset_counter_en_r(2) <= '1';
                            tx_ip_counter_en_r <= '1';
                            tx_fsm_r <= checksum_calc_s;
                        else
                            tx_icmp_ready_r <= '1';
                            tx_length_r <= icmp_data_i;
                        end if;
                    end if;

                when size_udp_s =>
                    if (udp_valid_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            packet_length_v := (unsigned(tx_length_r) & unsigned(udp_data_i)) + (unsigned(header_length_c) & to_unsigned(0, 2));
                            tx_data_shift_r <= ip_version_c & header_length_c & type_of_service_c & std_logic_vector(packet_length_v);
                            tx_udp_ready_r <= '0';
                            tx_ip_read_en_r <= '1';
                            tx_offset_counter_en_r(2) <= '1';
                            tx_ip_counter_en_r <= '1';
                            tx_fsm_r <= checksum_calc_s;
                        else
                            tx_udp_ready_r <= '1';
                            tx_length_r <= udp_data_i;
                        end if;
                    end if;

                when checksum_calc_s =>
                    if (vector_or(tx_offset_counter_r) = '0') then
                        tx_checksum_r <= checksum_add(tx_checksum_r, tx_data_shift_r(15 downto 0));
                    elsif ((tx_offset_counter_r(1) = '1') or (tx_offset_counter_r(3) = '1')) then
                        tx_checksum_r <= checksum_add(tx_checksum_r, tx_ip_r & tx_ip);
                    end if;
                    if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                        tx_ip_read_en_r <= '0';
                        tx_offset_counter_en_r(3) <= '1';
                        tx_ip_counter_en_r <= '0';
                        tx_fsm_r <= packet_nr_s;
                    end if;

                when packet_nr_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_fsm_r <= length_s;
                        end if;
                        tx_data_mux_ctrl_r <= '1';
                        tx_valid_r <= '0';
                    else
                        tx_valid_r <= not tx_data_mux_ctrl_r;
                    end if;

                when length_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= tx_identification_r & x"0000";
                            tx_fsm_r <= flags_s;
                        else
                            tx_valid_r <= '1';
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    end if;

                when flags_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            if (tx_is_icmp_r = '1') then
                                tx_data_shift_r <= ttl_c & type_icmp_c & (not tx_checksum_r);
                            else
                                tx_data_shift_r <= ttl_c & type_udp_c & (not tx_checksum_r);
                            end if;
                            tx_fsm_r <= checksum_s;
                        else
                            tx_valid_r <= '1';
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    end if;

                when checksum_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_shift_r <= ip_address_g;
                            tx_fsm_r <= source_address_s;
                        else
                            tx_valid_r <= '1';
                            tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                        end if;
                    end if;

                when source_address_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_data_mux_ip_sel_r <= '1';
                            tx_fsm_r <= destination_address_s;
                        else
                            tx_valid_r <= '1';
                        end if;
                        if (tx_offset_counter_r(tx_offset_counter_r'high-1) = '1') then
                            tx_ip_counter_en_r <= '1';
                        end if;
                        tx_data_shift_r <= tx_data_shift_r(tx_data_shift_r'high-8 downto 0) & x"00";
                    end if;

                when destination_address_s =>
                    if (eth_ready_i = '1') then
                        if (tx_offset_counter_r(tx_offset_counter_r'high) = '1') then
                            tx_valid_r <= '0';
                            tx_ip_counter_en_r <= '0';
                            tx_data_mux_ip_sel_r <= '0';
                            tx_fsm_r <= payload_s;
                        else
                            tx_valid_r <= '1';
                        end if;
                    end if;

                when payload_s =>
                    if ((((icmp_last_i = '1') and (icmp_valid_i = '1') and (tx_is_icmp_r = '1')) or
                         ((udp_last_i = '1') and (udp_valid_i = '1') and (tx_is_icmp_r = '0'))) and (eth_ready_i = '1')) then
                        payload_icmp_r <= '0';
                        payload_udp_r <= '0';
                        tx_identification_r <= std_logic_vector(unsigned(tx_identification_r) + 1);
                        tx_offset_counter_en_r <= (others => '0');
                        tx_fsm_r <= idle_s;
                    else
                        payload_icmp_r <= tx_is_icmp_r;
                        payload_udp_r <= not tx_is_icmp_r;
                    end if;

            end case;

        end if;
    end process tx_packet_gen_proc;

    tx_counter_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (tx_offset_counter_en_r(3) = '1') then
                if (eth_ready_i = '1') then
                    tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not vector_or(tx_offset_counter_r));
                end if;
            elsif (tx_offset_counter_en_r(2) = '1') then
                tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not vector_or(tx_offset_counter_r));
            elsif (tx_offset_counter_en_r(1) = '1') then
                if (udp_valid_i = '1') then
                    tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not vector_or(tx_offset_counter_r));
                end if;
            elsif (tx_offset_counter_en_r(0) = '1') then
                if (icmp_valid_i = '1') then
                    tx_offset_counter_r <= tx_offset_counter_r(tx_offset_counter_r'high-1 downto 0) & (not vector_or(tx_offset_counter_r));
                end if;
            else
                tx_offset_counter_r <= "0010";
            end if;

            if (tx_ip_counter_en_r = '1') then
                if (((tx_valid_r = '1') and (eth_ready_i = '1')) or (tx_ip_read_en_r = '1')) then
                    tx_ip_counter_r <= tx_ip_counter_r + 1;
                end if;
            else
                tx_ip_counter_r <= to_unsigned(2, tx_ip_counter_r'length);
            end if;
        end if;
    end process tx_counter_proc;

    tx_data_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (tx_data_mux_ctrl_r = '1') then
                if (eth_ready_i = '1') then
                    tx_data_r <= tx_data_shift_r(31 downto 24);
                end if;
            else
                tx_data_r <= tx_packet_nr_r;
            end if;
        end if;
    end process tx_data_proc;

    -- rx output signals
    eth_ready_o <= (udp_ready_i and icmp_ready_i and (not rx_send_nr_r)) or rx_remove_padding_en_r;
    udp_valid_o <= rx_is_udp_r and rx_transmit_packet_r;
    udp_last_o <= rx_last_r;    
    udp_data_o <= rx_shift_r(7 downto 0) when (rx_send_nr_r = '0') else rx_packet_nr_r;
    icmp_valid_o <= rx_is_icmp_r and rx_transmit_packet_r;
    icmp_last_o <= rx_last_r;
    icmp_data_o <= rx_shift_r(7 downto 0) when (rx_send_nr_r = '0') else rx_packet_nr_r;

    -- tx output signals
    icmp_ready_o <= eth_ready_i when (payload_icmp_r = '1') else tx_icmp_ready_r;
    udp_ready_o <= eth_ready_i when (payload_udp_r = '1') else tx_udp_ready_r;
    eth_valid_o <= icmp_valid_i when (payload_icmp_r = '1') else
                   udp_valid_i when (payload_udp_r = '1') else tx_valid_r;
    eth_last_o <= icmp_last_i when (payload_icmp_r = '1') else
                  udp_last_i when (payload_udp_r = '1') else '0';
    eth_data_o <= icmp_data_i when (payload_icmp_r = '1') else
                  udp_data_i when (payload_udp_r = '1') else 
                  tx_ip when (tx_data_mux_ip_sel_r = '1') else
                  tx_data_r;

end rtl;
