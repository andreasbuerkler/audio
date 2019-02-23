--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 10.02.2019
-- Filename  : crossfader.vhd
-- Changelog : 10.02.2019 - file created
--------------------------------------------------------------------------------
-- level input   0 = 0dB
--             199 = -100 dB
--             200 = mute
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity crossfader is
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
end entity crossfader;

architecture rtl of crossfader is

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

    constant zero_c : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    constant one_c  : std_logic_vector(data_width_g-1 downto 0) := std_logic_vector(to_unsigned(2**(data_width_g-1)-1, data_width_g));

    signal level_cc_left        : std_logic_vector(7 downto 0);
    signal level_cc_right       : std_logic_vector(7 downto 0);
    signal level_cc_left_valid  : std_logic;
    signal level_cc_right_valid : std_logic;

    signal address_mux         : std_logic_vector(7 downto 0);
    signal cos_address_r       : std_logic_vector(8 downto 0) := (others => '1');
    signal address_right_r     : std_logic_vector(7 downto 0) := (others => '0');
    signal address_left_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal old_address_right_r : std_logic_vector(7 downto 0) := (others => '0');
    signal old_address_left_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal lookup_address_r    : std_logic_vector(7 downto 0) := (others => '0');
    signal lookup_value        : std_logic_vector(data_width_g-1 downto 0);

    signal new_level_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal old_level_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

    signal master_value_r      : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal slave_value_right_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal slave_value_left_r  : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

    signal sub_a_mux      : std_logic_vector(data_width_g-1 downto 0);
    signal sub_b_mux      : std_logic_vector(data_width_g-1 downto 0);
    signal mul_mux        : std_logic_vector(data_width_g-1 downto 0);
    signal add_mux        : std_logic_vector(data_width_g-1 downto 0);
    signal sub_r          : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal mul_r          : std_logic_vector(2*data_width_g-1 downto 0) := (others => '0');
    signal add_r          : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal value_result_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal gain_result_r  : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

    signal calc_gain_r              : std_logic := '0';
    signal calc_master_value_r      : std_logic := '0';
    signal calc_slave_value_right_r : std_logic := '0';
    signal calc_slave_value_left_r  : std_logic := '0';
    signal store_value_result_r     : std_logic := '0';
    signal store_gain_result_r      : std_logic := '0';
    signal store_old_level_r        : std_logic := '0';
    signal store_new_level_r        : std_logic := '0';
    signal load_old_left_address_r  : std_logic := '0';
    signal load_left_address_r      : std_logic := '0';
    signal load_old_right_address_r : std_logic := '0';
    signal load_right_address_r     : std_logic := '0';
    signal slave_address_sel_r      : std_logic := '0';

    signal action_counter_r      : unsigned(5 downto 0) := (others => '1');
    signal channel_left_select_r : std_logic := '0';
    signal left_valid_r          : std_logic := '0';
    signal right_valid_r         : std_logic := '0';
    signal fade_in_progress_r    : std_logic := '0';
    signal level_has_changed_r   : std_logic := '0';
    signal load_next_level_r     : std_logic := '0';

begin

    i_cc_left : clock_converter
    generic map (
        data_width_g => 8,
        channels_g   => 1)
    port map (
        in_clk_i   => register_clk_i,
        valid_i(0) => m_level_valid_l_i,
        data_i     => m_level_l_i,
        out_clk_i  => audio_clk_i,
        valid_o(0) => level_cc_left_valid,
        data_o     => level_cc_left);

    i_cc_right : clock_converter
    generic map (
        data_width_g => 8,
        channels_g   => 1)
    port map (
        in_clk_i   => register_clk_i,
        valid_i(0) => m_level_valid_r_i,
        data_i     => m_level_r_i,
        out_clk_i  => audio_clk_i,
        valid_o(0) => level_cc_right_valid,
        data_o     => level_cc_right);

    i_rom : log_cos_data_rom
    generic map (
        data_width_g => data_width_g)
    port map (
        clk_i     => audio_clk_i,
        address_i => lookup_address_r,
        data_o    => lookup_value);

    reg_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            if ((m_left_valid_i = '1') or (m_right_valid_i = '1')) then
                master_value_r <= m_data_i;
            end if;
            if (s_right_valid_i = '1') then
                slave_value_right_r <= s_data_i;
            end if;
            if (s_left_valid_i = '1') then
                slave_value_left_r <= s_data_i;
            end if;
            if (load_next_level_r = '1') then
                address_left_r <= level_cc_left;
                old_address_left_r <= address_left_r;
            end if;
            if (load_next_level_r = '1') then
                address_right_r <= level_cc_right;
                old_address_right_r <= address_right_r;
            end if;
            if (store_gain_result_r = '1') then
                gain_result_r <= add_r;
            end if;
            if (store_value_result_r = '1') then
                value_result_r <= add_r;
            end if;
            if (store_new_level_r = '1') then
                new_level_r <= lookup_value;
            end if;
            if (store_old_level_r = '1') then
                old_level_r <= lookup_value;
            end if;
            if (slave_address_sel_r = '1') then
                lookup_address_r <= std_logic_vector(to_unsigned(200, lookup_address_r'length) - unsigned(address_mux));
            else
                lookup_address_r <= address_mux;
            end if;
        end if;
    end process reg_proc;

    address_mux <= old_address_right_r when (load_old_right_address_r = '1') else
                   old_address_left_r when (load_old_left_address_r = '1') else
                   address_right_r when (load_right_address_r = '1') else
                   address_left_r when (load_left_address_r = '1') else
                   cos_address_r(cos_address_r'high downto 1);

    sub_a_mux <= new_level_r when (calc_gain_r = '1') else
                 gain_result_r;

    sub_b_mux <= old_level_r when (calc_gain_r = '1') else
                 zero_c;

    mul_mux <= slave_value_right_r when (calc_slave_value_right_r = '1') else
               slave_value_left_r when (calc_slave_value_left_r = '1') else
               master_value_r when (calc_master_value_r = '1') else
               lookup_value;

    add_mux <= old_level_r when (calc_gain_r = '1') else
               value_result_r when (calc_master_value_r = '1') else
               zero_c;

    dsp_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            sub_r <= std_logic_vector(signed(sub_a_mux) - signed(sub_b_mux));
            mul_r <= std_logic_vector(signed(sub_r) * signed(mul_mux));
            add_r <= std_logic_vector(signed(mul_r(mul_r'high-1 downto data_width_g-1)) + signed(add_mux));
        end if;
    end process dsp_proc;

    control_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            load_old_left_address_r <= '0';
            load_old_right_address_r <= '0';
            load_left_address_r <= '0';
            load_right_address_r <= '0';
            store_old_level_r <= '0';
            store_new_level_r <='0';
            calc_gain_r <= '0';
            store_gain_result_r <= '0';
            calc_slave_value_right_r <= '0';
            calc_slave_value_left_r <= '0';
            store_value_result_r <= '0';
            calc_master_value_r <= '0';
            left_valid_r <= '0';
            right_valid_r <= '0';
            slave_address_sel_r <= '0';

            -- start calculation
            if ((m_left_valid_i = '1') or (m_right_valid_i = '1')) then
                action_counter_r <= (others => '0');
                channel_left_select_r <= m_left_valid_i;
            end if;
            if (action_counter_r(action_counter_r'high) = '0') then
                action_counter_r <= action_counter_r + 1;
            end if;

            ----------------------------------------------------------------------------------------

            -- load slave level
            if (action_counter_r = to_unsigned(0, action_counter_r'length)) then
                slave_address_sel_r <= '1';
                if (channel_left_select_r = '1') then
                    load_old_left_address_r <= '1';
                else
                    load_old_right_address_r <= '1';
                end if;
            end if;
            if (action_counter_r = to_unsigned(1, action_counter_r'length)) then
                slave_address_sel_r <= '1';
                if (channel_left_select_r = '1') then
                    load_left_address_r <= '1';
                else
                    load_right_address_r <= '1';
                end if;
            end if;
            -- store slave level
            if (action_counter_r = to_unsigned(2, action_counter_r'length)) then
                store_old_level_r <= '1';
            end if;
            if (action_counter_r = to_unsigned(3, action_counter_r'length)) then
                store_new_level_r <= '1';
            end if;

            ----------------------------------------------------------------------------------------

            -- calculate slave gain
            if ((action_counter_r = to_unsigned(4, action_counter_r'length)) or
                (action_counter_r = to_unsigned(6, action_counter_r'length))) then
                calc_gain_r <= '1';
            end if;
            -- store slave gain
            if (action_counter_r = to_unsigned(7, action_counter_r'length)) then
                store_gain_result_r <= '1';
            end if;
            -- calculate slave
            if ((action_counter_r = to_unsigned(9, action_counter_r'length))) then
                if (channel_left_select_r = '1') then
                    calc_slave_value_left_r <= '1';
                else
                    calc_slave_value_right_r <= '1';
                end if;
            end if;
            -- store slave result
            if (action_counter_r = to_unsigned(11, action_counter_r'length)) then
                store_value_result_r <= '1';
            end if;

            ----------------------------------------------------------------------------------------

            -- load master level
            if (action_counter_r = to_unsigned(8, action_counter_r'length)) then
                if (channel_left_select_r = '1') then
                    load_old_left_address_r <= '1';
                else
                    load_old_right_address_r <= '1';
                end if;
            end if;
            if (action_counter_r = to_unsigned(9, action_counter_r'length)) then
                if (channel_left_select_r = '1') then
                    load_left_address_r <= '1';
                else
                    load_right_address_r <= '1';
                end if;
            end if;
            -- store master level
            if (action_counter_r = to_unsigned(10, action_counter_r'length)) then
                store_old_level_r <= '1';
            end if;
            if (action_counter_r = to_unsigned(11, action_counter_r'length)) then
                store_new_level_r <= '1';
            end if;

            ----------------------------------------------------------------------------------------

            -- calculate master gain
            if ((action_counter_r = to_unsigned(12, action_counter_r'length)) or
                (action_counter_r = to_unsigned(14, action_counter_r'length))) then
                calc_gain_r <= '1';
            end if;
            -- store master gain
            if (action_counter_r = to_unsigned(15, action_counter_r'length)) then
                store_gain_result_r <= '1';
            end if;
            -- calculate master
            if ((action_counter_r = to_unsigned(17, action_counter_r'length)) or
                (action_counter_r = to_unsigned(18, action_counter_r'length))) then
                calc_master_value_r <= '1';
            end if;
            -- result done
            if (action_counter_r = to_unsigned(19, action_counter_r'length)) then
                if (channel_left_select_r = '1') then
                    left_valid_r <= '1';
                else
                    right_valid_r <= '1';
                end if;
            end if;
        end if;
    end process control_proc;

    fader_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            load_next_level_r <= '0';

            if ((level_cc_left_valid = '1') or (level_cc_right_valid = '1') or (level_has_changed_r = '1')) then
                if ((fade_in_progress_r = '0') and (action_counter_r(action_counter_r'high) = '1')) then
                    level_has_changed_r <= '0';
                    load_next_level_r <= '1';
                    fade_in_progress_r <= '1';
                    cos_address_r <= std_logic_vector(to_unsigned(200, cos_address_r'length-1)) & '0';
                else
                    level_has_changed_r <= '1';
                end if;
            end if;
            if ((m_left_valid_i = '1') or (m_right_valid_i = '1')) then
                if (vector_and(cos_address_r) = '0') then
                    cos_address_r <= std_logic_vector(unsigned(cos_address_r) + 1);
                else
                    fade_in_progress_r <= '0';
                end if;
            end if;
        end if;
    end process fader_proc;

    left_valid_o <= left_valid_r;
    right_valid_o <= right_valid_r;
    data_o <= add_r;

end rtl;
