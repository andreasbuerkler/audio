--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 17.03.2019
-- Filename  : sinus_gen.vhd
-- Changelog : 17.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity sinus_gen is
generic (
    data_width_g : natural := 24);
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
end entity sinus_gen;

architecture rtl of sinus_gen is

    component clock_converter is
    generic (
        data_width_g : natural;
        channels_g   : natural);
    port (
        in_clk_i      : in  std_logic;
        valid_i       : in  std_logic_vector(channels_g-1 downto 0);
        data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        out_clk_i     : in  std_logic;
        valid_o       : out std_logic_vector(channels_g-1 downto 0);
        data_o        : out std_logic_vector(data_width_g-1 downto 0));
    end component clock_converter;

    type lookup_array_t   is array (natural range <>) of std_logic_vector(data_width_g-1 downto 0);

    function init_lookup_table_f (number_of_samples : in positive)
        return lookup_array_t is
        variable lookup_array_v : lookup_array_t(number_of_samples-1 downto 0);
        variable cos_v          : real;
    begin
        for i in 0 to number_of_samples-1 loop
            cos_v := cos(MATH_PI_OVER_2*real(i)/(real(number_of_samples-1)));
            lookup_array_v(i) := std_logic_vector(to_unsigned(integer(round(cos_v*((2.0**(data_width_g-1))-1.0))), data_width_g));
        end loop;
        return lookup_array_v;
    end init_lookup_table_f;

    constant number_of_samples_c : positive := 512;
    constant lookup_cos_c        : lookup_array_t(number_of_samples_c-1 downto 0) := init_lookup_table_f(number_of_samples_c);
    constant max_gradient_c      : integer := to_integer(unsigned(lookup_cos_c(number_of_samples_c-2)) - unsigned(lookup_cos_c(number_of_samples_c-1)));
    constant gradient_width_c    : integer := log2ceil(max_gradient_c) + 1;
    constant sin_factor_c        : real := real(max_gradient_c) / real(2**(gradient_width_c-1));
    constant sin_mult_c          : signed(gradient_width_c-1 downto 0) := to_signed(integer(real(2**(gradient_width_c-1))*sin_factor_c), gradient_width_c);

    signal increment_cc       : std_logic_vector(31 downto 0);
    signal lookup_value_r     : std_logic_vector(data_width_g-1 downto 0) := lookup_cos_c(0);
    signal address_r          : std_logic_vector(log2ceil(number_of_samples_c)-1 downto 0) := (others => '0');
    signal phase_r            : std_logic_vector(31 downto 0) := (others => '0');
    signal quadrant_r         : std_logic_vector(1 downto 0) := (others => '0');
    signal quadrant2_r        : std_logic_vector(1 downto 0) := (others => '0');
    signal quadrant3_r        : std_logic_vector(1 downto 0) := (others => '0');
    signal sin_r              : std_logic_vector(data_width_g-1 downto 0) := lookup_cos_c(0);
    signal address_invert_r   : std_logic := '0';
    signal strb_vec_r         : std_logic_vector(8 downto 0) := (others => '0');
    signal cos_r              : std_logic_vector(gradient_width_c-1 downto 0) := (others => '0');
    signal cos_raw_r          : std_logic_vector(gradient_width_c-1 downto 0) := (others => '0');
    signal mul_a              : signed(gradient_width_c-1 downto 0);
    signal mul_b              : signed(gradient_width_c-1 downto 0);
    signal mul_r              : std_logic_vector(2*gradient_width_c-1 downto 0) := (others => '0');
    signal sin_interpolated_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

begin

    i_cc : clock_converter
    generic map (
        data_width_g => increment_i'length,
        channels_g   => 1)
    port map (
        in_clk_i     => register_clk_i,
        valid_i(0)   => change_i,
        data_i       => increment_i,
        out_clk_i    => audio_clk_i,
        valid_o      => open,
        data_o       => increment_cc);

    phase_proc : process (audio_clk_i)
        variable phase_v : std_logic_vector(31 downto 0);
    begin
        if (rising_edge(audio_clk_i)) then
            if (request_i = '1') then
                phase_v := std_logic_vector(unsigned(phase_r) + unsigned(increment_cc));
                if ((phase_r(phase_r'high) = '1') and (phase_v(phase_v'high) = '0')) then
                    quadrant_r <= std_logic_vector(unsigned(quadrant_r) + 1);
                    phase_r <= std_logic_vector(unsigned(phase_v) + to_unsigned(2**(phase_r'high+1-address_r'length), phase_r'length));
                else
                    phase_r <= phase_v;
                end if;
            end if;
            strb_vec_r(0) <= request_i;
            address_invert_r <= (not address_invert_r) or request_i;
        end if;
    end process phase_proc;

    address_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            quadrant2_r <= quadrant_r;
            strb_vec_r(1) <= strb_vec_r(0);
            if (address_invert_r = '1') then
                address_r <= std_logic_vector(to_unsigned(number_of_samples_c-1, address_r'length) - unsigned(phase_r(phase_r'high downto phase_r'high-address_r'length+1)));
            else
                address_r <= phase_r(phase_r'high downto phase_r'high-address_r'length+1);
            end if;
        end if;
    end process address_proc;

    rom_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            quadrant3_r <= quadrant2_r;
            strb_vec_r(2) <= strb_vec_r(1);
            lookup_value_r <= lookup_cos_c(to_integer(unsigned(address_r)));
        end if;
    end process rom_proc;

    mul_a <= signed(cos_raw_r) when (strb_vec_r(6) /= '1') else
             signed(cos_r);
    mul_b <= sin_mult_c when (strb_vec_r(6) /= '1') else
             signed('0' & phase_r(phase_r'high-address_r'length downto phase_r'high-address_r'length-gradient_width_c+2));

    mul_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            mul_r <= std_logic_vector(mul_a * mul_b);
        end if;
    end process mul_proc;

    quad_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            strb_vec_r(3) <= strb_vec_r(2);
            strb_vec_r(4) <= strb_vec_r(3);
            strb_vec_r(5) <= strb_vec_r(4);
            strb_vec_r(6) <= strb_vec_r(5);
            strb_vec_r(7) <= strb_vec_r(6);
            strb_vec_r(8) <= strb_vec_r(7);

            case (quadrant3_r) is
                when "00"   =>
                    if (strb_vec_r(2) = '1') then
                        cos_raw_r <= std_logic_vector(to_unsigned(0, gradient_width_c) - unsigned(lookup_value_r(lookup_value_r'high downto lookup_value_r'high-gradient_width_c+1)));
                    end if;
                    if (strb_vec_r(4) = '1') then
                        cos_r <= mul_r(mul_r'high-1 downto mul_r'high-gradient_width_c);
                    end if;
                    if (strb_vec_r(3) = '1') then
                        sin_r <= lookup_value_r;
                    end if;

                when "01"   =>
                    if (strb_vec_r(3) = '1') then
                        cos_raw_r <= std_logic_vector(to_unsigned(0, gradient_width_c) - unsigned(lookup_value_r(lookup_value_r'high downto lookup_value_r'high-gradient_width_c+1)));
                    end if;
                    if (strb_vec_r(5) = '1') then
                        cos_r <= mul_r(mul_r'high-1 downto mul_r'high-gradient_width_c);
                    end if;
                    if (strb_vec_r(4) = '1') then
                        sin_r <= std_logic_vector(to_unsigned(0, data_width_g) - unsigned(lookup_value_r));
                    end if;

                when "10"   =>
                    if (strb_vec_r(2) = '1') then
                        cos_raw_r <= lookup_value_r(lookup_value_r'high downto lookup_value_r'high-gradient_width_c+1);
                    end if;
                    if (strb_vec_r(4) = '1') then
                        cos_r <= mul_r(mul_r'high-1 downto mul_r'high-gradient_width_c);
                    end if;
                    if (strb_vec_r(3) = '1') then
                        sin_r <= std_logic_vector(to_unsigned(0, data_width_g) - unsigned(lookup_value_r));
                    end if;

                when others =>
                    if (strb_vec_r(3) = '1') then
                        cos_raw_r <= lookup_value_r(lookup_value_r'high downto lookup_value_r'high-gradient_width_c+1);
                    end if;
                    if (strb_vec_r(5) = '1') then
                        cos_r <= mul_r(mul_r'high-1 downto mul_r'high-gradient_width_c);
                    end if;
                    if (strb_vec_r(4) = '1') then
                        sin_r <= lookup_value_r;
                    end if;

            end case;

            if (strb_vec_r(7) = '1') then
                sin_interpolated_r <= std_logic_vector(signed(sin_r) + resize(signed(mul_r(mul_r'high-1 downto mul_r'high-gradient_width_c)), sin_interpolated_r'length));
            end if;

        end if;
    end process quad_proc;

    valid_o <= strb_vec_r(8);
    data_o <= sin_interpolated_r;

end rtl;
