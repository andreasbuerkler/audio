--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 06.04.2020
-- Filename  : main_pll.vhd
-- Changelog : 06.04.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity main_pll is
    port (
        rst_i       : in  std_logic;
        clk_i       : in  std_logic;
        clk_o       : out std_logic;
        clk_90_o    : out std_logic;
        video_clk_o : out std_logic;
        locked_o    : out std_logic);
end main_pll;

architecture rtl of main_pll is

    component altera_pll is
    generic (
        fractional_vco_multiplier : string;
        reference_clock_frequency : string;
        operation_mode            : string;
        number_of_clocks          : natural;
        output_clock_frequency0   : string;
        phase_shift0              : string;
        duty_cycle0               : natural;
        output_clock_frequency1   : string;
        phase_shift1              : string;
        duty_cycle1               : natural;
        output_clock_frequency2   : string;
        phase_shift2              : string;
        duty_cycle2               : natural;
        output_clock_frequency3   : string;
        phase_shift3              : string;
        duty_cycle3               : natural;
        output_clock_frequency4   : string;
        phase_shift4              : string;
        duty_cycle4               : natural;
        output_clock_frequency5   : string;
        phase_shift5              : string;
        duty_cycle5               : natural;
        output_clock_frequency6   : string;
        phase_shift6              : string;
        duty_cycle6               : natural;
        output_clock_frequency7   : string;
        phase_shift7              : string;
        duty_cycle7               : natural;
        output_clock_frequency8   : string;
        phase_shift8              : string;
        duty_cycle8               : natural;
        output_clock_frequency9   : string;
        phase_shift9              : string;
        duty_cycle9               : natural;
        output_clock_frequency10  : string;
        phase_shift10             : string;
        duty_cycle10              : natural;
        output_clock_frequency11  : string;
        phase_shift11             : string;
        duty_cycle11              : natural;
        output_clock_frequency12  : string;
        phase_shift12             : string;
        duty_cycle12              : natural;
        output_clock_frequency13  : string;
        phase_shift13             : string;
        duty_cycle13              : natural;
        output_clock_frequency14  : string;
        phase_shift14             : string;
        duty_cycle14              : natural;
        output_clock_frequency15  : string;
        phase_shift15             : string;
        duty_cycle15              : natural;
        output_clock_frequency16  : string;
        phase_shift16             : string;
        duty_cycle16              : natural;
        output_clock_frequency17  : string;
        phase_shift17             : string;
        duty_cycle17              : natural;
        pll_type                  : string;
        pll_subtype               : string);
    port (
        rst      : in  std_logic;
        outclk   : out std_logic_vector(number_of_clocks-1 downto 0);
        locked   : out std_logic;
        fboutclk : out std_logic;
        fbclk    : in  std_logic;
        refclk   : in  std_logic);
    end component altera_pll;

begin

    i_pll : altera_pll
    generic map (
        fractional_vco_multiplier => "false",
        reference_clock_frequency => "50.0 MHz",
        operation_mode            => "normal",
        number_of_clocks          => 3,
        output_clock_frequency0   => "50.000000 MHz",
        phase_shift0              => "0 ps",
        duty_cycle0               => 50,
        output_clock_frequency1   => "50.000000 MHz",
        phase_shift1              => "5000 ps",
        duty_cycle1               => 50,
        output_clock_frequency2   => "6.400000 MHz",
        phase_shift2              => "0 ps",
        duty_cycle2               => 50,
        output_clock_frequency3   => "0 MHz",
        phase_shift3              => "0 ps",
        duty_cycle3               => 50,
        output_clock_frequency4   => "0 MHz",
        phase_shift4              => "0 ps",
        duty_cycle4               => 50,
        output_clock_frequency5   => "0 MHz",
        phase_shift5              => "0 ps",
        duty_cycle5               => 50,
        output_clock_frequency6   => "0 MHz",
        phase_shift6              => "0 ps",
        duty_cycle6               => 50,
        output_clock_frequency7   => "0 MHz",
        phase_shift7              => "0 ps",
        duty_cycle7               => 50,
        output_clock_frequency8   => "0 MHz",
        phase_shift8              => "0 ps",
        duty_cycle8               => 50,
        output_clock_frequency9   => "0 MHz",
        phase_shift9              => "0 ps",
        duty_cycle9               => 50,
        output_clock_frequency10  => "0 MHz",
        phase_shift10             => "0 ps",
        duty_cycle10              => 50,
        output_clock_frequency11  => "0 MHz",
        phase_shift11             => "0 ps",
        duty_cycle11              => 50,
        output_clock_frequency12  => "0 MHz",
        phase_shift12             => "0 ps",
        duty_cycle12              => 50,
        output_clock_frequency13  => "0 MHz",
        phase_shift13             => "0 ps",
        duty_cycle13              => 50,
        output_clock_frequency14  => "0 MHz",
        phase_shift14             => "0 ps",
        duty_cycle14              => 50,
        output_clock_frequency15  => "0 MHz",
        phase_shift15             => "0 ps",
        duty_cycle15              => 50,
        output_clock_frequency16  => "0 MHz",
        phase_shift16             => "0 ps",
        duty_cycle16              => 50,
        output_clock_frequency17  => "0 MHz",
        phase_shift17             => "0 ps",
        duty_cycle17              => 50,
        pll_type                  => "General",
        pll_subtype               => "General")
    port map (
        rst       => rst_i,
        outclk(0) => clk_o,
        outclk(1) => clk_90_o,
        outclk(2) => video_clk_o,
        locked    => locked_o,
        fboutclk  => open,
        fbclk     => '0',
        refclk    => clk_i);

end rtl;
