##------------------------------------------------------------------------------
## Author    : Andreas Buerkler
## Date      : 07.10.2018
## Filename  : timing.sdc
## Changelog : 07.10.2018 - file created
##------------------------------------------------------------------------------

# input clocks
create_clock -name clk50 -period 20 [get_ports clk50_000_i]
create_clock -name clk12 -period 81 [get_ports clk12_288_i]

# output clocks
create_generated_clock -name audio_mclk -source [get_ports clk12_288_i] [get_ports {i2s_mclk_o}]

derive_clock_uncertainty

# I2S
set_input_delay -clock clk12 -clock_fall -max 10 [get_ports {i2s_i}]
set_input_delay -clock clk12 -clock_fall -min -10 [get_ports {i2s_i}]

set_output_delay -clock clk12 -max 10 [get_ports {i2s_o}]
set_output_delay -clock clk12 -min -10 [get_ports {i2s_o}]

set_output_delay -clock clk12 -max 10 [get_ports {i2s_bclk_o}]
set_output_delay -clock clk12 -min -10 [get_ports {i2s_bclk_o}]

set_output_delay -clock clk12 -max 10 [get_ports {i2s_lrclk_o}]
set_output_delay -clock clk12 -min -10 [get_ports {i2s_lrclk_o}]
