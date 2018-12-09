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

entity eth_subsystem_tb is
end entity eth_subsystem_tb;

architecture rtl of eth_subsystem_tb is

    component eth_subsystem is
    generic (
        mac_address_g  : std_logic_vector(47 downto 0);
        ip_address_g   : std_logic_vector(31 downto 0));
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

    -- TODO: check wrong mac address, wrong ip address, wrong ip checksum, wrong protocol, packet with / without padding, automatic packet check

    constant mac_address_c : std_logic_vector(47 downto 0) := x"010203040506";
    constant ip_address_c  : std_logic_vector(31 downto 0) := x"c0a80164";

    signal clk              : std_logic := '0';
    signal mac_rx_valid     : std_logic := '0';
    signal mac_rx_ready     : std_logic;
    signal mac_rx_last      : std_logic := '0';
    signal mac_rx_data      : std_logic_vector(7 downto 0) := (others => '0');

    signal mac_tx_ready_r       : std_logic := '0';
    signal mac_tx_valid         : std_logic;
    signal mac_tx_last          : std_logic;
    signal mac_tx_data          : std_logic_vector(7 downto 0);
    signal mac_rx_en            : std_logic := '0';
    signal mac_fifo_wr_en       : std_logic;
    signal tx_data_offset_r     : integer := 0;
    signal idle_counter_r       : integer := 0;
    signal packet_sel_counter_r : unsigned(0 downto 0) := (others => '0');

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
        mac_address_g  => mac_address_c,
        ip_address_g   => ip_address_c)
    port map (
        clk_i       => clk,
        reset_i     => '0',
        -- mac rx
        mac_valid_i => mac_rx_valid,
        mac_ready_o => mac_rx_ready,
        mac_last_i  => mac_rx_last,
        mac_data_i  => mac_rx_data,
        -- mac tx
        mac_valid_o => mac_tx_valid,
        mac_ready_i => mac_tx_ready_r,
        mac_last_o  => mac_tx_last,
        mac_data_o  => mac_tx_data);

    mac_fifo_wr_en <= mac_tx_valid and mac_tx_ready_r;

    i_tx_fifo : fifo
    generic map (
        size_exp_g     => 11,
        data_width_g   => 8,
        use_reject_g   => true,
        invert_full_g  => false,
        invert_empty_g => false)
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
        data_o   => open,
        rd_i     => '1',
        empty_o  => open);

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

    rx_data_gen_proc : process (clk)
        variable packet_length_v : positive;
    begin
        if (rising_edge(clk)) then
            if (idle_counter_r < 100) then
                idle_counter_r <= idle_counter_r + 1;
                mac_rx_en <= '0';
            else
                mac_rx_en <= '1';
            end if;

            if ((mac_rx_ready = '1') and (mac_rx_en = '1')) then
                mac_rx_valid <= '1';
                if (packet_sel_counter_r = to_unsigned(0, packet_sel_counter_r'length)) then
                    mac_rx_data <= test_arp_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_arp_packet_c'length;
                else
                    mac_rx_data <= test_icmp_packet_c(tx_data_offset_r to tx_data_offset_r+7);
                    packet_length_v := test_icmp_packet_c'length;
                end if;

                if (tx_data_offset_r = (packet_length_v-8)) then
                    mac_rx_last <= '1';
                    tx_data_offset_r <= 0;
                    mac_rx_en <= '0';
                    idle_counter_r <= 0;
                    packet_sel_counter_r <= packet_sel_counter_r + 1;
                else
                    tx_data_offset_r <= tx_data_offset_r + 8;
                    mac_rx_last <= '0';
                end if;
            elsif (mac_rx_en = '0') then
                mac_rx_valid <= '0';
                mac_rx_last <= '0';
            end if;

        end if;
    end process rx_data_gen_proc;

end rtl;
