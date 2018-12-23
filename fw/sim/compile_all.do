if { $::argc != 1 } {
    puts "tb argument missing"
} else {

    vdel -all

    vlib work

    # common
    vcom ../source/fpga_pkg.vhd -check_synthesis
    vcom ../source/fifo.vhd -check_synthesis
    vcom ../source/ram.vhd -check_synthesis

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

    # biquad
    vcom ../source/biquad_data_mem.vhd -check_synthesis
    vcom ../source/biquad_coeff_mem.vhd -check_synthesis
    vcom ../source/biquad_mult.vhd -check_synthesis
    vcom ../source/biquad.vhd -check_synthesis

    # i2c
    vcom ../source/i2c_config.vhd -check_synthesis
    vcom ../source/i2c_slave.vhd -check_synthesis

    # i2s
    vcom ../source/i2s_inout.vhd -check_synthesis
    vcom ../source/i2s_clock_converter.vhd -check_synthesis

    # audio
    vcom ../source/meter.vhd -check_synthesis

    # top level
    vcom ../source/audio_top.vhd -check_synthesis

    # test benches
    vcom ../testbench/crc32_tb.vhd
    vcom ../testbench/fifo_tb.vhd
    vcom ../testbench/i2c_config_tb.vhd
    vcom ../testbench/i2c_slave_tb.vhd
    vcom ../testbench/i2s_inout_tb.vhd
    vcom ../testbench/rmii_interface_tb.vhd
    vcom ../testbench/eth_mac_tb.vhd
    vcom ../testbench/eth_subsystem_tb.vhd

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