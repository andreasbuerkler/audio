--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2c_config_tb.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity i2c_config_tb is
end entity i2c_config_tb;

architecture rtl of i2c_config_tb is

    component i2c_config
    generic (
        I2C_ADDRESS : std_logic_vector(7 downto 0);
        CONFIG      : std_logic_vector;
        FREQ_I      : positive := 50000000;
        FREQ_O      : positive := 100000);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        error_o      : out std_logic;
        done_o       : out std_logic;
        scl_o        : out std_logic;
        sda_i        : in  std_logic;
        sda_o        : out std_logic);
    end component;

    component i2c_slave
    generic (
        I2C_ADDRESS : std_logic_vector(7 downto 0) := x"34");
    port (
        clk_i        : in  std_logic;
        scl_i        : in  std_logic;
        sda_i        : in  std_logic;
        sda_o        : out std_logic;
        address_o    : out std_logic_vector(7 downto 0);
        wr_o         : out std_logic;
        rd_o         : out std_logic;
        rd_valid_i   : in  std_logic;
        rd_data_i    : in  std_logic_vector(7 downto 0);
        wr_data_o    : out std_logic_vector(7 downto 0));
    end component;

    signal clk        : std_logic;
    signal reset      : std_logic;
    signal scl_m_to_s : std_logic;
    signal sda_m_to_s : std_logic;
    signal sda_s_to_m : std_logic;

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    reset_proc : process
    begin
        reset <= '0';
        wait for 10000000 ns;
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait;
    end process reset_proc;

    i_dut : i2c_config
    generic map (
        I2C_ADDRESS => x"5A",
        CONFIG      => x"07_03" & x"01_01" & x"02_80" & x"03_29" &
                       x"04_00" & x"05_00" & x"06_10" & x"07_02",
        FREQ_I      =>50000000,
        FREQ_O      => 100000)
    port map (
        clk_i   => clk,
        reset_i => reset,
        error_o => open,
        done_o  => open,
        scl_o   => scl_m_to_s,
        sda_i   => sda_s_to_m,
        sda_o   => sda_m_to_s);

    i_slave : i2c_slave
    generic map (
        I2C_ADDRESS => x"5A")
    port map (
        clk_i        => clk,
        scl_i        => scl_m_to_s,
        sda_i        => sda_m_to_s,
        sda_o        => sda_s_to_m,
        address_o    => open,
        wr_o         => open,
        rd_o         => open,
        rd_valid_i   => '0',
        rd_data_i    => x"00",
        wr_data_o    => open);

end rtl;