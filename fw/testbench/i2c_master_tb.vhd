--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.01.2020
-- Filename  : i2c_master_tb.vhd
-- Changelog : 03.01.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity i2c_master_tb is
end entity i2c_master_tb;

architecture rtl of i2c_master_tb is

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

    component i2c_master is
    generic (
        freq_in_g       : positive;
        freq_out_g      : positive);
    port (
        clk_i   : in  std_logic;
        reset_i : in  std_logic;
        scl_o   : out std_logic;
        sda_i   : in  std_logic;
        sda_o   : out std_logic;
        -- ctrl bus
        address_i   : in  std_logic_vector(9 downto 0);
        data_i      : in  std_logic_vector(31 downto 0);
        data_o      : out std_logic_vector(31 downto 0);
        strobe_i    : in  std_logic;
        write_i     : in  std_logic;
        ack_o       : out std_logic);
    end component i2c_master;

    component i2c_slave is
    generic (
        I2C_ADDRESS : std_logic_vector(7 downto 0));
    port (
        clk_i        : in  std_logic;
        scl_i        : in  std_logic;
        sda_i        : in  std_logic;
        sda_o        : out std_logic;
        address_o    : out std_logic_vector(7 downto 0);
        wr_o         : out std_logic;
        rd_o         : out std_logic;
        rd_valid_i   : in  std_logic;
        rd_data_i    : in  std_logic_vector(7 downto 0);
        wr_data_o    : out std_logic_vector(7 downto 0));
    end component i2c_slave;

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

    constant address_width_c  : positive := 16;
    constant data_width_c     : positive := 32;
    constant i2c_slave_addr_c : std_logic_vector(7 downto 0) := x"34";

    constant command_read_c          : std_logic_vector(7 downto 0) := x"01";
    constant command_write_c         : std_logic_vector(7 downto 0) := x"02";
    constant command_read_response_c : std_logic_vector(7 downto 0) := x"04";
    constant command_read_timeout_c  : std_logic_vector(7 downto 0) := x"08";

    signal clk    : std_logic := '0';
    signal clk_en : boolean := true;

    signal ctrl_address : std_logic_vector(address_width_c-1 downto 0);
    signal ctrl_data_r  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
    signal ctrl_data_w  : std_logic_vector(data_width_c-1 downto 0);
    signal ctrl_strobe  : std_logic;
    signal ctrl_write   : std_logic;
    signal ctrl_ack     : std_logic;

    signal scl_ms : std_logic;
    signal sda_ms : std_logic;
    signal sda_sm : std_logic;

    signal i2c_slave_address  : std_logic_vector(7 downto 0);
    signal i2c_slave_wr       : std_logic;
    signal i2c_slave_rd       : std_logic;
    signal i2c_slave_rd_valid : std_logic;
    signal i2c_slave_rd_data  : std_logic_vector(7 downto 0);
    signal i2c_slave_wr_data  : std_logic_vector(7 downto 0);

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
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
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

    i_i2c_master : i2c_master
    generic map (
        freq_in_g       => 50000000,
        freq_out_g      => 100000)
    port map (
        clk_i   => clk,
        reset_i => '0',
        scl_o   => scl_ms,
        sda_i   => sda_sm,
        sda_o   => sda_ms,
        -- ctrl bus
        address_i   => ctrl_address(9 downto 0),
        data_i      => ctrl_data_w,
        data_o      => ctrl_data_r,
        strobe_i    => ctrl_strobe,
        write_i     => ctrl_write,
        ack_o       => ctrl_ack);

    i_i2c_slave : i2c_slave
    generic map (
        I2C_ADDRESS => i2c_slave_addr_c)
    port map (
        clk_i        => clk,
        scl_i        => scl_ms,
        sda_i        => sda_ms,
        sda_o        => sda_sm,
        address_o    => i2c_slave_address,
        wr_o         => i2c_slave_wr,
        rd_o         => i2c_slave_rd,
        rd_valid_i   => i2c_slave_rd_valid,
        rd_data_i    => i2c_slave_rd_data,
        wr_data_o    => i2c_slave_wr_data);

    i_i2c_slave_ram : ram
    generic map (
        addr_width_g   => i2c_slave_address'length,
        data_width_g   => i2c_slave_wr_data'length)
    port map (
        clk_i     => clk,
        -- write port
        wr_data_i => i2c_slave_wr_data,
        wr_i      => i2c_slave_wr,
        wr_addr_i => i2c_slave_address,
        -- read port
        rd_data_o => i2c_slave_rd_data,
        rd_i      => i2c_slave_rd,
        rd_addr_i => i2c_slave_address);

    i2c_slave_ram_read_ack_proc : process (clk)
    begin
        if (rising_edge(clk)) then
            i2c_slave_rd_valid <= i2c_slave_rd;
        end if;
    end process i2c_slave_ram_read_ack_proc;

    ctrl_proc : process
        procedure ctrl_wait_for_signal (signal ready : in  std_logic) is
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

        procedure ctrl_write (signal   valid   : out std_logic;
                              signal   data    : out std_logic_vector(7 downto 0);
                              signal   last    : out std_logic;
                              signal   ready   : in  std_logic;
                              constant address : in  std_logic_vector(address_width_c-1 downto 0);
                              constant wdata   : in  std_logic_vector(data_width_c-1 downto 0);
                              constant wlength : in  std_logic_vector(7 downto 0)) is 
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
            data <= wlength; -- data length
            for i in 0 to (to_integer(unsigned(wlength))/4)-1 loop
                ctrl_wait_for_signal (ready);
                data <= wdata(31 downto 24); -- data msb
                ctrl_wait_for_signal (ready);
                data <= wdata(23 downto 16);
                ctrl_wait_for_signal (ready);
                data <= wdata(15 downto 8);
                ctrl_wait_for_signal (ready);
                data <= wdata(7 downto 0); -- data lsb
            end loop;
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
                             constant address : in  std_logic_vector(address_width_c-1 downto 0);
                             constant rlength : in  std_logic_vector(7 downto 0)) is
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
            ctrl_wait_for_signal (ready);
            data <= rlength; -- read length
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

        -- write 0x23 to adress 0x01
        address_v := x"01" & i2c_slave_addr_c;
        write_data_v := x"01_230000";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);

        -- read address 0x1
        address_v := x"00" & i2c_slave_addr_c;
        write_data_v := x"01_000000";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);
        address_v := x"00" & i2c_slave_addr_c;
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"04");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"00000023") report "read error" severity error;
        wait until rising_edge(clk);

        -- write 0xAABB to adress 0x02 (write 2 bytes)
        address_v := x"02" & i2c_slave_addr_c;
        write_data_v := x"02_AABB00";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);

        -- read address 0x2 (read 2 bytes)
        address_v := x"00" & i2c_slave_addr_c;
        write_data_v := x"02_000000";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);
        address_v := x"01" & i2c_slave_addr_c;
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"04");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"0000AABB") report "read error" severity error;
        wait until rising_edge(clk);

        -- write 0x123456 to adress 0x04 (write 3 bytes)
        address_v := x"03" & i2c_slave_addr_c;
        write_data_v := x"04_123456";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);

        -- read address 0x4 (read 3 bytes)
        address_v := x"00" & i2c_slave_addr_c;
        write_data_v := x"04_000000";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);
        address_v := x"02" & i2c_slave_addr_c;
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"04");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"00123456") report "read error" severity error;
        wait until rising_edge(clk);

        -- read address 0x1 (read 4 bytes)
        address_v := x"00" & i2c_slave_addr_c;
        write_data_v := x"01_000000";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"04");
        wait until rising_edge(clk);
        address_v := x"03" & i2c_slave_addr_c;
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"04");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v);
        debug_data <= read_data_v;
        assert (read_data_v = x"23AABB12") report "read error" severity error;
        wait until rising_edge(clk);

        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en <= false;
        wait;
    end process ctrl_proc;

end rtl;
