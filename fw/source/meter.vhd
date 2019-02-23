--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : meter.vhd
-- Changelog : 07.10.2018 - file created
--             12.01.2018 - clock converter added
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity meter is
generic (
    data_width_g : natural := 24);
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
end entity meter;

architecture rtl of meter is

    component log_cos_data_rom is
    generic (
        data_width_g : natural);
    port (
        clk_i     : in  std_logic;
        address_i : in  std_logic_vector(7 downto 0);
        data_o    : out std_logic_vector(data_width_g-1 downto 0));
    end component log_cos_data_rom;

    component clock_converter is
    generic (
        data_width_g : natural;
        channels_g   : natural := 2);
    port (
        in_clk_i  : in  std_logic;
        valid_i   : in  std_logic_vector(channels_g-1 downto 0);
        data_i    : in  std_logic_vector(data_width_g-1 downto 0);
        out_clk_i : in  std_logic;
        valid_o   : out std_logic_vector(channels_g-1 downto 0);
        data_o    : out std_logic_vector(data_width_g-1 downto 0));
    end component clock_converter;

    signal data_in_abs_r         : signed(data_width_g-1 downto 0) := (others => '0');
    signal data_in_abs_l_valid_r : std_logic := '0';
    signal data_in_abs_r_valid_r : std_logic := '0';

    signal left_max_r       : unsigned(data_width_g-1 downto 0) := (others => '0');
    signal right_max_r      : unsigned(data_width_g-1 downto 0) := (others => '0');
    signal lookup_address_r : std_logic_vector(7 downto 0) := (others => '0');
    signal compare_value    : std_logic_vector(data_width_g-1 downto 0);
    signal compare_level_r  : unsigned(7 downto 0) := (others => '0');
    signal level_l_r        : unsigned(7 downto 0) := (others => '0');
    signal level_r_r        : unsigned(7 downto 0) := (others => '0');
    signal level_out_l_r    : std_logic_vector(7 downto 0) := (others => '0');
    signal level_out_r_r    : std_logic_vector(7 downto 0) := (others => '0');
    signal level_strobe_r   : std_logic := '0';

    signal cc_in            : std_logic_vector(15 downto 0);
    signal cc_out           : std_logic_vector(15 downto 0);
    signal cc_strb          : std_logic;
    signal read_l_toggle_r  : std_logic := '0';
    signal read_r_toggle_r  : std_logic := '0';
    signal toggle_l_cc_r    : std_logic_vector(3 downto 0) := (others => '0');
    signal toggle_r_cc_r    : std_logic_vector(3 downto 0) := (others => '0');
    signal read_l_r         : std_logic := '0';
    signal read_r_r         : std_logic := '0';

begin

    abs_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            if (data_i(data_i'high) = '1') then
                data_in_abs_r <= - signed(data_i);
            else
                data_in_abs_r <= signed(data_i);
            end if;
            data_in_abs_l_valid_r <= left_valid_i;
            data_in_abs_r_valid_r <= right_valid_i;
        end if;
    end process abs_proc;

    input_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then

            if (read_l_r = '1') then
                left_max_r <= (others => '0');
            elsif (data_in_abs_l_valid_r = '1') then
                if (signed(std_logic_vector(left_max_r)) < data_in_abs_r) then
                    left_max_r <= unsigned(std_logic_vector(data_in_abs_r));
                end if;
            end if;

            if (read_r_r = '1') then
                right_max_r <= (others => '0');
            elsif (data_in_abs_r_valid_r = '1') then
                if (signed(std_logic_vector(right_max_r)) < data_in_abs_r) then
                    right_max_r <= unsigned(std_logic_vector(data_in_abs_r));
                end if;
            end if;

        end if;
    end process input_proc;

    i_rom : log_cos_data_rom
    generic map (
        data_width_g => data_width_g)
    port map (
        clk_i     => audio_clk_i,
        address_i => lookup_address_r,
        data_o    => compare_value);

    address_delay_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            compare_level_r <= unsigned(lookup_address_r);
        end if;
    end process address_delay_proc;

    compare_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            if (lookup_address_r = std_logic_vector(to_unsigned(199, lookup_address_r'length))) then
                lookup_address_r <= (others => '0');
            else
                lookup_address_r <= std_logic_vector(unsigned(lookup_address_r) + 1);
            end if;

            if (compare_level_r = to_unsigned(199, compare_level_r'length)) then
                level_l_r <= (others => '0');
                level_r_r <= (others => '0');
                level_out_l_r <= std_logic_vector(level_l_r);
                level_out_r_r <= std_logic_vector(level_r_r);
                level_strobe_r <= '1';
            else
                if (unsigned(compare_value) > left_max_r) then
                    level_l_r <= compare_level_r;
                end if;
                if (unsigned(compare_value) > right_max_r) then
                    level_r_r <= compare_level_r;
                end if;
                level_strobe_r <= '0';
            end if;

        end if;
    end process compare_proc;

    cc_in <= level_out_l_r & level_out_r_r;

    read_cc_register_proc : process (register_clk_i)
    begin
        if (rising_edge(register_clk_i)) then
            if (data_read_l_i = '1') then
                read_l_toggle_r <= not read_l_toggle_r;
            end if;
            if (data_read_r_i = '1') then
                read_r_toggle_r <= not read_r_toggle_r;
            end if;
        end if;
    end process;

    read_cc_audio_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            toggle_l_cc_r <= toggle_l_cc_r(toggle_l_cc_r'high-1 downto 0) & read_l_toggle_r;
            toggle_r_cc_r <= toggle_r_cc_r(toggle_r_cc_r'high-1 downto 0) & read_r_toggle_r;
            read_l_r <= toggle_l_cc_r(toggle_l_cc_r'high) xor toggle_l_cc_r(toggle_l_cc_r'high-1);
            read_r_r <= toggle_r_cc_r(toggle_r_cc_r'high) xor toggle_r_cc_r(toggle_r_cc_r'high-1);
        end if;
    end process read_cc_audio_proc;

    i_cc : clock_converter
    generic map (
        data_width_g => 16,
        channels_g   => 1)
    port map (
        in_clk_i   => audio_clk_i,
        valid_i(0) => level_strobe_r,
        data_i     => cc_in,
        out_clk_i  => register_clk_i,
        valid_o(0) => cc_strb,
        data_o     => cc_out);

    level_l_o <= cc_out(15 downto 8);
    level_r_o <= cc_out(7 downto 0);
    level_strobe_o <= cc_strb;

end rtl;
