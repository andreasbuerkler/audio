##------------------------------------------------------------------------------
## Author    : Andreas Buerkler
## Date      : 22.12.2019
## Filename  : lcd.sdc
## Changelog : 22.12.2019 - file created
##------------------------------------------------------------------------------

# input clocks
create_clock -name clk50 -period 20.000 [get_ports clk50_000_i]

derive_pll_clocks
derive_clock_uncertainty

# ETH
create_generated_clock -name eth_tx_clk -source [get_ports clk50_000_i] [get_ports {eth_refclk_o}]

set_input_delay -clock eth_tx_clk -max 9.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]
set_input_delay -clock eth_tx_clk -min 3.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]

set_output_delay -clock eth_tx_clk -max 4.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]
set_output_delay -clock eth_tx_clk -min -2.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]
