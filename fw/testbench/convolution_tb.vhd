--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.03.2019
-- Filename  : convolution_tb.vhd
-- Changelog : 03.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;
use work.step_response_pkg.all;

entity convolution_tb is
end entity convolution_tb;

architecture rtl of convolution_tb is

    type mem_t is array(natural range <>) of std_logic_vector(23 downto 0);

    function convert_init_data(inarray : std_logic_array) return mem_t is
        variable data_v : mem_t((2**9)-1 downto 0);
    begin
        for i in (2**9)-1 downto 0 loop
            for j in 23 downto 0 loop
                data_v(i)(j) := inarray(i, j);
            end loop;
        end loop;
        return data_v;
    end function convert_init_data;

    component convolution is
    generic (
        data_width_g : natural := 24);
    port (
        audio_clk_i    : in  std_logic;
        register_clk_i : in  std_logic;
        -- audio in
        left_valid_i   : in  std_logic;
        right_valid_i  : in  std_logic;
        data_i         : in  std_logic_vector(data_width_g-1 downto 0);
        -- audio out
        left_valid_o   : out std_logic;
        right_valid_o  : out std_logic;
        data_o         : out std_logic_vector(data_width_g-1 downto 0);
        -- control
        address_i      : in  std_logic_vector(8 downto 0);
        coeff_i        : in  std_logic_vector(31 downto 0);
        wr_en_i        : in  std_logic);
    end component convolution;

    constant coeff_c : mem_t := convert_init_data(step_response_c);

    type calc_array is array (natural range <>) of signed(52 downto 0);
        
    signal clk_audio    : std_logic := '0';
    signal clk_register : std_logic := '0';
    signal clk_en       : boolean := true;

    signal i2s_left_sel_r    : std_logic := '0';
    signal i2s_left_valid_r  : std_logic := '0';
    signal i2s_right_valid_r : std_logic := '0';
    signal i2s_data_r        : std_logic_vector(23 downto 0) := x"000000";
    signal i2s_counter_r     : unsigned(8 downto 0) := (others => '0');
    signal i2s_left_value_r  : std_logic_vector(23 downto 0) := x"800000";
    signal i2s_right_value_r : std_logic_vector(23 downto 0) := x"7FFFFF";

    signal out_left_valid  : std_logic;
    signal out_right_valid : std_logic;
    signal out_data        : std_logic_vector(23 downto 0);
    signal result_left_r   : std_logic_vector(23 downto 0) := (others => '0');
    signal result_right_r  : std_logic_vector(23 downto 0) := (others => '0');

    signal left_calc_vec_r  : calc_array(511 downto 0) := (others => (others => '0'));
    signal right_calc_vec_r : calc_array(511 downto 0) := (others => (others => '0'));
    signal model_left_r     : std_logic_vector(23 downto 0) := (others =>'0');
    signal model_right_r    : std_logic_vector(23 downto 0) := (others =>'0');

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
            i2s_left_valid_r <= '0';
            i2s_right_valid_r <= '0';
            i2s_counter_r <= i2s_counter_r + 1;
            if (i2s_counter_r = to_unsigned(0, i2s_counter_r'length)) then
                i2s_left_sel_r <= not i2s_left_sel_r;
                if (i2s_left_sel_r = '1') then
                    i2s_data_r <= i2s_left_value_r;
                else
                    i2s_data_r <= i2s_right_value_r;
                end if;
                i2s_left_valid_r <= i2s_left_sel_r;
                i2s_right_valid_r <= not i2s_left_sel_r;
            end if;
        end if;
    end process i2s_proc;

    i_dut : convolution
    generic map (
        data_width_g => 24)
    port map (
        audio_clk_i    => clk_audio,
        register_clk_i => clk_register,
        -- audio in
        left_valid_i   => i2s_left_valid_r,
        right_valid_i  => i2s_right_valid_r,
        data_i         => i2s_data_r,
        -- audio out
        left_valid_o   => out_left_valid,
        right_valid_o  => out_right_valid,
        data_o         => out_data,
        -- control
        address_i      => "000000000",
        coeff_i        => x"00000000",
        wr_en_i        => '0');

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

    model_proc : process (clk_audio)
    begin
        if (rising_edge(clk_audio)) then
            if (i2s_left_valid_r = '1') then
                for i in 0 to 460 loop
                    left_calc_vec_r(i) <= left_calc_vec_r(i+1) + resize(signed(i2s_data_r) * signed(coeff_c(i)), 52);
                end loop;
            end if;
            if (i2s_right_valid_r = '1') then
                for i in 0 to 460 loop
                    right_calc_vec_r(i) <= right_calc_vec_r(i+1) + resize(signed(i2s_data_r) * signed(coeff_c(i)), 52);
                end loop;
            end if;
            model_left_r <= std_logic_vector(left_calc_vec_r(0)(46 downto 23));
            model_right_r <= std_logic_vector(right_calc_vec_r(0)(46 downto 23));
        end if;
    end process model_proc;

    check_proc : process (clk_audio)
    begin
        if (rising_edge(clk_audio)) then
            if (out_left_valid = '1') then
                assert (out_data = model_left_r) report "left channel wrong" severity error;
            end if;
            if (out_right_valid = '1') then
                assert (out_data = model_right_r) report "right channel wrong" severity error;
            end if;
        end if;
    end process check_proc;

end rtl;
