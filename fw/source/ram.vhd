--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 16.11.2018
-- Filename  : ram.vhd
-- Changelog : 16.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
generic (
    addr_width_g   : positive := 11;
    data_width_g   : positive := 8);
port (
    clk_i     : in  std_logic;
    -- write port
    wr_data_i : in  std_logic_vector(data_width_g-1 downto 0);
    wr_i      : in  std_logic;
    wr_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
    -- read port
    rd_data_o : out std_logic_vector(data_width_g-1 downto 0);
    rd_i      : in  std_logic;
    rd_addr_i : in  std_logic_vector(addr_width_g-1 downto 0));
end entity ram;

architecture rtl of ram is

    type mem_t is array(natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    signal mem_r     : mem_t((2**addr_width_g)-1 downto 0) := (others => (others => '0'));
    signal rd_data_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    ram_wr_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (wr_i = '1') then
                mem_r(to_integer(unsigned(wr_addr_i))) <= wr_data_i;
            end if;
        end if;
    end process ram_wr_proc;

    ram_rd_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rd_i = '1') then
                rd_data_r <= mem_r(to_integer(unsigned(rd_addr_i)));
            end if;
        end if;
    end process ram_rd_proc;

    rd_data_o <= rd_data_r;

end rtl;
