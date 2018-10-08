--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2c_slave_tb.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity i2c_slave_tb is
end entity i2c_slave_tb;

architecture rtl of i2c_slave_tb is

    component i2c_slave
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
    end component i2c_slave;
    
    signal clk_fast   : std_logic := '0';
    signal scl        : std_logic := '1';
    signal sda_in     : std_logic := '1';
    signal sda_out    : std_logic := '1';
    signal address    : std_logic_vector(7 downto 0) := (others => '0');
    signal wr         : std_logic := '0';
    signal rd         : std_logic := '0';
    signal rd_valid   : std_logic := '0';
    signal rd_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal wr_data    : std_logic_vector(7 downto 0) := (others => '0');

    signal clk_i2c    : std_logic := '0';
    signal sda        : std_logic := '0';
    signal send_data  : std_logic_vector(7 downto 0) := (others => '0');

begin

    i2c_clk_gen_proc : process
    begin
        clk_i2c <= '0';
        wait for 50 ns;
        clk_i2c <= '1';
        wait for 50 ns;
    end process i2c_clk_gen_proc;

    fast_clk_gen_proc : process
    begin
        clk_fast <= '0';
        wait for 5 ns;
        clk_fast <= '1';
        wait for 5 ns;
    end process fast_clk_gen_proc;
    
    i_dut : i2c_slave
    generic map (
        I2C_ADDRESS => x"34")
    port map(
        clk_i        => clk_fast,
        scl_i        => scl,
        sda_i        => sda_in,
        sda_o        => sda_out,
        address_o    => address,
        wr_o         => wr,
        rd_o         => rd,
        rd_valid_i   => rd_valid,
        rd_data_i    => rd_data,
        wr_data_o    => wr_data);

    sda <= sda_in and sda_out;

    read_data_proc : process (clk_fast)
    begin
        if (rising_edge(clk_fast)) then
            if (rd = '1') then
                case address is
                    when x"22" => rd_data <= x"aa";
                    when x"23" => rd_data <= x"55";
                    when x"24" => rd_data <= x"ff";
                    when others => rd_data <= x"00";
                end case;
                rd_valid <= '1';
            else
                rd_valid <= '0';
            end if;
        end if;
    end process read_data_proc;
    
    i2c_master_proc : process
    begin

        -- start
        scl <= '1';
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- write slave address
        send_data <= x"68";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
            
        -- write register address
        send_data <= x"81";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- write data 1
        send_data <= x"14";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- write data 2
        send_data <= x"25";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- write data 3
        send_data <= x"25";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- stop
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        
        
        -- pause
        for i in 0 to 10 loop
            wait until rising_edge(clk_i2c);
        end loop;
        
        -- start
        scl <= '1';
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- write slave address
        send_data <= x"68";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
            
        -- write register address
        send_data <= x"22";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
  
        if (false) then
            -- stop
            wait until rising_edge(clk_i2c);
            sda_in <= '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            sda_in <= '1';
        
            -- pause
            for i in 0 to 10 loop
                wait until rising_edge(clk_i2c);
            end loop;

            -- start
            scl <= '1';
            sda_in <= '1';
            wait until rising_edge(clk_i2c);
            sda_in <= '0';
            wait until rising_edge(clk_i2c);
            scl <= '0';
        else  
            -- repeated start
            wait until rising_edge(clk_i2c);
            sda_in <= '1';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            sda_in <= '0';
            wait until rising_edge(clk_i2c);
        end if;

        -- write slave address
        send_data <= x"69";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- read data 1
        send_data <= x"25";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- read data 2
        send_data <= x"26";
        for i in 0 to 7 loop
            wait until rising_edge(clk_i2c);
            sda_in <= send_data(send_data'high);
            send_data <= send_data(send_data'high-1 downto 0) & '0';
            wait until rising_edge(clk_i2c);
            scl <= '1';
            wait until rising_edge(clk_i2c);
            wait until rising_edge(clk_i2c);
            scl <= '0';
        end loop;
        
        -- ack
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        wait until rising_edge(clk_i2c);
        scl <= '0';
        
        -- stop
        wait until rising_edge(clk_i2c);
        sda_in <= '0';
        wait until rising_edge(clk_i2c);
        scl <= '1';
        wait until rising_edge(clk_i2c);
        sda_in <= '1';
        
        wait;
    end process i2c_master_proc;



end rtl;