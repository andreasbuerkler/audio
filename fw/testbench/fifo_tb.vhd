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
        size_exp_g     : positive := 10;
        data_width_g   : positive := 8;
        use_reject_g   : boolean  := false;
        invert_full_g  : boolean  := false;
        invert_empty_g : boolean  := false);
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

    type std_logic_array_16_t is array (natural range <>) of std_logic_vector(15 downto 0);

    signal clk                  : std_logic;
    signal store_r              : std_logic := '0';
    signal reject_r             : std_logic := '0';

    signal write_data_r         : std_logic_vector(15 downto 0) := (others => '0');
    signal write_en_r           : std_logic := '0';
    signal full                 : std_logic;
    signal read_data            : std_logic_vector(15 downto 0);
    signal read_en_r            : std_logic := '0';
    signal empty                : std_logic;
    signal expected_data_r      : std_logic_vector(15 downto 0) := (others => '0');

    signal write_data_2_r       : std_logic_vector(15 downto 0) := (others => '0');
    signal write_en_2_r         : std_logic := '0';
    signal full_2               : std_logic;
    signal read_data_2          : std_logic_vector(15 downto 0);
    signal read_en_2_r          : std_logic := '0';
    signal empty_2              : std_logic;

    signal expected_data_count_r     : integer := 0;   
    signal expected_data_vec_count_r : integer := 0;

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
        size_exp_g     => 4,
        data_width_g   => 16,
        use_reject_g   => false,
        invert_full_g  => false,
        invert_empty_g => false)
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

--------------------------------------------------------------------

    i_fifo_2 : fifo
    generic map (
        size_exp_g     => 4,
        data_width_g   => 16,
        use_reject_g   => true,
        invert_full_g  => false,
        invert_empty_g => false)
    port map (
        clk_i    => clk,
        reset_i  => '0',
        -- write port
        data_i   => write_data_2_r,
        wr_i     => write_en_2_r,
        store_i  => store_r,
        reject_i => reject_r,
        full_o   => full_2,
        -- read port
        data_o   => read_data_2,
        rd_i     => read_en_2_r,
        empty_o  => empty_2);

    stimuli_proc : process (clk)
        variable seed1_v : positive := 254;
        variable seed2_v : positive := 14;
        variable rand_v  : real;
    begin
        if (rising_edge(clk)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.5) then
                write_en_2_r <= '1';
            else
                write_en_2_r <= '0';
            end if;
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.5) then
                read_en_2_r <= '1';
            else
                read_en_2_r <= '0';
            end if;
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.9) then
                store_r <= '1';
            else
                store_r <= '0';
            end if;
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.9) then
                reject_r <= '1';
            else
                reject_r <= '0';
            end if;
            if (full_2 = '0') and (write_en_2_r = '1') then
                write_data_2_r <= std_logic_vector(unsigned(write_data_2_r) + 1);
            end if;
        end if;
    end process stimuli_proc;

    model_proc : process (clk)
        variable expected_data_2_v         : std_logic_array_16_t(2**5 downto 0) := (others => (others => '0'));
        variable expected_data_vec_v       : std_logic_array_16_t(2**5 downto 0) := (others => (others => '0'));
        variable expected_data_count_v     : integer := 0;   
        variable expected_data_vec_count_v : integer := 0;
    begin
        if (rising_edge(clk)) then
            if ((write_en_2_r = '1') and (full_2 = '0')) then
                expected_data_vec_v := expected_data_vec_v(expected_data_vec_v'high-1 downto 0) & write_data_2_r;
                expected_data_vec_count_v := expected_data_vec_count_v + 1;
            end if;
            if (reject_r = '1') then
                expected_data_vec_count_v := 0;
            elsif (store_r = '1') then
                for i in 0 to expected_data_vec_count_v-1 loop
                    expected_data_2_v(expected_data_count_v) := expected_data_vec_v(expected_data_vec_count_v-1-i);
                    expected_data_count_v := expected_data_count_v + 1;
                end loop;
                expected_data_vec_count_v := 0;
            end if;

            if ((read_en_2_r = '1') and (empty_2 = '0')) then
                assert (read_data_2 = expected_data_2_v(0)) report "error 2: expected " & integer'image(to_integer(unsigned(expected_data_2_v(0)))) &
                                                                ", got " & integer'image(to_integer(unsigned(read_data_2))) severity error;
                expected_data_2_v := x"0000" & expected_data_2_v(expected_data_2_v'high downto 1);
                expected_data_count_v := expected_data_count_v - 1;
            end if;

            expected_data_count_r <= expected_data_count_v;
            expected_data_vec_count_r <= expected_data_vec_count_v;

        end if;
    end process model_proc;
end rtl;
