--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 02.08.2020
-- Filename  : interconnect.vhd
-- Changelog : 02.08.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity interconnect is
generic (
    data_width_g    : positive := 32;
    address_width_g : positive := 32;
    burst_size_g    : positive := 5);
port (
    clk_i                : in std_logic;
    reset_i              : in std_logic;
    -- master 0
    master0_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
    master0_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
    master0_data_o       : out std_logic_vector(data_width_g-1 downto 0);
    master0_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    master0_strobe_i     : in  std_logic;
    master0_write_i      : in  std_logic;
    master0_ack_o        : out std_logic;
    -- master 1
    master1_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
    master1_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
    master1_data_o       : out std_logic_vector(data_width_g-1 downto 0);
    master1_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    master1_strobe_i     : in  std_logic;
    master1_write_i      : in  std_logic;
    master1_ack_o        : out std_logic;
    -- slave 0
    slave0_address_o     : out std_logic_vector(address_width_g-1 downto 0);
    slave0_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    slave0_data_o        : out std_logic_vector(data_width_g-1 downto 0);
    slave0_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    slave0_strobe_o      : out std_logic;
    slave0_write_o       : out std_logic;
    slave0_ack_i         : in  std_logic;
    -- slave 1
    slave1_address_o     : out std_logic_vector(address_width_g-1 downto 0);
    slave1_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    slave1_data_o        : out std_logic_vector(data_width_g-1 downto 0);
    slave1_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    slave1_strobe_o      : out std_logic;
    slave1_write_o       : out std_logic;
    slave1_ack_i         : in  std_logic;
    -- slave 2
    slave2_address_o     : out std_logic_vector(address_width_g-1 downto 0);
    slave2_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    slave2_data_o        : out std_logic_vector(data_width_g-1 downto 0);
    slave2_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    slave2_strobe_o      : out std_logic;
    slave2_write_o       : out std_logic;
    slave2_ack_i         : in  std_logic);
end entity interconnect;

architecture rtl of interconnect is

    component master_interconnect is
    generic (
        number_of_masters_g : positive;
        data_width_g        : positive;
        address_width_g     : positive;
        burst_size_g        : positive);
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        -- master
        master_address_i    : in  std_logic_array;
        master_data_i       : in  std_logic_array;
        master_data_o       : out std_logic_array;
        master_burst_size_i : in  std_logic_array;
        master_strobe_i     : in  std_logic_vector;
        master_write_i      : in  std_logic_vector;
        master_ack_o        : out std_logic_vector;
        -- slave
        slave_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave_strobe_o      : out std_logic;
        slave_write_o       : out std_logic;
        slave_ack_i         : in  std_logic);
    end component master_interconnect;

    component slave_interconnect is
    generic (
        address_map_g          : std_logic_array;
        master_data_width_g    : positive;
        master_address_width_g : positive;
        master_burst_size_g    : positive);
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        -- master
        master_address_i    : in  std_logic_vector(master_address_width_g-1 downto 0);
        master_data_i       : in  std_logic_vector(master_data_width_g-1 downto 0);
        master_data_o       : out std_logic_vector(master_data_width_g-1 downto 0);
        master_burst_size_i : in  std_logic_vector(log2ceil(master_burst_size_g)-1 downto 0);
        master_strobe_i     : in  std_logic;
        master_write_i      : in  std_logic;
        master_ack_o        : out std_logic;
        -- slave
        slave_address_o     : out std_logic_array;
        slave_data_i        : in  std_logic_array;
        slave_data_o        : out std_logic_array;
        slave_burst_size_o  : out std_logic_array;
        slave_strobe_o      : out std_logic_vector;
        slave_write_o       : out std_logic_vector;
        slave_ack_i         : in  std_logic_vector);
    end component slave_interconnect;

    constant number_of_masters_c : positive := 2;
    constant number_of_slaves_c  : positive := 3;
    constant address_map_c : std_logic_array := (0 => "00----------------------",
                                                 1 => "01----------------------",
                                                 2 => "1-----------------------");

    signal slave0_address         : std_logic_array(number_of_slaves_c-1 downto 0, address_width_g-1 downto 0);
    signal slave0_read_data       : std_logic_array(number_of_slaves_c-1 downto 0, data_width_g-1 downto 0);
    signal slave0_write_data      : std_logic_array(number_of_slaves_c-1 downto 0, data_width_g-1 downto 0);
    signal slave0_burst_size      : std_logic_array(number_of_slaves_c-1 downto 0, log2ceil(burst_size_g)-1 downto 0);
    signal slave0_strobe          : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave0_write           : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave0_ack             : std_logic_vector(number_of_slaves_c-1 downto 0);

    signal slave1_address         : std_logic_array(number_of_slaves_c-1 downto 0, address_width_g-1 downto 0);
    signal slave1_read_data       : std_logic_array(number_of_slaves_c-1 downto 0, data_width_g-1 downto 0);
    signal slave1_write_data      : std_logic_array(number_of_slaves_c-1 downto 0, data_width_g-1 downto 0);
    signal slave1_burst_size      : std_logic_array(number_of_slaves_c-1 downto 0, log2ceil(burst_size_g)-1 downto 0);
    signal slave1_strobe          : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave1_write           : std_logic_vector(number_of_slaves_c-1 downto 0);
    signal slave1_ack             : std_logic_vector(number_of_slaves_c-1 downto 0);

    signal master0_address         : std_logic_array(number_of_masters_c-1 downto 0, address_width_g-1 downto 0);
    signal master0_read_data       : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master0_write_data      : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master0_burst_size      : std_logic_array(number_of_masters_c-1 downto 0, log2ceil(burst_size_g)-1 downto 0);
    signal master0_strobe          : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master0_write           : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master0_ack             : std_logic_vector(number_of_masters_c-1 downto 0);

    signal master1_address         : std_logic_array(number_of_masters_c-1 downto 0, address_width_g-1 downto 0);
    signal master1_read_data       : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master1_write_data      : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master1_burst_size      : std_logic_array(number_of_masters_c-1 downto 0, log2ceil(burst_size_g)-1 downto 0);
    signal master1_strobe          : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master1_write           : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master1_ack             : std_logic_vector(number_of_masters_c-1 downto 0);

    signal master2_address         : std_logic_array(number_of_masters_c-1 downto 0, address_width_g-1 downto 0);
    signal master2_read_data       : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master2_write_data      : std_logic_array(number_of_masters_c-1 downto 0, data_width_g-1 downto 0);
    signal master2_burst_size      : std_logic_array(number_of_masters_c-1 downto 0, log2ceil(burst_size_g)-1 downto 0);
    signal master2_strobe          : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master2_write           : std_logic_vector(number_of_masters_c-1 downto 0);
    signal master2_ack             : std_logic_vector(number_of_masters_c-1 downto 0);

begin

--                               Master Interconnect 
--
--                                    +------+
--     Slave interconnect         ---A|      |
--                           ----/    |   0  |SLAVE 0
--          +------+    ----/      --D|      |
--          |      |A--/         -/   +------+
-- MASTER 0 |   0  |B---\      -/
--          |      |C-\  -----/-\     +------+
--          +------+   -\  -/    ----B|      |
--                       -/           |   1  |SLAVE 1
--          +------+   -/  -\    ----E|      |
--          |      |D-/  -------/     +------+
-- MASTER 1 |   1  |E---/      -\
--          |      |F--\         -\   +------+       
--          +------+    ----\      --C|      |
--                           ----\    |   2  |SLAVE 2
--                                ---F|      |
--                                    +------+

    i_slave0_interconnect : slave_interconnect
    generic map (
        address_map_g          => address_map_c,
        master_data_width_g    => data_width_g,
        master_address_width_g => address_width_g,
        master_burst_size_g    => burst_size_g)
    port map (
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- master
        master_address_i    => master0_address_i,
        master_data_i       => master0_data_i,
        master_data_o       => master0_data_o,
        master_burst_size_i => master0_burst_size_i,
        master_strobe_i     => master0_strobe_i,
        master_write_i      => master0_write_i,
        master_ack_o        => master0_ack_o,
        -- slave
        slave_address_o    => slave0_address,
        slave_data_i       => slave0_read_data,
        slave_data_o       => slave0_write_data,
        slave_burst_size_o => slave0_burst_size,
        slave_strobe_o     => slave0_strobe,
        slave_write_o      => slave0_write,
        slave_ack_i        => slave0_ack);

    i_slave1_interconnect : slave_interconnect
    generic map (
        address_map_g          => address_map_c,
        master_data_width_g    => data_width_g,
        master_address_width_g => address_width_g,
        master_burst_size_g    => burst_size_g)
    port map (
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- master
        master_address_i    => master1_address_i,
        master_data_i       => master1_data_i,
        master_data_o       => master1_data_o,
        master_burst_size_i => master1_burst_size_i,
        master_strobe_i     => master1_strobe_i,
        master_write_i      => master1_write_i,
        master_ack_o        => master1_ack_o,
        -- slave
        slave_address_o    => slave1_address,
        slave_data_i       => slave1_read_data,
        slave_data_o       => slave1_write_data,
        slave_burst_size_o => slave1_burst_size,
        slave_strobe_o     => slave1_strobe,
        slave_write_o      => slave1_write,
        slave_ack_i        => slave1_ack);

    i_master0_interconnect : master_interconnect
    generic map (
        number_of_masters_g => number_of_masters_c,
        data_width_g        => data_width_g,
        address_width_g     => address_width_g,
        burst_size_g        => burst_size_g)
    port map (
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- master
        master_address_i    => master0_address,
        master_data_i       => master0_write_data,
        master_data_o       => master0_read_data,
        master_burst_size_i => master0_burst_size,
        master_strobe_i     => master0_strobe,
        master_write_i      => master0_write,
        master_ack_o        => master0_ack,
        -- slave
        slave_address_o     => slave0_address_o,
        slave_data_i        => slave0_data_i,
        slave_data_o        => slave0_data_o,
        slave_burst_size_o  => slave0_burst_size_o,
        slave_strobe_o      => slave0_strobe_o,
        slave_write_o       => slave0_write_o,
        slave_ack_i         => slave0_ack_i);

    i_master1_interconnect : master_interconnect
    generic map (
        number_of_masters_g => number_of_masters_c,
        data_width_g        => data_width_g,
        address_width_g     => address_width_g,
        burst_size_g        => burst_size_g)
    port map (
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- master
        master_address_i    => master1_address,
        master_data_i       => master1_write_data,
        master_data_o       => master1_read_data,
        master_burst_size_i => master1_burst_size,
        master_strobe_i     => master1_strobe,
        master_write_i      => master1_write,
        master_ack_o        => master1_ack,
        -- slave
        slave_address_o     => slave1_address_o,
        slave_data_i        => slave1_data_i,
        slave_data_o        => slave1_data_o,
        slave_burst_size_o  => slave1_burst_size_o,
        slave_strobe_o      => slave1_strobe_o,
        slave_write_o       => slave1_write_o,
        slave_ack_i         => slave1_ack_i);

    i_master2_interconnect : master_interconnect
    generic map (
        number_of_masters_g => number_of_masters_c,
        data_width_g        => data_width_g,
        address_width_g     => address_width_g,
        burst_size_g        => burst_size_g)
    port map (
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- master
        master_address_i    => master2_address,
        master_data_i       => master2_write_data,
        master_data_o       => master2_read_data,
        master_burst_size_i => master2_burst_size,
        master_strobe_i     => master2_strobe,
        master_write_i      => master2_write,
        master_ack_o        => master2_ack,
        -- slave
        slave_address_o     => slave2_address_o,
        slave_data_i        => slave2_data_i,
        slave_data_o        => slave2_data_o,
        slave_burst_size_o  => slave2_burst_size_o,
        slave_strobe_o      => slave2_strobe_o,
        slave_write_o       => slave2_write_o,
        slave_ack_i         => slave2_ack_i);

    -- address connection
    address_gen : for i in address_width_g-1 downto 0 generate
        master0_address(0, i) <= slave0_address(0, i);
        master1_address(0, i) <= slave0_address(1, i);
        master2_address(0, i) <= slave0_address(2, i);
        master0_address(1, i) <= slave1_address(0, i);
        master1_address(1, i) <= slave1_address(1, i);
        master2_address(1, i) <= slave1_address(2, i);
    end generate address_gen;

    -- write data connection
    write_data_gen : for i in data_width_g-1 downto 0 generate
        master0_write_data(0, i) <= slave0_write_data(0, i);
        master1_write_data(0, i) <= slave0_write_data(1, i);
        master2_write_data(0, i) <= slave0_write_data(2, i);
        master0_write_data(1, i) <= slave1_write_data(0, i);
        master1_write_data(1, i) <= slave1_write_data(1, i);
        master2_write_data(1, i) <= slave1_write_data(2, i);
    end generate write_data_gen;

    -- read data connection
    read_data_gen : for i in data_width_g-1 downto 0 generate
        slave0_read_data(0, i) <= master0_read_data(0, i);
        slave0_read_data(1, i) <= master1_read_data(0, i);
        slave0_read_data(2, i) <= master2_read_data(0, i);
        slave1_read_data(0, i) <= master0_read_data(1, i);
        slave1_read_data(1, i) <= master1_read_data(1, i);
        slave1_read_data(2, i) <= master2_read_data(1, i);
    end generate read_data_gen;

    -- burst size connection
    burst_size_gen : for i in log2ceil(burst_size_g)-1 downto 0 generate
        master0_burst_size(0, i) <= slave0_burst_size(0, i);
        master1_burst_size(0, i) <= slave0_burst_size(1, i);
        master2_burst_size(0, i) <= slave0_burst_size(2, i);
        master0_burst_size(1, i) <= slave1_burst_size(0, i);
        master1_burst_size(1, i) <= slave1_burst_size(1, i);
        master2_burst_size(1, i) <= slave1_burst_size(2, i);
    end generate burst_size_gen;

    -- strobe connection
    master0_strobe(0) <= slave0_strobe(0);
    master1_strobe(0) <= slave0_strobe(1);
    master2_strobe(0) <= slave0_strobe(2);
    master0_strobe(1) <= slave1_strobe(0);
    master1_strobe(1) <= slave1_strobe(1);
    master2_strobe(1) <= slave1_strobe(2);

    -- write connection
    master0_write(0) <= slave0_write(0);
    master1_write(0) <= slave0_write(1);
    master2_write(0) <= slave0_write(2);
    master0_write(1) <= slave1_write(0);
    master1_write(1) <= slave1_write(1);
    master2_write(1) <= slave1_write(2);

    -- ack connection
    slave0_ack(0) <= master0_ack(0);
    slave0_ack(1) <= master1_ack(0);
    slave0_ack(2) <= master2_ack(0);
    slave1_ack(0) <= master0_ack(1);
    slave1_ack(1) <= master1_ack(1);
    slave1_ack(2) <= master2_ack(1);

end rtl;
