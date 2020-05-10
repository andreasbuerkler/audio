--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 28.12.2018
-- Filename  : registerbank.vhd
-- Changelog : 28.12.2018 - file created
--             13.01.2019 - read strobe added
--             31.12.2019 - write ack added
--             10.05.2020 - burst added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity registerbank is
generic (
    register_count_g : positive := 8;
    register_init_g  : std_logic_array_32 := (0 => x"00000000");
    register_mask_g  : std_logic_array_32 := (0 => x"ffffffff");
    read_only_g      : std_logic_vector := (0 => '0');
    data_width_g     : positive := 32;
    address_width_g  : positive := 16;
    burst_size_g     : positive := 32);
port (
    clk_i             : in  std_logic;
    reset_i           : in  std_logic;
    -- register
    data_i            : in  std_logic_array_32(register_count_g-1 downto 0);
    data_strb_i       : in  std_logic_vector(register_count_g-1 downto 0);
    data_o            : out std_logic_array_32(register_count_g-1 downto 0);
    data_strb_o       : out std_logic_vector(register_count_g-1 downto 0);
    read_strb_o       : out std_logic_vector(register_count_g-1 downto 0);
    -- ctrl bus
    ctrl_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
    ctrl_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
    ctrl_data_o       : out std_logic_vector(data_width_g-1 downto 0);
    ctrl_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    ctrl_strobe_i     : in  std_logic;
    ctrl_write_i      : in  std_logic;
    ctrl_ack_o        : out std_logic);
end entity registerbank;

architecture rtl of registerbank is

    signal register_r      : std_logic_array_32(register_count_g-1 downto 0) := register_init_g;
    signal data_strb_r     : std_logic_vector(register_count_g-1 downto 0) := (others => '0');
    signal read_strb_r     : std_logic_vector(register_count_g-1 downto 0) := (others => '0');
    signal read_data_r     : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal ctrl_ack_r      : std_logic := '0';
    signal burst_counter_r : unsigned(ctrl_burst_size_i'range) := (others => '0');
    signal address_r       : std_logic_vector(ctrl_address_i'range) := (others => '0');
    signal write_data_r    : std_logic_vector(ctrl_data_i'range) := (others => '0');
    signal write_r         : std_logic := '0';
    signal strb_r          : std_logic := '0';

begin

    burst_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            strb_r <= '0';
            if (vector_or(std_logic_vector(burst_counter_r)) = '0') then
                if (ctrl_strobe_i = '1') then
                    burst_counter_r <= unsigned(ctrl_burst_size_i);
                    write_r <= ctrl_write_i;
                    write_data_r <= ctrl_data_i;
                    address_r <= ctrl_address_i;
                    strb_r <= '1';
                end if;
            else
                if (write_r = '0') then
                    strb_r <= '1';
                    burst_counter_r <= burst_counter_r - 1;
                    address_r <= std_logic_vector(unsigned(address_r) + 1);
                elsif (ctrl_strobe_i = '1') then
                    strb_r <= '1';
                    burst_counter_r <= burst_counter_r - 1;
                    address_r <= std_logic_vector(unsigned(address_r) + 1);
                    write_data_r <= ctrl_data_i;
                end if;
            end if;
        end if;
    end process burst_proc;

    write_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            data_strb_r <= (others => '0');
            for i in 0 to register_count_g-1 loop
                if ((strb_r = '1') and (write_r = '1')) then
                    if ((unsigned(address_r) = to_unsigned(i, address_r'length)) and (read_only_g(i) = '0')) then
                        for j in 0 to data_width_g-1 loop
                            register_r(i)(j) <= write_data_r(j) and register_mask_g(i)(j);
                        end loop;
                        data_strb_r(i) <= '1';
                    end if;
                elsif (data_strb_i(i) = '1') then
                    for j in 0 to data_width_g-1 loop
                        register_r(i)(j) <= data_i(i)(j) and register_mask_g(i)(j);
                    end loop;
                end if;
            end loop;

            if (reset_i = '1') then
                register_r <= register_init_g;
            end if;
        end if;
    end process write_proc;

    read_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            read_strb_r <= (others => '0');
            for i in 0 to register_count_g-1 loop
                if ((strb_r = '1') and (write_r = '0')) then
                    if (unsigned(address_r) = to_unsigned(i, address_r'length)) then
                        read_strb_r(i) <= '1';
                        for j in 0 to data_width_g-1 loop
                            read_data_r(j) <= register_r(i)(j) and register_mask_g(i)(j);
                        end loop;
                    end if;
                end if;
            end loop;
        end if;
    end process read_proc;

    ack_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            ctrl_ack_r <= '0';
            for i in 0 to register_count_g-1 loop
                if (unsigned(address_r) = to_unsigned(i, address_r'length)) then
                    ctrl_ack_r <= strb_r and ((not write_r) or (not vector_or(std_logic_vector(burst_counter_r))));
                end if;
            end loop;
        end if;
    end process ack_proc;

    data_o <= register_r;
    data_strb_o <= data_strb_r;
    read_strb_o <= read_strb_r;

    ctrl_data_o <= read_data_r;
    ctrl_ack_o <= ctrl_ack_r;

end rtl;
