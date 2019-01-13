--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 12.01.2019
-- Filename  : meter_tb.vhd
-- Changelog : 12.01.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.
std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity meter_tb is
end entity meter_tb;

architecture rtl of meter_tb is

    component meter
    generic (
        data_width_g : natural);
    port (
        audio_clk_i    : in  std_logic;
        left_valid_i   : in  std_logic;
        right_valid_i  : in  std_logic;
        data_i         : in  std_logic_vector(data_width_g-1 downto 0);
        register_clk_i : in  std_logic;
        data_read_l_i  : in  std_logic;
        data_read_r_i  : in  std_logic;
        level_l_o      : out std_logic_vector(7 downto 0);
        level_r_o      : out std_logic_vector(7 downto 0);
        level_strobe_o : out std_logic);
    end component meter;

    signal clk_audio          : std_logic := '0';
    signal clk_register       : std_logic := '0';
    signal clk_en             : boolean := true;
    signal data_r             : std_logic_vector(23 downto 0) := (others => '0');
    signal data_right_valid_r : std_logic := '0';
    signal data_left_valid_r  : std_logic := '0';
    signal data_counter_r     : unsigned(6 downto 0) := (others => '1');
    signal data_sel_r         : std_logic := '0';
    signal source_right_r     : integer := 255;
    signal source_left_r      : integer := 255;

    signal right_valid_r      : std_logic := '0';
    signal left_valid_r       : std_logic := '0';
    signal read_counter_r     : unsigned(9 downto 0) := (others => '0');
    signal read_r             : std_logic := '0';
    signal max_left_r         : integer := 255;
    signal max_right_r        : integer := 255;

begin

    -- 12.288 MHz
    audio_clk_proc : process
    begin
        if (clk_en) then
            clk_audio <= '0';
            wait for 41 ns;
            clk_audio <= '1';
            wait for 41 ns;
        end if;
    end process audio_clk_proc;

    -- 50 MHz
    register_clk_proc : process
    begin
        if (clk_en) then
            clk_register <= '0';
            wait for 20 ns;
            clk_register <= '1';
            wait for 20 ns;
        end if;
    end process register_clk_proc;

    i_dut : meter
    generic map (
        data_width_g => 24)
    port map (
        audio_clk_i    => clk_audio,
        left_valid_i   => data_left_valid_r,
        right_valid_i  => data_right_valid_r,
        data_i         => data_r,
        register_clk_i => clk_register,
        data_read_l_i  => read_r,
        data_read_r_i  => read_r,
        level_l_o      => open,
        level_r_o      => open,
        level_strobe_o => open);

    data_gen_proc : process (clk_audio)
        variable seed1_v    : positive := 125;
        variable seed2_v    : positive := 54;
        variable rand_v     : real;
        variable level_db_v : real;
    begin
        if (rising_edge(clk_audio)) then
            data_counter_r <= data_counter_r + 1;
            data_right_valid_r <= '0';
            data_left_valid_r <= '0';
            if (data_counter_r = to_unsigned(0, data_counter_r'length)) then
                data_right_valid_r <= data_sel_r;
                data_left_valid_r <= not data_sel_r;
                data_sel_r <= not data_sel_r;
                uniform(seed1_v, seed2_v, rand_v);
                level_db_v := rand_v*128.0;
                report integer'image(integer(level_db_v));
                if (data_sel_r = '1') then
                    source_right_r <= integer(level_db_v*2.0);
                else
                    source_left_r <= integer(level_db_v*2.0);
                end if;
                data_r <= std_logic_vector(to_unsigned(integer(round((10.0**(-level_db_v/20.0))*((2.0**23)-1.0))), 24));
            end if;
        end if;
    end process data_gen_proc;

    data_read_proc : process (clk_register, clk_audio)
        variable seed1_v : positive := 222;
        variable seed2_v : positive := 587;
        variable rand_v  : real;
    begin
        if (rising_edge(clk_audio)) then
            left_valid_r <= data_left_valid_r;
            right_valid_r <= data_right_valid_r;
            if ((left_valid_r = '1') and (source_left_r < max_left_r)) then
                max_left_r <= source_left_r;
            end if;
            if ((right_valid_r = '1') and (source_right_r < max_right_r)) then
                max_right_r <= source_right_r;
            end if;
        end if;
        if (rising_edge(clk_register)) then
            read_counter_r <= read_counter_r + 1;
            read_r <= '0';
            if (read_counter_r = to_unsigned(0, read_counter_r'length)) then
                uniform(seed1_v, seed2_v, rand_v);
                if (rand_v > 0.8) then
                    read_r <= '1';
                end if;
            end if;
            if (read_r = '1') then
                max_left_r <= 255;
                max_right_r <= 255;
            end if;
        end if;
    end process data_read_proc;

end rtl;
