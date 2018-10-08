--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2c_slave.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity i2c_slave is
generic (
    I2C_ADDRESS : std_logic_vector(7 downto 0) := x"34");
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
end entity i2c_slave;

architecture rtl of i2c_slave is

    type fsm_t is (WAIT_FOR_START_ST, WAIT_FOR_END_ST, SLAVE_ADDRESS_ST, SLAVE_ADDRESS_ACK_ST,
                   REGISTER_ADDRESS_ST, REGISTER_ADDRESS_ACK_ST, WRITE_DATA_ST, WRITE_DATA_ACK_ST,
                   READ_DATA_ST, READ_DATA_ACK_ST);

    signal scl_in_vec_r : std_logic_vector(2 downto 0) := (others => '1');
    signal sda_in_vec_r : std_logic_vector(2 downto 0) := (others => '1');

    signal sda_r            : std_logic := '0';
    signal scl_r            : std_logic := '0';
    signal start_r          : std_logic := '0';
    signal stop_r           : std_logic := '0';
    signal scl_rising_r     : std_logic := '0';
    signal scl_falling_r    : std_logic := '0';
    signal sda_toggle_r     : std_logic := '0';
    signal sda_valid_r      : std_logic := '0';
    signal read_data_stop_r : std_logic := '0';
    signal start_state_r    : std_logic := '0';

    signal fsm_r              : fsm_t := WAIT_FOR_START_ST;
    signal bit_counter_r      : unsigned(3 downto 0) := (others => '0');
    signal slave_address_r    : std_logic_vector(6 downto 0) := (others => '0');
    signal read_bit_r         : std_logic := '0';
    signal register_address_r : std_logic_vector(7 downto 0) := (others => '0');
    signal write_data_r       : std_logic_vector(7 downto 0) := (others => '0');
    signal sda_out_r          : std_logic := '1';
    
    signal wr_en_r         : std_logic := '0';
    signal rd_en_r         : std_logic := '0';
    signal address_out_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal data_in_r       : std_logic_vector(7 downto 0) := (others => '0');
    signal data_in_shift_r : std_logic_vector(7 downto 0) := (others => '0');

    signal clock_low_counter_r      : unsigned(10 downto 0) := (others => '0');
    signal clock_high_counter_r     : unsigned(10 downto 0) := (others => '0');
    signal clock_low_half_period_r  : unsigned(9 downto 0) := to_unsigned(10, 10);
    signal clock_high_half_period_r : unsigned(9 downto 0) := to_unsigned(10, 10);

begin

    input_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            sda_in_vec_r <= sda_in_vec_r(sda_in_vec_r'high-1 downto 0) & sda_i;
            scl_in_vec_r <= scl_in_vec_r(scl_in_vec_r'high-1 downto 0) & scl_i;
        end if;
    end process input_proc;

    event_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
        
            sda_r <= sda_in_vec_r(sda_in_vec_r'high);
            scl_r <= scl_in_vec_r(scl_in_vec_r'high);
            start_r <= '0';
            stop_r <= '0';
            scl_rising_r <= '0';
            scl_falling_r <= '0';
            sda_toggle_r <= '0';
            sda_valid_r <= '0';

            if ((sda_in_vec_r(sda_in_vec_r'high) = '0') and (sda_r = '1') and (scl_in_vec_r(scl_in_vec_r'high) = '1')) then
                start_r <= '1';
                start_state_r <= '1';
            end if;
            
            if ((sda_in_vec_r(sda_in_vec_r'high) = '1') and (sda_r = '0') and (scl_in_vec_r(scl_in_vec_r'high) = '1')) then
                stop_r <= '1';
            end if;

            if ((scl_in_vec_r(scl_in_vec_r'high) = '1') and (scl_r = '0')) then
                scl_rising_r <= '1';
            --    if (clock_low_half_period_r > clock_low_counter_r(clock_low_counter_r'high downto 1)) then
            --        clock_low_half_period_r <= clock_low_counter_r(clock_low_counter_r'high downto 1);
            --    end if;
            end if;

            if ((scl_in_vec_r(scl_in_vec_r'high) = '0') and (scl_r = '1')) then
                scl_falling_r <= '1';
            --    if (clock_high_half_period_r > clock_high_counter_r(clock_high_counter_r'high downto 1)) then
            --        clock_high_half_period_r <= clock_high_counter_r(clock_high_counter_r'high downto 1);
            --    end if;
            end if;

            if (clock_low_counter_r = resize(clock_low_half_period_r, clock_low_counter_r'length)) then
                sda_toggle_r <= '1';
                start_state_r <= '0';
            end if;

            if (clock_high_counter_r = resize(clock_high_half_period_r, clock_high_counter_r'length)) then
                sda_valid_r <= not start_state_r;
            end if;

        end if;
    end process event_proc;

    counter_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then

            if ((scl_in_vec_r(scl_in_vec_r'high) = '0') and (clock_low_counter_r(clock_low_counter_r'high) = '0')) then
                clock_low_counter_r <= clock_low_counter_r + 1;
            else
                clock_low_counter_r <= (others => '0');
            end if;

            if ((scl_in_vec_r(scl_in_vec_r'high) = '1') and (clock_high_counter_r(clock_high_counter_r'high) = '0')) then
                clock_high_counter_r <= clock_high_counter_r + 1;
            else
                clock_high_counter_r <= (others => '0');
            end if;

        end if;
    end process counter_proc;
    
    i2c_fsm_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            rd_en_r <= '0';
            wr_en_r <= '0';
            
            if (rd_valid_i = '1') then
                data_in_r <= rd_data_i;
            end if;
            
            case fsm_r is
                when WAIT_FOR_START_ST =>
                    bit_counter_r <= (others => '0');
                    if (start_r = '1') then
                        fsm_r <= SLAVE_ADDRESS_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '1';
                    end if;

                when SLAVE_ADDRESS_ST =>
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_valid_r = '1') then
                        bit_counter_r <= bit_counter_r + 1;
                        if (bit_counter_r /= to_unsigned(7, bit_counter_r'length)) then
                            slave_address_r <= slave_address_r(slave_address_r'high-1 downto 0) & sda_in_vec_r(sda_in_vec_r'high);
                        else
                            read_bit_r <= sda_in_vec_r(sda_in_vec_r'high);
                            if (sda_in_vec_r(sda_in_vec_r'high) = '1') then
                                rd_en_r <= '1';
                                address_out_r <= register_address_r;
                                register_address_r <= std_logic_vector(unsigned(register_address_r) + 1);
                            end if;
                        end if;
                    elsif (scl_falling_r = '1') then
                        if (bit_counter_r = to_unsigned(8, bit_counter_r'length)) then
                            fsm_r <= SLAVE_ADDRESS_ACK_ST;
                        end if;
                    end if;

                when SLAVE_ADDRESS_ACK_ST =>
                    bit_counter_r <= (others => '0');
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (slave_address_r = I2C_ADDRESS(slave_address_r'range)) then
                        if (sda_toggle_r = '1') then
                            sda_out_r <= '0';
                        elsif (scl_falling_r = '1') then
                            data_in_shift_r <= data_in_r;
                            if (read_bit_r = '1') then
                                fsm_r <= READ_DATA_ST;
                            else
                                fsm_r <= REGISTER_ADDRESS_ST;
                            end if;
                        end if;
                    else
                        fsm_r <= WAIT_FOR_END_ST;
                    end if;

                when REGISTER_ADDRESS_ST =>
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '1';
                    elsif (sda_valid_r = '1') then
                        bit_counter_r <= bit_counter_r + 1;
                        register_address_r <= register_address_r(register_address_r'high-1 downto 0) & sda_in_vec_r(sda_in_vec_r'high);
                    elsif (scl_falling_r = '1') then
                        if (bit_counter_r = to_unsigned(8, bit_counter_r'length)) then
                            fsm_r <= REGISTER_ADDRESS_ACK_ST;
                        end if;
                    end if;

                when REGISTER_ADDRESS_ACK_ST =>
                    bit_counter_r <= (others => '0');
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '0';
                    elsif (scl_falling_r = '1') then
                        fsm_r <= WRITE_DATA_ST;
                    end if;

                when WRITE_DATA_ST =>
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (start_r = '1') then
                        bit_counter_r <= (others => '0');
                        fsm_r <= SLAVE_ADDRESS_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '1';
                    elsif (sda_valid_r = '1') then
                        bit_counter_r <= bit_counter_r + 1;
                        write_data_r <= write_data_r(write_data_r'high-1 downto 0) & sda_in_vec_r(sda_in_vec_r'high);
                    elsif (scl_falling_r = '1') then
                        if (bit_counter_r = to_unsigned(8, bit_counter_r'length)) then
                            fsm_r <= WRITE_DATA_ACK_ST;
                        end if;
                    end if;

                when WRITE_DATA_ACK_ST =>
                    bit_counter_r <= (others => '0');
                    if (stop_r = '1') then
                        wr_en_r <= '1';
                        data_out_r <= write_data_r;
                        address_out_r <= register_address_r;
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '0';
                    elsif (scl_falling_r = '1') then
                        wr_en_r <= '1';
                        data_out_r <= write_data_r;
                        address_out_r <= register_address_r;
                        register_address_r <= std_logic_vector(unsigned(register_address_r) + 1);
                        fsm_r <= WRITE_DATA_ST;
                    end if;
                
                when READ_DATA_ST =>
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_toggle_r = '1') then
                        bit_counter_r <= bit_counter_r + 1;
                        sda_out_r <= data_in_shift_r(data_in_shift_r'high);
                        data_in_shift_r <= data_in_shift_r(data_in_shift_r'high-1 downto 0) & '1';
                    elsif (scl_falling_r = '1') then
                        if (bit_counter_r = to_unsigned(8, bit_counter_r'length)) then
                            rd_en_r <= '1';
                            address_out_r <= register_address_r;
                            register_address_r <= std_logic_vector(unsigned(register_address_r) + 1);
                            fsm_r <= READ_DATA_ACK_ST;
                        end if;
                    end if;

                when READ_DATA_ACK_ST =>
                    bit_counter_r <= (others => '0');
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    elsif (sda_toggle_r = '1') then
                        sda_out_r <= '1';
                    elsif (sda_valid_r = '1') then
                        if (sda_r = '0') then
                            read_data_stop_r <= '0';
                        else
                            read_data_stop_r <= '1';
                        end if;
                    elsif (scl_falling_r = '1') then
                        if (read_data_stop_r = '1') then
                            fsm_r <= WAIT_FOR_END_ST;
                        else
                            data_in_shift_r <= data_in_r;
                            fsm_r <= READ_DATA_ST;
                        end if;
                    end if;

                when WAIT_FOR_END_ST =>
                    if (stop_r = '1') then
                        fsm_r <= WAIT_FOR_START_ST;
                    end if;

            end case;
        end if;
    end process i2c_fsm_proc;

    sda_o <= sda_out_r;

    address_o <= address_out_r;
    wr_o <= wr_en_r;
    rd_o <= rd_en_r;
    wr_data_o <= data_out_r;

end rtl;