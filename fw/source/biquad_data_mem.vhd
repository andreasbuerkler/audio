--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : biquad_data_mem.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity biquad_data_mem is
generic (
    ADDR_W : natural := 1;
    DATA_W : natural := 54);
port (
    clk_i    : in  std_logic;
    r_data_o : out std_logic_vector(DATA_W-1 downto 0);
    r_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
    w_data_i : in  std_logic_vector(DATA_W-1 downto 0);
    w_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
    w_en_i   : in  std_logic);
end entity biquad_data_mem;

architecture rtl of biquad_data_mem is

    type mem_t is array(natural range <>) of std_logic_vector(DATA_W-1 downto 0);

    signal mem_r        : mem_t((2**ADDR_W)-1 downto 0) := (others => (others => '0'));
    signal r_addr_r     : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal r_data_r     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal r_data_out_r : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal w_addr_r     : std_logic_vector(ADDR_W-1 downto 0) := (others => '0');
    signal w_en_r       : std_logic := '0';
    signal w_data_r     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    w_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            w_addr_r <= w_addr_i;
            w_data_r <= w_data_i;
            w_en_r <= w_en_i;
            if (w_en_r = '1') then
                mem_r(to_integer(unsigned(w_addr_r))) <= w_data_r;
            end if;
        end if;
    end process w_proc;

    r_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            r_addr_r <= r_addr_i;
            r_data_r <= mem_r(to_integer(unsigned(r_addr_r)));
            r_data_out_r <= r_data_r;
        end if;
    end process r_proc;

    r_data_o <= r_data_out_r;

end rtl;