if { $::argc != 1 } {
    puts "tb argument missing"
} else {

    vdel -all

    vlib work
    vlib fmf

    # common
    vcom ../source/fpga_pkg.vhd -check_synthesis
    vcom ../source/fifo.vhd -check_synthesis
    vcom ../source/fifo_dual_clock.vhd -check_synthesis
    vcom ../source/ram.vhd -check_synthesis
    vcom ../source/dual_clock_ram.vhd -check_synthesis
    vcom ../source/registerbank.vhd -check_synthesis
    vcom ../source/clock_converter.vhd -check_synthesis
    vcom ../source/slave_interconnect.vhd -check_synthesis
    vcom ../source/master_interconnect.vhd -check_synthesis
    vcom ../source/interconnect.vhd -check_synthesis

    # eth mac
    vcom ../source/rmii_interface.vhd -check_synthesis
    vcom ../source/crc32.vhd -check_synthesis
    vcom ../source/eth_fcs.vhd -check_synthesis
    vcom ../source/eth_padder.vhd -check_synthesis
    vcom ../source/eth_mac.vhd -check_synthesis

    # eth subsystem
    vcom ../source/eth_processing.vhd -check_synthesis
    vcom ../source/arp_processing.vhd -check_synthesis
    vcom ../source/eth_subsystem.vhd -check_synthesis
    vcom ../source/eth_ip.vhd -check_synthesis
    vcom ../source/eth_icmp.vhd -check_synthesis
    vcom ../source/eth_udp.vhd -check_synthesis
    vcom ../source/eth_ctrl.vhd -check_synthesis

    # biquad
    vcom ../source/biquad_data_mem.vhd -check_synthesis
    vcom ../source/biquad_coeff_mem.vhd -check_synthesis
    vcom ../source/biquad_mult.vhd -check_synthesis
    vcom ../source/biquad.vhd -check_synthesis

    # i2c
    vcom ../source/i2c_config.vhd -check_synthesis
    vcom ../source/i2c_slave.vhd -check_synthesis
    vcom ../source/i2c_master.vhd -check_synthesis

    # audio
    vcom ../source/i2s_inout.vhd -check_synthesis
    vcom ../source/log_cos_data_rom.vhd -check_synthesis
    vcom ../source/meter.vhd -check_synthesis
    vcom ../source/crossfader.vhd -check_synthesis
    vcom ../source/step_response_pkg.vhd -check_synthesis
    vcom ../source/convolution.vhd -check_synthesis
    vcom ../source/sinus_gen.vhd -check_synthesis

    # video
    vcom ../source/lcd_controller.vhd -check_synthesis

    # ram controller
    vcom ../source/hyper_ram_controller.vhd -check_synthesis

    # debug
    vcom ../source/mdio_debug.vhd -check_synthesis

    # top level
    vcom ../source/audio_top.vhd -check_synthesis
    vcom ../source/lcd_top.vhd -check_synthesis

    # hyper ram functional model
    vcom -work fmf ../testbench/s27kl0641/utilities/gen_utils.vhd
    vcom -work fmf ../testbench/s27kl0641/utilities/conversions.vhd
    vcom ../testbench/s27kl0641/model/s27kl0641.vhd

    # test benches
    vcom ../testbench/crc32_tb.vhd
    vcom ../testbench/fifo_tb.vhd
    vcom ../testbench/fifo_dual_clock_tb.vhd
    vcom ../testbench/i2c_config_tb.vhd
    vcom ../testbench/i2c_master_tb.vhd
    vcom ../testbench/i2c_slave_tb.vhd
    vcom ../testbench/i2s_inout_tb.vhd
    vcom ../testbench/rmii_interface_tb.vhd
    vcom ../testbench/eth_mac_tb.vhd
    vcom ../testbench/eth_subsystem_tb.vhd
    vcom ../testbench/registerbank_tb.vhd
    vcom ../testbench/meter_tb.vhd
    vcom ../testbench/crossfader_tb.vhd
    vcom ../testbench/convolution_tb.vhd
    vcom ../testbench/sinus_gen_tb.vhd
    vcom ../testbench/slave_interconnect_tb.vhd
    vcom ../testbench/master_interconnect_tb.vhd
    vcom ../testbench/interconnect_tb.vhd
    vcom ../testbench/mdio_debug_tb.vhd
    vcom ../testbench/lcd_controller_tb.vhd
    vcom ../testbench/hyper_ram_controller_tb.vhd

    # start simulation
    set tbName $1
    append tbName _tb
    set waveName wave_ 
    append waveName $tbName
    append waveName .do
    vsim $tbName
    do $waveName
    run -all
}
