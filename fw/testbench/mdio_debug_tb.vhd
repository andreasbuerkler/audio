--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 18.01.2020
-- Filename  : mdio_debug_tb.vhd
-- Changelog : 18.01.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity mdio_debug_tb is
end entity mdio_debug_tb;

architecture rtl of mdio_debug_tb is

    component mdio_debug
    generic (
        mdio_address_g : std_logic_vector(4 downto 0));
    port (
        clk_i    : in  std_logic;
        enable_i : in  std_logic;
        mdc_o    : out std_logic;
        mdio_i   : in  std_logic;
        mdio_o   : out std_logic);
    end component mdio_debug;

    signal clk    : std_logic := '0';
    signal clk_en : boolean := true;

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        if (clk_en) then
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end if;
    end process clkgen_proc;

    i_mdio : mdio_debug
    generic map (
        mdio_address_g => "00101")
    port map (
        clk_i    => clk,
        enable_i => '1',
        mdc_o    => open,
        mdio_i   => '0',
        mdio_o   => open);


    ctrl_proc : process
    begin
        wait for 1 ms;
        wait until rising_edge(clk);
        report "done";
        clk_en <= false;
        wait;
    end process ctrl_proc;

end rtl;
