##------------------------------------------------------------------------------
## Author    : Andreas Buerkler
## Date      : 07.10.2018
## Filename  : timing.sdc
## Changelog : 07.10.2018 - file created
##------------------------------------------------------------------------------

# input clocks
create_clock -name clk50 -period 20.000 [get_ports clk50_000_i]
create_clock -name clk12 -period 81.380 [get_ports clk12_288_i]

# pll
create_generated_clock -name audio_fast_clk -divide_by 1 -multiply_by 4 -source [get_ports clk12_288_i] [get_pins {i_pll|i_pll|auto_generated|pll1|clk[0]}]

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

# ETH
create_generated_clock -name eth_tx_clk -source [get_ports clk50_000_i] [get_ports {eth_refclk_o}]

set_input_delay -clock eth_tx_clk -max 9.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]
set_input_delay -clock eth_tx_clk -min 3.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]

set_output_delay -clock eth_tx_clk -max 4.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]
set_output_delay -clock eth_tx_clk -min -2.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]
