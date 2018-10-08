--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : biquad.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity biquad is
generic (
    INTERFACE_DATA_W  : natural := 24;
    DATA_W            : natural := 27;
    NOISE_SHAPING_EN  : boolean := true;
    NUMBER_OF_BIQUADS : natural := 2);
port (
    coeff_clk_i   : in  std_logic;
    coeff_addr_i  : in  std_logic_vector(4+log2ceil(NUMBER_OF_BIQUADS) downto 0);
    coeff_data_i  : in  std_logic_vector(DATA_W-1 downto 0);
    coeff_wr_i    : in  std_logic;
    clk_i         : in  std_logic;
    left_valid_i  : in  std_logic;
    right_valid_i : in  std_logic;
    data_i        : in  std_logic_vector(INTERFACE_DATA_W-1 downto 0);
    left_valid_o  : out std_logic;
    right_valid_o : out std_logic;
    data_o        : out std_logic_vector(INTERFACE_DATA_W-1 downto 0));
end entity biquad;

architecture rtl of biquad is

    constant COEFF_ADDRESS_W : natural := 5 + log2ceil(NUMBER_OF_BIQUADS);
    constant DATA_ADDRESS_W  : natural := 3 + log2ceil(NUMBER_OF_BIQUADS);
    
    component biquad_mult is
    generic (
        DATA_W : natural := 27);
    port (
        clk_i      : in  std_logic;
        data_a_i   : in  std_logic_vector(DATA_W-1 downto 0);
        data_b_i   : in  std_logic_vector(DATA_W-1 downto 0);
        data_o     : out std_logic_vector(2*DATA_W-1 downto 0));
    end component;

    component biquad_data_mem is
    generic (
        ADDR_W : natural := 1;
        DATA_W : natural := 54);
    port (
        clk_i    : in  std_logic;
        r_data_o : out std_logic_vector(DATA_W-1 downto 0);
        r_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
        w_data_i : in  std_logic_vector(DATA_W-1 downto 0);
        w_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
        w_en_i   : in  std_logic);
    end component;

    component biquad_coeff_mem is
    generic (
        ADDR_W : natural := 7;
        DATA_W : natural := 27);
    port (
        r_clk_i  : in  std_logic;
        r_data_o : out std_logic_vector(DATA_W-1 downto 0);
        r_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
        w_clk_i  : in  std_logic;
        w_data_i : in  std_logic_vector(DATA_W-1 downto 0);
        w_addr_i : in  std_logic_vector(ADDR_W-1 downto 0);
        w_en_i   : in  std_logic);
    end component;

    signal data_in_r          : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal address_counter_r  : unsigned(4 downto 0) := (others => '0');
    signal address_r          : std_logic_vector(COEFF_ADDRESS_W-1 downto 0) := (others => '0');
    signal left_r             : std_logic := '0';
    signal shift_vec_r        : std_logic_vector(31 downto 0) := (others => '0');
    signal mult_result        : std_logic_vector(2*DATA_W-1 downto 0);
    signal coeff_result       : std_logic_vector(DATA_W-1 downto 0);
    signal mul_a              : std_logic_vector(DATA_W-1 downto 0);
    signal sum_a_a            : std_logic_vector(2*DATA_W-1 downto 0);
    signal sum_b_a            : std_logic_vector(2*DATA_W-1 downto 0);
    signal left_valid_r       : std_logic := '0';
    signal right_valid_r      : std_logic := '0';
    signal data_result_r      : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal noise_shaping_a    : std_logic_vector(2*DATA_W-1 downto 0);
    signal adder_r            : std_logic_vector(2*DATA_W-1 downto 0) := (others => '0');
    signal data_mem_wr_en_a   : std_logic;
    signal data_mem_wr_addr_a : std_logic_vector(DATA_ADDRESS_W-1 downto 0);
    signal data_mem_rd_addr_a : std_logic_vector(DATA_ADDRESS_W-1 downto 0);
    signal data_mem_rd_data   : std_logic_vector(2*DATA_W-1 downto 0);
    signal biquad_sel_r       : std_logic_vector(log2ceil(NUMBER_OF_BIQUADS)-1 downto 0) := (others => '0');

    signal adder_overflow_r   : std_logic := '0';
    signal adder_underflow_r  : std_logic := '0';
    
begin

    --------------------------------------------------------------------------------
    -- input multiplexer / input register

    data_in_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            -- first biquad uses input data
            if ((left_valid_i = '1') or (right_valid_i = '1')) then
                data_in_r <= std_logic_vector(resize(signed(data_i), DATA_W));
                left_r <= left_valid_i;
            -- all other biquads use output of last biquad
            elsif ((shift_vec_r(0) = '1') and (biquad_sel_r /= std_logic_vector(to_unsigned(0, biquad_sel_r'length)))) then
                data_in_r <= data_result_r;
            end if;
        end if;
    end process data_in_proc;

    --------------------------------------------------------------------------------
    -- biquad select

    biquad_sel_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (shift_vec_r(31) = '1') then
                biquad_sel_r <= std_logic_vector(unsigned(biquad_sel_r) + 1);
            end if;
        end if;
    end process biquad_sel_proc;

    --------------------------------------------------------------------------------
    -- coefficient memory / address generator

    i_coeff_mem : biquad_coeff_mem
    generic map (
        ADDR_W => COEFF_ADDRESS_W,
        DATA_W => DATA_W)
    port map (
        r_clk_i  => clk_i,
        r_data_o => coeff_result,
        r_addr_i => address_r,
        w_clk_i  => coeff_clk_i,
        w_data_i => coeff_data_i,
        w_addr_i => coeff_addr_i,
        w_en_i   => coeff_wr_i);

    address_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((left_valid_i = '1') or (right_valid_i = '1')) then
                address_counter_r <= (others => '0');
                shift_vec_r <= x"00000001";
            else
                address_counter_r <= address_counter_r + 1;
                if ((shift_vec_r(31) = '1') and (biquad_sel_r /= std_logic_vector(to_unsigned(NUMBER_OF_BIQUADS-1, biquad_sel_r'length)))) then
                    shift_vec_r <= x"00000001";
                else
                    shift_vec_r <= shift_vec_r(shift_vec_r'high-1 downto 0) & '0';
                end if;
            end if;
            address_r <= left_r & biquad_sel_r & std_logic_vector(address_counter_r(3 downto 0));
        end if;
    end process address_proc;

    --------------------------------------------------------------------------------
    -- multiplier / multiplexer between data_out_r and data_in_r

    mul_a <= data_mem_rd_data(24+DATA_W-1 downto 24) when (shift_vec_r(11) = '1') or
                                                          (shift_vec_r(15) = '1') else
             data_in_r;

    i_mul : biquad_mult
    generic map (
        DATA_W => DATA_W)
    port map (
        clk_i      => clk_i,
        data_a_i   => coeff_result,
        data_b_i   => mul_a,
        data_o     => mult_result);

    --------------------------------------------------------------------------------
    -- data memory

    data_mem_wr_en_a <= shift_vec_r(7) or shift_vec_r(14) or shift_vec_r(17);

    rd_addr_proc : process (left_r, shift_vec_r, biquad_sel_r)
    begin
        if (shift_vec_r(14) = '1') then
            data_mem_wr_addr_a <= left_r & biquad_sel_r & "10";
        elsif (shift_vec_r(17) = '1') then
            data_mem_wr_addr_a <= left_r & biquad_sel_r & "11";
        else
            data_mem_wr_addr_a <= left_r & biquad_sel_r & "01";
        end if;
    end process rd_addr_proc;
    
    -- address(1:0) map
    -- 0: not used
    -- 1: data_out_r
    -- 2: data_r
    -- 3: data_delay_r
    i_data_mem : biquad_data_mem
    generic map (
        ADDR_W => DATA_ADDRESS_W,
        DATA_W => 2*DATA_W)
    port map (
        clk_i    => clk_i,
        r_data_o => data_mem_rd_data,
        r_addr_i => data_mem_rd_addr_a,
        w_data_i => adder_r,
        w_addr_i => data_mem_wr_addr_a,
        w_en_i   => data_mem_wr_en_a);

    data_mem_rd_addr_a <= left_r & biquad_sel_r & "01" when (shift_vec_r(1) = '1') or
                                                            (shift_vec_r(8) = '1') or
                                                            (shift_vec_r(12) = '1') else
                          left_r & biquad_sel_r & "10" when (shift_vec_r(3) = '1') else
                          left_r & biquad_sel_r & "11" when (shift_vec_r(10) = '1') else
                          (others => '0');

    --------------------------------------------------------------------------------
    -- adder

    -- noise shaping
    noise_shaping_a <= x"0000000" & "00" & data_mem_rd_data(23 downto 0) when (data_mem_rd_data(data_mem_rd_data'high) = '0') else
                       x"fffffff" & "11" & (not data_mem_rd_data(23 downto 0));

    -- adder input multiplexer
    sum_a_a <= noise_shaping_a         when ((shift_vec_r(4) = '1') and NOISE_SHAPING_EN) else
               x"0000000000000" & "00" when (shift_vec_r(4) = '1') or
                                            (shift_vec_r(10) = '1') or
                                            (shift_vec_r(14) = '1') else
               adder_r;
               
    sum_b_a <= data_mem_rd_data        when (shift_vec_r(6) = '1') or
                                            (shift_vec_r(13) = '1') else
               x"0000000000000" & "00" when (shift_vec_r(4) = '1') or
                                            (shift_vec_r(10) = '1') or
                                            (shift_vec_r(14) = '1') else
               mult_result;

    sum_proc : process (clk_i)
        variable adder_v : std_logic_vector(adder_r'high+1 downto adder_r'low);
    begin
        if (rising_edge(clk_i)) then
            adder_v := std_logic_vector(unsigned(sum_a_a(sum_a_a'high) & sum_a_a) + unsigned(sum_b_a(sum_b_a'high) & sum_b_a));
            adder_r <= adder_v(adder_r'range);
            adder_overflow_r <= '0';
            adder_underflow_r <= '0';
            -- overflow protection only for "data_out_r"
            if ((adder_v(24+INTERFACE_DATA_W downto 24+INTERFACE_DATA_W-1) = "01") and (shift_vec_r(6) = '1')) then
                -- overflow
                adder_r(adder_r'high downto 24+INTERFACE_DATA_W-1) <= (others => '0');
                adder_r(24+INTERFACE_DATA_W-2 downto 0) <= (others => '1');
                adder_overflow_r <= '1';
            elsif ((adder_v(24+INTERFACE_DATA_W downto 24+INTERFACE_DATA_W-1) = "10") and (shift_vec_r(6) = '1')) then
                -- underflow
                adder_r(adder_r'high downto 24+INTERFACE_DATA_W-1) <= (others => '1');
                adder_r(24+INTERFACE_DATA_W-2 downto 0) <= (others => '0');
                adder_underflow_r <= '1';
            else
                adder_r <= adder_v(adder_r'range);
            end if;
        end if;
    end process sum_proc;

    --------------------------------------------------------------------------------
    -- output register / valid generation

    out_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (biquad_sel_r = std_logic_vector(to_unsigned(NUMBER_OF_BIQUADS-1, biquad_sel_r'length))) then
                left_valid_r <= left_r and shift_vec_r(7);
                right_valid_r <= (not left_r) and shift_vec_r(7);
            else
                left_valid_r <= '0';
                right_valid_r <= '0';
            end if;

            if (shift_vec_r(7) = '1') then
                data_result_r <= adder_r(24+DATA_W-1 downto 24);
            end if;
        end if;
    end process out_proc;
    
    left_valid_o  <= left_valid_r;
    right_valid_o <= right_valid_r;
    data_o        <= data_result_r(INTERFACE_DATA_W-1 downto 0);
    
end rtl;

