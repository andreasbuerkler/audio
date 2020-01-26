--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 04.01.2020
-- Filename  : interconnect.vhd
-- Changelog : 04.01.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity interconnect is
generic (
    address_map_g          : std_logic_array := (0 => "--------");
    master_data_width_g    : positive := 32;
    master_address_width_g : positive := 16);
port (
    clk_i            : in std_logic;
    reset_i          : in std_logic;
    -- master
    master_address_i : in  std_logic_vector(master_address_width_g-1 downto 0);
    master_data_i    : in  std_logic_vector(master_data_width_g-1 downto 0);
    master_data_o    : out std_logic_vector(master_data_width_g-1 downto 0);
    master_strobe_i  : in  std_logic;
    master_write_i   : in  std_logic;
    master_ack_o     : out std_logic;
    -- slave
    slave_address_o : out std_logic_array;
    slave_data_i    : in  std_logic_array;
    slave_data_o    : out std_logic_array;
    slave_strobe_o  : out std_logic_vector;
    slave_write_o   : out std_logic_vector;
    slave_ack_i     : in  std_logic_vector);
end entity interconnect;

architecture rtl of interconnect is

    signal strobe_a               : std_logic_vector(address_map_g'length-1 downto 0);
    signal write_a                : std_logic_vector(address_map_g'length-1 downto 0);
    signal transfer_in_progress_r : std_logic_vector(address_map_g'length-1 downto 0) := (others => '0');
    signal read_data_r            : std_logic_vector(master_data_width_g-1 downto 0) := (others => '0');
    signal ack_r                  : std_logic := '0';

begin

    -- forward address and write data to all slaves
    forward_gen : for i in address_map_g'range generate
        addr_bit_gen :for j in slave_address_o'range(2) generate
            slave_address_o(i, j) <= master_address_i(j);
        end generate addr_bit_gen;
        data_bit_gen : for j in master_data_i'range generate
            slave_data_o(i, j) <= master_data_i(j);
        end generate data_bit_gen;
    end generate forward_gen;

    -- address decode
    address_decode_proc : process (master_strobe_i, master_write_i, master_address_i, master_data_i)
        variable strobe_v : std_logic_vector(address_map_g'length-1 downto 0);
        variable write_v  : std_logic_vector(address_map_g'length-1 downto 0);
    begin
        strobe_v := (others => '0');
        write_v := (others => '0');
        for i in 0 to address_map_g'length-1 loop
            if (std_match(master_address_i, array_extract(i, address_map_g))) then
                strobe_v(i) := master_strobe_i;
                write_v(i) := master_write_i;
            end if;
        end loop;
        strobe_a <= strobe_v;
        write_a <= write_v;
    end process address_decode_proc;

    -- read data
    transfer_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (master_strobe_i = '1') then
                transfer_in_progress_r <= transfer_in_progress_r or strobe_a;
            end if;
            for o in 0 to address_map_g'length-1 loop
                if (slave_ack_i(o) = '1') then
                    read_data_r <= array_extract(o, slave_data_i);
                end if;
            end loop;
            if ((vector_or(slave_ack_i) = '1') or (reset_i = '1')) then
                transfer_in_progress_r <= (others => '0');
            end if;
            ack_r <= vector_or(slave_ack_i);
        end if;
    end process transfer_proc;

    slave_strobe_o <= strobe_a;
    slave_write_o <= write_a;
    master_ack_o <= ack_r;
    master_data_o <= read_data_r;

end rtl;