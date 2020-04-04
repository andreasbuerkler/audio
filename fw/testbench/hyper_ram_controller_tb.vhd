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

    signal clk     : std_logic;
    signal clk_en  : boolean := true;
    signal reset   : std_logic := '1';
    signal reset_n : std_logic;

    signal hyper_data      : std_logic_vector(7 downto 0);
    signal hyper_rwds      : std_logic;
    signal hyper_cs_n      : std_logic;
    signal hyper_clk       : std_logic;
    signal hyper_clk_delay : std_logic;
    signal hyper_reset_n   : std_logic;

    signal ctrl_address    : std_logic_vector(21 downto 0) := (others => '0');
    signal ctrl_data_w     : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_burst_size : std_logic_vector(2 downto 0) := (others => '0');
    signal ctrl_strobe     : std_logic := '0';
    signal ctrl_write      : std_logic := '0';
    signal ctrl_ack        : std_logic;

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

    reset_proc : process
    begin
        wait for 100 ns;
        wait until rising_edge(clk);
        reset <= '0';
        wait;
    end process reset_proc;

    control_proc : process
    begin
        wait for 250 us;
        wait until rising_edge(clk);

        -- single word write
        ctrl_address <= "0000100001000000001000";
        ctrl_data_w <= x"12345678";
        ctrl_burst_size <= "000";
        ctrl_strobe <= '1';
        ctrl_write <= '1';
        wait until rising_edge(clk);
        ctrl_data_w <= x"DEADBEEF";
        ctrl_write <= '0';
        ctrl_strobe <= '0';
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);

        -- single word read
        ctrl_address <= "0000100001000000001000";
        ctrl_data_w <= x"12345678";
        ctrl_burst_size <= "000";
        ctrl_strobe <= '1';
        ctrl_write <= '0';
        wait until rising_edge(clk);
        ctrl_data_w <= x"DEADBEEF";
        ctrl_strobe <= '0';
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);

        -- 2 burst write
        ctrl_address <= "0000100001000000001000";
        ctrl_data_w <= x"12345678";
        ctrl_burst_size <= "001";
        ctrl_strobe <= '1';
        ctrl_write <= '1';
        wait until rising_edge(clk);
        ctrl_data_w <= x"DEADBEEF";
        ctrl_write <= '0';
        ctrl_strobe <= '0';
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);
        ctrl_data_w <= x"ABCDEF01";
        ctrl_strobe <= '1';
        wait until rising_edge(clk);
        ctrl_data_w <= x"DEADBEEF";
        ctrl_strobe <= '0';
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);

        -- 2 burst read
        ctrl_address <= "0000100001000000001000";
        ctrl_data_w <= x"00000000";
        ctrl_burst_size <= "001";
        ctrl_strobe <= '1';
        ctrl_write <= '0';
        wait until rising_edge(clk);
        ctrl_strobe <= '0';
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);
        wait until ctrl_ack = '1';
        wait until rising_edge(clk);

        wait for 1 us;
        clk_en <= false;
        wait;
    end process control_proc;

    hyper_clk_delay <= transport hyper_clk after 5 ns;

    i_dut : hyper_ram_controller
    generic map (
        clock_period_ns_g      => 20,
        config0_register_g     => x"8FEC",
        latency_cycles_g       => 6,
        max_burst_size_g       => 8,
        data_width_g           => 32,
        row_address_width_g    => 13,
        column_address_width_g => 9)
    port map (
        clk_i             => clk,
        reset_i           => reset,
        -- hyper bus
        hyper_rst_n_o     => hyper_reset_n,
        hyper_cs_n_o      => hyper_cs_n,
        hyper_clk_o       => hyper_clk,
        hyper_rwds_io     => hyper_rwds,
        hyper_data_io     => hyper_data,
        -- ctrl bus
        ctrl_address_i    => ctrl_address,
        ctrl_data_i       => ctrl_data_w,
        ctrl_data_o       => open,
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
        tpd_CK_RWDS                        => UnitDelay01Z,
        tpd_CSNeg_DQ0                      => UnitDelay01Z,
        tpd_CK_DQ0                         => UnitDelay01Z,
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
        CK       => hyper_clk_delay,
        RESETNeg => hyper_reset_n,
        RWDS     => hyper_rwds);

end rtl;
