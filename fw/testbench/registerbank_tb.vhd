--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 28.12.2018
-- Filename  : registerbank_tb.vhd
-- Changelog : 28.12.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity registerbank_tb is
end entity registerbank_tb;

architecture rtl of registerbank_tb is

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

    component registerbank is
    generic (
        register_count_g : positive;
        register_init_g  : std_logic_array_32;
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
        -- ctrl bus
        ctrl_address_i : in  std_logic_vector(address_width_g-1 downto 0);
        ctrl_data_i    : in  std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o    : out std_logic_vector(data_width_g-1 downto 0);
        ctrl_strobe_i  : in  std_logic;
        ctrl_write_i   : in  std_logic;
        ctrl_ack_o     : out std_logic);
    end component registerbank;

    constant address_width_c  : positive := 16;
    constant data_width_c     : positive := 32;
    constant register_count_c : positive := 8;
    constant register_init_c  : std_logic_array_32(register_count_c-1 downto 0) :=
                               (x"00000000",
                                x"00000001",
                                x"00000002",
                                x"00000003",
                                x"00000004",
                                x"00000005",
                                x"00000006",
                                x"00000007");

    constant command_read_c          : std_logic_vector(7 downto 0) := x"01";
    constant command_write_c         : std_logic_vector(7 downto 0) := x"02";
    constant command_read_response_c : std_logic_vector(7 downto 0) := x"04";
    constant command_read_timeout_c  : std_logic_vector(7 downto 0) := x"08";

    signal clk    : std_logic := '0';
    signal clk_en : boolean := true;

    signal ctrl_address : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_data_r  : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_data_w  : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_strobe  : std_logic;
    signal ctrl_write   : std_logic;
    signal ctrl_ack     : std_logic;

    signal register_read_data_r : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_read_strb_r : std_logic_vector(register_count_c-1 downto 0) := (others => '0');

    signal udp_rx_valid_r : std_logic := '0';
    signal udp_rx_ready   : std_logic;
    signal udp_rx_last_r  : std_logic := '0';
    signal udp_rx_data_r  : std_logic_vector(7 downto 0) := x"00";

    signal udp_tx_valid : std_logic;
    signal udp_tx_last  : std_logic;
    signal udp_tx_data  : std_logic_vector(7 downto 0);

    signal debug_data : std_logic_vector(data_width_c-1 downto 0) := (others => '0');

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        if (clk_en) then
            clk <= '0';
            wait for 20 ns;
            clk <= '1';
            wait for 20 ns;
        end if;
    end process clkgen_proc;

    i_ctrl : eth_ctrl
    generic map (
        address_width_g => address_width_c,
        data_width_g    => data_width_c)
    port map (
        clk_i       => clk,
        reset_i     => '0',
        -- udp tx
        udp_valid_o => udp_tx_valid,
        udp_ready_i => '1',
        udp_last_o  => udp_tx_last,
        udp_data_o  => udp_tx_data,
        -- udp rx
        udp_valid_i => udp_rx_valid_r,
        udp_ready_o => udp_rx_ready,
        udp_last_i  => udp_rx_last_r,
        udp_data_i  => udp_rx_data_r,
        -- ctrl bus
        address_o   => ctrl_address,
        data_o      => ctrl_data_w,
        data_i      => ctrl_data_r,
        strobe_o    => ctrl_strobe,
        write_o     => ctrl_write,
        ack_i       => ctrl_ack);

    i_registerbank : registerbank
    generic map (
        register_count_g => 8,
        register_init_g  => register_init_c,
        data_width_g     => data_width_c,
        address_width_g  => address_width_c)
    port map (
        clk_i          => clk,
        reset_i        => '0',
        -- register
        data_i         => register_read_data_r,
        data_strb_i    => register_read_strb_r,
        data_o         => open,
        data_strb_o    => open,
        -- ctrl bus
        ctrl_address_i => ctrl_address,
        ctrl_data_i    => ctrl_data_w,
        ctrl_data_o    => ctrl_data_r,
        ctrl_strobe_i  => ctrl_strobe,
        ctrl_write_i   => ctrl_write,
        ctrl_ack_o     => ctrl_ack);

    ctrl_proc : process
        procedure ctrl_wait_for_signal (signal ready : in  std_logic) is
        begin
            wait until rising_edge(clk);
            if (ready = '0') then
                wait until ready = '1';
            end if;
            wait for 1 ns;
        end ctrl_wait_for_signal;

        procedure ctrl_write (signal   valid   : out std_logic;
                              signal   data    : out std_logic_vector(7 downto 0);
                              signal   last    : out std_logic;
                              signal   ready   : in  std_logic;
                              constant address : in  std_logic_vector(address_width_c-1 downto 0);
                              constant wdata   : in  std_logic_vector(data_width_c-1 downto 0)) is 
        begin
            ctrl_wait_for_signal (ready);
            valid <= '1';
            data <= x"07"; -- packet number
            ctrl_wait_for_signal (ready);
            data <= x"02"; -- id
            ctrl_wait_for_signal (ready);
            data <= command_write_c; -- command
            ctrl_wait_for_signal (ready);
            data <= x"04"; -- address length
            ctrl_wait_for_signal (ready);
            data <= x"00"; -- address msb
            ctrl_wait_for_signal (ready);
            data <= x"00";
            ctrl_wait_for_signal (ready);
            data <= address(15 downto 8);
            ctrl_wait_for_signal (ready);
            data <= address(7 downto 0); -- address lsb
            ctrl_wait_for_signal (ready);
            data <= x"04"; -- data length
            ctrl_wait_for_signal (ready);
            data <= wdata(31 downto 24); -- data msb
            ctrl_wait_for_signal (ready);
            data <= wdata(23 downto 16);
            ctrl_wait_for_signal (ready);
            data <= wdata(15 downto 8);
            ctrl_wait_for_signal (ready);
            data <= wdata(7 downto 0); -- data lsb
            last <= '1';
            ctrl_wait_for_signal (ready);
            last <= '0';
            valid <= '0';
            data <= x"00";
        end ctrl_write;

        procedure ctrl_read (signal   valid   : out std_logic;
                             signal   data    : out std_logic_vector(7 downto 0);
                             signal   last    : out std_logic;
                             signal   ready   : in  std_logic;
                             constant address : in  std_logic_vector(address_width_c-1 downto 0)) is
        begin
            ctrl_wait_for_signal (ready);
            valid <= '1';
            data <= x"07"; -- packet number
            ctrl_wait_for_signal (ready);
            data <= x"02"; -- id
            ctrl_wait_for_signal (ready);
            data <= command_read_c; -- command
            ctrl_wait_for_signal (ready);
            data <= x"04"; -- address length
            ctrl_wait_for_signal (ready);
            data <= x"00"; -- address msb
            ctrl_wait_for_signal (ready);
            data <= x"00";
            ctrl_wait_for_signal (ready);
            data <= address(15 downto 8);
            ctrl_wait_for_signal (ready);
            data <= address(7 downto 0); -- address lsb
            last <= '1';
            ctrl_wait_for_signal (ready);
            last <= '0';
            valid <= '0';
            data <= x"00";
        end ctrl_read;

        procedure ctrl_wait_for_read_data (signal   valid   : in  std_logic;
                                           signal   data    : in  std_logic_vector(7 downto 0);
                                           signal   last    : in  std_logic;
                                           variable rdata   : out std_logic_vector(data_width_c-1 downto 0)) is
            variable data_v : std_logic_vector(31 downto 0);
        begin
            ctrl_wait_for_signal(valid); -- packet number
            ctrl_wait_for_signal(valid); -- id
            ctrl_wait_for_signal(valid); -- command
            if (data = command_read_timeout_c) then
                if (last = '0') then
                    ctrl_wait_for_signal(last);
                end if;
                rdata := x"00000000";
            else
                ctrl_wait_for_signal(valid); -- size
                ctrl_wait_for_signal(valid);
                data_v(31 downto 24) := data;
                ctrl_wait_for_signal(valid);
                data_v(23 downto 16) := data;
                ctrl_wait_for_signal(valid);
                data_v(15 downto 8) := data;
                ctrl_wait_for_signal(valid);
                data_v(7 downto 0) := data;
                if (last = '0') then
                    ctrl_wait_for_signal(last);
                end if;
                rdata := data_v(rdata'range);
            end if;
        end ctrl_wait_for_read_data;

        variable address_v    : std_logic_vector(address_width_c-1 downto 0);
        variable write_data_v : std_logic_vector(data_width_c-1 downto 0);
        variable read_data_v  : std_logic_vector(data_width_c-1 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);
        -- read init values
        for i in 0 to register_count_c-1 loop
            address_v := std_logic_vector(to_unsigned(i, address_v'length));
            ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v);
            ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
            assert (read_data_v = register_init_c(i)) report "read error" severity error;
            debug_data <= read_data_v;
        end loop;
        -- overwrite all registers
        for i in 0 to register_count_c-1 loop
            address_v := std_logic_vector(to_unsigned(i, address_v'length));
            write_data_v := std_logic_vector(to_unsigned(i*20, write_data_v'length));
            ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v);
        end loop;
        -- read overwritten values
        for i in 0 to register_count_c-1 loop
            address_v := std_logic_vector(to_unsigned(i, address_v'length));
            ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v);
            ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
            assert (read_data_v = std_logic_vector(to_unsigned(i*20, write_data_v'length))) report "read error" severity error;
            debug_data <= read_data_v;
        end loop;
        -- test read timeout
        address_v := std_logic_vector(to_unsigned(register_count_c, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v);
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        -- write 0x12345678 to adress 0x2
        address_v := x"0002";
        write_data_v := x"12345678";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v);
        -- write 0xaabbccdd to adress 0x3
        address_v := x"0003";
        write_data_v := x"aabbccdd";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v);
        wait until rising_edge(clk);
        -- read address 0x2
        address_v := x"0002";
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v);
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"12345678") report "read error" severity error;
        -- read address 0x3
        address_v := x"0003";
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v);
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"aabbccdd") report "read error" severity error;
        report "done";
        clk_en <= false;
        wait;
    end process ctrl_proc;

end rtl;
