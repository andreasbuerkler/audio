--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 18.05.2020
-- Filename  : master_interconnect_tb.vhd
-- Changelog : 18.05.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity master_interconnect_tb is
end entity master_interconnect_tb;

architecture rtl of master_interconnect_tb is

    component eth_ctrl is
    generic (
        address_width_g : positive;
        data_width_g    : positive;
        burst_size_g    : positive := 32);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- udp tx
        udp_valid_o  : out std_logic;
        udp_ready_i  : in  std_logic;
        udp_last_o   : out std_logic;
        udp_data_o   : out std_logic_vector(7 downto 0);
        -- udp rx
        udp_valid_i  : in  std_logic;
        udp_ready_o  : out std_logic;
        udp_last_i   : in  std_logic;
        udp_data_i   : in  std_logic_vector(7 downto 0);
        -- ctrl bus
        address_o    : out std_logic_vector(address_width_g-1 downto 0);
        data_o       : out std_logic_vector(data_width_g-1 downto 0);
        data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        burst_size_o : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        strobe_o     : out std_logic;
        write_o      : out std_logic;
        ack_i        : in  std_logic);
    end component eth_ctrl;

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
        -- ctrl bus
        ctrl_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        ctrl_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        ctrl_strobe_i     : in  std_logic;
        ctrl_write_i      : in  std_logic;
        ctrl_ack_o        : out std_logic);
    end component registerbank;

    component master_interconnect is
    generic (
        number_of_masters_g : positive;
        data_width_g        : positive;
        address_width_g     : positive;
        burst_size_g        : positive);
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        -- master
        master_address_i    : in  std_logic_array;
        master_data_i       : in  std_logic_array;
        master_data_o       : out std_logic_array;
        master_burst_size_i : in  std_logic_array;
        master_strobe_i     : in  std_logic_vector;
        master_write_i      : in  std_logic_vector;
        master_ack_o        : out std_logic_vector;
        -- slave
        slave_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave_strobe_o      : out std_logic;
        slave_write_o       : out std_logic;
        slave_ack_i         : in  std_logic);
    end component master_interconnect;

    constant address_width_c  : positive := 16;
    constant data_width_c     : positive := 32;
    constant burst_size_c     : positive := 32;
    constant register_count_c : positive := 24;
    constant read_only_c      : std_logic_vector(register_count_c-1 downto 0) := (others => '0');
    constant register_init_c  : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    constant register_mask_c : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '1'));

    constant command_read_c          : std_logic_vector(7 downto 0) := x"01";
    constant command_write_c         : std_logic_vector(7 downto 0) := x"02";
    constant command_read_response_c : std_logic_vector(7 downto 0) := x"04";
    constant command_read_timeout_c  : std_logic_vector(7 downto 0) := x"08";

    procedure ctrl_wait_for_signal (signal clk : in std_logic; signal ready : in  std_logic) is
    begin
        wait until rising_edge(clk);
        ready_loop : loop
            if (ready = '0') then
                wait until rising_edge(clk);
            else
                exit ready_loop;
            end if;
        end loop;
    end ctrl_wait_for_signal;

    procedure ctrl_write (signal   clk     : in  std_logic;
                          signal   valid   : out std_logic;
                          signal   data    : out std_logic_vector(7 downto 0);
                          signal   last    : out std_logic;
                          signal   ready   : in  std_logic;
                          constant address : in  std_logic_vector(15 downto 0);
                          constant wdata   : in  std_logic_array_32;
                          constant wlength : in  std_logic_vector(15 downto 0)) is 
    begin
        ctrl_wait_for_signal(clk, ready);
        valid <= '1';
        data <= x"07"; -- packet number
        ctrl_wait_for_signal(clk, ready);
        data <= x"02"; -- id
        ctrl_wait_for_signal(clk, ready);
        data <= command_write_c; -- command
        ctrl_wait_for_signal(clk, ready);
        data <= x"04"; -- address length
        ctrl_wait_for_signal(clk, ready);
        data <= x"00"; -- address msb
        ctrl_wait_for_signal(clk, ready);
        data <= x"00";
        ctrl_wait_for_signal(clk, ready);
        data <= address(15 downto 8);
        ctrl_wait_for_signal(clk, ready);
        data <= address(7 downto 0); -- address lsb
        ctrl_wait_for_signal(clk, ready);
        data <= wlength(15 downto 8); -- data length msb
        ctrl_wait_for_signal(clk, ready);
        data <= wlength(7 downto 0); -- data length lsb
        for i in 0 to (to_integer(unsigned(wlength))/4)-1 loop
            ctrl_wait_for_signal(clk, ready);
            data <= wdata(i)(31 downto 24); -- data msb
            ctrl_wait_for_signal(clk, ready);
            data <= wdata(i)(23 downto 16);
            ctrl_wait_for_signal(clk, ready);
            data <= wdata(i)(15 downto 8);
            ctrl_wait_for_signal(clk, ready);
            data <= wdata(i)(7 downto 0); -- data lsb
        end loop;
        last <= '1';
        ctrl_wait_for_signal(clk, ready);
        last <= '0';
        valid <= '0';
        data <= x"00";
    end ctrl_write;

    procedure ctrl_read (signal   clk     : in  std_logic;
                         signal   valid   : out std_logic;
                         signal   data    : out std_logic_vector(7 downto 0);
                         signal   last    : out std_logic;
                         signal   ready   : in  std_logic;
                         constant address : in  std_logic_vector(15 downto 0);
                         constant rlength : in  std_logic_vector(15 downto 0)) is
    begin
        ctrl_wait_for_signal(clk, ready);
        valid <= '1';
        data <= x"07"; -- packet number
        ctrl_wait_for_signal(clk, ready);
        data <= x"02"; -- id
        ctrl_wait_for_signal(clk, ready);
        data <= command_read_c; -- command
        ctrl_wait_for_signal(clk, ready);
        data <= x"04"; -- address length
        ctrl_wait_for_signal(clk, ready);
        data <= x"00"; -- address msb
        ctrl_wait_for_signal(clk, ready);
        data <= x"00";
        ctrl_wait_for_signal(clk, ready);
        data <= address(15 downto 8);
        ctrl_wait_for_signal(clk, ready);
        data <= address(7 downto 0); -- address lsb
        ctrl_wait_for_signal(clk, ready);
        data <= rlength(15 downto 8); -- read length msb
        ctrl_wait_for_signal(clk, ready);
        data <= rlength(7 downto 0); -- read length lsb
        last <= '1';
        ctrl_wait_for_signal(clk, ready);
        last <= '0';
        valid <= '0';
        data <= x"00";
    end ctrl_read;

    procedure ctrl_wait_for_read_data (signal   clk     : in  std_logic;
                                       signal   valid   : in  std_logic;
                                       signal   data    : in  std_logic_vector(7 downto 0);
                                       signal   last    : in  std_logic;
                                       variable rdata   : out std_logic_array_32;
                                       constant rlength : in  natural) is
        variable data_v : std_logic_vector(31 downto 0);
    begin
        ctrl_wait_for_signal(clk, valid); -- packet number
        ctrl_wait_for_signal(clk, valid); -- id
        ctrl_wait_for_signal(clk, valid); -- command
        if (data = command_read_timeout_c) then
            if (last = '0') then
                ctrl_wait_for_signal(clk, last);
            end if;
            for i in 0 to rlength-1 loop
                rdata(i) := x"00000000";
            end loop;
        else
            ctrl_wait_for_signal(clk, valid); -- size msb
            ctrl_wait_for_signal(clk, valid); -- size lsb
            for i in 0 to rlength-1 loop
                ctrl_wait_for_signal(clk, valid);
                data_v(31 downto 24) := data;
                ctrl_wait_for_signal(clk, valid);
                data_v(23 downto 16) := data;
                ctrl_wait_for_signal(clk, valid);
                data_v(15 downto 8) := data;
                ctrl_wait_for_signal(clk, valid);
                data_v(7 downto 0) := data;
                rdata(i) := data_v;
            end loop;
            if (last = '0') then
                ctrl_wait_for_signal(clk, last);
            end if;
        end if;
    end ctrl_wait_for_read_data;

    signal clk    : std_logic := '0';
    signal clk_en_0 : boolean := true;
    signal clk_en_1 : boolean := true;
    signal clk_en_2 : boolean := true;

    signal ctrl_0_address    : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_0_data_r     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_0_data_w     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_0_burst_size : std_logic_vector(log2ceil(burst_size_c)-1 downto 0);
    signal ctrl_0_strobe     : std_logic;
    signal ctrl_0_write      : std_logic;
    signal ctrl_0_ack        : std_logic;

    signal ctrl_1_address    : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_1_data_r     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_1_data_w     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_1_burst_size : std_logic_vector(log2ceil(burst_size_c)-1 downto 0);
    signal ctrl_1_strobe     : std_logic;
    signal ctrl_1_write      : std_logic;
    signal ctrl_1_ack        : std_logic;

    signal ctrl_2_address    : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_2_data_r     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_2_data_w     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_2_burst_size : std_logic_vector(log2ceil(burst_size_c)-1 downto 0);
    signal ctrl_2_strobe     : std_logic;
    signal ctrl_2_write      : std_logic;
    signal ctrl_2_ack        : std_logic;

    signal ctrl_3_address    : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_3_data_r     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_3_data_w     : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_3_burst_size : std_logic_vector(log2ceil(burst_size_c)-1 downto 0);
    signal ctrl_3_strobe     : std_logic;
    signal ctrl_3_write      : std_logic;
    signal ctrl_3_ack        : std_logic;

    signal register_read_data_r : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_read_strb_r : std_logic_vector(register_count_c-1 downto 0) := (others => '0');

    signal udp_0_rx_valid_r : std_logic := '0';
    signal udp_0_rx_ready   : std_logic;
    signal udp_0_rx_last_r  : std_logic := '0';
    signal udp_0_rx_data_r  : std_logic_vector(7 downto 0) := x"00";
    signal udp_0_tx_valid   : std_logic;
    signal udp_0_tx_last    : std_logic;
    signal udp_0_tx_data    : std_logic_vector(7 downto 0);

    signal udp_1_rx_valid_r : std_logic := '0';
    signal udp_1_rx_ready   : std_logic;
    signal udp_1_rx_last_r  : std_logic := '0';
    signal udp_1_rx_data_r  : std_logic_vector(7 downto 0) := x"00";
    signal udp_1_tx_valid   : std_logic;
    signal udp_1_tx_last    : std_logic;
    signal udp_1_tx_data    : std_logic_vector(7 downto 0);

    signal udp_2_rx_valid_r : std_logic := '0';
    signal udp_2_rx_ready   : std_logic;
    signal udp_2_rx_last_r  : std_logic := '0';
    signal udp_2_rx_data_r  : std_logic_vector(7 downto 0) := x"00";
    signal udp_2_tx_valid   : std_logic;
    signal udp_2_tx_last    : std_logic;
    signal udp_2_tx_data    : std_logic_vector(7 downto 0);

    signal debug_data : std_logic_vector(data_width_c-1 downto 0) := (others => '0');

    signal master_address    : std_logic_array(2 downto 0, address_width_c-1 downto 0);
    signal master_write_data : std_logic_array(2 downto 0, data_width_c-1 downto 0);
    signal master_read_data  : std_logic_array(2 downto 0, data_width_c-1 downto 0);
    signal master_burst_size : std_logic_array(2 downto 0, log2ceil(burst_size_c)-1 downto 0);
    signal master_strobe     : std_logic_vector(2 downto 0);
    signal master_write      : std_logic_vector(2 downto 0);
    signal master_ack        : std_logic_vector(2 downto 0);

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        if (clk_en_0 or clk_en_1 or clk_en_2) then
            clk <= '0';
            wait for 20 ns;
            clk <= '1';
            wait for 20 ns;
        end if;
    end process clkgen_proc;

    i_ctrl_0 : eth_ctrl
    generic map (
        address_width_g => address_width_c,
        data_width_g    => data_width_c,
        burst_size_g    => burst_size_c)
    port map (
        clk_i        => clk,
        reset_i      => '0',
        -- udp tx
        udp_valid_o  => udp_0_tx_valid,
        udp_ready_i  => '1',
        udp_last_o   => udp_0_tx_last,
        udp_data_o   => udp_0_tx_data,
        -- udp rx
        udp_valid_i  => udp_0_rx_valid_r,
        udp_ready_o  => udp_0_rx_ready,
        udp_last_i   => udp_0_rx_last_r,
        udp_data_i   => udp_0_rx_data_r,
        -- ctrl bus
        address_o    => ctrl_0_address,
        data_o       => ctrl_0_data_w,
        data_i       => ctrl_0_data_r,
        burst_size_o => ctrl_0_burst_size,
        strobe_o     => ctrl_0_strobe,
        write_o      => ctrl_0_write,
        ack_i        => ctrl_0_ack);

    i_ctrl_1 : eth_ctrl
    generic map (
        address_width_g => address_width_c,
        data_width_g    => data_width_c,
        burst_size_g    => burst_size_c)
    port map (
        clk_i        => clk,
        reset_i      => '0',
        -- udp tx
        udp_valid_o  => udp_1_tx_valid,
        udp_ready_i  => '1',
        udp_last_o   => udp_1_tx_last,
        udp_data_o   => udp_1_tx_data,
        -- udp rx
        udp_valid_i  => udp_1_rx_valid_r,
        udp_ready_o  => udp_1_rx_ready,
        udp_last_i   => udp_1_rx_last_r,
        udp_data_i   => udp_1_rx_data_r,
        -- ctrl bus
        address_o    => ctrl_1_address,
        data_o       => ctrl_1_data_w,
        data_i       => ctrl_1_data_r,
        burst_size_o => ctrl_1_burst_size,
        strobe_o     => ctrl_1_strobe,
        write_o      => ctrl_1_write,
        ack_i        => ctrl_1_ack);

    i_ctrl_2 : eth_ctrl
    generic map (
        address_width_g => address_width_c,
        data_width_g    => data_width_c,
        burst_size_g    => burst_size_c)
    port map (
        clk_i        => clk,
        reset_i      => '0',
        -- udp tx
        udp_valid_o  => udp_2_tx_valid,
        udp_ready_i  => '1',
        udp_last_o   => udp_2_tx_last,
        udp_data_o   => udp_2_tx_data,
        -- udp rx
        udp_valid_i  => udp_2_rx_valid_r,
        udp_ready_o  => udp_2_rx_ready,
        udp_last_i   => udp_2_rx_last_r,
        udp_data_i   => udp_2_rx_data_r,
        -- ctrl bus
        address_o    => ctrl_2_address,
        data_o       => ctrl_2_data_w,
        data_i       => ctrl_2_data_r,
        burst_size_o => ctrl_2_burst_size,
        strobe_o     => ctrl_2_strobe,
        write_o      => ctrl_2_write,
        ack_i        => ctrl_2_ack);

    master_address_gen : for j in ctrl_0_address'range generate
        master_address(0, j) <= ctrl_0_address(j);
        master_address(1, j) <= ctrl_1_address(j);
        master_address(2, j) <= ctrl_2_address(j);
    end generate master_address_gen;

    master_write_data_gen : for j in ctrl_0_data_w'range generate
        master_write_data(0, j) <= ctrl_0_data_w(j);
        master_write_data(1, j) <= ctrl_1_data_w(j);
        master_write_data(2, j) <= ctrl_2_data_w(j);
    end generate master_write_data_gen;

    master_burst_size_gen : for j in ctrl_0_burst_size'range generate
        master_burst_size(0, j) <= ctrl_0_burst_size(j);
        master_burst_size(1, j) <= ctrl_1_burst_size(j);
        master_burst_size(2, j) <= ctrl_2_burst_size(j);
    end generate master_burst_size_gen;

    master_strobe(0) <= ctrl_0_strobe;
    master_strobe(1) <= ctrl_1_strobe;
    master_strobe(2) <= ctrl_2_strobe;

    master_write(0) <= ctrl_0_write;
    master_write(1) <= ctrl_1_write;
    master_write(2) <= ctrl_2_write;

    ctrl_0_ack <= master_ack(0);
    ctrl_1_ack <= master_ack(1);
    ctrl_2_ack <= master_ack(2);

    ctrl_0_data_r <= array_extract(0, master_read_data);
    ctrl_1_data_r <= array_extract(1, master_read_data);
    ctrl_2_data_r <= array_extract(2, master_read_data);

    i_master_interconnect : master_interconnect
    generic map (
        number_of_masters_g => 3,
        data_width_g        => data_width_c,
        address_width_g     => address_width_c,
        burst_size_g        => burst_size_c)
    port map (
        clk_i               => clk,
        reset_i             => '0',
        -- master
        master_address_i    => master_address,
        master_data_i       => master_write_data,
        master_data_o       => master_read_data,
        master_burst_size_i => master_burst_size,
        master_strobe_i     => master_strobe,
        master_write_i      => master_write,
        master_ack_o        => master_ack,
        -- slave
        slave_address_o     => ctrl_3_address,
        slave_data_i        => ctrl_3_data_r,
        slave_data_o        => ctrl_3_data_w,
        slave_burst_size_o  => ctrl_3_burst_size,
        slave_strobe_o      => ctrl_3_strobe,
        slave_write_o       => ctrl_3_write,
        slave_ack_i         => ctrl_3_ack);

    i_registerbank : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => read_only_c,
        data_width_g     => data_width_c,
        address_width_g  => address_width_c-2,
        burst_size_g     => burst_size_c)
    port map (
        clk_i             => clk,
        reset_i           => '0',
        -- register
        data_i            => register_read_data_r,
        data_strb_i       => register_read_strb_r,
        data_o            => open,
        data_strb_o       => open,
        -- ctrl bus
        ctrl_address_i    => ctrl_3_address(address_width_c-1 downto 2),
        ctrl_data_i       => ctrl_3_data_w,
        ctrl_data_o       => ctrl_3_data_r,
        ctrl_burst_size_i => ctrl_3_burst_size,
        ctrl_strobe_i     => ctrl_3_strobe,
        ctrl_write_i      => ctrl_3_write,
        ctrl_ack_o        => ctrl_3_ack);

    ctrl0_proc : process
        variable address_v    : std_logic_vector(address_width_c-1 downto 0);
        variable write_data_v : std_logic_array_32(255 downto 0);
        variable read_data_v  : std_logic_array_32(255 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);
        -- write 0x12345678 to adress 0x8
        address_v := x"0008";
        write_data_v(0) := x"12345678";
        ctrl_write(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, write_data_v, x"0004");
        -- write 0xaabbccdd to adress 0xC
        address_v := x"000C";
        write_data_v(0) := x"aabbccdd";
        ctrl_write(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, write_data_v, x"0004");
        wait until rising_edge(clk);
        -- read address 0x8
        address_v := x"0008";
        ctrl_read(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_0_tx_valid, udp_0_tx_data, udp_0_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"12345678") report "read error" severity error;
        -- read address 0xC
        address_v := x"000C";
        ctrl_read(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_0_tx_valid, udp_0_tx_data, udp_0_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"aabbccdd") report "read error" severity error;
        -- 4 word burst write
        address_v := x"0010";
        for i in 0 to 3 loop
            write_data_v(i) := std_logic_vector(to_unsigned(256+i, 32));
        end loop;
        ctrl_write(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, write_data_v, x"0010");
        -- 4 word burst read
        address_v := x"0010";
        ctrl_read(clk, udp_0_rx_valid_r, udp_0_rx_data_r, udp_0_rx_last_r, udp_0_rx_ready, address_v, x"0010");
        ctrl_wait_for_read_data(clk, udp_0_tx_valid, udp_0_tx_data, udp_0_tx_last, read_data_v, 4);
        for i in 0 to 3 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(256+i, 32))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en_0 <= false;
        wait;
    end process ctrl0_proc;

    ctrl1_proc : process
        variable address_v    : std_logic_vector(address_width_c-1 downto 0);
        variable write_data_v : std_logic_array_32(255 downto 0);
        variable read_data_v  : std_logic_array_32(255 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);
        -- write to adress 0x28
        address_v := x"0028";
        write_data_v(0) := x"12ab34cd";
        ctrl_write(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, write_data_v, x"0004");
        -- write to adress 0x2C
        address_v := x"002C";
        write_data_v(0) := x"aa12bb34";
        ctrl_write(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, write_data_v, x"0004");
        wait until rising_edge(clk);
        -- read address 0x28
        address_v := x"0028";
        ctrl_read(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_1_tx_valid, udp_1_tx_data, udp_1_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"12ab34cd") report "read error" severity error;
        -- read address 0x2C
        address_v := x"002C";
        ctrl_read(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_1_tx_valid, udp_1_tx_data, udp_1_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"aa12bb34") report "read error" severity error;
        -- 4 word burst write
        address_v := x"0030";
        for i in 0 to 3 loop
            write_data_v(i) := std_logic_vector(to_unsigned(512+i, 32));
        end loop;
        ctrl_write(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, write_data_v, x"0010");
        -- 4 word burst read
        address_v := x"0030";
        ctrl_read(clk, udp_1_rx_valid_r, udp_1_rx_data_r, udp_1_rx_last_r, udp_1_rx_ready, address_v, x"0010");
        ctrl_wait_for_read_data(clk, udp_1_tx_valid, udp_1_tx_data, udp_1_tx_last, read_data_v, 4);
        for i in 0 to 3 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(512+i, 32))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en_1 <= false;
        wait;
    end process ctrl1_proc;

    ctrl2_proc : process
        variable address_v    : std_logic_vector(address_width_c-1 downto 0);
        variable write_data_v : std_logic_array_32(255 downto 0);
        variable read_data_v  : std_logic_array_32(255 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);
        -- write to adress 0x48
        address_v := x"0048";
        write_data_v(0) := x"cdab99cd";
        ctrl_write(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, write_data_v, x"0004");
        -- write to adress 0x4C
        address_v := x"004C";
        write_data_v(0) := x"ff12bb34";
        ctrl_write(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, write_data_v, x"0004");
        wait until rising_edge(clk);
        -- read address 0x48
        address_v := x"0048";
        ctrl_read(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_2_tx_valid, udp_2_tx_data, udp_2_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"cdab99cd") report "read error" severity error;
        -- read address 0x4C
        address_v := x"004C";
        ctrl_read(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data(clk, udp_2_tx_valid, udp_2_tx_data, udp_2_tx_last, read_data_v, 1);
        debug_data <= read_data_v(0);
        assert (read_data_v(0) = x"Ff12bb34") report "read error" severity error;
        -- 4 word burst write
        address_v := x"0050";
        for i in 0 to 3 loop
            write_data_v(i) := std_logic_vector(to_unsigned(1024+i, 32));
        end loop;
        ctrl_write(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, write_data_v, x"0010");
        -- 4 word burst read
        address_v := x"0050";
        ctrl_read(clk, udp_2_rx_valid_r, udp_2_rx_data_r, udp_2_rx_last_r, udp_2_rx_ready, address_v, x"0010");
        ctrl_wait_for_read_data(clk, udp_2_tx_valid, udp_2_tx_data, udp_2_tx_last, read_data_v, 4);
        for i in 0 to 3 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(1024+i, 32))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en_2 <= false;
        wait;
    end process ctrl2_proc;

end rtl;
