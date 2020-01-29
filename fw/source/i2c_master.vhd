--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 31.12.2019
-- Filename  : i2c_master.vhd
-- Changelog : 31.12.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity i2c_master is
generic (
    freq_in_g  : positive := 50000000;
    freq_out_g : positive := 100000);
port (
    clk_i     : in  std_logic;
    reset_i   : in  std_logic;
    scl_o     : out std_logic;
    sda_i     : in  std_logic;
    sda_o     : out std_logic;
    -- ctrl bus
    address_i : in  std_logic_vector(9 downto 0);
    data_i    : in  std_logic_vector(31 downto 0);
    data_o    : out std_logic_vector(31 downto 0);
    strobe_i  : in  std_logic;
    write_i   : in  std_logic;
    ack_o     : out std_logic);
end entity i2c_master;

architecture rtl of i2c_master is

    constant freq_div_c   : positive := freq_in_g / freq_out_g / 4;

    type fsm_t is (idle_s, prepare_start_s, start_s,
                   address_s, rw_s, error_s, address_ack_s,
                   data_write_s, data_write_ack_s,
                   data_read_s, data_read_ack_s,
                   end0_s, end1_s);

    signal scl_counter_r : unsigned(log2ceil(freq_div_c)-1 downto 0) := (others => '0');
    signal clock_state_r : std_logic_vector(1 downto 0) := "00";
    signal scl_r         : std_logic := '1';
    signal sda_r         : std_logic := '1';

    signal fsm_r             : fsm_t := idle_s;
    signal state_done_r      : std_logic := '0';
    signal address_r         : std_logic_vector(6 downto 0) := (others => '0');
    signal address_counter_r : unsigned(2 downto 0) := (others => '0');
    signal ack_r             : std_logic := '0';
    signal ack_done_r        : std_logic := '0';
    signal read_r            : std_logic := '0';
    signal data_r            : std_logic_vector(31 downto 0) := (others => '0');
    signal data_counter_r    : unsigned(2 downto 0) := (others => '0');
    signal byte_counter_r    : unsigned(1 downto 0) := (others => '0');
    signal ctrl_ack_r        : std_logic := '0';
    signal error_r           : std_logic := '0';

begin

    clk_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (scl_counter_r /= to_unsigned(freq_div_c-1, scl_counter_r'length)) then
                scl_counter_r <= scl_counter_r + 1;
            else
                scl_counter_r <= (others => '0');
                clock_state_r <= std_logic_vector(unsigned(clock_state_r) + 1);
            end if;
        end if;
    end process clk_proc;

    i2c_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            ctrl_ack_r <= '0';
            case (fsm_r) is
                when idle_s =>
                    -- address_i(9 downto 8) : number of transaction bytes
                    -- address_i(7)          : read error bit
                    -- address_i(6 downto 0) : slave address
                    -- data_i(31 downto 24)  : read/write register
                    -- data_i(23 downto 0)   : read/write data (left aligned for write)
                    if (strobe_i = '1') then
                        if (address_i(7) = '1') then
                            data_r <= x"0000000" & "000" & error_r;
                            error_r <= '0';
                            ctrl_ack_r <= '1';
                        else
                            address_r <= address_i(6 downto 0);
                            byte_counter_r <= unsigned(address_i(9 downto 8));
                            data_r <= data_i;
                            read_r <= not write_i;
                            fsm_r <= prepare_start_s;
                        end if;
                    end if;

                when prepare_start_s =>
                    if (sda_i = '1') and (clock_state_r = "11") then
                        state_done_r <= '0';
                        fsm_r <= start_s;
                    end if;
                    address_counter_r <= (others => '0');
                    data_counter_r <= (others => '0');

                when start_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '0';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        fsm_r <= address_s;
                    end if;

                when address_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= address_r(address_r'high);
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        address_r <= address_r(address_r'high-1 downto 0) & '1';
                        if (address_counter_r = to_unsigned(6, address_counter_r'length)) then
                            fsm_r <= rw_s;
                        else
                            address_counter_r <= address_counter_r + 1;
                        end if;
                    end if;

                when rw_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= read_r;
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        fsm_r <= address_ack_s;
                    end if;

                when address_ack_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") and (ack_done_r = '0') then
                        ack_done_r <= '1';
                        ack_r <= sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        ack_done_r <= '0';
                        if (ack_r = '0') then
                            if (read_r = '1') then
                                fsm_r <= data_read_s;
                            else
                                fsm_r <= data_write_s;
                            end if;
                        else
                            fsm_r <= error_s;
                        end if;
                    end if;

                when error_s =>
                    scl_r <= '1';
                    error_r <= '1';
                    ctrl_ack_r <= '1';
                    fsm_r <= idle_s;

                when data_write_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= data_r(data_r'high);
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        data_r <= data_r(data_r'high-1 downto 0) & '1';
                        data_counter_r <= data_counter_r + 1;
                        if (data_counter_r = to_unsigned(7, data_counter_r'length)) then
                            fsm_r <= data_write_ack_s;
                        end if;
                    end if;

                when data_write_ack_s =>
                    data_counter_r <= (others => '0');
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") and (ack_done_r = '0') then
                        ack_done_r <= '1';
                        ack_r <= sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        ack_done_r <= '0';
                        if (ack_r = '0') then
                            if (byte_counter_r /= "00") then
                                byte_counter_r <= byte_counter_r - 1;
                                fsm_r <= data_write_s;
                            else
                                fsm_r <= end0_s;
                            end if;
                        else
                            fsm_r <= error_s;
                        end if;
                    end if;

                when data_read_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") and (ack_done_r = '0') then
                        ack_done_r <= '1';
                        data_r <= data_r(data_r'high-1 downto 0) & sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        ack_done_r <= '0';
                        data_counter_r <= data_counter_r + 1;
                        if (data_counter_r = to_unsigned(7, data_counter_r'length)) then
                            fsm_r <= data_read_ack_s;
                        end if;
                    end if;

                when data_read_ack_s =>
                    data_counter_r <= (others => '0');
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        if (byte_counter_r /= "00") then
                            sda_r <= '0';
                        else
                            sda_r <= '1';
                        end if;
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        if (ack_r = '0') then
                            if (byte_counter_r /= "00") then
                                byte_counter_r <= byte_counter_r - 1;
                                fsm_r <= data_read_s;
                            else
                                fsm_r <= end0_s;
                            end if;
                        else
                            fsm_r <= error_s;
                        end if;
                    end if;

                when end0_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '0';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        state_done_r <= '0';
                        fsm_r <= end1_s;
                    end if;

                when end1_s =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        state_done_r <= '0';
                        ctrl_ack_r <= '1';
                        fsm_r <= idle_s;
                    end if;

            end case;

            if (reset_i = '1') then
                fsm_r <= idle_s;
                error_r <= '0';
                ack_done_r <= '0';
                scl_r <= '1';
                sda_r <= '1';
            end if;
        end if;
    end process i2c_proc;

    scl_o <= scl_r;
    sda_o <= sda_r;
    ack_o <= ctrl_ack_r;
    data_o <= data_r;

end rtl;