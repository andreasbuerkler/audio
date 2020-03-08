--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 02.02.2020
-- Filename  : lcd_controller_tb.vhd
-- Changelog : 02.02.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity lcd_controller_tb is
end entity lcd_controller_tb;

architecture rtl of lcd_controller_tb is

    component lcd_controller
    generic (
        ctrl_data_width_g        : positive := 32;
        ctrl_address_width_g     : positive := 32;
        ctrl_max_burst_size_g    : positive := 32;
        framebuffer_count_g      : positive := 3;
        color_bits_g             : positive := 4;
        image_width_g            : positive := 320;
        image_height_g           : positive := 240;
        vertical_front_porch_g   : positive := 4;
        vertical_back_porch_g    : positive := 16;
        vertical_pulse_g         : positive := 2;
        horizontal_front_porch_g : positive := 20;
        horizontal_back_porch_g  : positive := 66;
        horizontal_pulse_g       : positive := 2);
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        enable_i          : in  std_logic;
        video_clk_i       : in  std_logic;
        -- lcd
        red_o             : out std_logic_vector(color_bits_g-1 downto 0);
        blue_o            : out std_logic_vector(color_bits_g-1 downto 0);
        green_o           : out std_logic_vector(color_bits_g-1 downto 0);
        hsync_o           : out std_logic;
        vsync_o           : out std_logic;
        de_o              : out std_logic;
        pclk_o            : out std_logic;
        -- frame buffer
        buffer_i          : in  std_logic_vector(framebuffer_count_g-1 downto 0);
        buffer_o          : out std_logic_vector(framebuffer_count_g-1 downto 0);
        ctrl_address_o    : out std_logic_vector(ctrl_address_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(ctrl_data_width_g-1 downto 0);
        ctrl_burst_size_o : out std_logic_vector(log2ceil(ctrl_max_burst_size_g) downto 0);
        ctrl_strobe_o     : out std_logic;
        ctrl_ack_i        : in  std_logic);
    end component lcd_controller;

    signal clk_register : std_logic := '0';
    signal clk_video    : std_logic := '0';
    signal clk_en       : boolean := true;

    signal ctrl_address    : std_logic_vector(31 downto 0);
    signal ctrl_data_r     : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_burst_size : std_logic_vector(5 downto 0);
    signal ctrl_strobe     : std_logic;
    signal ctrl_ack_r      : std_logic := '0';

    signal burst_counter_r : unsigned(5 downto 0) := (others => '0');

begin

    -- 20 MHz
    video_clk_proc : process
    begin
        if (clk_en) then
            clk_video <= '0';
            wait for 25 ns;
            clk_video <= '1';
            wait for 25 ns;
        end if;
    end process video_clk_proc;

    -- 50 MHz
    register_clk_proc : process
    begin
        if (clk_en) then
            clk_register <= '0';
            wait for 10 ns;
            clk_register <= '1';
            wait for 10 ns;
        end if;
    end process register_clk_proc;

    i_dut : lcd_controller
    generic map (
        ctrl_data_width_g        => 32,
        ctrl_address_width_g     => 32,
        ctrl_max_burst_size_g    => 32,
        framebuffer_count_g      => 3,
        color_bits_g             => 4,
        image_width_g            => 320,
        image_height_g           => 240,
        vertical_front_porch_g   => 4,
        vertical_back_porch_g    => 16,
        vertical_pulse_g         => 2,
        horizontal_front_porch_g => 20,
        horizontal_back_porch_g  => 66,
        horizontal_pulse_g       => 2)
    port map (
        clk_i             => clk_register,
        reset_i           => '0',
        enable_i          => '1',
        video_clk_i       => clk_video,
        -- lcd
        red_o             => open,
        blue_o            => open,
        green_o           => open,
        hsync_o           => open,
        vsync_o           => open,
        de_o              => open,
        pclk_o            => open,
        -- frame buffer
        buffer_i          => "010",
        buffer_o          => open,
        ctrl_address_o    => ctrl_address,
        ctrl_data_i       => ctrl_data_r,
        ctrl_burst_size_o => ctrl_burst_size,
        ctrl_strobe_o     => ctrl_strobe,
        ctrl_ack_i        => ctrl_ack_r);

    mem_proc : process (clk_register)
    begin
        if (rising_edge(clk_register)) then
            ctrl_ack_r <= '0';
            if (ctrl_strobe = '1') then
                burst_counter_r <= unsigned(ctrl_burst_size);
                ctrl_data_r <= std_logic_vector(unsigned(ctrl_address) - 1);
            elsif (burst_counter_r /= 0) then
                burst_counter_r <= burst_counter_r - 1;
                ctrl_ack_r <= '1';
                ctrl_data_r <= std_logic_vector(unsigned(ctrl_data_r) + 1);
            end if;
        end if;
    end process mem_proc;

end rtl;
