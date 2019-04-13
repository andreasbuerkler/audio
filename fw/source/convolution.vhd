--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.03.2019
-- Filename  : convolution.vhd
-- Changelog : 03.03.2019 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;
use work.step_response_pkg.all;

entity convolution is
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
end entity convolution;

architecture rtl of convolution is

    constant sign_bits_c   : natural := 4;
    constant coeff_width_c : natural := 24;

    component dual_clock_ram is
    generic (
        addr_width_g : natural;
        data_width_g : natural;
        init_data_g  : std_logic_array);
    port (
        r_clk_i  : in  std_logic;
        r_data_o : out std_logic_vector(data_width_g-1 downto 0);
        r_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
        w_clk_i  : in  std_logic;
        w_data_i : in  std_logic_vector(data_width_g-1 downto 0);
        w_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
        w_en_i   : in  std_logic);
    end component dual_clock_ram;

    component ram is
    generic (
        addr_width_g : positive;
        data_width_g : positive);
    port (
        clk_i     : in  std_logic;
        wr_data_i : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i      : in  std_logic;
        wr_addr_i : in  std_logic_vector(addr_width_g-1 downto 0);
        rd_data_o : out std_logic_vector(data_width_g-1 downto 0);
        rd_i      : in  std_logic;
        rd_addr_i : in  std_logic_vector(addr_width_g-1 downto 0));
    end component ram;

    type ctrl_fsm_t is (idle_s, left_s, right_s);

    signal ctrl_fsm_r        : ctrl_fsm_t := idle_s;
    signal coeff_addr_r      : std_logic_vector(8 downto 0) := (others => '0');
    signal coeff             : std_logic_vector(coeff_width_c-1 downto 0);
    signal mul_r             : std_logic_vector(coeff_width_c+data_width_g-1 downto 0) := (others => '0');
    signal add_r             : std_logic_vector(sign_bits_c+coeff_width_c+data_width_g-1 downto 0) := (others => '0');
    signal data_left_r       : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal data_right_r      : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    signal data_input        : std_logic_vector(data_width_g-1 downto 0);
    signal wr_en_r           : std_logic := '0';
    signal wr_addr_r         : std_logic_vector(8 downto 0) := (others => '0');
    signal wr_addr           : std_logic_vector(9 downto 0);
    signal rd_data           : std_logic_vector(sign_bits_c+coeff_width_c+data_width_g-1 downto 0);
    signal rd_addr_r         : std_logic_vector(8 downto 0) := (others => '0');
    signal rd_addr           : std_logic_vector(9 downto 0);
    signal left_sel_r        : std_logic := '0';
    signal left_valid_r      : std_logic := '0';
    signal right_valid_r     : std_logic := '0';
    signal counter_en_r      : std_logic := '0';
    signal right_present_r   : std_logic := '0';
    signal data_out_r        : std_logic_vector(data_width_g-1 downto 0);
    signal left_valid_out_r  : std_logic := '0';
    signal right_valid_out_r : std_logic := '0';

begin

    i_coeff_mem : dual_clock_ram
    generic map (
        addr_width_g => 9,
        data_width_g => coeff_width_c,
        init_data_g  => step_response_c)
    port map (
        r_clk_i  => audio_clk_i,
        r_data_o => coeff,
        r_addr_i => coeff_addr_r,
        w_clk_i  => register_clk_i,
        w_data_i => coeff_i(coeff_width_c-1 downto 0),
        w_addr_i => address_i,
        w_en_i   => wr_en_i);

    i_data_mem : ram
    generic map (
        addr_width_g => 10,
        data_width_g => sign_bits_c+coeff_width_c+data_width_g)
    port map (
        clk_i     => audio_clk_i,
        wr_data_i => add_r,
        wr_i      => wr_en_r,
        wr_addr_i => wr_addr,
        rd_data_o => rd_data,
        rd_i      => '1',
        rd_addr_i => rd_addr);

    wr_addr <= left_sel_r & wr_addr_r;
    rd_addr <= left_sel_r & rd_addr_r;

    input_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            if (left_valid_i = '1') then
                data_left_r <= data_i;
            end if;
            if (right_valid_i = '1') then
                data_right_r <= data_i;
            end if;
        end if;
    end process input_proc;

    data_input <= data_left_r when (left_sel_r = '1') else
                  data_right_r;

    mul_acc_proc : process (audio_clk_i)
        variable add_v : std_logic_vector(sign_bits_c+coeff_width_c+data_width_g-1 downto 0);
    begin
        if (rising_edge(audio_clk_i)) then
            mul_r <= std_logic_vector(signed(data_input) * signed(coeff));
            add_v := std_logic_vector(resize(signed(mul_r), add_r'length) + signed(rd_data));
            if ((add_v(add_v'high downto add_v'high-1) = "10") and (rd_data(rd_data'high downto rd_data'high-1) = "01")) then
                -- overflow
                add_r <= '0' & std_logic_vector(to_signed(-1, sign_bits_c+coeff_width_c+data_width_g-1));
            elsif ((add_v(add_v'high downto add_v'high-1) = "01") and (rd_data(rd_data'high downto rd_data'high-1) = "10")) then
                -- underflow
                add_r <= '1' & std_logic_vector(to_signed(0, sign_bits_c+coeff_width_c+data_width_g-1));
            else
                add_r <= add_v;
            end if;
        end if;
    end process mul_acc_proc;

    ctrl_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            left_valid_r <= '0';
            right_valid_r <= '0';

            if (right_valid_i = '1') then
                right_present_r <= '1';
            end if;

            if (counter_en_r = '1') then
                coeff_addr_r <= std_logic_vector(unsigned(coeff_addr_r) + 1);
                rd_addr_r <= std_logic_vector(unsigned(coeff_addr_r) + 1);
                wr_addr_r <= std_logic_vector(unsigned(coeff_addr_r) - 2);
            else
                coeff_addr_r <= std_logic_vector(to_unsigned(0, coeff_addr_r'length));
                rd_addr_r <= std_logic_vector(to_signed(-2, rd_addr_r'length));
                wr_addr_r <= std_logic_vector(to_signed(-3, wr_addr_r'length));
            end if;

            case (ctrl_fsm_r) is
                when idle_s =>
                    if (left_valid_i = '1') then
                        ctrl_fsm_r <= left_s;
                    elsif ((right_valid_i = '1') or (right_present_r = '1')) then
                        ctrl_fsm_r <= right_s;
                    end if;

                when left_s =>
                    left_sel_r <= '1';
                    if (unsigned(coeff_addr_r) = to_unsigned(2, coeff_addr_r'length)) then
                        wr_en_r <= '1';
                        left_valid_r <= '1';
                    elsif (unsigned(coeff_addr_r) = to_unsigned(459+3, coeff_addr_r'length)) then
                        wr_en_r <= '0';
                        counter_en_r <= '0';
                        ctrl_fsm_r <= idle_s;
                    else
                        counter_en_r <= '1';
                    end if;

                when right_s =>
                    left_sel_r <= '0';
                    right_present_r <= '0';
                    if (unsigned(coeff_addr_r) = to_unsigned(2, coeff_addr_r'length)) then
                        wr_en_r <= '1';
                        right_valid_r <= '1';
                    elsif (unsigned(coeff_addr_r) = to_unsigned(459+3, coeff_addr_r'length)) then
                        wr_en_r <= '0';
                        counter_en_r <= '0';
                        ctrl_fsm_r <= idle_s;
                    else
                        counter_en_r <= '1';
                    end if;

            end case;

        end if;
    end process ctrl_proc;

    truncate_proc : process (audio_clk_i)
    begin
        if (rising_edge(audio_clk_i)) then
            if (add_r(add_r'high downto add_r'high-sign_bits_c-1) = std_logic_vector(to_signed(0, sign_bits_c+2))) then
                data_out_r <= add_r(add_r'high-sign_bits_c-1 downto data_width_g-1);
            elsif (add_r(add_r'high downto add_r'high-sign_bits_c-1) = std_logic_vector(to_signed(-1, sign_bits_c+2))) then
                data_out_r <= add_r(add_r'high-sign_bits_c-1 downto data_width_g-1);
            elsif (add_r(add_r'high) = '1') then
                data_out_r <= '1' & std_logic_vector(to_signed(0, data_width_g-1));
            else
                data_out_r <= '0' & std_logic_vector(to_signed(-1, data_width_g-1));
            end if;
            left_valid_out_r <= left_valid_r;
            right_valid_out_r <= right_valid_r;
        end if;
    end process truncate_proc;

    left_valid_o <= left_valid_out_r;
    right_valid_o <= right_valid_out_r;
    data_o <= data_out_r;

end rtl;
