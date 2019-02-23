--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 10.02.2019
-- Filename  : crossfader_tb.vhd
-- Changelog : 10.02.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity crossfader_tb is
end entity crossfader_tb;

architecture rtl of crossfader_tb is

    component crossfader is
    generic (
        data_width_g : natural := 24);
    port (
        audio_clk_i       : in  std_logic;
        register_clk_i    : in  std_logic;
        -- audio in
        m_left_valid_i    : in  std_logic;
        m_right_valid_i   : in  std_logic;
        m_data_i          : in  std_logic_vector(data_width_g-1 downto 0);
        s_left_valid_i    : in  std_logic;
        s_right_valid_i   : in  std_logic;
        s_data_i          : in  std_logic_vector(data_width_g-1 downto 0);
        -- audio out
        left_valid_o      : out std_logic;
        right_valid_o     : out std_logic;
        data_o            : out std_logic_vector(data_width_g-1 downto 0);
        -- control
        m_level_valid_l_i : in  std_logic;
        m_level_valid_r_i : in  std_logic;
        m_level_l_i       : in  std_logic_vector(7 downto 0);
        m_level_r_i       : in  std_logic_vector(7 downto 0));
    end component crossfader;

    signal clk_audio    : std_logic := '0';
    signal clk_register : std_logic := '0';
    signal clk_en       : boolean := true;

    signal m_level_valid_l : std_logic := '0';
    signal m_level_valid_r : std_logic := '0';
    signal m_level_l       : std_logic_vector(7 downto 0) := (others => '0');
    signal m_level_r       : std_logic_vector(7 downto 0) := (others => '0');

    signal i2s_left_sel_r           : std_logic := '0';
    signal i2s_master_left_valid_r  : std_logic := '0';
    signal i2s_master_right_valid_r : std_logic := '0';
    signal i2s_master_data_r        : std_logic_vector(23 downto 0) := x"000000";
    signal i2s_slave_left_valid_r   : std_logic := '0';
    signal i2s_slave_right_valid_r  : std_logic := '0';
    signal i2s_slave_data_r         : std_logic_vector(23 downto 0) := (others => '0');
    signal i2s_counter_r            : unsigned(6 downto 0) := (others => '0');
    signal i2s_left_value_r         : std_logic_vector(23 downto 0) := x"800000";
    signal i2s_right_value_r        : std_logic_vector(23 downto 0) := x"7FFFFF";

    signal out_left_valid  : std_logic;
    signal out_right_valid : std_logic;
    signal out_data        : std_logic_vector(23 downto 0);
    signal result_left_r   : std_logic_vector(23 downto 0) := (others => '0');
    signal result_right_r  : std_logic_vector(23 downto 0) := (others => '0');

    signal enable_master : std_logic := '0';
    signal enable_slave  : std_logic := '0';

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

    i2s_proc : process (clk_audio)
    begin
        if (rising_edge(clk_audio)) then
            i2s_master_left_valid_r <= '0';
            i2s_master_right_valid_r <= '0';
            i2s_slave_left_valid_r <= '0';
            i2s_slave_right_valid_r <= '0';
            i2s_counter_r <= i2s_counter_r + 1;
            if (i2s_counter_r = to_unsigned(0, i2s_counter_r'length)) then
                i2s_left_sel_r <= not i2s_left_sel_r;
                if (i2s_left_sel_r = '1') then
                    if (enable_master = '1') then
                        i2s_master_data_r <= i2s_left_value_r;
                    else
                        i2s_master_data_r <= (others => '0');
                    end if;
                    if (enable_slave = '1') then
                        i2s_slave_data_r <= i2s_right_value_r;
                    else
                        i2s_slave_data_r <= (others => '0');
                    end if;
                else
                    if (enable_master = '1') then
                        i2s_master_data_r <= i2s_right_value_r;
                    else
                        i2s_master_data_r <= (others => '0');
                    end if;
                    if (enable_slave = '1') then
                        i2s_slave_data_r <= i2s_left_value_r;
                    else
                        i2s_slave_data_r <= (others => '0');
                    end if;
                end if;
                i2s_master_left_valid_r <= i2s_left_sel_r;
                i2s_master_right_valid_r <= not i2s_left_sel_r;
                i2s_slave_left_valid_r <= i2s_left_sel_r;
                i2s_slave_right_valid_r <= not i2s_left_sel_r;
            end if;
        end if;
    end process i2s_proc;

    i_dut : crossfader
    generic map (
        data_width_g => 24)
    port map (
        audio_clk_i       => clk_audio,
        register_clk_i    => clk_register,
        -- audio in
        m_left_valid_i    => i2s_master_left_valid_r,
        m_right_valid_i   => i2s_master_right_valid_r,
        m_data_i          => i2s_master_data_r,
        s_left_valid_i    => i2s_slave_left_valid_r,
        s_right_valid_i   => i2s_slave_right_valid_r,
        s_data_i          => i2s_slave_data_r,
        -- audio out
        left_valid_o      => out_left_valid,
        right_valid_o     => out_right_valid,
        data_o            => out_data,
        -- control
        m_level_valid_l_i => m_level_valid_l,
        m_level_valid_r_i => m_level_valid_r,
        m_level_l_i       => m_level_l,
        m_level_r_i       => m_level_r);

    result_proc : process (clk_audio)
    begin
        if (rising_edge(clk_audio)) then
            if (out_left_valid = '1') then
                result_left_r <= out_data;
            end if;
            if (out_right_valid = '1') then
                result_right_r <= out_data;
            end if;
        end if;
    end process result_proc;

    control_proc : process
    begin
        enable_slave <= '1';
        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_l <= std_logic_vector(to_unsigned(200, m_level_l'length));
        m_level_valid_l <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_l <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_r <= std_logic_vector(to_unsigned(200, m_level_r'length));
        m_level_valid_r <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_r <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_l <= std_logic_vector(to_unsigned(60, m_level_l'length));
        m_level_valid_l <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_l <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_r <= std_logic_vector(to_unsigned(60, m_level_r'length));
        m_level_valid_r <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_r <= '0';

        wait for 2 ms;
        wait until rising_edge(clk_register);
        enable_slave <= '0';
        enable_master <= '1';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_l <= std_logic_vector(to_unsigned(200, m_level_l'length));
        m_level_valid_l <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_l <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_r <= std_logic_vector(to_unsigned(200, m_level_r'length));
        m_level_valid_r <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_r <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_l <= std_logic_vector(to_unsigned(0, m_level_l'length));
        m_level_valid_l <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_l <= '0';

        wait for 1 ms;
        wait until rising_edge(clk_register);
        m_level_r <= std_logic_vector(to_unsigned(0, m_level_r'length));
        m_level_valid_r <= '1';
        wait until rising_edge(clk_register);
        m_level_valid_r <= '0';

        wait for 2 ms;
        clk_en <= false;
        wait;
    end process control_proc;

end rtl;
