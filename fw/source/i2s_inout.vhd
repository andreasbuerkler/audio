--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 07.10.2018
-- Filename  : i2s_inout.vhd
-- Changelog : 07.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity i2s_inout is
port (
    m_clk_i       : in  std_logic;
    b_clk_o       : out std_logic;
    lr_clk_o      : out std_logic;
    i2s_i         : in  std_logic;
    i2s_o         : out std_logic;
    right_valid_o : out std_logic;
    left_valid_o  : out std_logic;
    data_o        : out std_logic_vector(23 downto 0);
    right_valid_i : in  std_logic;
    left_valid_i  : in  std_logic;
    data_i        : in  std_logic_vector(23 downto 0));
end entity i2s_inout;

architecture rtl of i2s_inout is

    signal shift_in_r     : std_logic_vector(31 downto 0) := (others => '0');
    signal shift_out_r    : std_logic_vector(31 downto 0) := (others => '0');
    signal data_r         : std_logic_vector(23 downto 0) := (others => '0');
    signal data_l_r       : std_logic_vector(23 downto 0) := (others => '0');
    signal data_r_r       : std_logic_vector(23 downto 0) := (others => '0');
    signal left_valid_r   : std_logic := '0';
    signaL right_valid_r  : std_logic := '0';
    signal lr_clk_vec_r   : std_logic_vector(1 downto 0) := (others => '0');
    signal lrclk_cnt_r    : unsigned(7 downto 0) := (others => '0');
    signal b_clk_r        : std_logic := '0';
    signal lr_clk_r       : std_logic := '0';

begin

    clk_gen_proc : process (m_clk_i)
    begin
        if (rising_edge(m_clk_i)) then
            lrclk_cnt_r <= lrclk_cnt_r + 1;
            b_clk_r <= lrclk_cnt_r(1);
            lr_clk_r <= lrclk_cnt_r(lrclk_cnt_r'high);
        end if;
    end process clk_gen_proc;

    b_clk_o <= b_clk_r;
    lr_clk_o <= lr_clk_r;

    ser2par_proc : process (m_clk_i)
    begin
        if (rising_edge(m_clk_i)) then
            if (lrclk_cnt_r(1 downto 0) = "10") then
                lr_clk_vec_r <= lr_clk_vec_r(0) & lr_clk_r;
                shift_in_r <= shift_in_r(shift_in_r'high-1 downto 0) & i2s_i;
                left_valid_r <= '0';
                right_valid_r <= '0';

                if (lr_clk_vec_r = "01") then
                    left_valid_r <= '1';
                    data_r <= shift_in_r(31 downto 8);
                elsif (lr_clk_vec_r = "10") then
                    right_valid_r <= '1';
                    data_r <= shift_in_r(31 downto 8);
                end if;
            end if;
        end if;
    end process ser2par_proc;

    data_o <= data_r;
    left_valid_o <= left_valid_r;
    right_valid_o <= right_valid_r;

    par2ser_proc : process (m_clk_i)
    begin
        if (rising_edge(m_clk_i)) then

            if (right_valid_i = '1') then
                data_r_r <= data_i;
            end if;

            if (left_valid_i = '1') then
                data_l_r <= data_i;
            end if;

            if (lrclk_cnt_r(1 downto 0) = "00") then 
                shift_out_r <= shift_out_r(shift_out_r'high-1 downto 0) & '0';
            
                if (lr_clk_vec_r = "01") then
                    shift_out_r <= data_r_r & x"00";
                elsif (lr_clk_vec_r = "10") then
                    shift_out_r <= data_l_r & x"00";
                end if;
            end if;
        
        end if;
    end process par2ser_proc;

    i2s_o <= shift_out_r(31);

end rtl;