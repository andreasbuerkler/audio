--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.04.2020
-- Filename  : hyper_ram_controller_tb.vhd
-- Changelog : 03.04.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.vital_timing.all;

library fmf;
use fmf.gen_utils.all;

library work;
use work.fpga_pkg.all;

entity hyper_ram_controller_tb is
end entity hyper_ram_controller_tb;

architecture rtl of hyper_ram_controller_tb is

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

    component hyper_ram_controller is
    generic (
        clock_period_ns_g      : positive;
        config0_register_g     : std_logic_vector(15 downto 0);
        latency_cycles_g       : positive;
        max_burst_size_g       : positive;
        data_width_g           : positive;
        row_address_width_g    : positive;
        column_address_width_g : positive);
    port (
        clk_i             : in    std_logic;
        clk_shifted_i     : in    std_logic;
        reset_i           : in    std_logic;
        -- hyper bus
        hyper_rst_n_o     : out   std_logic;
        hyper_cs_n_o      : out   std_logic;
        hyper_clk_o       : out   std_logic;
        hyper_rwds_io     : inout std_logic;
        hyper_data_io     : inout std_logic_vector(7 downto 0);
        -- ctrl bus
        ctrl_address_i    : in    std_logic_vector(row_address_width_g+column_address_width_g-1 downto 0);
        ctrl_data_i       : in    std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o       : out   std_logic_vector(data_width_g-1 downto 0);
        ctrl_burst_size_i : in    std_logic_vector(log2ceil(max_burst_size_g)-1 downto 0);
        ctrl_strobe_i     : in    std_logic;
        ctrl_write_i      : in    std_logic;
        ctrl_ack_o        : out   std_logic);
    end component hyper_ram_controller;

    component s27kl0641 is
    generic (
        tipd_DQ0                           : VitalDelayType01;
        tipd_DQ1                           : VitalDelayType01;
        tipd_DQ2                           : VitalDelayType01;
        tipd_DQ3                           : VitalDelayType01;
        tipd_DQ4                           : VitalDelayType01;
        tipd_DQ5                           : VitalDelayType01;
        tipd_DQ6                           : VitalDelayType01;
        tipd_DQ7                           : VitalDelayType01;
        tipd_CSNeg                         : VitalDelayType01;
        tipd_CK                            : VitalDelayType01;
        tipd_RESETNeg                      : VitalDelayType01;
        tipd_RWDS                          : VitalDelayType01;
        tpd_CSNeg_RWDS                     : VitalDelayType01Z;
        tpd_CK_RWDS                        : VitalDelayType01Z;
        tpd_CSNeg_DQ0                      : VitalDelayType01Z;
        tpd_CK_DQ0                         : VitalDelayType01Z;
        tsetup_CSNeg_CK                    : VitalDelayType;
        tsetup_DQ0_CK                      : VitalDelayType;
        thold_CSNeg_CK                     : VitalDelayType;
        thold_DQ0_CK                       : VitalDelayType;
        thold_CSNeg_RESETNeg               : VitalDelayType;
        trecovery_CSNeg_CK_posedge_negedge : VitalDelayType;
        tpw_CK_negedge                     : VitalDelayType;
        tpw_CK_posedge                     : VitalDelayType;
        tpw_CSNeg_posedge                  : VitalDelayType;
        tpw_RESETNeg_negedge               : VitalDelayType;
        tperiod_CK                         : VitalDelayType;
        tdevice_VCS                        : VitalDelayType;
        tdevice_DPD                        : VitalDelayType;
        tdevice_DPDCSL                     : VitalDelayType;
        tdevice_RPH                        : VitalDelayType;
        tdevice_REF100                     : VitalDelayType;
        tdevice_PO100                      : VitalDelayType;
        tdevice_CSM                        : VitalDelayType;
        InstancePath                       : string;
        TimingChecksOn                     : boolean;
        MsgOn                              : boolean;
        XOn                                : boolean;
        mem_file_name                      : string;
        UserPreload                        : boolean;
        TimingModel                        : string);
    port (
        DQ7      : inout std_logic;
        DQ6      : inout std_logic;
        DQ5      : inout std_logic;
        DQ4      : inout std_logic;
        DQ3      : inout std_logic;
        DQ2      : inout std_logic;
        DQ1      : inout std_logic;
        DQ0      : inout std_logic;
        CSNeg    : in    std_ulogic;
        CK       : in    std_ulogic;
        RESETNeg : in    std_ulogic;
        RWDS     : inout std_logic);
    end component s27kl0641;

    constant burst_size_c            : positive := 32;
    constant command_read_c          : std_logic_vector(7 downto 0) := x"01";
    constant command_write_c         : std_logic_vector(7 downto 0) := x"02";
    constant command_read_response_c : std_logic_vector(7 downto 0) := x"04";
    constant command_read_timeout_c  : std_logic_vector(7 downto 0) := x"08";

    signal clk         : std_logic;
    signal clk_shifted : std_logic;
    signal clk_en      : boolean := true;
    signal reset       : std_logic := '1';
    signal reset_n     : std_logic;

    signal hyper_data    : std_logic_vector(7 downto 0);
    signal hyper_rwds    : std_logic;
    signal hyper_cs_n    : std_logic;
    signal hyper_clk     : std_logic;
    signal hyper_reset_n : std_logic;

    signal ctrl_address    : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_data_r     : std_logic_vector(31 downto 0);
    signal ctrl_data_w     : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_burst_size : std_logic_vector(log2ceil(burst_size_c)-1 downto 0);
    signal ctrl_strobe     : std_logic;
    signal ctrl_write      : std_logic;
    signal ctrl_ack        : std_logic;

    signal udp_rx_valid_r : std_logic := '0';
    signal udp_rx_ready   : std_logic;
    signal udp_rx_last_r  : std_logic := '0';
    signal udp_rx_data_r  : std_logic_vector(7 downto 0) := x"00";

    signal udp_tx_valid : std_logic;
    signal udp_tx_last  : std_logic;
    signal udp_tx_data  : std_logic_vector(7 downto 0);

    signal debug_data : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- 50 MHz
    clk_proc : process
    begin
        if (clk_en) then
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end if;
    end process clk_proc;

    clk_shifted <= transport clk after 5 ns;

    reset_proc : process
    begin
        wait for 100 ns;
        wait until rising_edge(clk);
        reset <= '0';
        wait;
    end process reset_proc;

    i_ctrl : eth_ctrl
    generic map (
        address_width_g => 32,
        data_width_g    => 32,
        burst_size_g    => burst_size_c)
    port map (
        clk_i        => clk, 
        reset_i      => '0',
        -- udp tx
        udp_valid_o  => udp_tx_valid,
        udp_ready_i  => '1',
        udp_last_o   => udp_tx_last,
        udp_data_o   => udp_tx_data,
        -- udp rx
        udp_valid_i  => udp_rx_valid_r,
        udp_ready_o  => udp_rx_ready,
        udp_last_i   => udp_rx_last_r,
        udp_data_i   => udp_rx_data_r,
        -- ctrl bus
        address_o    => ctrl_address,
        data_o       => ctrl_data_w,
        data_i       => ctrl_data_r,
        burst_size_o => ctrl_burst_size,
        strobe_o     => ctrl_strobe,
        write_o      => ctrl_write,
        ack_i        => ctrl_ack);

    control_proc : process
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
                              constant address : in  std_logic_vector(31 downto 0);
                              constant wdata   : in  std_logic_array_32;
                              constant wlength : in  std_logic_vector(15 downto 0)) is 
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
            data <= wlength(15 downto 8); -- data length msb
            ctrl_wait_for_signal (ready);
            data <= wlength(7 downto 0); -- data length lsb
            for i in 0 to (to_integer(unsigned(wlength))/4)-1 loop
                ctrl_wait_for_signal (ready);
                data <= wdata(i)(31 downto 24); -- data msb
                ctrl_wait_for_signal (ready);
                data <= wdata(i)(23 downto 16);
                ctrl_wait_for_signal (ready);
                data <= wdata(i)(15 downto 8);
                ctrl_wait_for_signal (ready);
                data <= wdata(i)(7 downto 0); -- data lsb
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
                             constant address : in  std_logic_vector(31 downto 0);
                             constant rlength : in  std_logic_vector(15 downto 0)) is
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
            data <= rlength(15 downto 8); -- read length msb
            ctrl_wait_for_signal (ready);
            data <= rlength(7 downto 0); -- read length lsb
            last <= '1';
            ctrl_wait_for_signal (ready);
            last <= '0';
            valid <= '0';
            data <= x"00";
        end ctrl_read;

        procedure ctrl_wait_for_read_data (signal   valid   : in  std_logic;
                                           signal   data    : in  std_logic_vector(7 downto 0);
                                           signal   last    : in  std_logic;
                                           variable rdata   : out std_logic_array_32;
                                           constant rlength : in  natural) is
            variable data_v : std_logic_vector(31 downto 0);
        begin
            ctrl_wait_for_signal(valid); -- packet number
            ctrl_wait_for_signal(valid); -- id
            ctrl_wait_for_signal(valid); -- command
            if (data = command_read_timeout_c) then
                if (last = '0') then
                    ctrl_wait_for_signal(last);
                end if;
                for i in 0 to rlength-1 loop
                    rdata(i) := x"00000000";
                end loop;
            else
                ctrl_wait_for_signal(valid); -- size msb
                ctrl_wait_for_signal(valid); -- size lsb
                for i in 0 to rlength-1 loop
                    ctrl_wait_for_signal(valid);
                    data_v(31 downto 24) := data;
                    ctrl_wait_for_signal(valid);
                    data_v(23 downto 16) := data;
                    ctrl_wait_for_signal(valid);
                    data_v(15 downto 8) := data;
                    ctrl_wait_for_signal(valid);
                    data_v(7 downto 0) := data;
                    rdata(i) := data_v;
                end loop;
                if (last = '0') then
                    ctrl_wait_for_signal(last);
                end if;
            end if;
        end ctrl_wait_for_read_data;

        variable address_v    : std_logic_vector(31 downto 0);
        variable write_data_v : std_logic_array_32(255 downto 0);
        variable read_data_v  : std_logic_array_32(255 downto 0);
    begin
        wait for 210 us;
        wait until rising_edge(clk);

        -- single word write
        address_v := std_logic_vector(to_unsigned(4, address_v'length));
        write_data_v(0) := x"12345678";
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"0004");

        -- single word read
        address_v := std_logic_vector(to_unsigned(4, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"0004");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v, 1);
        assert (read_data_v(0) = x"12345678") report "read error" severity error;
        debug_data <= read_data_v(0);

        -- 4 word burst write
        address_v := std_logic_vector(to_unsigned(16, address_v'length));
        for i in 0 to 3 loop
            write_data_v(i) := std_logic_vector(to_unsigned(256+i, address_v'length));
        end loop;
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"0010");

        -- 4 word burst read
        address_v := std_logic_vector(to_unsigned(16, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"0010");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v, 4);
        for i in 0 to 3 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(256+i, address_v'length))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        -- 32 word burst write
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        for i in 0 to 31 loop
            write_data_v(i) := std_logic_vector(to_unsigned(1024+i, address_v'length));
        end loop;
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"0080");

        -- 32 word burst read
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"0080");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v, 32);
        for i in 0 to 31 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(1024+i, address_v'length))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        -- 256 word burst write
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        for i in 0 to 255 loop
            write_data_v(i) := std_logic_vector(to_unsigned(i, address_v'length));
        end loop;
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"0400");

        -- 256 word burst read
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"0400");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v, 256);
        for i in 0 to 255 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(i, address_v'length))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        -- 33 word burst write
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        for i in 0 to 32 loop
            write_data_v(i) := std_logic_vector(to_unsigned(1024+i, address_v'length));
        end loop;
        ctrl_write(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, write_data_v, x"0084");

        -- 33 word burst read
        address_v := std_logic_vector(to_unsigned(20, address_v'length));
        ctrl_read(udp_rx_valid_r, udp_rx_data_r, udp_rx_last_r, udp_rx_ready, address_v, x"0084");
        ctrl_wait_for_read_data (udp_tx_valid, udp_tx_data, udp_tx_last, read_data_v, 33);
        for i in 0 to 32 loop
            assert (read_data_v(i) = std_logic_vector(to_unsigned(1024+i, address_v'length))) report "read error" severity error;
            debug_data <= read_data_v(i);
            wait until rising_edge(clk);
        end loop;

        wait for 1 us;
        clk_en <= false;
        wait;
    end process control_proc;

    i_dut : hyper_ram_controller
    generic map (
        clock_period_ns_g      => 20,
        config0_register_g     => x"8FEC",
        latency_cycles_g       => 6,
        max_burst_size_g       => burst_size_c,
        data_width_g           => 32,
        row_address_width_g    => 13,
        column_address_width_g => 9)
    port map (
        clk_i             => clk,
        clk_shifted_i     => clk_shifted,
        reset_i           => reset,
        -- hyper bus
        hyper_rst_n_o     => hyper_reset_n,
        hyper_cs_n_o      => hyper_cs_n,
        hyper_clk_o       => hyper_clk,
        hyper_rwds_io     => hyper_rwds,
        hyper_data_io     => hyper_data,
        -- ctrl bus
        ctrl_address_i    => ctrl_address(22 downto 1),
        ctrl_data_i       => ctrl_data_w,
        ctrl_data_o       => ctrl_data_r,
        ctrl_burst_size_i => ctrl_burst_size,
        ctrl_strobe_i     => ctrl_strobe,
        ctrl_write_i      => ctrl_write,
        ctrl_ack_o        => ctrl_ack);

    i_model : s27kl0641
    generic map (
        tipd_DQ0                           => VitalZeroDelay01,
        tipd_DQ1                           => VitalZeroDelay01,
        tipd_DQ2                           => VitalZeroDelay01,
        tipd_DQ3                           => VitalZeroDelay01,
        tipd_DQ4                           => VitalZeroDelay01,
        tipd_DQ5                           => VitalZeroDelay01,
        tipd_DQ6                           => VitalZeroDelay01,
        tipd_DQ7                           => VitalZeroDelay01,
        tipd_CSNeg                         => VitalZeroDelay01,
        tipd_CK                            => VitalZeroDelay01,
        tipd_RESETNeg                      => VitalZeroDelay01,
        tipd_RWDS                          => VitalZeroDelay01,
        tpd_CSNeg_RWDS                     => UnitDelay01Z,
        tpd_CK_RWDS                        => (others => 6.0 ns),
        tpd_CSNeg_DQ0                      => UnitDelay01Z,
        tpd_CK_DQ0                         => (others => 5.2 ns),
        tsetup_CSNeg_CK                    => UnitDelay,
        tsetup_DQ0_CK                      => UnitDelay,
        thold_CSNeg_CK                     => UnitDelay,
        thold_DQ0_CK                       => UnitDelay,
        thold_CSNeg_RESETNeg               => UnitDelay,
        trecovery_CSNeg_CK_posedge_negedge => UnitDelay,
        tpw_CK_negedge                     => UnitDelay,
        tpw_CK_posedge                     => UnitDelay,
        tpw_CSNeg_posedge                  => UnitDelay,
        tpw_RESETNeg_negedge               => UnitDelay,
        tperiod_CK                         => UnitDelay,
        tdevice_VCS                        => 150 us,
        tdevice_DPD                        => 150 us,
        tdevice_DPDCSL                     => 200 ns,
        tdevice_RPH                        => 400 ns,
        tdevice_REF100                     => 40 ns,
        tdevice_PO100                      => 40 ns,
        tdevice_CSM                        => 4 us,
        InstancePath                       => DefaultInstancePath,
        TimingChecksOn                     => DefaultTimingChecks,
        MsgOn                              => DefaultMsgOn,
        XOn                                => DefaultXOn,
        mem_file_name                      => "../testbench/s27kl0641/model/s27kl0641.mem",
        UserPreload                        => false,
        TimingModel                        => "S27KL0641DABHI000")
    port map (
        DQ7      => hyper_data(7),
        DQ6      => hyper_data(6),
        DQ5      => hyper_data(5),
        DQ4      => hyper_data(4),
        DQ3      => hyper_data(3),
        DQ2      => hyper_data(2),
        DQ1      => hyper_data(1),
        DQ0      => hyper_data(0),
        CSNeg    => hyper_cs_n,
        CK       => hyper_clk,
        RESETNeg => hyper_reset_n,
        RWDS     => hyper_rwds);

end rtl;
