--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2s_inout_tb.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity i2s_inout_tb is
end entity i2s_inout_tb;

architecture rtl of i2s_inout_tb is

    -- settings
    constant enable_fast_i2c_clock : boolean := true;

    -- low pass filter 1 kHz
    constant coeff_low_pass_a0_c : real :=  0.0039160766836994;
    constant coeff_low_pass_a1_c : real :=  0.0078321533673989;
    constant coeff_low_pass_a2_c : real :=  0.0039160766836994;
    constant coeff_low_pass_b1_c : real :=  1.8153179156742152;
    constant coeff_low_pass_b2_c : real := -0.8309822224090128;
    
    -- high pass filter 1 kHz
    constant coeff_high_pass_a0_c : real :=  0.9115859293184209;
    constant coeff_high_pass_a1_c : real := -1.8231718586368417;
    constant coeff_high_pass_a2_c : real :=  0.9115859293184209;
    constant coeff_high_pass_b1_c : real :=  1.8153396116625289;
    constant coeff_high_pass_b2_c : real := -0.8310041056111546;
    
    component audio is
    generic (
        I2C_ADDRESS : std_logic_vector(7 downto 0) := x"34";
        DATA_W      : natural := 24);
    port (
        -- i2c
        i2c_scl_i   : in  std_logic;
        i2c_sda_i   : in  std_logic;
        i2c_sda_o   : out std_logic;
        -- i2s
        i2s_i       : in  std_logic;
        i2s_o       : out std_logic;
        i2s_mclk_i  : in  std_logic;  -- 12.288 MHz
        i2s_lrclk_o : out std_logic); --     48 kHz
    end component audio;

    component i2s_inout is
    port (
        m_clk_i       : in  std_logic;
        b_clk_o       : out std_logic;
        lr_clk_o      : out std_logic;
        i2s_i         : in  std_logic;
        i2s_o         : out std_logic;
        right_valid_o : out std_logic;
        left_valid_o  : out std_logic;
        data_o        : out std_logic_vector(23 downto 0);
        right_valid_i : in  std_logic;
        left_valid_i  : in  std_logic;
        data_i        : in  std_logic_vector(23 downto 0));
    end component;

    procedure i2c_write_32 (
        constant device  : in  std_logic_vector(7 downto 0);
        constant address : in  std_logic_vector(7 downto 0);
        constant data    : in  std_logic_vector(31 downto 0);
        signal   i2c_clk : in  std_logic;
        signal   scl     : out std_logic;
        signal   sda     : out std_logic) is
        variable send_data_v : std_logic_vector(7 downto 0);
    begin
        -- start
        scl <= '1';
        sda <= '1';
        wait until rising_edge(i2c_clk);
        sda <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write slave address
        send_data_v := device(6 downto 0) & '0';
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
            
        -- write register address
        send_data_v := address;
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write data 1
        send_data_v := data(7 downto 0);
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write data 2
        send_data_v := data(15 downto 8);
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write data 3
        send_data_v := data(23 downto 16);
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write data 4
        send_data_v := data(31 downto 24);
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- stop
        wait until rising_edge(i2c_clk);
        sda <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        sda <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);

    end i2c_write_32;

    procedure i2c_read_32 (
        constant device  : in  std_logic_vector(7 downto 0);
        constant address : in  std_logic_vector(7 downto 0);
        signal   data    : out std_logic_vector(31 downto 0);
        signal   i2c_clk : in  std_logic;
        signal   scl     : out std_logic;
        signal   sda_in  : in  std_logic;
        signal   sda_out : out std_logic) is
        variable send_data_v : std_logic_vector(7 downto 0);
    begin
         -- start
        scl <= '1';
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- write slave address
        send_data_v := device(6 downto 0) & '0';
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
            
        -- write register address
        send_data_v := address;
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= send_data_v(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';

        -- repeated start
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '0';

        -- write slave address
        send_data_v := device(6 downto 0) & '1';
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= send_data_V(send_data_v'high);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & '0';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- read data 1
        send_data_v := x"FF";
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & sda_in;
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        data(7 downto 0) <= send_data_v;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- read data 2
        send_data_v := x"FF";
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= '1';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & sda_in;
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        data(15 downto 8) <= send_data_v;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- read data 3
        send_data_v := x"FF";
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= '1';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & sda_in;
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        data(23 downto 16) <= send_data_v;
        
        -- ack
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';
        
        -- read data 4
        send_data_v := x"FF";
        for i in 0 to 7 loop
            wait until rising_edge(i2c_clk);
            sda_out <= '1';
            wait until rising_edge(i2c_clk);
            scl <= '1';
            wait until rising_edge(i2c_clk);
            send_data_v := send_data_v(send_data_v'high-1 downto 0) & sda_in;
            wait until rising_edge(i2c_clk);
            scl <= '0';
        end loop;
        
        data(31 downto 24) <= send_data_v;
        
        -- nack
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        scl <= '0';

        -- stop
        wait until rising_edge(i2c_clk);
        sda_out <= '0';
        wait until rising_edge(i2c_clk);
        scl <= '1';
        wait until rising_edge(i2c_clk);
        sda_out <= '1';
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);
        wait until rising_edge(i2c_clk);

    end i2c_read_32;

    -- clocks
    signal fast_clk                  : std_logic := '0';
    signal b_clk                     : std_logic := '0';
    signal lrclk                     : std_logic;
    signal i2c_clk                   : std_logic := '0';

    -- i2s signal generator
    signal i2s_r                     : std_logic := '0';
    signal i2s_data_r                : std_logic_vector(31 downto 0) := x"00000A00";
    signal i2s_counter_r             : unsigned(4 downto 0) := (others => '0');
    signal bclkold_r                 : std_logic_vector(3 downto 0) := x"0";
    signal lrclkold_r                : std_logic := '0';
    signal sinus_r                   : std_logic_vector(23 downto 0) := (others => '0');
    signal sinus_real_r              : real := 0.0;

    -- i2c
    signal scl     : std_logic := '1';
    signal sda_in  : std_logic := '1';
    signal sda_out : std_logic;

    -- dut output conversion
    signal i2s_out         : std_logic;
    signal left_valid_out  : std_logic;
    signal right_valid_out : std_logic;
    signal data_out        : std_logic_vector(23 downto 0);
    signal result_left_r   : std_logic_vector(23 downto 0);
    signal result_right_r  : std_logic_vector(23 downto 0);

    -- debug model
    signal debug_data_r       : signed(53 downto 0) := (others => '0');
    signal debug_data_delay_r : signed(53 downto 0) := (others => '0');
    signal debug_result_r     : std_logic_vector(23 downto 0) := (others => '0');

    -- real model
    signal model_data_r       : real := 0.0;
    signal model_data_delay_r : real := 0.0;
    signal model_result_r     : std_logic_vector(23 downto 0) := (others => '0');

    -- control process
    signal read_data : std_logic_vector(31 downto 0);

begin

    -- 3.072 MHz
--    bclkgen_proc : process
--    begin
--        b_clk <= '0';
--        wait for 15 ns;
--        b_clk <= '1';
--        wait for 15 ns;
--    end process bclkgen_proc;

    -- 12.288 MHz
    fastclkgen_proc : process
    begin
        fast_clk <= '0';
        wait for 3.75 ns;
        fast_clk <= '1';
        wait for 3.75 ns;
    end process fastclkgen_proc;

    -- for 400 kHz i2c clock
    i2cclkgen_proc : process
    begin
        i2c_clk <= '0';
        if (enable_fast_i2c_clock) then
            wait for 125 ns;
        else
            wait for 1.25 us;
        end if;
        i2c_clk <= '1';
        if (enable_fast_i2c_clock) then
            wait for 125 ns;
        else
            wait for 1.25 us;
        end if;
    end process i2cclkgen_proc;

    sin_gen_proc : process (fast_clk)
        variable inc_v      : real := 0.0;
    begin
        if (rising_edge(fast_clk)) then
            lrclkold_r <= lrclk;
            if ((lrclkold_r = '0') and (lrclk = '1')) then
                inc_v := inc_v + 1.0;
                if (inc_v = 48.0) then
                    inc_v := 0.0;
                end if;
                sinus_real_r <= SIN(MATH_2_PI/48.0*inc_v); -- 1kHz
                sinus_r <= std_logic_vector(to_signed(integer(sinus_real_r * ((2.0**22.0)-1.0)), 24));
            end if;
        end if;
    end process sin_gen_proc;

    i2s_proc : process (fast_clk)
    begin
        if (rising_edge(fast_clk)) then
            bclkold_r <= bclkold_r(bclkold_r'high-1 downto 0) & b_clk;
            if (bclkold_r(bclkold_r'high downto bclkold_r'high-1) = "10") then
                if ((lrclkold_r = '0') and (lrclk = '1')) then
                    i2s_counter_r <= to_unsigned(31, i2s_counter_r'length);
                else
                    i2s_counter_r <= i2s_counter_r - 1;
                end if;
                if (i2s_counter_r = to_unsigned(0, i2s_counter_r'length)) then
                    i2s_data_r <= sinus_r & x"00";
                end if;
                i2s_r <= i2s_data_r(to_integer(i2s_counter_r));
            end if;
        end if;
    end process i2s_proc;
    
    i2c_proc : process
    begin
        for i in 0 to 15 loop
            wait until rising_edge(i2c_clk);
        end loop;

        i2c_read_32 (x"34", x"04", read_data, i2c_clk, scl, sda_out, sda_in);

        -- 0 right channel low pass 1kHz
        i2c_write_32 (x"34", x"00", x"00000000", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000006", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000007", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000000a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000000b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 1 right channel channel low pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000010", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000016", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000017", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000001a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000001b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 2 right channel channel low pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000020", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000026", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000027", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000002a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000002b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 3 right channel channel low pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000030", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000036", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000037", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000003a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000003b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_low_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);


        -- 0 left channel high pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000040", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000046", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000047", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000004a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000004b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 1 left channel high pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000050", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000056", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000057", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000005a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000005b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 2 left channel high pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000060", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000066", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000067", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000006a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000006b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        -- 3 left channel high pass 1 kHz
        i2c_write_32 (x"34", x"00", x"00000070", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a0_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a0
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000076", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"00000077", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b1_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b1
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000007a", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_a2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- a2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_write_32 (x"34", x"00", x"0000007b", i2c_clk, scl, sda_in);
        i2c_write_32 (x"34", x"04", std_logic_vector(to_signed(integer(coeff_high_pass_b2_c * (2.0**24.0)), 32)), i2c_clk, scl, sda_in); -- b2
        i2c_write_32 (x"34", x"08", x"00000000", i2c_clk, scl, sda_in);

        i2c_read_32 (x"34", x"04", read_data, i2c_clk, scl, sda_out, sda_in);
        i2c_read_32 (x"34", x"04", read_data, i2c_clk, scl, sda_out, sda_in);
                        
        wait;
    end process i2c_proc;
 
    dut_i : audio
    generic map (
        I2C_ADDRESS => x"34",
        DATA_W      => 24)
    port map (
        -- i2c
        i2c_scl_i   => scl,
        i2c_sda_i   => sda_in,
        i2c_sda_o   => sda_out,
        -- i2s
        i2s_i       => i2s_r,
        i2s_o       => i2s_out,
        i2s_mclk_i  => fast_clk,
        i2s_lrclk_o => lrclk);
    
    conv_i : i2s_inout
    port map (
        m_clk_i       => fast_clk,
        b_clk_o       => b_clk,
        lr_clk_o      => lrclk,
        i2s_i         => i2s_out,
        i2s_o         => open,
        right_valid_o => right_valid_out,
        left_valid_o  => left_valid_out,
        data_o        => data_out,
        right_valid_i => '0',
        left_valid_i  => '0',
        data_i        => x"000000");

     biquad_model_proc : process (b_clk)
        variable result_v       : signed(53 downto 0) := (others => '0');
        variable input_v        : signed(26 downto 0) := (others => '0');
        variable model_result_v : real := 0.0;
     begin
        if (rising_edge(b_clk)) then
            input_v      := resize(signed(sinus_r), 27);
            if ((lrclkold_r = '0') and (lrclk = '1')) then
                -- bit true model
                result_v           := debug_data_r + (input_v * to_signed(integer(coeff_low_pass_a0_c * (2.0**24.0)), 27));
                debug_data_r       <= debug_data_delay_r + (result_v(50 downto 24) * to_signed(integer(coeff_low_pass_b1_c * (2.0**24.0)), 27)) + (input_v * to_signed(integer(coeff_low_pass_a1_c * (2.0**24.0)), 27));
                debug_data_delay_r <= (result_v(50 downto 24) * to_signed(integer(coeff_low_pass_b2_c * (2.0**24.0)), 27)) + (input_v * to_signed(integer(coeff_low_pass_a2_c * (2.0**24.0)), 27));
                debug_result_r     <= std_logic_vector(result_v(47 downto 24));
  
                -- another real type model
                model_result_v     := model_data_r + (sinus_real_r * coeff_low_pass_a0_c);
                model_data_r       <= model_data_delay_r + (sinus_real_r * coeff_low_pass_a1_c) + (model_result_v * coeff_low_pass_b1_c);
                model_data_delay_r <= (sinus_real_r * coeff_low_pass_a2_c) + (model_result_v * coeff_low_pass_b2_c);
                model_result_r     <= std_logic_vector(to_signed(integer(model_result_v*(2.0**23.0)), 24));
  
            end if;
        end if;
     end process biquad_model_proc;

     result_proc : process (b_clk)
     begin
        if (rising_edge(b_clk)) then
            if (left_valid_out = '1') then
                result_left_r <= data_out;
            end if;
            
            if (right_valid_out = '1') then
                result_right_r <= data_out;
            end if;
        end if;
     end process result_proc;

end rtl;
