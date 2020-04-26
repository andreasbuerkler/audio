--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 27.12.2018
-- Filename  : eth_ctrl.vhd
-- Changelog : 27.12.2018 - file created
--           : 32.12.2019 - write ack added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_ctrl is
generic (
    address_width_g : positive := 16;
    data_width_g    : positive := 32);
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
end entity eth_ctrl;

architecture rtl of eth_ctrl is

    constant command_read_c          : std_logic_vector(7 downto 0) := x"01";
    constant command_write_c         : std_logic_vector(7 downto 0) := x"02";
    constant command_read_response_c : std_logic_vector(7 downto 0) := x"04";
    constant command_read_timeout_c  : std_logic_vector(7 downto 0) := x"08";

    constant bytes_per_transfer_c    : positive := data_width_g / 8;

    type rx_fsm_t is (idle_s, id_s, command_s, addr_size_s, addr_s, data_size_s,
                      write_s, write_ack_s, read_s, wait_for_done_s, wait_for_end_s);

    type tx_fsm_t is (idle_s, packet_nr_s, id_s, command_s,
                      data_size_s, data_s, last_byte_s, wait_for_next_byte_s);

    signal rx_fsm_r             : rx_fsm_t := idle_s;
    signal udp_ready_r          : std_logic := '0';
    signal last_store_r         : std_logic := '0';
    signal address_r            : std_logic_vector(address_width_g-1 downto 0) := (others => '0');
    signal rx_data_r            : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal tx_data_r            : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal strobe_r             : std_logic := '0';
    signal write_r              : std_logic := '0';
    signal packet_number_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal id_r                 : std_logic_vector(7 downto 0) := (others => '0');
    signal command_write_r      : std_logic := '0';
    signal command_read_r       : std_logic := '0';
    signal size_counter_r       : unsigned(7 downto 0) := (others => '0');
    signal send_response_r      : std_logic := '0';
    signal ack_received_r       : std_logic := '0';

    signal tx_fsm_r             : tx_fsm_t := idle_s;
    signal udp_valid_r          : std_logic := '0';
    signal udp_last_r           : std_logic := '0';
    signal udp_data_r           : std_logic_vector(7 downto 0) := (others => '0');
    signal timeout_counter_r    : unsigned(17 downto 0) := (others => '0');
    signal timeout_counter_en_r : std_logic := '0';
    signal timeout_active_r     : std_logic := '0';
    signal data_counter_r       : unsigned(log2ceil(bytes_per_transfer_c)-1 downto 0) := (others => '0');
    signal response_done_r      : std_logic := '0';
    signal tx_size_r            : unsigned(8 downto 0) := (others => '0');
    signal tx_request_next_r    : std_logic := '0';
    signal ack_r                : std_logic := '0';

begin

    assert (data_width_g = 32) report "only 32 bit data width supported" severity error;
    assert ((address_width_g mod 8) = 0) report "only multiple of 8 bit address width supported" severity error;

    rx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            strobe_r <= '0';
            write_r <= '0';

            case (rx_fsm_r) is
                when idle_s =>
                    command_write_r <= '0';
                    command_read_r <= '0';
                    udp_ready_r <= '1';
                    address_r <= (others => '0');
                    if ((udp_ready_r = '1') and (udp_valid_i = '1')) then
                        packet_number_r <= udp_data_i;
                        rx_fsm_r <= id_s;
                    end if;

                when id_s =>
                    if (udp_valid_i = '1') then
                        id_r <= udp_data_i;
                        rx_fsm_r <= command_s;
                    end if;

                when command_s =>
                    if (udp_valid_i = '1') then
                        if (udp_data_i = command_write_c) then
                            command_write_r <= '1';
                            rx_fsm_r <= addr_size_s;
                        elsif (udp_data_i = command_read_c) then
                            command_read_r <= '1';
                            rx_fsm_r <= addr_size_s;
                        else
                            rx_fsm_r <= wait_for_end_s;
                        end if;
                    end if;

                when addr_size_s =>
                    size_counter_r <= unsigned(udp_data_i);
                    if (udp_valid_i = '1') then
                        rx_fsm_r <= addr_s;
                    end if;

                when addr_s =>
                    if (udp_valid_i = '1') then
                        size_counter_r <= size_counter_r - 1;
                        address_r <= address_r(address_r'high-8 downto 0) & udp_data_i;
                        if (size_counter_r = to_unsigned(1, size_counter_r'length)) then
                            rx_fsm_r <= data_size_s;
                        end if;
                    end if;

                when data_size_s =>
                    size_counter_r <= unsigned(udp_data_i);
                    if (udp_valid_i = '1') then
                        if (command_write_r = '1') then
                            rx_fsm_r <= write_s;
                        elsif (command_read_r = '1') then
                            udp_ready_r <= '0';
                            rx_fsm_r <= read_s;
                        else
                            rx_fsm_r <= wait_for_end_s;
                        end if;
                    end if;

                when write_s =>
                    if (udp_valid_i = '1') then
                        size_counter_r <= size_counter_r - 1;
                        rx_data_r <= rx_data_r(rx_data_r'high-8 downto 0) & udp_data_i;
                        if (size_counter_r(1 downto 0) = "01") then -- TODO: only for 32 bit data
                            strobe_r <= '1';
                            write_r <= '1';
                            udp_ready_r <= '0';
                            last_store_r <= udp_last_i;
                            rx_fsm_r <= write_ack_s;
                        end if;
                    end if;

                when write_ack_s =>
                    if (ack_received_r = '1') then
                        if (size_counter_r = to_unsigned(0, size_counter_r'length)) then
                            if (last_store_r = '1') then
                                rx_fsm_r <= idle_s;
                            else
                                udp_ready_r <= '1';
                                rx_fsm_r <= wait_for_end_s;
                            end if;
                        else
                            udp_ready_r <= '1';
                            address_r <= std_logic_vector(unsigned(address_r) + bytes_per_transfer_c);
                            rx_fsm_r <= write_s;
                        end if;
                    end if;

                when read_s =>
                    strobe_r <= '1';
                    rx_fsm_r <= wait_for_done_s;

                when wait_for_done_s =>
                    if (response_done_r = '1') then
                        send_response_r <= '0';
                        rx_fsm_r <= idle_s;
                    else
                        send_response_r <= '1';
                    end if;
                    if (tx_request_next_r = '1') then
                        address_r <= std_logic_vector(unsigned(address_r) + bytes_per_transfer_c);
                        strobe_r <= '1';
                    end if;

                when wait_for_end_s =>
                    if ((udp_valid_i = '1') and (udp_last_i = '1')) then
                        rx_fsm_r <= idle_s;
                    end if;

            end case;
        end if;
    end process rx_proc;

    timeout_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (timeout_counter_en_r = '1') then
                if (timeout_counter_r(timeout_counter_r'high) = '0') then
                    timeout_counter_r <= timeout_counter_r + 1;
                end if;
            else
                timeout_counter_r <= (others => '0');
            end if;
        end if;
    end process timeout_proc;

    ack_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (udp_ready_r = '1') then
                ack_received_r <= '0';
            elsif (ack_i = '1') then
                ack_received_r <= '1';
            end if;
        end if;
    end process ack_proc;

    tx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            udp_valid_r <= '0';
            udp_last_r <= '0';
            response_done_r <= '0';
            tx_request_next_r <= '0';

            case (tx_fsm_r) is
                when idle_s =>
                    data_counter_r <= to_unsigned(bytes_per_transfer_c-1, data_counter_r'length);
                    tx_size_r <= '0' & size_counter_r;
                    if (ack_i = '1') then
                        tx_data_r <= data_i;
                    end if;

                    timeout_counter_en_r <= send_response_r;
                    timeout_active_r <= timeout_counter_r(timeout_counter_r'high);
                    if ((timeout_counter_r(timeout_counter_r'high) = '1') or ((send_response_r = '1') and (ack_i = '1'))) then
                        tx_fsm_r <= packet_nr_s;
                    end if;

                when packet_nr_s =>
                    udp_valid_r <= '1';
                    udp_data_r <= packet_number_r;
                    if (udp_ready_i = '1') then
                        tx_fsm_r <= id_s;
                    end if;

                when id_s =>
                    udp_valid_r <= '1';
                    udp_data_r <= id_r;
                    if (udp_ready_i = '1') then
                        tx_fsm_r <= command_s;
                    end if;

                when command_s =>
                    udp_valid_r <= '1';
                    if (timeout_active_r = '1') then
                        udp_data_r <= command_read_timeout_c;
                        udp_last_r <= '1';
                        if (udp_ready_i = '1') then
                            response_done_r <= '1';
                            tx_fsm_r <= idle_s;
                        end if;
                    else
                        udp_data_r <= command_read_response_c;
                        if (udp_ready_i = '1') then
                            tx_fsm_r <= data_size_s;
                        end if;
                    end if;

                when data_size_s =>
                    udp_valid_r <= '1';
                    udp_data_r <= std_logic_vector(tx_size_r(udp_data_r'range));
                    if (udp_ready_i = '1') then
                        tx_size_r <= tx_size_r - (bytes_per_transfer_c + 1);
                        tx_fsm_r <= data_s;
                    end if;

                when data_s =>
                    ack_r <= '0';
                    udp_valid_r <= '1';
                    udp_data_r <= tx_data_r(tx_data_r'high downto tx_data_r'high-7);
                    if (udp_ready_i = '1') then
                        tx_data_r <= tx_data_r(tx_data_r'high-8 downto 0) & x"00";
                        data_counter_r <= data_counter_r - 1;
                        if (data_counter_r = to_unsigned(1, data_counter_r'length)) then
                            if (tx_size_r(tx_size_r'high) = '0') then
                                tx_request_next_r <= '1';
                            end if;
                            tx_fsm_r <= last_byte_s;
                        end if;
                    end if;

                when last_byte_s =>
                    udp_data_r <= tx_data_r(tx_data_r'high downto tx_data_r'high-7);
                    tx_fsm_r <= wait_for_next_byte_s;

                when wait_for_next_byte_s =>
                    data_counter_r <= to_unsigned(bytes_per_transfer_c-1, data_counter_r'length);
                    timeout_counter_en_r <= not timeout_counter_r(timeout_counter_r'high);
                    if (ack_i = '1') then
                        ack_r <= '1';
                        tx_data_r <= data_i;
                    end if;
                    if ((tx_size_r(tx_size_r'high) = '1') or (timeout_counter_r(timeout_counter_r'high) = '1')) then
                        udp_valid_r <= '1';
                        udp_last_r <= '1';
                        if (udp_ready_i = '1') then
                            response_done_r <= '1';
                            tx_fsm_r <= idle_s;
                        end if;
                    elsif (ack_r = '1') then
                        udp_valid_r <= '1';
                        if (udp_ready_i = '1') then
                            tx_size_r <= tx_size_r - bytes_per_transfer_c;
                            tx_fsm_r <= data_s;
                        end if;
                    end if;

            end case;
        end if;
    end process tx_proc;

    -- udp tx
    udp_valid_o <= udp_valid_r;
    udp_last_o <= udp_last_r;
    udp_data_o <= udp_data_r;
    -- udp rx
    udp_ready_o <= udp_ready_r;
    -- ctrl bus
    address_o <= address_r;
    data_o <= rx_data_r;
    strobe_o <= strobe_r;
    write_o <= write_r;

end rtl;
