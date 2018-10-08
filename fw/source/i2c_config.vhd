--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2c_config.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity i2c_config is
generic (
    I2C_ADDRESS : std_logic_vector(7 downto 0) := x"34";
    CONFIG      : std_logic_vector := x"07_03";
    FREQ_I      : positive := 50000000;
    FREQ_O      : positive := 100000);
port (
    clk_i   : in  std_logic;
    reset_i : in  std_logic;
    error_o : out std_logic;
    done_o  : out std_logic;
    scl_o   : out std_logic;
    sda_i   : in  std_logic;
    sda_o   : out std_logic);
end entity i2c_config;

architecture rtl of i2c_config is

    constant ADDR_W     : positive := 8;
    constant DATA_W     : positive := 8;
    constant FREQ_DIV   : positive := FREQ_I / FREQ_O / 4;
    constant MEM_DATA_W : positive := CONFIG'length / (DATA_W + ADDR_W);
    constant MEM_ADDR_W : positive := log2ceil(MEM_DATA_W);

    type mem_t is array(natural range <>) of std_logic_vector(DATA_W+ADDR_W-1 downto 0);
    type fsm_t is (IDLE_ST, START_ST, ADDRESS_ST, RW_ST, ERROR_ST,
                   ADDRESS_ACK_ST, DATA0_ST, DATA0_ACK_ST,
                   DATA1_ST, DATA1_ACK_ST, END0_ST, END1_ST);
                   
    function mem_init return mem_t is
        variable mem_v : mem_t((2**MEM_ADDR_W)-1 downto 0) := (others => (others => '0'));
    begin
        for i in 0 to 2**MEM_ADDR_W-1 loop
            if (i<MEM_DATA_W) then
                mem_v(i) := CONFIG((i*(DATA_W+ADDR_W)) to ((i+1)*(DATA_W+ADDR_W))-1);
            end if;
        end loop;
        return mem_v;
    end mem_init;

    signal mem_r        : mem_t((2**MEM_ADDR_W)-1 downto 0) := mem_init;
    signal r_addr_r     : std_logic_vector(MEM_ADDR_W downto 0) := (others => '0');
    signal r_data_r     : std_logic_vector(DATA_W+ADDR_W-1 downto 0) := (others => '0');
    signal r_data_out_r : std_logic_vector(DATA_W+ADDR_W-1 downto 0) := (others => '0');

    signal scl_counter_r : unsigned(log2ceil(FREQ_DIV)-1 downto 0) := (others => '0');
    signal clock_state_r : std_logic_vector(1 downto 0) := "00";
    signal scl_r         : std_logic := '1';
    signal sda_r         : std_logic := '1';

    signal fsm_r             : fsm_t := IDLE_ST;
    signal state_done_r      : std_logic := '0';
    signal address_r         : std_logic_vector(6 downto 0) := I2C_ADDRESS(6 downto 0);
    signal address_counter_r : unsigned(2 downto 0) := (others => '0');
    signal error_r           : std_logic := '0';
    signal done_r            : std_logic := '0';
    signal ack_r             : std_logic := '0';
    signal data_r            : std_logic_vector(ADDR_W+DATA_W-1 downto 0) := (others => '0');
    signal data_counter_r    : unsigned(log2ceil(DATA_W+ADDR_W) downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    mem_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            r_data_r <= mem_r(to_integer(unsigned(r_addr_r(MEM_ADDR_W-1 downto 0))));
            r_data_out_r <= r_data_r;
        end if;
    end process mem_proc;

    clk_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (scl_counter_r /= to_unsigned(FREQ_DIV-1, scl_counter_r'length)) then
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
            case (fsm_r) is
                when IDLE_ST =>
                    if (unsigned(r_addr_r) < to_unsigned(MEM_DATA_W, r_addr_r'length)) then
                        if (sda_i = '1') and (clock_state_r = "11") then
                            state_done_r <= '0';
                            r_addr_r <= std_logic_vector(unsigned(r_addr_r) + 1);
                            fsm_r <= START_ST;
                        end if;
                        address_r <= I2C_ADDRESS(6 downto 0);
                        data_r <= r_data_out_r;
                        address_counter_r <= (others => '0');
                        data_counter_r <= (others => '0');
                    else
                        done_r <= '1';
                    end if;

                when START_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '0';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        fsm_r <= ADDRESS_ST;
                    end if;

                when ADDRESS_ST =>
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
                            fsm_r <= RW_ST;
                        else
                            address_counter_r <= address_counter_r + 1;
                        end if;
                    end if;

                when RW_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '0';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        fsm_r <= ADDRESS_ACK_ST;
                    end if;

                when ADDRESS_ACK_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") then
                        ack_r <= sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        if (ack_r = '0') then
                            fsm_r <= DATA0_ST;
                        else
                            fsm_r <= ERROR_ST;
                        end if;
                    end if;

                when ERROR_ST =>
                    error_r <= '1';

                when DATA0_ST =>
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
                        if (data_counter_r = to_unsigned(ADDR_W-1, data_counter_r'length)) then
                            fsm_r <= DATA0_ACK_ST;
                        end if;
                    end if;

                when DATA0_ACK_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") then
                        ack_r <= sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        if (ack_r = '0') then
                            fsm_r <= DATA1_ST;
                        else
                            fsm_r <= ERROR_ST;
                        end if;
                    end if;

                when DATA1_ST =>
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
                        if (data_counter_r = to_unsigned(ADDR_W+DATA_W-1, data_counter_r'length)) then
                            fsm_r <= DATA1_ACK_ST;
                        else
                            data_counter_r <= data_counter_r + 1;
                        end if;
                    end if;

                when DATA1_ACK_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "10") then
                        ack_r <= sda_i;
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        scl_r <= '0';
                        state_done_r <= '0';
                        if (ack_r = '0') then
                            fsm_r <= END0_ST;
                        else
                            fsm_r <= ERROR_ST;
                        end if;
                    end if;

                when END0_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '0';
                    end if;
                    if (clock_state_r = "01") then
                        scl_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        state_done_r <= '0';
                        fsm_r <= END1_ST;
                    end if;

                when END1_ST =>
                    if (clock_state_r = "00") then
                        state_done_r <= '1';
                        sda_r <= '1';
                    end if;
                    if (clock_state_r = "11") and (state_done_r = '1') then
                        state_done_r <= '0';
                        fsm_r <= IDLE_ST;
                    end if;

            end case;

            if (reset_i = '1') then
                r_addr_r <= (others => '0');
                error_r <= '0';
                done_r <= '0';
                fsm_r <= IDLE_ST;
            end if;
        end if;
    end process i2c_proc;

    scl_o <= scl_r;
    sda_o <= sda_r;
    error_o <= error_r;
    done_o <= done_r;

end rtl;