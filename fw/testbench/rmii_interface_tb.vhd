--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 11.10.2018
-- Filename  : rmii_interface_tb.vhd
-- Changelog : 11.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rmii_interface_tb is
end entity rmii_interface_tb;

architecture rtl of rmii_interface_tb is

    component rmii_interface
    port (
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        -- rmii
        rx_d_i           : in  std_logic_vector(1 downto 0);
        rx_dv_i          : in  std_logic;
        tx_d_o           : out std_logic_vector(1 downto 0);
        tx_en_o          : out std_logic;
        -- data stream
        data_out_o       : out std_logic_vector(7 downto 0);
        data_out_valid_o : out std_logic;
        data_in_i        : in  std_logic_vector(7 downto 0);
        data_in_last_i   : in  std_logic;
        data_in_valid_i  : in  std_logic;
        data_in_ready_o  : out std_logic);
    end component rmii_interface;

    constant test_packet_c : std_logic_vector := x"FFFFFFFF" &
                                                 x"FFFF9CEB" &
                                                 x"E80E6C62" &
                                                 x"08060001" &
                                                 x"08000604" &
                                                 x"00019CEB" &
                                                 x"E80E6C62" &
                                                 x"C0A80514" &
                                                 x"00000000" &
                                                 x"0000C0A8" &
                                                 x"050B0000" &
                                                 x"00000000" &
                                                 x"00000000" &
                                                 x"00000000" &
                                                 x"00000000" &
                                                 x"7F625A3B";

    signal clk           : std_logic;
    signal reset         : std_logic;

    signal rx_d          : std_logic_vector(1 downto 0) := (others => '0');
    signal rx_dv         : std_logic := '0';

    signal tx_data       : std_logic_vector(7 downto 0);
    signal tx_data_valid : std_logic;
    signal tx_data_ready : std_logic;
    signal tx_data_last  : std_logic;

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    reset_proc : process
    begin
        reset <= '0';
        --wait for 10000000 ns;
        --reset <= '1';
        --wait for 100 ns;
        --reset <= '0';
        wait;
    end process reset_proc;

    i_dut : rmii_interface
    port map (
        clk_i            => clk,
        reset_i          => reset,
        -- rmii
        rx_d_i           => rx_d,
        rx_dv_i          => rx_dv,
        tx_d_o           => open,
        tx_en_o          => open,
        -- data stream
        data_out_o       => open,
        data_out_valid_o => open,
        data_in_i        => tx_data,
        data_in_last_i   => tx_data_last,
        data_in_valid_i  => tx_data_valid,
        data_in_ready_o  => tx_data_ready);

    rx_data_gen_proc : process
        variable dv_toggle_en_v : boolean := false;
    begin
        rx_d <= "00";
        rx_dv <= '0';
        wait for 840 ns;
        rx_dv <= '1';
        -- preamble and SFD
        for i in 0 to 30 loop
            rx_d <= "01";
            wait for 40 ns;
        end loop;
        rx_d <= "11";
        wait for 40 ns;

        for i in 0 to ((test_packet_c'length-32)/8)-1 loop
            for j in 3 downto 0 loop
                rx_d <= test_packet_c((i*8)+(j*2) to (i*8)+(j*2)+1);
                wait for 40 ns;
            end loop;
        end loop;

        -- crc
        for i in ((test_packet_c'length/8)-4) to (test_packet_c'length/8)-1 loop
            for j in 3 downto 0 loop
                rx_d <= test_packet_c((i*8)+(j*2) to (i*8)+(j*2)+1);
                if (j = 1) then
                    dv_toggle_en_v := true;
                end if;
                if (dv_toggle_en_v) then
                    rx_dv <= not rx_dv;
                end if;
                wait for 40 ns;
            end loop;
        end loop;

        rx_d <= "00";
        rx_dv <= '0';
        wait for 40 ns;
        wait;
    end process rx_data_gen_proc;

    tx_data_gen_proc : process
    begin
        tx_data <= (others => '0');
        tx_data_valid <= '0';
        tx_data_last <= '0';

        for i in 0 to 50 loop
            wait until rising_edge(clk);
        end loop;

        for i in 0 to 3 loop
            tx_data <= std_logic_vector(unsigned(tx_data) + 1);
            tx_data_valid <= '1';
            if (i = 3) then
                tx_data_last <= '1';
            end if;
            wait until rising_edge(clk);
            while (tx_data_ready = '0') loop
                wait until rising_edge(clk);
            end loop;
        end loop;

        tx_data_valid <= '0';
        tx_data_last <= '0';
        wait;
    end process tx_data_gen_proc;

end rtl;
