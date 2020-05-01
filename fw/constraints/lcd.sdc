##------------------------------------------------------------------------------
## Author    : Andreas Buerkler
## Date      : 22.12.2019
## Filename  : lcd.sdc
## Changelog : 22.12.2019 - file created
##------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Clocks
# ------------------------------------------------------------------------------

# Input Clocks
create_clock -name clk50 -period 20.000 [get_ports clk50_000_i]

derive_pll_clocks

# Main PLL
set main_pll_clk         "i_main_pll|i_pll|general[0].gpll~PLL_OUTPUT_COUNTER|divclk"
set main_pll_clk_shifted "i_main_pll|i_pll|general[1].gpll~PLL_OUTPUT_COUNTER|divclk"
set main_pll_video_clk   "i_main_pll|i_pll|general[2].gpll~PLL_OUTPUT_COUNTER|divclk"

# ETH clock
create_generated_clock -name eth_tx_clk -source [get_pins ${main_pll_clk}] [get_ports {eth_refclk_o}]

# Hyper RAM clocks
create_generated_clock -name ram_clk -source [get_pins ${main_pll_clk_shifted}] -multiply_by 1 [get_ports {ram_clk_o}]

# I2C clock
create_generated_clock -name i2c_clk_int -source [get_pins ${main_pll_clk}] -divide_by 500 [get_registers {i_i2c_master|scl_r}]
create_generated_clock -name i2c_clk -source [get_registers {i_i2c_master|scl_r}] -multiply_by 1 [get_ports {i2c_scl_o}]

create_generated_clock -name ram_return_clk -source [get_ports {ram_clk_o}] -multiply_by 1 [get_ports {ram_rwds_io}]
set_clock_latency -source -early 1.0 [get_clocks {ram_return_clk}]
set_clock_latency -source -late 7.0 [get_clocks {ram_return_clk}]

derive_clock_uncertainty

# ------------------------------------------------------------------------------
# ETH
# ------------------------------------------------------------------------------
set_input_delay -clock eth_tx_clk -max 9.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]
set_input_delay -clock eth_tx_clk -min 3.000 [get_ports {eth_rx_d0_i eth_rx_d1_i eth_rx_dv_i}]

set_output_delay -clock eth_tx_clk -max 4.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]
set_output_delay -clock eth_tx_clk -min -2.000 [get_ports {eth_tx_d0_o eth_tx_d1_o eth_tx_en_o}]

set_false_path -to eth_rst_n_o
set_false_path -to eth_mdio_io
set_false_path -to eth_mdc_o

# ------------------------------------------------------------------------------
# Hyper RAM
# ------------------------------------------------------------------------------
set_input_delay -max 10.8 -clock [get_clocks ram_return_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io}] -add_delay
set_input_delay -max 10.8 -clock [get_clocks ram_return_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io}] -clock_fall -add_delay
set_input_delay -min 9.2 -clock [get_clocks ram_return_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io}] -add_delay
set_input_delay -min 9.2 -clock [get_clocks ram_return_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io}] -clock_fall -add_delay

set_output_delay -max 3.5 -clock [get_clocks ram_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io ram_rwds_io}] -add_delay
set_output_delay -max 3.5 -clock [get_clocks ram_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io ram_rwds_io}] -clock_fall -add_delay
set_output_delay -min -3.5 -clock [get_clocks ram_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io ram_rwds_io}] -add_delay
set_output_delay -min -3.5 -clock [get_clocks ram_clk] [get_ports {ram_d0_io ram_d1_io ram_d2_io ram_d3_io ram_d4_io ram_d5_io ram_d6_io ram_d7_io ram_rwds_io}] -clock_fall -add_delay

set_output_delay -max 3.5 -clock [get_clocks ram_clk] [get_ports {ram_cs_n_o}]
set_output_delay -min -3.5 -clock [get_clocks ram_clk] [get_ports {ram_cs_n_o}]

# Multicycle path to fix timing analyzer issue
set_multicycle_path -from [get_clocks ram_return_clk] -to [get_clocks ${main_pll_clk}] 2

# False paths for input data
set_false_path -rise_from [get_clocks ram_return_clk] -fall_to [get_clocks ram_return_clk] -hold
set_false_path -fall_from [get_clocks ram_return_clk] -rise_to [get_clocks ram_return_clk] -hold
set_false_path -rise_from [get_clocks ram_return_clk] -rise_to [get_clocks ram_return_clk] -setup
set_false_path -fall_from [get_clocks ram_return_clk] -fall_to [get_clocks ram_return_clk] -setup

# False paths for output data
set_false_path -rise_from [get_clocks ${main_pll_clk}] -fall_to [get_clocks ram_clk] -setup
set_false_path -fall_from [get_clocks ${main_pll_clk}] -rise_to [get_clocks ram_clk] -setup
set_false_path -rise_from [get_clocks ${main_pll_clk}] -rise_to [get_clocks ram_clk] -hold
set_false_path -fall_from [get_clocks ${main_pll_clk}] -fall_to [get_clocks ram_clk] -hold

# multicycle path for asynchronous reset
set_multicycle_path -from [get_registers {i_hyper_ram|hyper_data_in_counter_reset_r}] -to [get_registers {i_hyper_ram|hyper_data_in_counter_r[*]}] 0

set_false_path -to ram_rst_n_o

# ------------------------------------------------------------------------------
# I2C
# ------------------------------------------------------------------------------
set_false_path -from i2c_sda_io

set_output_delay -max 10.0 -clock [get_clocks i2c_clk] [get_ports {i2c_sda_io}]
set_output_delay -min 0.0 -clock [get_clocks i2c_clk] [get_ports {i2c_sda_io}]

# ------------------------------------------------------------------------------
# LED
# ------------------------------------------------------------------------------
set_false_path -to led0_o
set_false_path -to led1_o
set_false_path -to led2_o

# ------------------------------------------------------------------------------
# LCD
# ------------------------------------------------------------------------------
set_false_path -from [get_clocks ${main_pll_clk}] -to [get_clocks ${main_pll_video_clk}]
set_false_path -from [get_clocks ${main_pll_video_clk}] -to [get_clocks ${main_pll_clk}]
