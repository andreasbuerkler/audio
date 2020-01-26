--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 18.01.2020
-- Filename  : mdio_debug.vhd
-- Changelog : 18.01.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity mdio_debug is
generic (
    mdio_address_g : std_logic_vector(4 downto 0) := "00000");
port (
    clk_i    : in  std_logic;
    enable_i : in  std_logic;
    mdc_o    : out std_logic;
    mdio_i   : in  std_logic;
    mdio_o   : out std_logic);
end entity mdio_debug;

architecture rtl of mdio_debug is

    type fsm_t is (wait_s, idle_s, preamble_s, start_s, read_s, phy_addr_s,
                   reg_addr_s, turn_s, receive_data_s, end_s);

    signal fsm_r          : fsm_t := wait_s;
    signal mdc_r          : std_logic := '0';
    signal mdio_r         : std_logic := '1';
    signal clk_div_r      : unsigned(5 downto 0) := (others => '0');
    signal counter_r      : unsigned(5 downto 0) := (others => '0');
    signal data_r         : std_logic_vector(4 downto 0) := (others => '0');
    signal register_r     : std_logic_vector(4 downto 0) := (others => '0');
    signal wait_counter_r : unsigned(24 downto 0) := (others => '0');

begin

    clk_gen_proc : process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            clk_div_r <= clk_div_r + 1;
        end if;
    end process clk_gen_proc;

    read_proc : process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            case (fsm_r) is
                when wait_s =>
                    if (enable_i = '1') then
                        wait_counter_r <= wait_counter_r + 1;
                        if (wait_counter_r(wait_counter_r'high) = '1') then
                            fsm_r <= idle_s;
                        end if;
                    end if;

                when idle_s =>
                    mdio_r <= '1';
                    counter_r <= (others => '0');
                    fsm_r <= preamble_s;

                when preamble_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(31, counter_r'length)) then
                            counter_r <= (others => '0');
                            mdio_r <= '0';
                            fsm_r <= start_s;
                        end if;
                    end if;

                when start_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(1, counter_r'length)) then
                            counter_r <= (others => '0');
                            mdio_r <= '1';
                            fsm_r <= read_s;
                        else
                            mdio_r <= '1';
                        end if;
                    end if;

                when read_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(1, counter_r'length)) then
                            counter_r <= (others => '0');
                            register_r <= "11111";
                            data_r <= mdio_address_g; -- phy address
                            mdio_r <= mdio_address_g(mdio_address_g'high);
                            fsm_r <= phy_addr_s;
                        else
                            mdio_r <= '0';
                        end if;
                    end if;

                when phy_addr_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(4, counter_r'length)) then
                            counter_r <= (others => '0');
                            mdio_r <= register_r(register_r'high);
                            data_r <= register_r;
                            fsm_r <= reg_addr_s;
                        else
                            mdio_r <= data_r(data_r'high-1);
                            data_r <= data_r(data_r'high-1 downto 0) & '0';
                        end if;
                    end if;

                when reg_addr_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(4, counter_r'length)) then
                            counter_r <= (others => '0');
                            mdio_r <= '1';
                            fsm_r <= turn_s;
                        else
                            mdio_r <= data_r(data_r'high-1);
                            data_r <= data_r(data_r'high-1 downto 0) & '0';
                        end if;
                    end if;

                when turn_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(1, counter_r'length)) then
                            counter_r <= (others => '0');
                            fsm_r <= receive_data_s;
                        end if;
                    end if;

                when receive_data_s =>
                    if (clk_div_r = "000000") then
                        mdc_r <= '1';
                    elsif (clk_div_r = "100000") then
                        mdc_r <= '0';
                    elsif (clk_div_r = "110000") then
                        counter_r <= counter_r + 1;
                        if (counter_r = to_unsigned(15, counter_r'length)) then
                            counter_r <= (others => '0');
                            fsm_r <= end_s;
                        end if;
                    end if;

                when end_s =>
                    wait_counter_r <= (others => '0');
                    fsm_r <= wait_s;

            end case;
        end if;
    end process read_proc;

    mdc_o <= mdc_r;
    mdio_o <= mdio_r;

end rtl;