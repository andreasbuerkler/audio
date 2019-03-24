--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 17.03.2019
-- Filename  : sinus_gen_tb.vhd
-- Changelog : 17.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity sinus_gen_tb is
end entity sinus_gen_tb;

architecture rtl of sinus_gen_tb is

    component sinus_gen is
    generic (
        data_width_g : natural);
    port (
        audio_clk_i    : in  std_logic;
        register_clk_i : in  std_logic;
        -- audio in
        request_i      : in  std_logic;
        -- audio out
        valid_o        : out std_logic;
        data_o         : out std_logic_vector(data_width_g-1 downto 0);
        -- control
        increment_i    : in  std_logic_vector(31 downto 0);
        change_i       : in  std_logic);
    end component sinus_gen;

    signal clk_audio    : std_logic := '0';
    signal clk_register : std_logic := '0';
    signal clk_en       : boolean := true;

    signal trigger_r         : std_logic := '0';
    signal trigger_counter_r : integer := 0;

    signal phase_r   : real := 0.0;
    signal sin_r     : std_logic_vector(23 downto 0);
    signal dut_valid : std_logic;
    signal dut_sin   : std_logic_vector(23 downto 0);
    signal diff_r    : std_logic_vector(23 downto 0);

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

    trigger_proc : process (clk_audio)
    begin
        if (rising_edge(clk_audio)) then
            if (trigger_counter_r = 255) then
                trigger_counter_r <= 0;
                trigger_r <= '1';
            else
                trigger_counter_r <= trigger_counter_r + 1;
                trigger_r <= '0';
            end if;
        end if;
    end process trigger_proc;

    i_dut : sinus_gen
    generic map (
        data_width_g => 24)
    port map (
        audio_clk_i    => clk_audio,
        register_clk_i => clk_register,
        -- audio in
        request_i      => trigger_r,
        -- audio out
        valid_o        => dut_valid,
        data_o         => dut_sin,
        -- control
        increment_i    => x"00400000",
        change_i       => '1');

    model_proc : process (clk_audio)
        variable phase_v : real := 0.0;
    begin
        if (rising_edge(clk_audio)) then
            if (trigger_r = '1') then
                phase_v := phase_r + (2.0*MATH_PI/(4096.0-8.0));
                phase_r <= phase_v;
                sin_r <= std_logic_vector(to_signed(integer(cos(phase_v)*((2.0**23.0)-1.0)), 24));
            end if;
            if (dut_valid = '1') then
                diff_r <= std_logic_vector(signed(dut_sin) - signed(sin_r));
            end if;
        end if;
    end process model_proc;

end rtl;
