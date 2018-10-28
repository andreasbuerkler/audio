--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 13.10.2018
-- Filename  : crc32_tb.vhd
-- Changelog : 13.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity crc32_tb is
end entity crc32_tb;

architecture rtl of crc32_tb is

    component crc32 is
    port (
        clk_i        : in  std_logic;
        clear_i      : in  std_logic;
        data_valid_i : in  std_logic;
        data_i       : in  std_logic_vector(7 downto 0);
        crc_o        : out std_logic_vector(31 downto 0));
    end component crc32;

    component eth_fcs is
    port (
        clk_i             : in  std_logic;
        -- rx data
        rx_valid_i        : in  std_logic;
        rx_data_i         : in  std_logic_vector(7 downto 0);
        rx_fifo_full_i    : in  std_logic;
        rx_valid_o        : out std_logic;
        rx_last_o         : out std_logic;
        rx_data_o         : out std_logic_vector(7 downto 0);
        rx_crc_fail_o     : out std_logic;
        rx_crc_ok_o       : out std_logic;
        -- tx data
        tx_valid_i        : in  std_logic;
        tx_ready_o        : out std_logic;
        tx_last_i         : in  std_logic;
        tx_data_i         : in  std_logic_vector(7 downto 0);
        tx_valid_o        : out std_logic;
        tx_ready_i        : in  std_logic;
        tx_last_o         : out std_logic;
        tx_data_o         : out std_logic_vector(7 downto 0);
        -- rx crc32
        rx_crc_clear_o    : out std_logic;
        rx_crc_valid_o    : out std_logic;
        rx_crc_data_o     : out std_logic_vector(7 downto 0);
        rx_crc_checksum_i : in  std_logic_vector(31 downto 0);
        -- tx crc32
        tx_crc_clear_o    : out std_logic;
        tx_crc_valid_o    : out std_logic;
        tx_crc_data_o     : out std_logic_vector(7 downto 0);
        tx_crc_checksum_i : in  std_logic_vector(31 downto 0));
    end component eth_fcs;

    component eth_padder is
    port (
        clk_i        : in  std_logic;
        data_valid_i : in  std_logic;
        data_ready_o : out std_logic;
        last_i       : in  std_logic;
        data_i       : in  std_logic_vector(7 downto 0);
        data_valid_o : out std_logic;
        data_ready_i : in  std_logic;
        last_o       : out std_logic;
        data_o       : out std_logic_vector(7 downto 0));
    end component eth_padder;

    constant data_c : std_logic_vector := x"FFFFFFFF" &
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
    signal rx_clear      : std_logic := '0';
    signal rx_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data_valid : std_logic := '0';
    signal rx_crc        : std_logic_vector(31 downto 0);
    signal rx_gen_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_gen_valid  : std_logic := '0';

    signal tx_clear      : std_logic := '0';
    signal tx_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data_valid : std_logic := '0';
    signal tx_crc        : std_logic_vector(31 downto 0);
    signal tx_gen_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_gen_valid  : std_logic := '0';
    signal tx_gen_ready  : std_logic;
    signal tx_gen_last   : std_logic := '0';
    signal tx_ready      : std_logic := '0';

    signal tx_pad_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_pad_valid  : std_logic := '0';
    signal tx_pad_ready  : std_logic;
    signal tx_pad_last   : std_logic := '0';

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process clkgen_proc;

    i_dut_fcs : eth_fcs
    port map (
        clk_i              => clk,
        -- rx data
        rx_valid_i         => rx_gen_valid,
        rx_data_i          => rx_gen_data,
        rx_fifo_full_i     => '0',
        rx_valid_o         => open,
        rx_last_o          => open,
        rx_data_o          => open,
        rx_crc_fail_o      => open,
        rx_crc_ok_o        => open,
        -- tx data
        tx_valid_i         => tx_pad_valid,
        tx_ready_o         => tx_pad_ready,
        tx_last_i          => tx_pad_last,
        tx_data_i          => tx_pad_data,
        tx_valid_o         => open,
        tx_ready_i         => tx_ready,
        tx_last_o          => open,
        tx_data_o          => open,
        -- rx crc32
        rx_crc_clear_o     => rx_clear,
        rx_crc_valid_o     => rx_data_valid,
        rx_crc_data_o      => rx_data,
        rx_crc_checksum_i  => rx_crc,
        -- tx crc32
        tx_crc_clear_o     => tx_clear,
        tx_crc_valid_o     => tx_data_valid,
        tx_crc_data_o      => tx_data,
        tx_crc_checksum_i  => tx_crc);

    i_rx_crc : crc32
    port map (
        clk_i        => clk,
        clear_i      => rx_clear,
        data_valid_i => rx_data_valid,
        data_i       => rx_data,
        crc_o        => rx_crc);

    i_tx_crc : crc32
    port map (
        clk_i        => clk,
        clear_i      => tx_clear,
        data_valid_i => tx_data_valid,
        data_i       => tx_data,
        crc_o        => tx_crc);

    i_padder : eth_padder
    port map (
        clk_i        => clk,
        data_valid_i => tx_gen_valid,
        data_ready_o => tx_gen_ready,
        last_i       => tx_gen_last,
        data_i       => tx_gen_data,
        data_valid_o => tx_pad_valid,
        data_ready_i => tx_pad_ready,
        last_o       => tx_pad_last,
        data_o       => tx_pad_data);


    rx_data_gen_proc: process
        variable data_v : std_logic_vector(7 downto 0);
    begin
        wait for 420 ns;
        wait until rising_edge(clk);
        for i in 0 to (data_c'length/8)-1 loop
            data_v := data_c(i*8 to (i*8)+7);
            rx_gen_data(3 downto 0) <= data_v(3 downto 0);
            rx_gen_data(7 downto 4) <= data_v(7 downto 4);
            rx_gen_valid <= '1';
            wait until rising_edge(clk);
            rx_gen_valid <= '0';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
        end loop;
        wait;
    end process rx_data_gen_proc;

    tx_data_gen_proc: process
        variable data_v : std_logic_vector(7 downto 0);
    begin
        wait for 420 ns;
        wait until rising_edge(clk);
        for i in 0 to (data_c'length/8)-5-16 loop
            data_v := data_c(i*8 to (i*8)+7);
            tx_gen_data(3 downto 0) <= data_v(3 downto 0);
            tx_gen_data(7 downto 4) <= data_v(7 downto 4);
            tx_gen_valid <= '1';
            if (i = (data_c'length/8)-5-16) then
                tx_gen_last <= '1';
            else
                tx_gen_last <= '0';
            end if;
            wait until rising_edge(clk);
            while (tx_gen_ready = '0') loop
                wait until rising_edge(clk);
            end loop;
        end loop;

        tx_gen_last <= '0';
        tx_gen_valid <= '0';

        wait;
    end process tx_data_gen_proc;

    ready_gen : process (clk)
        variable seed1_v : positive := 23;
        variable seed2_v : positive := 78;
        variable rand_v  : real;   
    begin
        if (rising_edge(clk)) then
            uniform(seed1_v, seed2_v, rand_v);
            if (rand_v > 0.5) then
                tx_ready <= '1';
            else
                tx_ready <= '0';
            end if;
        end if;
    end process ready_gen;

end rtl;
