--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 21.10.2018
-- Filename  : fifo_tb.vhd
-- Changelog : 21.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo_tb is
end entity fifo_tb;

architecture rtl of fifo_tb is

    component fifo is
    generic (
        size_exp_g   : positive := 10;
        data_width_g : positive := 8;
        use_reject_g : boolean  := false);
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        -- write port
        data_i   : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i     : in  std_logic;
        store_i  : in  std_logic;
        reject_i : in  std_logic;
        full_o   : out std_logic;
        -- read port
        data_o   : out std_logic_vector(data_width_g-1 downto 0);
        rd_i     : in  std_logic;
        empty_o  : out std_logic);
    end component fifo;

    signal clk             : std_logic;
    signal write_data_r    : std_logic_vector(15 downto 0) := (others => '0');
    signal write_en_r      : std_logic := '0';
    signal full            : std_logic;
    signal read_data       : std_logic_vector(15 downto 0);
    signal read_en_r       : std_logic := '0';
    signal empty           : std_logic;
    signal expected_data_r : std_logic_vector(15 downto 0) := (others => '0');

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    i_fifo : fifo
    generic map (
        size_exp_g   => 4,
        data_width_g => 16,
        use_reject_g => false)
    port map (
        clk_i    => clk,
        reset_i  => '0',
        -- write port
        data_i   => write_data_r,
        wr_i     => write_en_r,
        store_i  => '0',
        reject_i => '0',
        full_o   => full,
        -- read port
        data_o   => read_data,
        rd_i     => read_en_r,
        empty_o  => empty);

    write_proc : process (clk)
        variable seed1_v : positive := 125;
        variable seed2_v : positive := 53;
        variable rand_v  : real;   
    begin
        if (rising_edge(clk)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.5) then
                write_en_r <= '1';
            else
                write_en_r <= '0';
            end if;
            if (full = '0') and (write_en_r = '1') then
                write_data_r <= std_logic_vector(unsigned(write_data_r) + 1);
            end if;
        end if;
    end process write_proc;

    read_proc : process (clk)
        variable seed1_v : positive := 23;
        variable seed2_v : positive := 78;
        variable rand_v  : real;   
    begin
        if (rising_edge(clk)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.5) then
                read_en_r <= '1';
            else
                read_en_r <= '0';
            end if;
            if ((empty = '0') and (read_en_r = '1')) then
                expected_data_r <= std_logic_vector(unsigned(expected_data_r) + 1);
                assert (read_data = expected_data_r) report "error: expected " & integer'image(to_integer(unsigned(expected_data_r))) &
                                                            ", got " & integer'image(to_integer(unsigned(read_data))) severity error;
            end if;
        end if;
    end process read_proc;

end rtl;
