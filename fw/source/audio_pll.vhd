--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 09.03.2019
-- Filename  : audio_pll.vhd
-- Changelog : 09.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

entity audio_pll is
    port (
        rst_i    : in  std_logic;
        clk_i    : in  std_logic;
        clkx4_o  : out std_logic;
        locked_o : out std_logic);
end audio_pll;

architecture rtl of audio_pll is

    component altpll
    generic (
        bandwidth_type          : string;
        clk0_divide_by          : natural;
        clk0_duty_cycle         : natural;
        clk0_multiply_by        : natural;
        clk0_phase_shift        : string;
        compensate_clock        : string;
        inclk0_input_frequency  : natural;
        intended_device_family  : string;
        lpm_hint                : string;
        lpm_type                : string;
        operation_mode          : string;
        pll_type                : string;
        port_activeclock        : string;
        port_areset             : string;
        port_clkbad0            : string;
        port_clkbad1            : string;
        port_clkloss            : string;
        port_clkswitch          : string;
        port_configupdate       : string;
        port_fbin               : string;
        port_inclk0             : string;
        port_inclk1             : string;
        port_locked             : string;
        port_pfdena             : string;
        port_phasecounterselect : string;
        port_phasedone          : string;
        port_phasestep          : string;
        port_phaseupdown        : string;
        port_pllena             : string;
        port_scanaclr           : string;
        port_scanclk            : string;
        port_scanclkena         : string;
        port_scandata           : string;
        port_scandataout        : string;
        port_scandone           : string;
        port_scanread           : string;
        port_scanwrite          : string;
        port_clk0               : string;
        port_clk1               : string;
        port_clk2               : string;
        port_clk3               : string;
        port_clk4               : string;
        port_clk5               : string;
        port_clkena0            : string;
        port_clkena1            : string;
        port_clkena2            : string;
        port_clkena3            : string;
        port_clkena4            : string;
        port_clkena5            : string;
        port_extclk0            : string;
        port_extclk1            : string;
        port_extclk2            : string;
        port_extclk3            : string;
        self_reset_on_loss_lock : string;
        width_clock             : natural);
    port (
        areset : in  std_logic;
        inclk  : in  std_logic_vector(1 downto 0);
        clk    : out std_logic_vector(4 downto 0);
        locked : out std_logic);
    end component;

    signal unused : std_logic_vector(3 downto 0);

begin

    i_pll : altpll
    generic map (
        bandwidth_type          => "AUTO",
        clk0_divide_by          => 1,
        clk0_duty_cycle         => 50,
        clk0_multiply_by        => 4,
        clk0_phase_shift        => "0",
        compensate_clock        => "CLK0",
        inclk0_input_frequency  => 81380,
        intended_device_family  => "MAX 10",
        lpm_hint                => "CBX_MODULE_PREFIX=audio_pll",
        lpm_type                => "altpll",
        operation_mode          => "NORMAL",
        pll_type                => "AUTO",
        port_activeclock        => "port_UNUSED",
        port_areset             => "port_USED",
        port_clkbad0            => "port_UNUSED",
        port_clkbad1            => "port_UNUSED",
        port_clkloss            => "port_UNUSED",
        port_clkswitch          => "port_UNUSED",
        port_configupdate       => "port_UNUSED",
        port_fbin               => "port_UNUSED",
        port_inclk0             => "port_USED",
        port_inclk1             => "port_UNUSED",
        port_locked             => "port_USED",
        port_pfdena             => "port_UNUSED",
        port_phasecounterselect => "port_UNUSED",
        port_phasedone          => "port_UNUSED",
        port_phasestep          => "port_UNUSED",
        port_phaseupdown        => "port_UNUSED",
        port_pllena             => "port_UNUSED",
        port_scanaclr           => "port_UNUSED",
        port_scanclk            => "port_UNUSED",
        port_scanclkena         => "port_UNUSED",
        port_scandata           => "port_UNUSED",
        port_scandataout        => "port_UNUSED",
        port_scandone           => "port_UNUSED",
        port_scanread           => "port_UNUSED",
        port_scanwrite          => "port_UNUSED",
        port_clk0               => "port_USED",
        port_clk1               => "port_UNUSED",
        port_clk2               => "port_UNUSED",
        port_clk3               => "port_UNUSED",
        port_clk4               => "port_UNUSED",
        port_clk5               => "port_UNUSED",
        port_clkena0            => "port_UNUSED",
        port_clkena1            => "port_UNUSED",
        port_clkena2            => "port_UNUSED",
        port_clkena3            => "port_UNUSED",
        port_clkena4            => "port_UNUSED",
        port_clkena5            => "port_UNUSED",
        port_extclk0            => "port_UNUSED",
        port_extclk1            => "port_UNUSED",
        port_extclk2            => "port_UNUSED",
        port_extclk3            => "port_UNUSED",
        self_reset_on_loss_lock => "OFF",
        width_clock             => 5)
    port map (
        areset   => rst_i,
        inclk(0) => clk_i,
        inclk(1) => '0',
        clk(0)   => clkx4_o,
        clk(1)   => unused(0),
        clk(2)   => unused(1),
        clk(3)   => unused(2),
        clk(4)   => unused(3),
        locked   => locked_o);

end rtl;
