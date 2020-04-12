--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 30.12.2019
-- Filename  : hyper_ram_controller.vhd
-- Changelog : 30.12.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity hyper_ram_controller is
generic (
    clock_period_ns_g      : positive := 20;
    config0_register_g     : std_logic_vector(15 downto 0) := x"8FEC";
    latency_cycles_g       : positive := 6;
    max_burst_size_g       : positive := 32;
    data_width_g           : positive := 32;
    row_address_width_g    : positive := 13;
    column_address_width_g : positive := 9);
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
end entity hyper_ram_controller;

architecture rtl of hyper_ram_controller is

    constant power_up_wait_cycles_c : positive := 200000/clock_period_ns_g;
    constant ca_read_sel_c          : natural := 47;
    constant ca_space_sel_c         : natural := 46;
    constant ca_burst_sel_c         : natural := 45;
    subtype  ca_upper_address_range_c is natural range 44 downto 16;
    subtype  ca_lower_address_range_c is natural range 2 downto 0;

    type fsm_t is (idle_s, start_s, init_s, address_s, wait_s, read_s, write_s);

    signal fsm_r               : fsm_t := idle_s;
    signal init_done_r         : std_logic := '0';
    signal init_counter_r      : unsigned(log2ceil(power_up_wait_cycles_c+1)-1 downto 0) := to_unsigned(power_up_wait_cycles_c, log2ceil(power_up_wait_cycles_c+1));
    signal data_r              : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal data_read_r         : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal data_read_cc_r      : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal data_ack_r          : std_logic := '0';
    signal data_halfword_sel_r : std_logic := '0';
    signal burst_counter_r     : unsigned(log2ceil(max_burst_size_g)-1 downto 0) := (others => '0');
    signal ca_r                : std_logic_vector(47 downto 0) := (others => '0');
    signal ca_counter_r        : unsigned(1 downto 0) := (others => '0');
    signal latency_counter_r   : unsigned(log2ceil(latency_cycles_g)-1 downto 0) := to_unsigned(latency_cycles_g-2, log2ceil(latency_cycles_g));
    signal read_request_r      : std_logic := '0';
    signal write_request_r     : std_logic := '0';
    signal address_r           : std_logic_vector(row_address_width_g+column_address_width_g-1 downto 0) := (others => '0');
    signal burst_size_r        : std_logic_vector(ctrl_burst_size_i'range) := (others => '0');
    signal first_data_r        : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal in_progress_r       : std_logic := '0';

    signal hyper_clk_en_r        : std_logic := '0';
    signal hyper_clk_en_delay_r  : std_logic := '0';
    signal hyper_cs_en_r         : std_logic := '0';
    signal hyper_cs_en_delay_r   : std_logic := '0';

    signal hyper_data_en_r       : std_logic := '0';
    signal hyper_data_en_delay_r : std_logic := '0';
    signal hyper_data_in         : std_logic_vector(15 downto 0);
    signal hyper_data_in_upper_r : std_logic_vector(7 downto 0) := (others => '0');
    signal hyper_data_out_r      : std_logic_vector(15 downto 0) := (others => '0');

    signal hyper_rwds_en_r       : std_logic := '0';
    signal hyper_rwds_en_delay_r : std_logic := '0';

    signal hyper_data_in_counter_r       : unsigned(log2ceil(2*max_burst_size_g) downto 0) := (others => '0');
    signal hyper_data_in_counter_cc_r    : unsigned(log2ceil(2*max_burst_size_g) downto 0) := (others => '0');
    signal hyper_data_in_counter_delay_r : unsigned(log2ceil(2*max_burst_size_g) downto 0) := (others => '0');
    signal hyper_data_in_counter_low_r   : std_logic := '0';
    signal hyper_data_in_counter_reset_r : std_logic := '0';

begin

    input_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (ctrl_strobe_i = '1') then
                address_r <= ctrl_address_i;
                burst_size_r <= ctrl_burst_size_i;
                first_data_r <= ctrl_data_i;
                if (ctrl_write_i = '1') then
                    write_request_r <= '1';
                else
                    read_request_r <= '1';
                end if;
            end if;
            if ((reset_i = '1') or (data_ack_r = '1')) then
                read_request_r <= '0';
                write_request_r <= '0';
            end if;
        end if;
    end process input_proc;

    fsm_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            data_ack_r <= '0';
            hyper_data_in_counter_reset_r <= '0';
            case (fsm_r) is
                when idle_s =>
                    in_progress_r <= '0';
                    hyper_rwds_en_r <= '0';
                    hyper_data_en_r <= '0';
                    hyper_cs_en_r <= '0';
                    hyper_clk_en_r <= '0';
                    data_halfword_sel_r <= '0';
                    latency_counter_r <= to_unsigned(latency_cycles_g-2, latency_counter_r'length);
                    if (init_done_r = '0') then
                        fsm_r <= init_s;
                    elsif (((read_request_r = '1') or (write_request_r = '1')) and (in_progress_r = '0')) then
                        in_progress_r <= '1';
                        fsm_r <= start_s;
                    end if;

                when start_s =>
                    hyper_data_in_counter_reset_r <= '1';
                    ca_r(ca_read_sel_c) <= read_request_r;
                    ca_r(ca_space_sel_c) <= '0'; -- access to memory space
                    ca_r(ca_burst_sel_c) <= '1'; -- linear burst
                    ca_r(ca_upper_address_range_c) <= std_logic_vector(resize(unsigned(address_r(address_r'high downto 3)), 29));
                    ca_r(ca_lower_address_range_c) <= address_r(2 downto 0);
                    burst_counter_r <= unsigned(burst_size_r);
                    if (write_request_r = '1') then
                        data_r <= first_data_r;
                    end if;
                    ca_counter_r <= (others => '0');
                    fsm_r <= address_s;

                when init_s =>
                    ca_r(ca_read_sel_c) <= '0';
                    ca_r(ca_space_sel_c) <= '1'; -- access to register space
                    ca_r(ca_burst_sel_c) <= '1'; -- linear burst
                    ca_r(ca_upper_address_range_c) <= '0' & x"0000100"; -- configuration 0 register
                    ca_r(ca_lower_address_range_c) <= "000";
                    burst_counter_r <= to_unsigned(0, burst_counter_r'length);
                    data_r <= x"0000" & config0_register_g(7 downto 0) & config0_register_g(15 downto 8);
                    ca_counter_r <= (others => '0');
                    -- wait 200us before first access
                    if (vector_or(std_logic_vector(init_counter_r)) = '0') then
                        fsm_r <= address_s;
                    else
                        init_counter_r <= init_counter_r - 1;
                    end if;

                when address_s =>
                    hyper_clk_en_r <= '1';
                    hyper_cs_en_r <= '1';
                    hyper_data_en_r <= '1';
                    ca_counter_r <= ca_counter_r + 1;
                    if (ca_counter_r = "00") then
                        hyper_data_out_r <= ca_r(47 downto 32);
                    elsif (ca_counter_r = "01") then
                        hyper_data_out_r <= ca_r(31 downto 16);
                    else
                        hyper_data_out_r <= ca_r(15 downto 0);
                        if (init_done_r = '0') then
                            -- go directly to write without latency for register access
                            fsm_r <= write_s;
                        else
                            -- add additional latency
                            fsm_r <= wait_s;
                        end if;
                    end if;

                when wait_s =>
                    hyper_data_en_r <= '0';
                    -- wait until initial latency has passed
                    if (vector_or(std_logic_vector(latency_counter_r)) = '0') then
                        if (ca_r(ca_read_sel_c) = '0') then
                            data_ack_r <= '1';
                            fsm_r <= write_s;
                        else
                            fsm_r <= read_s;
                        end if;
                    else
                        latency_counter_r <= latency_counter_r - 1;
                    end if;

                when read_s =>
                    hyper_data_en_r <= '0';
                    if (hyper_data_in_counter_low_r = '1') and (hyper_data_in_counter_delay_r(0) = '0') then
                        data_ack_r <= '1';
                    end if;
                    if (hyper_data_in_counter_delay_r(hyper_data_in_counter_delay_r'high downto 1) = (unsigned(burst_size_r)+1)) then
                        hyper_cs_en_r <= '0';
                        hyper_clk_en_r <= '0';
                        fsm_r <= idle_s;
                    end if;

                when write_s =>
                    hyper_data_en_r <= '1';
                    hyper_data_out_r <= data_r(7 downto 0) & data_r(15 downto 8);
                    data_halfword_sel_r <= not data_halfword_sel_r;
                    -- strobe signal is ignored but data is expected to be valid after each ack
                    if (data_halfword_sel_r = '0') then
                        data_r <= x"0000" & data_r(31 downto 16);
                    else
                        data_r <= ctrl_data_i;
                        burst_counter_r <= burst_counter_r - 1;
                    end if;
                    if (init_done_r = '0') then
                        -- transfer only 2 bytes to write configuration 0 register
                        init_done_r <= '1';
                        fsm_r <= idle_s;
                    else
                        if (vector_or(std_logic_vector(burst_counter_r)) = '0') then
                            if (data_halfword_sel_r = '1') then
                                fsm_r <= idle_s;
                            end if;
                        else
                            data_ack_r <= data_halfword_sel_r;
                        end if;
                        hyper_rwds_en_r <= '1';
                    end if;

            end case;

            if (reset_i = '1') then
                fsm_r <= idle_s;
                init_done_r <= '0';
                in_progress_r <= '0';
                init_counter_r <= to_unsigned(power_up_wait_cycles_c, init_counter_r'length);
            end if;
        end if;
    end process fsm_proc;

    delay_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            hyper_clk_en_delay_r <= hyper_clk_en_r;
            hyper_cs_en_delay_r <= hyper_cs_en_r;
            hyper_data_en_delay_r <= hyper_data_en_r;
            hyper_rwds_en_delay_r <= hyper_rwds_en_r;
            data_read_cc_r <= data_read_r;
        end if;
    end process delay_proc;

    data_read_proc : process (clk_i)
    begin
        if (falling_edge(clk_i)) then
            -- input data reordering on falling edge to improve timing
            hyper_data_in_upper_r <= hyper_data_in(7 downto 0);
            if (hyper_data_in_counter_cc_r(0) = '0') and (hyper_data_in_counter_delay_r(0) = '1') then
                data_read_r(31 downto 16) <= hyper_data_in(15 downto 8) & hyper_data_in_upper_r;
            elsif (hyper_data_in_counter_cc_r(0) = '1') and (hyper_data_in_counter_delay_r(0) = '0') then
                data_read_r(15 downto 0) <= hyper_data_in(15 downto 8) & hyper_data_in_upper_r;
            end if;
            hyper_data_in_counter_cc_r <= hyper_data_in_counter_r;
            hyper_data_in_counter_delay_r <= hyper_data_in_counter_cc_r;
            hyper_data_in_counter_low_r <= hyper_data_in_counter_delay_r(0);
        end if;
    end process data_read_proc;

    data_in_counter_proc : process (hyper_rwds_io, hyper_data_in_counter_reset_r)
    begin
        if (hyper_data_in_counter_reset_r = '1') then
            hyper_data_in_counter_r <= (others => '0');
        elsif (rising_edge(hyper_rwds_io)) then
            hyper_data_in_counter_r <= hyper_data_in_counter_r + 1;
        end if;
    end process data_in_counter_proc;

    i_ddr_data_reg : altddio_bidir
    generic map (
        extend_oe_disable        => "OFF",
        implement_input_in_lcell => "OFF",
        intended_device_family   => "Cyclone V",
        invert_output            => "OFF",
        lpm_hint                 => "UNUSED",
        lpm_type                 => "altddio_bidir",
        oe_reg                   => "UNREGISTERED",
        power_up_high            => "OFF",
        width                    => 8)
    port map (
        datain_h   => hyper_data_out_r(15 downto 8),
        datain_l   => hyper_data_out_r(7 downto 0),
        inclock    => hyper_rwds_io,
        outclock   => clk_i,
        dataout_h  => hyper_data_in(7 downto 0),
        dataout_l  => hyper_data_in(15 downto 8),
        padio      => hyper_data_io,
        oe         => hyper_data_en_delay_r);

    hyper_rwds_io <= '0' when (hyper_rwds_en_delay_r = '1') else 'Z';

    i_ddr_clk_reg : altddio_out
    generic map (
        extend_oe_disable      => "OFF",
        intended_device_family => "Cyclone V",
        invert_output          => "OFF",
        lpm_hint               => "UNUSED",
        lpm_type               => "altddio_out",
        oe_reg                 => "UNREGISTERED",
        power_up_high          => "OFF",
        width                  => 1)
    port map (
        datain_h(0) => hyper_clk_en_delay_r,
        datain_l(0) => '0',
        outclock    => clk_shifted_i,
        dataout(0)  => hyper_clk_o);

    hyper_cs_n_o <= not hyper_cs_en_delay_r;

    hyper_rst_n_o <= not reset_i;

    ctrl_data_o <= data_read_cc_r;
    ctrl_ack_o <= data_ack_r;

end rtl;
