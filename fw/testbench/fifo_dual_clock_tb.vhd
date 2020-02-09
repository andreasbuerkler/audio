--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 09.02.2020
-- Filename  : fifo_dual_clock_tb.vhd
-- Changelog : 09.02.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo_dual_clock_tb is
end entity fifo_dual_clock_tb;

architecture rtl of fifo_dual_clock_tb is

    component fifo_dual_clock is
    generic (
        size_exp_g     : positive;
        data_width_g   : positive;
        invert_full_g  : boolean;
        invert_empty_g : boolean);
    port (
        -- write port
        clk_w_i  : in  std_logic;
        data_i   : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i     : in  std_logic;
        full_o   : out std_logic;
        -- read port
        clk_r_i  : in  std_logic;
        data_o   : out std_logic_vector(data_width_g-1 downto 0);
        rd_i     : in  std_logic;
        empty_o  : out std_logic);
    end component fifo_dual_clock;

    signal clk_w                : std_logic;
    signal clk_r                : std_logic;
    signal write_data_r         : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(1, 16));
    signal write_en_r           : std_logic := '0';
    signal full                 : std_logic;
    signal read_data            : std_logic_vector(15 downto 0);
    signal read_en_r            : std_logic := '0';
    signal empty                : std_logic;
    signal expected_data_r      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(1, 16));

begin

    -- 50 MHz
    clk_write_proc : process
    begin
        clk_w <= '0';
        wait for 8 ns;
        clk_w <= '1';
        wait for 8 ns;
    end process clk_write_proc;

    clk_read_proc : process
    begin
        clk_r <= '0';
        wait for 20 ns;
        clk_r <= '1';
        wait for 20 ns;
    end process clk_read_proc;

    i_fifo : fifo_dual_clock
    generic map (
        size_exp_g     => 4,
        data_width_g   => 16,
        invert_full_g  => false,
        invert_empty_g => false)
    port map (
            -- write port
        clk_w_i  => clk_w,
        data_i   => write_data_r,
        wr_i     => write_en_r,
        full_o   => full,
        -- read port
        clk_r_i  => clk_r,
        data_o   => read_data,
        rd_i     => read_en_r,
        empty_o  => empty);

    write_proc : process (clk_w)
        variable seed1_v : positive := 125;
        variable seed2_v : positive := 53;
        variable rand_v  : real;
    begin
        if (rising_edge(clk_w)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.75) then
                write_en_r <= '1';
            else
                write_en_r <= '0';
            end if;
            if (full = '0') and (write_en_r = '1') then
                write_data_r <= std_logic_vector(unsigned(write_data_r) + 1);
            end if;
        end if;
    end process write_proc;

    read_proc : process (clk_r)
        variable seed1_v : positive := 23;
        variable seed2_v : positive := 78;
        variable rand_v  : real;
    begin
        if (rising_edge(clk_r)) then
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
