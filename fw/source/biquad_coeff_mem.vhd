--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : biquad_coeff_mem.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
  
entity biquad_coeff_mem is
generic (
    ADDR_W : natural := 7;
    DATA_W : natural := 27);
port (
    r_clk_i  : in  std_logic;
    r_data_o : out std_logic_vector(DATA_W-1 downto 0);
    r_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
    w_clk_i  : in  std_logic;
    w_data_i : in  std_logic_vector(DATA_W-1 downto 0);
    w_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
    w_en_i   : in  std_logic);
end entity biquad_coeff_mem;

architecture rtl of biquad_coeff_mem is

    type mem_t is array(natural range <>) of std_logic_vector(DATA_W-1 downto 0);

    function mem_init return mem_t is
        variable mem_v : mem_t((2**ADDR_W)-1 downto 0) := (others => (others => '0'));
    begin
        for i in 0 to 2**ADDR_W-1 loop
            case i is
                -- 0 right channel low pass 1kHz
                when 0      => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 6      => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 7      => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 10     => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 11     => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 1 right channel channel low pass 1 kHz
                when 16     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 16+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 16+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 16+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 16+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 2 right channel channel low pass 1 kHz
                when 32     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 32+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 32+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 32+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 32+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 3 right channel channel low pass 1 kHz
                when 48     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 48+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 48+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 48+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 48+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 0 left channel high pass 1 kHz
                when 64     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 64+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 64+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 64+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 64+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 1 left channel high pass 1 kHz
                when 80     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 80+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 80+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 80+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 80+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 2 left channel high pass 1 kHz
                when 96     => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 96+6   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 96+7   => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 96+10  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 96+11  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- 3 left channel high pass 1 kHz
                when 112    => mem_v(i) := std_logic_vector(to_signed(integer(1.0 * (2.0**24.0)), DATA_W)); -- a0
                when 112+6  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a1
                when 112+7  => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b1
                when 112+10 => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- a2
                when 112+11 => mem_v(i) := std_logic_vector(to_signed(integer(0.0 * (2.0**24.0)), DATA_W)); -- -b2
                -- unused
                when others => mem_v(i) := std_logic_vector(to_signed(0, DATA_W));
            end case;
        end loop;
        return mem_v;
    end mem_init;

    signal mem_r        : mem_t((2**ADDR_W)-1 downto 0) := mem_init;
    signal r_addr_r     : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal r_data_r     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal r_data_out_r : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal w_addr_r     : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal w_en_r       : std_logic := '0';
    signal w_data_r     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    w_proc : process (w_clk_i)
    begin
        if (rising_edge(w_clk_i)) then
            w_addr_r <= w_addr_i;
            w_data_r <= w_data_i;
            w_en_r <= w_en_i;
            if (w_en_r = '1') then
                mem_r(to_integer(unsigned(w_addr_r))) <= w_data_r;
            end if;
        end if;
    end process w_proc;

    r_proc : process (r_clk_i)
    begin
        if (rising_edge(r_clk_i)) then
            r_addr_r <= r_addr_i;
            r_data_r <= mem_r(to_integer(unsigned(r_addr_r)));
            r_data_out_r <= r_data_r;
        end if;
    end process r_proc;

    r_data_o <= r_data_out_r;

end rtl;