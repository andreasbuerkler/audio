--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.03.2019
-- Filename  : dual_clock_ram.vhd
-- Changelog : 03.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity dual_clock_ram is
generic (
    addr_width_g : natural := 7;
    data_width_g : natural := 27;
    init_data_g  : std_logic_array);
port (
    r_clk_i  : in  std_logic;
    r_data_o : out std_logic_vector(data_width_g-1 downto 0);
    r_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
    w_clk_i  : in  std_logic;
    w_data_i : in  std_logic_vector(data_width_g-1 downto 0);
    w_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
    w_en_i   : in  std_logic);
end entity dual_clock_ram;

architecture rtl of dual_clock_ram is

    type mem_t is array(natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    function convert_init_data(inarray : std_logic_array) return mem_t is
        variable data_v : mem_t((2**addr_width_g)-1 downto 0);
    begin
        for i in (2**addr_width_g)-1 downto 0 loop
            for j in data_width_g-1 downto 0 loop
                data_v(i)(j) := inarray(i, j);
            end loop;
        end loop;
        return data_v;
    end function convert_init_data;

    signal mem_r        : mem_t((2**addr_width_g)-1 downto 0) := convert_init_data(init_data_g);
    signal r_data_out_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    w_proc : process (w_clk_i)
    begin
        if (rising_edge(w_clk_i)) then
            if (w_en_i = '1') then
                mem_r(to_integer(unsigned(w_addr_i))) <= w_data_i;
            end if;
        end if;
    end process w_proc;

    r_proc : process (r_clk_i)
    begin
        if (rising_edge(r_clk_i)) then
            r_data_out_r <= mem_r(to_integer(unsigned(r_addr_i)));
        end if;
    end process r_proc;

    r_data_o <= r_data_out_r;

end rtl;