--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 02.02.2020
-- Filename  : lcd_controller.vhd
-- Changelog : 02.02.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity lcd_controller is
generic (
    buffer_address_g         : std_logic_vector := x"00000000";
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
    ctrl_data_o       : out std_logic_vector(ctrl_data_width_g-1 downto 0);
    ctrl_burst_size_o : out std_logic_vector(log2ceil(ctrl_max_burst_size_g)-1 downto 0);
    ctrl_strobe_o     : out std_logic;
    ctrl_write_o      : out std_logic;
    ctrl_ack_i        : in  std_logic);
end entity lcd_controller;

architecture rtl of lcd_controller is

    component fifo_dual_clock
    generic (
        size_exp_g     : positive;
        data_width_g   : positive;
        almost_full_g  : positive;
        invert_full_g  : boolean;
        invert_empty_g : boolean);
    port (
        -- write port
        clk_w_i       : in  std_logic;
        data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i          : in  std_logic;
        full_o        : out std_logic;
        almost_full_o : out std_logic;
        -- read port
        clk_r_i       : in  std_logic;
        data_o        : out std_logic_vector(data_width_g-1 downto 0);
        rd_i          : in  std_logic;
        empty_o       : out std_logic);
    end component fifo_dual_clock;

    constant address_end_c : std_logic_vector(ctrl_address_width_g-1 downto 0) := std_logic_vector(unsigned(buffer_address_g)+ to_unsigned((image_width_g*image_height_g-ctrl_max_burst_size_g)*4, ctrl_address_width_g));

    signal buffer_sel_r       : std_logic_vector(framebuffer_count_g-1 downto 0) := std_logic_vector(to_unsigned(1, framebuffer_count_g));
    signal address_r          : std_logic_vector(ctrl_address_width_g-1 downto 0) := buffer_address_g;
    signal burst_size_r       : std_logic_vector(log2ceil(ctrl_max_burst_size_g)-1 downto 0) := (others => '0');
    signal strobe_r           : std_logic := '0';
    signal burst_counter_r    : unsigned(log2ceil(ctrl_max_burst_size_g) downto 0) := (others => '0');
    signal transfer_pending_r : std_logic := '0';

    signal fifo_read_data   : std_logic_vector(3*color_bits_g-1 downto 0);
    signal fifo_empty       : std_logic;
    signal fifo_full        : std_logic;

    signal enable_vec_r       : std_logic_vector(2 downto 0) := (others => '0');
    signal enable_timing_r    : std_logic := '0';
    signal timing_h_r         : std_logic_vector(3 downto 0) := "1000";
    signal timing_v_r         : std_logic_vector(3 downto 0) := "1000";
    signal timing_h_counter_r : unsigned(log2ceil(image_width_g)-1 downto 0) := (others => '0');
    signal timing_v_counter_r : unsigned(log2ceil(image_height_g)-1 downto 0) := (others => '0');
    signal hsync_pre_r        : std_logic := '0';
    signal hsync_r            : std_logic := '0';
    signal vsync_r            : std_logic := '0';
    signal de_pre_r           : std_logic := '0';
    signal de_r               : std_logic := '0';
    signal de_v_r             : std_logic := '0';

begin

    dma_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((fifo_full = '0') and (transfer_pending_r = '0') and (enable_i = '1')) then
                strobe_r <= '1';
                transfer_pending_r <= '1';
                burst_size_r <= std_logic_vector(to_unsigned(31, burst_size_r'length)); -- can be done with only using 32 word bursts (works for 320*240)
            else
                strobe_r <= '0';
            end if;

            if (transfer_pending_r = '1') then
                if (ctrl_ack_i = '1') then
                    burst_counter_r <= burst_counter_r + 1;
                elsif (burst_counter_r = (unsigned('0' & burst_size_r) + 1)) then
                    burst_counter_r <= (others => '0');
                    transfer_pending_r <= '0';
                    if (address_r >= address_end_c) then
                        address_r <= buffer_address_g;
                        buffer_sel_r <= buffer_sel_r xnor buffer_i;
                    else
                        address_r <= std_logic_vector(unsigned(address_r) + ((unsigned('0' & burst_size_r) + 1) & "00"));
                    end if;
                end if;
            end if;
        end if;
    end process dma_proc;

    i_fifo : fifo_dual_clock
    generic map (
        size_exp_g     => 10,
        data_width_g   => 3*color_bits_g,
        almost_full_g  => (2**10)-1-ctrl_max_burst_size_g,
        invert_full_g  => false,
        invert_empty_g => false)
    port map (
        -- write port
        clk_w_i       => clk_i,
        data_i        => ctrl_data_i(3*color_bits_g-1 downto 0),
        wr_i          => ctrl_ack_i,
        full_o        => open,
        almost_full_o => fifo_full,
        -- read port
        clk_r_i       => video_clk_i,
        data_o        => fifo_read_data,
        rd_i          => de_r,
        empty_o       => fifo_empty);

    enable_proc : process (video_clk_i)
    begin
        if (rising_edge(video_clk_i)) then
            enable_vec_r <= enable_vec_r(enable_vec_r'high-1 downto 0) & enable_i;
            if ((enable_vec_r(enable_vec_r'high) = '1') and (fifo_empty = '0')) then
                enable_timing_r <= '1';
            elsif ((enable_vec_r(enable_vec_r'high) = '0') and (fifo_empty = '1')) then
                enable_timing_r <= '0';
            end if;
        end if;
    end process enable_proc;

    timing_proc : process (video_clk_i)
    begin
        if (rising_edge(video_clk_i)) then
            -- horizontal timing
            if ((timing_h_r(0) = '1') and (timing_h_counter_r = horizontal_pulse_g-1)) then
                timing_h_counter_r <= to_unsigned(0, timing_h_counter_r'length);
                hsync_pre_r <= '1';
            elsif ((timing_h_r(1) = '1') and (timing_h_counter_r = horizontal_back_porch_g-1)) then
                timing_h_counter_r <= to_unsigned(0, timing_h_counter_r'length);
                de_pre_r <= de_v_r;
            elsif ((timing_h_r(2) = '1') and (timing_h_counter_r = image_width_g-1)) then
                timing_h_counter_r <= to_unsigned(0, timing_h_counter_r'length);
                de_pre_r <= '0';
            elsif ((timing_h_r(3) = '1') and (timing_h_counter_r = horizontal_front_porch_g-1)) then
                timing_h_counter_r <= to_unsigned(0, timing_h_counter_r'length);
                hsync_pre_r <= '0';
            elsif (enable_timing_r = '1') then
                timing_h_counter_r <= timing_h_counter_r + 1;
                if (timing_h_counter_r = to_unsigned(0, timing_h_counter_r'length)) then
                    timing_h_r <= timing_h_r(timing_h_r'high-1 downto 0) & timing_h_r(timing_h_r'high);
                end if;
            else
                hsync_pre_r <= '1';
                timing_h_r <= "0001";
                timing_h_counter_r <=  to_unsigned(0, timing_h_counter_r'length);
            end if;
            hsync_r <= hsync_pre_r;
            de_r <= de_pre_r;
            -- vertical timing
            if ((enable_timing_r = '1') and (timing_h_counter_r = 0) and (timing_h_r(3) = '1')) then
                if ((timing_v_r(0) = '1') and (timing_v_counter_r = vertical_pulse_g-1)) then
                    timing_v_counter_r <= to_unsigned(0, timing_v_counter_r'length);
                    vsync_r <= '1';
                elsif ((timing_v_r(1) = '1') and (timing_v_counter_r = vertical_back_porch_g-1)) then
                    timing_v_counter_r <= to_unsigned(0, timing_v_counter_r'length);
                    de_v_r <= '1';
                elsif ((timing_v_r(2) = '1') and (timing_v_counter_r = image_height_g-1)) then
                    timing_v_counter_r <= to_unsigned(0, timing_v_counter_r'length);
                    de_v_r <= '0';
                elsif ((timing_v_r(3) = '1') and (timing_v_counter_r = vertical_front_porch_g-1)) then
                    timing_v_counter_r <= to_unsigned(0, timing_v_counter_r'length);
                    vsync_r <= '0';
                else
                    timing_v_counter_r <= timing_v_counter_r + 1;
                end if;
                if (timing_v_counter_r = to_unsigned(0, timing_v_counter_r'length)) then
                    timing_v_r <= timing_v_r(timing_v_r'high-1 downto 0) & timing_v_r(timing_v_r'high);
                end if;
            elsif (enable_timing_r = '0') then
                vsync_r <= '1';
                timing_v_r <= "0001";
                timing_v_counter_r <=  to_unsigned(0, timing_v_counter_r'length);
            end if;
        end if;
    end process timing_proc;

    red_o <= fifo_read_data(3*color_bits_g-1 downto 2*color_bits_g);
    blue_o <= fifo_read_data(color_bits_g-1 downto 0);
    green_o <= fifo_read_data(2*color_bits_g-1 downto color_bits_g);
    hsync_o <= hsync_r;
    vsync_o <= vsync_r;
    de_o <= de_r;
    pclk_o <= not video_clk_i;

    buffer_o <= buffer_sel_r;
    ctrl_address_o <= address_r;
    ctrl_burst_size_o <= burst_size_r;
    ctrl_strobe_o <= strobe_r;
    ctrl_data_o <= (others => '0');
    ctrl_write_o <= '0';

end rtl;
