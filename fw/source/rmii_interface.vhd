--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 11.10.2018
-- Filename  : rmii_interface.vhd
-- Changelog : 11.10.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rmii_interface is
port (
    clk_i            : in  std_logic;
    reset_i          : in  std_logic; -- TODO
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
end entity rmii_interface;

architecture rtl of rmii_interface is

    signal data_out_r            : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_valid_r      : std_logic := '0';
    signal data_in_ready_r       : std_logic := '0';

    signal rx_data_r             : std_logic_vector(1 downto 0) := (others => '0');
    signal rx_data_valid_r       : std_logic := '0';
    signal rx_data_error_r       : std_logic := '0';
    signal rx_preamble_counter_r : unsigned(5 downto 0) := (others => '0');
    signal rx_offset_counter_r   : unsigned(1 downto 0) := (others => '0');
    signal rx_data_shift_r       : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data_active_r      : std_logic := '0';
    signal rx_data_active_next_r : std_logic := '0';
    signal rx_offset_r           : unsigned(1 downto 0) := (others => '0');

    signal tx_data_r             : std_logic_vector(1 downto 0) := (others => '0');
    signal tx_data_valid_r       : std_logic := '0';    
    signal tx_preamble_counter_r : unsigned(5 downto 0) := "100000";
    signal tx_preamble_en_r      : std_logic := '0';
    signal tx_data_en_r          : std_logic := '0';
    signal tx_gap_en_r           : std_logic := '0';
    signal tx_offset_counter_r   : unsigned(1 downto 0) := (others => '0');
    signal tx_gap_counter_r      : unsigned(6 downto 0) := "1000000";

begin

    input_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            rx_data_r <= rx_d_i;
            rx_data_valid_r <= rx_dv_i;
            rx_offset_counter_r <= rx_offset_counter_r + 1;
            rx_data_shift_r <= rx_data_r & rx_data_shift_r(rx_data_shift_r'high downto rx_data_r'length);
        end if;
    end process input_proc;

    rx_data_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rx_data_r = "01") and (rx_data_valid_r = '1') then
                if (rx_preamble_counter_r(rx_preamble_counter_r'high) = '0') then
                    rx_preamble_counter_r <= rx_preamble_counter_r + 1;
                end if;
            else
                rx_preamble_counter_r <= (others => '0');
            end if;

            if (rx_data_valid_r = '1') then
                if ((rx_data_r = "11") and (rx_data_active_r = '0') and (rx_preamble_counter_r >= to_unsigned(28, rx_preamble_counter_r'length))) then
                    rx_offset_r <= rx_offset_counter_r + 1;
                    rx_data_active_next_r <= '1';
                end if;
                rx_data_active_r <= rx_data_active_next_r;
            elsif (rx_offset_r(0) /= rx_offset_counter_r(0)) then
                rx_data_active_r <= '0';
                rx_data_active_next_r <= '0';
            end if;

            if (rx_offset_counter_r = rx_offset_r) then
                data_out_r <= rx_data_shift_r;
                data_out_valid_r <= rx_data_active_r;
            else
                data_out_valid_r <= '0';
            end if;
        end if;
    end process rx_data_proc;

    tx_data_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            data_in_ready_r <= '0';

            if (tx_gap_en_r = '1') then
                -- interframe gap, 12 octets
                if (tx_gap_counter_r = to_unsigned(43, tx_gap_counter_r'length)) then
                    tx_gap_en_r <= '0';
                    tx_gap_counter_r <= "1000000";
                end if;
            elsif (tx_data_en_r = '1') then
                -- transmit data and fcs
                if (tx_offset_counter_r = "01") then
                    if (data_in_valid_i = '1') then
                        data_in_ready_r <= '1';
                    else
                        -- no data available -> abort
                        tx_data_en_r <= '0';
                        tx_gap_en_r <= '1';
                        tx_gap_counter_r(tx_gap_counter_r'high) <= '0';
                    end if;
                end if;
                if (tx_offset_counter_r = "10") then
                    if ((data_in_valid_i = '1') and (data_in_last_i = '1')) then
                        tx_data_en_r <= '0';
                        tx_gap_en_r <= '1';
                        tx_gap_counter_r(tx_gap_counter_r'high) <= '0';
                    end if;
                end if;
            elsif (tx_preamble_en_r = '1') then
                -- transmit preamble and sfd, 8 octets
                if (tx_preamble_counter_r = to_unsigned(31, tx_preamble_counter_r'length)) then
                    tx_preamble_en_r <= '0';
                    tx_data_en_r <= '1';
                end if;
            else
                -- wait for next packet
                if ((data_in_valid_i = '1') and (tx_offset_counter_r = "10")) then
                    tx_preamble_counter_r(tx_preamble_counter_r'high) <= '0';
                    tx_preamble_en_r <= '1';
                end if;
            end if;

            if (tx_preamble_counter_r(tx_preamble_counter_r'high) = '0') then
                tx_preamble_counter_r <= tx_preamble_counter_r + 1;
            end if;

            if (tx_gap_counter_r(tx_gap_counter_r'high) = '0') then
                tx_gap_counter_r <= tx_gap_counter_r + 1;
            end if;

            tx_offset_counter_r <= tx_offset_counter_r + 1;

        end if;
    end process tx_data_proc;

    output_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (tx_preamble_counter_r = to_unsigned(31, tx_preamble_counter_r'length)) then
                tx_data_r <= "11";
                tx_data_valid_r <= '1';
            elsif (tx_preamble_en_r = '1') then
                tx_data_r <= "01";
                tx_data_valid_r <= '1';
            elsif (tx_data_en_r = '1') then
                case tx_offset_counter_r is
                    when "00"   => tx_data_r <= data_in_i(3 downto 2);
                    when "01"   => tx_data_r <= data_in_i(5 downto 4);
                    when "10"   => tx_data_r <= data_in_i(7 downto 6);
                    when others => tx_data_r <= data_in_i(1 downto 0);
                end case;
                tx_data_valid_r <= '1';
            else
                tx_data_r <= "00";
                tx_data_valid_r <= '0';
            end if;
        end if;
    end process output_proc;

    tx_en_o <= tx_data_valid_r;
    tx_d_o <= tx_data_r;

    data_out_o <= data_out_r;
    data_out_valid_o <= data_out_valid_r;

    data_in_ready_o <= data_in_ready_r;

end rtl;