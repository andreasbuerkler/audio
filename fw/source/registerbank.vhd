--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 28.12.2018
-- Filename  : registerbank.vhd
-- Changelog : 28.12.2018 - file created
--             13.01.2019 - read strobe added
--             31.12.2019 - write ack added
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
    address_width_g  : positive := 16);
port (
    clk_i          : in  std_logic;
    reset_i        : in  std_logic;
    -- register
    data_i         : in  std_logic_array_32(register_count_g-1 downto 0);
    data_strb_i    : in  std_logic_vector(register_count_g-1 downto 0);
    data_o         : out std_logic_array_32(register_count_g-1 downto 0);
    data_strb_o    : out std_logic_vector(register_count_g-1 downto 0);
    read_strb_o    : out std_logic_vector(register_count_g-1 downto 0);
    -- ctrl bus
    ctrl_address_i : in  std_logic_vector(address_width_g-1 downto 0);
    ctrl_data_i    : in  std_logic_vector(data_width_g-1 downto 0);
    ctrl_data_o    : out std_logic_vector(data_width_g-1 downto 0);
    ctrl_strobe_i  : in  std_logic;
    ctrl_write_i   : in  std_logic;
    ctrl_ack_o     : out std_logic);
end entity registerbank;

architecture rtl of registerbank is

    signal register_r  : std_logic_array_32(register_count_g-1 downto 0) := register_init_g;
    signal data_strb_r : std_logic_vector(register_count_g-1 downto 0) := (others => '0');
    signal read_strb_r : std_logic_vector(register_count_g-1 downto 0) := (others => '0');
    signal ctrl_data_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal ctrl_ack_r  : std_logic := '0';

begin

    write_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            data_strb_r <= (others => '0');
            for i in 0 to register_count_g-1 loop
                if ((ctrl_strobe_i = '1') and (ctrl_write_i = '1')) then
                    if ((unsigned(ctrl_address_i) = to_unsigned(i, ctrl_address_i'length)) and (read_only_g(i) = '0')) then
                        for j in 0 to data_width_g-1 loop
                            register_r(i)(j) <= ctrl_data_i(j) and register_mask_g(i)(j);
                        end loop;
                        data_strb_r(i) <= '1';
                    end if;
                else
                    if (data_strb_i(i) = '1') then
                        for j in 0 to data_width_g-1 loop
                            register_r(i)(j) <= data_i(i)(j) and register_mask_g(i)(j);
                        end loop;
                    end if;
                end if;
            end loop;
        end if;
    end process write_proc;

    read_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            read_strb_r <= (others => '0');
            for i in 0 to register_count_g-1 loop
                if ((ctrl_strobe_i = '1') and (ctrl_write_i = '0')) then
                    if (unsigned(ctrl_address_i) = to_unsigned(i, ctrl_address_i'length)) then
                        read_strb_r(i) <= '1';
                        for j in 0 to data_width_g-1 loop
                            ctrl_data_r(j) <= register_r(i)(j) and register_mask_g(i)(j);
                        end loop;
                    end if;
                end if;
            end loop;
        end if;
    end process read_proc;

    ack_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            ctrl_ack_r <= ctrl_strobe_i;
        end if;
    end process ack_proc;

    data_o <= register_r;
    data_strb_o <= data_strb_r;
    read_strb_o <= read_strb_r;

    ctrl_data_o <= ctrl_data_r;
    ctrl_ack_o <= ctrl_ack_r;

end rtl;
