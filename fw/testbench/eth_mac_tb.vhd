--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 29.10.2018
-- Filename  : eth_mac_tb.vhd
-- Changelog : 29.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_mac_tb is
end entity eth_mac_tb;

architecture rtl of eth_mac_tb is

    component eth_mac is
    generic (
        fifo_size_exp_g : positive := 10);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- tx
        data_valid_i : in  std_logic;
        data_ready_o : out std_logic;
        last_i       : in  std_logic;
        data_i       : in  std_logic_vector(7 downto 0);
        -- rx
        data_valid_o : out std_logic;
        data_ready_i : in  std_logic;
        last_o       : out std_logic;
        data_o       : out std_logic_vector(7 downto 0);
        -- rmii
        rx_d_i       : in  std_logic_vector(1 downto 0);
        rx_dv_i      : in  std_logic;
        tx_d_o       : out std_logic_vector(1 downto 0);
        tx_en_o      : out std_logic);
    end component eth_mac;

    type tx_fsm_t is (idle_s, send_data_s, end_s);

    signal clk             : std_logic;
    signal rmii_data_loop  : std_logic_vector(1 downto 0);
    signal rmii_valid_loop : std_logic;
    signal tx_data_valid_r : std_logic := '0';
    signal tx_data_ready   : std_logic;
    signal tx_last_r       : std_logic := '0';
    signal tx_data_r       : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_fsm_r        : tx_fsm_t := idle_s;
    signal idle_counter_r  : unsigned(7 downto 0) := "10000000";
    signal data_counter_r  : unsigned(9 downto 0) := (others => '0');

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    i_mac : eth_mac
    generic map (
        fifo_size_exp_g => 8)
    port map (
        clk_i        => clk,
        reset_i      => '0',
        -- tx
        data_valid_i => tx_data_valid_r,
        data_ready_o => tx_data_ready,
        last_i       => tx_last_r,
        data_i       => tx_data_r,
        -- rx
        data_valid_o => open,
        data_ready_i => '1',
        last_o       => open,
        data_o       => open,
        -- rmii
        rx_d_i       => rmii_data_loop,
        rx_dv_i      => rmii_valid_loop,
        tx_d_o       => rmii_data_loop,
        tx_en_o      => rmii_valid_loop);

    data_gen_proc : process (clk)
    begin
        if (rising_edge(clk)) then
            tx_data_valid_r <= '0';

            case (tx_fsm_r) is
                when idle_s =>
                    idle_counter_r <= idle_counter_r - 1;
                    if (idle_counter_r = to_unsigned(0, idle_counter_r'length)) then
                        data_counter_r <= to_unsigned(10, data_counter_r'length);
                        tx_fsm_r <= send_data_s;
                    end if;

                when send_data_s =>
                    tx_data_valid_r <= '1';
                    if (tx_data_ready = '1') then
                        data_counter_r <= data_counter_r - 1;
                        if (data_counter_r = to_unsigned(1, data_counter_r'length)) then
                            tx_last_r <= '1';
                        end if;
                        if (tx_last_r = '1') then
                            tx_last_r <= '0';
                            tx_data_valid_r <= '0';
                            tx_fsm_r <= end_s;
                        end if;
                        tx_data_r <= std_logic_vector(unsigned(tx_data_r) + 1);
                    end if;

                when end_s =>

            end case;

        end if;
    end process data_gen_proc;

end rtl;
