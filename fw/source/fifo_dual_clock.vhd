--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.02.2020
-- Filename  : fifo_dual_clock.vhd
-- Changelog : 03.02.2020 - file created
--           : 08.03.2020 - almost full added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity fifo_dual_clock is
generic (
    size_exp_g     : positive := 10;
    data_width_g   : positive := 8;
    almost_full_g  : positive := 2**10-1;
    invert_full_g  : boolean  := false;
    invert_empty_g : boolean  := false);
port (
    -- write port
    clk_w_i       : in  std_logic;
    data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    wr_i          : in  std_logic;
    full_o        : out std_logic;
    almost_full_o : out std_logic;
    -- read port
    clk_r_i       : in  std_logic;
    data_o        : out std_logic_vector(data_width_g-1 downto 0);
    rd_i          : in  std_logic;
    empty_o       : out std_logic);
end entity fifo_dual_clock;

architecture rtl of fifo_dual_clock is

    type mem_t is array(natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    signal mem_r                    : mem_t((2**size_exp_g)-1 downto 0) := (others => (others => '0'));
    signal word_counter_r_cc0_r     : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_r_cc1_r     : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_w_cc0_r     : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_w_cc1_r     : unsigned(size_exp_g downto 0) := (others => '0');

    signal rd_data_r                : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal preload_r                : std_logic := '0';
    signal rd_addr_r                : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal empty_next_a             : std_logic;
    signal empty_r                  : std_logic := '1';

    signal word_counter_r_a         : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_r_r         : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_rw_r        : unsigned(size_exp_g downto 0) := (others => '0');

    signal wr_addr_r                : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal full_r                   : std_logic := '0';
    signal almost_full_r            : std_logic := '0';
    signal word_counter_w_r         : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_wr_r        : unsigned(size_exp_g downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M10K";

begin

    ram_wr_proc : process (clk_w_i)
    begin
        if (rising_edge(clk_w_i)) then
            if ((wr_i = '1') and (full_r = '0')) then
                mem_r(to_integer(unsigned(wr_addr_r))) <= data_i;
            end if;
        end if;
    end process ram_wr_proc;

    ram_rd_proc : process (clk_r_i)
    begin
        if (rising_edge(clk_r_i)) then
            if (((rd_i = '1') and (empty_r = '0') and (empty_next_a = '0')) or (preload_r = '1')) then
                rd_data_r <= mem_r(to_integer(unsigned(rd_addr_r)));
            end if;
        end if;
    end process ram_rd_proc;

    addr_w_proc : process (clk_w_i)
    begin
        if (rising_edge(clk_w_i)) then
            if ((wr_i = '1') and (full_r = '0')) then
                wr_addr_r <= std_logic_vector(unsigned(wr_addr_r) + 1);
            end if;
        end if;
    end process addr_w_proc;

    addr_r_proc : process (clk_r_i)
    begin
        if (rising_edge(clk_r_i)) then
            if (((rd_i = '1') and (empty_r = '0') and (empty_next_a = '0')) or (preload_r = '1')) then
                rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);
            end if;
        end if;
    end process addr_r_proc;

    counter_w_proc : process (clk_w_i)
        variable word_counter_v : unsigned(size_exp_g downto 0);
        variable used_words_v   : unsigned(size_exp_g downto 0);
    begin
        if (rising_edge(clk_w_i)) then
            if ((wr_i = '1') and (full_r = '0')) then
                word_counter_v := word_counter_w_r + 1;
            else
                word_counter_v := word_counter_w_r;
            end if;
            word_counter_w_r <= word_counter_v;

            word_counter_w_cc0_r <= bin_to_gray(word_counter_r_r);
            word_counter_w_cc1_r <= word_counter_w_cc0_r;
            word_counter_wr_r <= gray_to_bin(word_counter_w_cc1_r);

            used_words_v := word_counter_v - word_counter_wr_r;
            if (used_words_v = to_unsigned((2**(size_exp_g))-1, used_words_v'length)) then
                full_r <= '1';
            else
                full_r <= '0';
            end if;

            if (used_words_v >= to_unsigned(almost_full_g, used_words_v'length)) then
                almost_full_r <= '1';
            else
                almost_full_r <= '0';
            end if;

        end if;
    end process counter_w_proc;

    counter_r_async_proc : process (word_counter_r_r, word_counter_rw_r, rd_i, empty_r)
        variable word_counter_v : unsigned(size_exp_g downto 0);
        variable used_words_v   : unsigned(size_exp_g downto 0);
    begin
        if ((rd_i = '1') and (empty_r = '0')) then
            word_counter_v := word_counter_r_r + 1;
        else 
            word_counter_v := word_counter_r_r;
        end if;
        used_words_v := word_counter_rw_r - word_counter_v;
        if (used_words_v = to_unsigned(0, used_words_v'length)) then
            empty_next_a <= '1';
        else
            empty_next_a <= '0';
        end if;
        word_counter_r_a <= word_counter_v;
    end process counter_r_async_proc;

    counter_r_proc : process (clk_r_i)
        variable word_counter_v : unsigned(size_exp_g downto 0);
        variable used_words_v   : unsigned(size_exp_g downto 0);
    begin
        if (rising_edge(clk_r_i)) then
            word_counter_r_cc0_r <= bin_to_gray(word_counter_w_r);
            word_counter_r_cc1_r <= word_counter_r_cc0_r;
            word_counter_rw_r <= gray_to_bin(word_counter_r_cc1_r);

            word_counter_r_r <= word_counter_r_a;

            if (empty_next_a = '1') then
                empty_r <= '1';
            elsif (preload_r = '1') then
                preload_r <= '0';
                empty_r <= '0';
            elsif (empty_r = '1') then
                preload_r <= '1';
            end if;
        end if;
    end process counter_r_proc;

    invert_full_gen : if (invert_full_g) generate
        full_o <= not full_r;
    end generate invert_full_gen;

    normal_full_gen : if (not invert_full_g) generate
        full_o <= full_r;
    end generate normal_full_gen;

    invert_empty_gen : if (invert_empty_g) generate
        empty_o <= not empty_r;
    end generate invert_empty_gen;

    normal_empty_gen : if (not invert_empty_g) generate
        empty_o <= empty_r;
    end generate normal_empty_gen;

    data_o <= rd_data_r;
    almost_full_o <= almost_full_r;

end rtl;
