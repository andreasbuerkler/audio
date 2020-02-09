--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 20.10.2018
-- Filename  : fifo.vhd
-- Changelog : 20.10.2018 - file created
--             27.10.2018 - reject functionality added
--             27.10.2018 - invert full/empty added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
generic (
    size_exp_g     : positive := 10;
    data_width_g   : positive := 8;
    use_reject_g   : boolean  := false;
    invert_full_g  : boolean  := false;
    invert_empty_g : boolean  := false);
port (
    clk_i    : in  std_logic;
    reset_i  : in  std_logic; -- TODO: implement reset
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
end entity fifo;

architecture rtl of fifo is

    type mem_t is array(natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    signal mem_r                    : mem_t((2**size_exp_g)-1 downto 0) := (others => (others => '0'));
    signal rd_data_r                : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal preload_r                : std_logic := '0';

    signal wr_addr_r                : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal wr_addr_store_r          : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal rd_addr_r                : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal full_next                : std_logic;
    signal full_r                   : std_logic := '0';
    signal empty_next               : std_logic;
    signal empty_r                  : std_logic := '1';
    signal word_counter_r           : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_next_r      : unsigned(size_exp_g downto 0) := (others => '0');
    signal word_counter_inc_r       : std_logic := '0';
    signal store_delay_r            : std_logic := '0';
    signal reject_delay_r           : std_logic := '0';

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M10K";

begin

    ram_wr_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((wr_i = '1') and (full_r = '0')) then
                mem_r(to_integer(unsigned(wr_addr_r))) <= data_i;
            end if;
        end if;
    end process ram_wr_proc;

    ram_rd_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (((rd_i = '1') and (empty_r = '0')) or (preload_r = '1')) then
                rd_data_r <= mem_r(to_integer(unsigned(rd_addr_r)));
            end if;
        end if;
    end process ram_rd_proc;

    delay_proc : process (clk_i)
        variable wr_en_v : std_logic := '0';
    begin
        if (rising_edge(clk_i)) then
            wr_en_v := wr_i and (not full_r);
            word_counter_inc_r <= wr_en_v;
            if (use_reject_g) then
                store_delay_r <= store_i;
                reject_delay_r <= reject_i;
            end if;
        end if;
    end process delay_proc;

    preload_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (use_reject_g) then
                if ((word_counter_r = to_unsigned(0, word_counter_r'length)) and
                    ((word_counter_next_r /= to_unsigned(0, word_counter_next_r'length)) or (word_counter_inc_r = '1'))) then
                    preload_r <= store_delay_r and (not reject_delay_r);
                else
                    preload_r <= '0';
                end if;
            else
                if (word_counter_r = to_unsigned(0, word_counter_r'length)) then
                    preload_r <= word_counter_inc_r;
                else
                    preload_r <= '0';
                end if;
            end if;
        end if;
    end process preload_proc;

    addr_proc : process (clk_i)
        variable rd_en_v : std_logic := '0';
        variable wr_en_v : std_logic := '0';
    begin
        if (rising_edge(clk_i)) then
            rd_en_v := rd_i and (not empty_r);
            wr_en_v := wr_i and (not full_r);
            if (wr_en_v = '1') then
                if (use_reject_g) then
                    if (reject_i = '1') then
                        wr_addr_r <= wr_addr_store_r;
                    else
                        if (store_i = '1') then
                            wr_addr_store_r <= std_logic_vector(unsigned(wr_addr_r) + 1);
                        end if;
                        wr_addr_r <= std_logic_vector(unsigned(wr_addr_r) + 1);
                    end if;
                else
                    wr_addr_r <= std_logic_vector(unsigned(wr_addr_r) + 1);
                end if;
            else
                if (use_reject_g) then
                   if (reject_i = '1') then
                        wr_addr_r <= wr_addr_store_r;
                    elsif (store_i = '1') then
                        wr_addr_store_r <= wr_addr_r;
                    end if;
                end if;
            end if;
            if (((rd_en_v = '1') and (empty_next = '0')) or (preload_r = '1')) then
                rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);
            end if;
        end if;
    end process addr_proc;

    counter_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((rd_i = '0') or (empty_r = '1')) then
                if (use_reject_g) then
                    if (word_counter_inc_r = '1') then
                        if (reject_delay_r = '1') then
                            word_counter_next_r <= word_counter_r;
                        elsif (store_delay_r = '1') then
                            word_counter_next_r <= word_counter_next_r + 1;
                            word_counter_r <= word_counter_next_r + 1;
                        else
                            word_counter_next_r <= word_counter_next_r + 1;
                        end if;
                    else
                        if (reject_delay_r = '1') then
                            word_counter_next_r <= word_counter_r;
                        elsif (store_delay_r = '1') then
                            word_counter_r <= word_counter_next_r;
                        end if;
                    end if;
                else
                    if (word_counter_inc_r = '1') then
                        word_counter_r <= word_counter_r + 1;
                    end if;
                end if;
            else
                if (use_reject_g) then
                    if (reject_delay_r = '1') then
                        word_counter_next_r <= word_counter_r - 1;
                        word_counter_r <= word_counter_r - 1;
                    elsif (store_delay_r = '1') then
                        if (word_counter_inc_r = '0') then
                            word_counter_next_r <= word_counter_next_r - 1;
                            word_counter_r <= word_counter_next_r - 1;
                        else
                            word_counter_r <= word_counter_next_r;
                        end if;
                    else
                        if (word_counter_inc_r = '0') then
                            word_counter_next_r <= word_counter_next_r - 1;
                        end if;
                        word_counter_r <= word_counter_r - 1;
                    end if;
                else
                    if (word_counter_inc_r = '0') then
                        word_counter_r <= word_counter_r - 1;
                    end if;
                end if;
            end if;
        end if;
    end process counter_proc;

    flag_async : process (word_counter_inc_r, word_counter_r, word_counter_next_r, store_delay_r, reject_delay_r)
    begin
        if (use_reject_g) then
            if (word_counter_r = to_unsigned(1, word_counter_r'length)) then
                if (((word_counter_next_r /= to_unsigned(1, word_counter_next_r'length)) or (word_counter_inc_r = '1')) and (store_delay_r = '1') and (reject_delay_r = '0')) then
                    empty_next <= '0';
                else
                    empty_next <= '1';
                end if;
            else
                empty_next <= '0';
            end if;
        else
            if ((word_counter_inc_r = '0') and (word_counter_r = to_unsigned(1, word_counter_r'length))) then
                empty_next <= '1';
            else
                empty_next <= '0';
            end if;
        end if;

        if (use_reject_g) then
            if (word_counter_next_r(word_counter_next_r'high downto 1) = to_unsigned((2**(size_exp_g-1))-1, word_counter_next_r'length-1)) then
                if (word_counter_next_r(0) = '0') then
                    full_next <= word_counter_inc_r;
                else
                    full_next <= '1';
                end if;
            else
                full_next <= word_counter_next_r(word_counter_next_r'high);
            end if;
        else
            if (word_counter_r(word_counter_r'high downto 1) = to_unsigned((2**(size_exp_g-1))-1, word_counter_r'length-1)) then
                if (word_counter_r(0) = '0') then
                    full_next <= word_counter_inc_r;
                else
                    full_next <= '1';
                end if;
            else
                full_next <= '0';
            end if;
        end if;
    end process flag_async;

    flag_proc : process (clk_i)
        variable rd_en_v : std_logic := '0';
        variable wr_en_v : std_logic := '0';
    begin
        if (rising_edge(clk_i)) then
            rd_en_v := rd_i and (not empty_r);
            wr_en_v := wr_i and (not full_r);

            if (preload_r = '1') then
                empty_r <= '0';
            elsif ((empty_next = '1') and (rd_en_v = '1')) then
                empty_r <= '1';
            end if;
            if (((rd_i = '1') and (full_r = '1') and (empty_r = '0')) or ((reject_i = '1') and (full_next = '0'))) then
                full_r <= '0';
            elsif ((full_next = '1') and (wr_en_v = '1') and (rd_en_v = '0')) then
                full_r <= '1';
            end if;
        end if;
    end process flag_proc;

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

end rtl;
