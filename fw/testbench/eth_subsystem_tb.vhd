--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 04.11.2018
-- Filename  : eth_subsystem_tb.vhd
-- Changelog : 04.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity eth_subsystem_tb is
end entity eth_subsystem_tb;

architecture rtl of eth_subsystem_tb is

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

    component fifo is
    generic (
        size_exp_g     : positive := 10;
        data_width_g   : positive := 8;
        use_reject_g   : boolean  := false;
        invert_full_g  : boolean  := false;
        invert_empty_g : boolean  := false);
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        -- write port
        data_i   : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i     : in  std_logic;
        store_i  : in  std_logic;
        reject_i : in  std_logic;
        full_o   : out std_logic;
        -- read port
        data_o   : out std_logic_vector(data_width_g-1 downto 0);
        rd_i     : in  std_logic;
        empty_o  : out std_logic);
    end component fifo;

    constant mac_address_c        : std_logic_vector(47 downto 0) := x"010203040506";
    constant ip_address_c         : std_logic_vector(31 downto 0) := x"c0a80164";
    constant ctrl_port_c          : std_logic_vector(15 downto 0) := x"1234";
    constant ctrl_address_width_c : positive := 16;
    constant ctrl_data_width_c    : positive := 32;

    constant test_arp_packet_c : std_logic_vector := x"ffffffff" &
                                                     x"ffff74d0" &
                                                     x"2b808ea2" &
                                                     x"08060001" &
                                                     x"08000604" &
                                                     x"000174d0" &
                                                     x"2b808ea2" &
                                                     x"c0a80010" &
                                                     x"00000000" &
                                                     x"0000c0a8" &
                                                     x"01640000" &
                                                     x"00000000" &
                                                     x"00000000" &
                                                     x"00000000" &
                                                     x"00000000";

    constant response_arp_packet_c : std_logic_vector := x"74d02b80" &
                                                         x"8ea2" & mac_address_c &
                                                         x"08060001" &
                                                         x"08000604" &
                                                         x"0002" & mac_address_c &
                                                         ip_address_c &
                                                         x"74d02b80" &
                                                         x"8ea2c0a8" &
                                                         x"00100000" &
                                                         x"00000000" &
                                                         x"00000000" &
                                                         x"00000000" &
                                                         x"00000000";

    constant test_icmp_packet_c : std_logic_vector := x"01020304" &
                                                      x"05069ceb" &
                                                      x"e80e6c62" &
                                                      x"08004500" &
                                                      x"003c0e53" &
                                                      x"00008001" &
                                                      x"a8a5c0a8" &
                                                      x"0114c0a8" &
                                                      x"01640800" &
                                                      x"4d5a0001" &
                                                      x"00016162" &
                                                      x"63646566" &
                                                      x"6768696a" &
                                                      x"6b6c6d6e" &
                                                      x"6f707172" &
                                                      x"73747576" &
                                                      x"77616263" &
                                                      x"64656667" &
                                                      x"6869";

    constant response_icmp_packet_c : std_logic_vector := x"9cebe80e" &
                                                          x"6c62" & mac_address_c &
                                                          x"08004500" &
                                                          x"003c0000" &
                                                          x"0000ff01" &
                                                          x"a8a5c0a8" &
                                                          x"0164c0a8" &
                                                          x"01140000" &
                                                          x"4d5a0001" &
                                                          x"00016162" &
                                                          x"63646566" &
                                                          x"6768696a" &
                                                          x"6b6c6d6e" &
                                                          x"6f707172" &
                                                          x"73747576" &
                                                          x"77616263" &
                                                          x"64656667" &
                                                          x"6869";

    constant test_udp_packet_c : std_logic_vector := x"01020304" &
                                                     x"05069ceb" &
                                                     x"e80e6c62" &
                                                     x"08004500" &
                                                     x"00240002" &
                                                     x"00008011" &
                                                     x"b6fec0a8" &
                                                     x"0114c0a8" &
                                                     x"01640102" &
                                                     x"12340010" &
                                                     x"00000701" &
                                                     x"04000000" &
                                                     x"0404";

    constant response_udp_packet_c : std_logic_vector := x"9cebe80e" &
                                                         x"6c620102" &
                                                         x"03040506" &
                                                         x"08004500" &
                                                         x"00230002" &
                                                         x"0000ff11" &
                                                         x"b704c0a8" &
                                                         x"0164c0a8" &
                                                         x"01141234" &
                                                         x"1234000f" &
                                                         x"00000704" &
                                                         x"04aabbcc" &
                                                         x"dd";

    constant test_udp_short_packet_c : std_logic_vector := x"01020304" &
                                                           x"05069ceb" &
                                                           x"e80e6c62" &
                                                           x"08004500" &
                                                           x"00220002" &
                                                           x"00008011" &
                                                           x"b700c0a8" &
                                                           x"0114c0a8" &
                                                           x"01640102" &
                                                           x"03040506" &
                                                           x"0708090a"; -- 4 byte too short

    constant test_udp_wrong_port_packet_c : std_logic_vector := x"01020304" &
                                                                x"05069ceb" &
                                                                x"e80e6c62" &
                                                                x"08004500" &
                                                                x"00242e4e" &
                                                                x"00008011" &
                                                                x"88b2c0a8" &
                                                                x"0114c0a8" &
                                                                x"0164f50e" &
                                                                x"07d00010" &
                                                                x"83ea4865" &
                                                                x"6c6c6f21" &
                                                                x"2121";

    constant test_wrong_mac_packet_c : std_logic_vector := x"02020304" &
                                                           x"05069ceb" &
                                                           x"e80e6c62" &
                                                           x"08004500" &
                                                           x"001e0002" &
                                                           x"00008011" &
                                                           x"a8a5c0a8" &
                                                           x"0114c0a8" &
                                                           x"01640102" &
                                                           x"03040506" &
                                                           x"0708090a" &
                                                           x"00000000";

    constant test_wrong_ip_packet_c : std_logic_vector := x"01020304" &
                                                          x"05069ceb" &
                                                          x"e80e6c62" &
                                                          x"08004500" &
                                                          x"003c0e53" &
                                                          x"00008001" &
                                                          x"a8a4c0a8" &
                                                          x"0114c0a8" &
                                                          x"01650800" &
                                                          x"4d5a0001" &
                                                          x"00016162" &
                                                          x"63646566" &
                                                          x"6768696a" &
                                                          x"6b6c6d6e" &
                                                          x"6f707172" &
                                                          x"73747576" &
                                                          x"77616263" &
                                                          x"64656667" &
                                                          x"6869";

    constant test_wrong_ip_checksum_packet_c : std_logic_vector := x"01020304" &
                                                                   x"05069ceb" &
                                                                   x"e80e6c62" &
                                                                   x"08004500" &
                                                                   x"003c0e53" &
                                                                   x"00008001" &
                                                                   x"a8a6c0a8" &
                                                                   x"0114c0a8" &
                                                                   x"01640800" &
                                                                   x"4d5a0001" &
                                                                   x"00016162" &
                                                                   x"63646566" &
                                                                   x"6768696a" &
                                                                   x"6b6c6d6e" &
                                                                   x"6f707172" &
                                                                   x"73747576" &
                                                                   x"77616263" &
                                                                   x"64656667" &
                                                                   x"6869";

    signal clk                     : std_logic := '0';
    signal mac_rx_valid            : std_logic := '0';
    signal mac_rx_ready            : std_logic;
    signal mac_rx_last             : std_logic := '0';
    signal mac_rx_data             : std_logic_vector(7 downto 0) := (others => '0');

    signal mac_tx_ready_r          : std_logic := '0';
    signal mac_tx_valid            : std_logic;
    signal mac_tx_last             : std_logic;
    signal mac_tx_data             : std_logic_vector(7 downto 0);
    signal mac_fifo_wr_en          : std_logic;
    signal tx_data_offset_r        : integer := 0;
    signal idle_counter_r          : integer := 0;
    signal rx_packet_sel_counter_r : unsigned(2 downto 0) := (others => '0');

    signal check_data_valid        : std_logic;
    signal check_data_valid_r      : std_logic;
    signal check_data              : std_logic_vector(7 downto 0);
    signal check_data_r            : std_logic_vector(7 downto 0) := (others => '0');
    signal check_data_counter_r    : integer := 0;
    signal arp_packet_valid_r      : std_logic := '0';
    signal icmp_packet_valid_r     : std_logic := '0';
    signal udp_packet_valid_r      : std_logic := '0';
    signal tx_packet_sel_counter_r : unsigned(1 downto 0) := (others => '0');
    signal ip_packet_detected_r    : std_logic := '0';
    signal ip_checksum_r           : std_logic_vector(15 downto 0) := (others => '0');
    signal ctrl_strobe             : std_logic := '0';
    signal ctrl_strobe_r           : std_logic := '0';

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    i_eth : eth_subsystem
    generic map (
        mac_address_g        => mac_address_c,
        ip_address_g         => ip_address_c,
        ctrl_port_g          => ctrl_port_c,
        ctrl_address_width_g => ctrl_address_width_c,
        ctrl_data_width_g    => ctrl_data_width_c)
    port map (
        clk_i          => clk,
        reset_i        => '0',
        -- mac rx
        mac_valid_i    => mac_rx_valid,
        mac_ready_o    => mac_rx_ready,
        mac_last_i     => mac_rx_last,
        mac_data_i     => mac_rx_data,
        -- mac tx
        mac_valid_o    => mac_tx_valid,
        mac_ready_i    => mac_tx_ready_r,
        mac_last_o     => mac_tx_last,
        mac_data_o     => mac_tx_data,
        -- ctrl
        ctrl_address_o => open,
        ctrl_data_o    => open,
        ctrl_data_i    => x"aabbccdd",
        ctrl_strobe_o  => ctrl_strobe,
        ctrl_write_o   => open,
        ctrl_ack_i     => ctrl_strobe_r);

    ack_delay_proc : process (clk)
    begin
        if (rising_edge(clk)) then
            ctrl_strobe_r <= ctrl_strobe;
        end if;
    end process ack_delay_proc;

    mac_fifo_wr_en <= mac_tx_valid and mac_tx_ready_r;

    i_tx_fifo : fifo
    generic map (
        size_exp_g     => 11,
        data_width_g   => 8,
        use_reject_g   => true,
        invert_full_g  => false,
        invert_empty_g => true)
    port map (
        clk_i    => clk,
        reset_i  => '0',
        -- write port
        data_i   => mac_tx_data,
        wr_i     => mac_fifo_wr_en,
        store_i  => mac_tx_last,
        reject_i => '0',
        full_o   => open,
        -- read port
        data_o   => check_data,
        rd_i     => '1',
        empty_o  => check_data_valid);

    tx_ready_proc : process (clk)
        variable seed1_v : positive := 125;
        variable seed2_v : positive := 53;
        variable rand_v  : real;
    begin
        if (rising_edge(clk)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (mac_tx_ready_r = '0') or ((mac_tx_ready_r = '1') and (mac_tx_valid = '1')) then
                if (rand_v >= 0.5) then
                    mac_tx_ready_r <= '1';
                else
                    mac_tx_ready_r <= '0';
                end if;
            end if;
        end if;
    end process tx_ready_proc;

    tx_check_proc : process (clk)
    begin
        if (rising_edge(clk)) then
            check_data_valid_r <= check_data_valid;
            if ((check_data_valid_r = '1') and (check_data_valid = '0')) then
                if (tx_packet_sel_counter_r = to_unsigned(2, tx_packet_sel_counter_r'length)) then
                    tx_packet_sel_counter_r <= (others => '0');
                else
                    tx_packet_sel_counter_r <= tx_packet_sel_counter_r + 1;
                end if;
            end if;
            if (check_data_valid = '1') then
                check_data_counter_r <= check_data_counter_r + 8;
                if (tx_packet_sel_counter_r = to_unsigned(0, tx_packet_sel_counter_r'length)) then
                    if (check_data = response_arp_packet_c(check_data_counter_r to check_data_counter_r+7)) then
                        arp_packet_valid_r <= '1';
                    else
                        report "Error: received ARP packet wrong";
                        arp_packet_valid_r <= '0';
                    end if;
                elsif (tx_packet_sel_counter_r = to_unsigned(1, tx_packet_sel_counter_r'length)) then
                    if (check_data = response_icmp_packet_c(check_data_counter_r to check_data_counter_r+7)) then
                        icmp_packet_valid_r <= '1';
                    -- don't check checksum fields and ip identification field
                    elsif ((check_data_counter_r /= 192) and (check_data_counter_r /= 200) and
                           (check_data_counter_r /= 288) and (check_data_counter_r /= 296) and
                           (check_data_counter_r /= 144) and (check_data_counter_r /= 152)) then
                        report "Error: received ICMP packet wrong";
                        icmp_packet_valid_r <= '0';
                    end if;
                else
                    if (check_data = response_udp_packet_c(check_data_counter_r to check_data_counter_r+7)) then
                        udp_packet_valid_r <= '1';
                    -- don't check checksum field and ip identification field
                    elsif ((check_data_counter_r /= 192) and (check_data_counter_r /= 200) and
                           (check_data_counter_r /= 144) and (check_data_counter_r /= 152)) then
                        report "Error: received UDP packet wrong";
                        udp_packet_valid_r <= '0';
                    end if;
                end if;
            else
                check_data_counter_r <= 0;
                icmp_packet_valid_r <= '0';
                arp_packet_valid_r <= '0';
                udp_packet_valid_r <= '0';
            end if;
        end if;
    end process tx_check_proc;

    tx_ip_checksum_check_proc : process (clk)
    begin
        if (rising_edge(clk)) then
            check_data_r <= check_data;
            if (check_data_valid = '0') then
                ip_packet_detected_r <= '0';
            elsif ((check_data_counter_r = 104) and (check_data_r = x"08") and (check_data = x"00")) then
                ip_packet_detected_r <= '1';
            end if;
            if (check_data_valid = '0') then
                ip_checksum_r <= (others => '0');
            elsif ((check_data_counter_r = 120) or (check_data_counter_r = 136) or
                (check_data_counter_r = 152) or (check_data_counter_r = 168) or
                (check_data_counter_r = 184) or (check_data_counter_r = 200) or
                (check_data_counter_r = 216) or (check_data_counter_r = 232) or
                (check_data_counter_r = 248) or (check_data_counter_r = 264)) then
                ip_checksum_r <= checksum_add(ip_checksum_r, check_data_r & check_data);
            elsif ((check_data_counter_r = 272) and (ip_packet_detected_r = '1')) then
                if (ip_checksum_r /= x"FFFF") then
                    report "Error: received IP checksum wrong";
                end if;
            end if;
        end if;
    end process tx_ip_checksum_check_proc;

    rx_data_gen_proc : process (clk)
        variable packet_length_v : positive;
    begin
        if (rising_edge(clk)) then
            if (mac_rx_ready = '1') then
                mac_rx_valid <= '1';
                if (rx_packet_sel_counter_r = to_unsigned(0, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_arp_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_arp_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(1, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_icmp_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_icmp_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(2, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_udp_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_udp_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(3, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_wrong_mac_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_wrong_mac_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(4, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_wrong_ip_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_wrong_ip_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(5, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_wrong_ip_checksum_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_wrong_ip_checksum_packet_c'length;
                elsif (rx_packet_sel_counter_r = to_unsigned(6, rx_packet_sel_counter_r'length)) then
                    mac_rx_data <= test_udp_wrong_port_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_udp_wrong_port_packet_c'length;
                else
                    mac_rx_data <= test_udp_short_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_udp_short_packet_c'length;
                end if;

                if (tx_data_offset_r = (packet_length_v-8)) then
                    mac_rx_last <= '1';
                    tx_data_offset_r <= 0;
                    idle_counter_r <= 0;
                    rx_packet_sel_counter_r <= rx_packet_sel_counter_r + 1;
                else
                    tx_data_offset_r <= tx_data_offset_r + 8;
                    mac_rx_last <= '0';
                end if;
            end if;
        end if;
    end process rx_data_gen_proc;

end rtl;
