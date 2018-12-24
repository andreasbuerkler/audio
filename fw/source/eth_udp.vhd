--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 22.12.2018
-- Filename  : eth_udp.vhd
-- Changelog : 22.12.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_udp is
generic (
    ctrl_port_g : std_logic_vector(15 downto 0) := x"1204");
port (
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    -- udp rx
    udp_valid_i  : in  std_logic;
    udp_ready_o  : out std_logic;
    udp_last_i   : in  std_logic;
    udp_data_i   : in  std_logic_vector(7 downto 0);
    -- udp tx
    udp_valid_o  : out std_logic;
    udp_ready_i  : in  std_logic;
    udp_last_o   : out std_logic;
    udp_data_o   : out std_logic_vector(7 downto 0);
    -- ctrl rx
    ctrl_valid_o : out std_logic;
    ctrl_ready_i : in  std_logic;
    ctrl_last_o  : out std_logic;
    ctrl_data_o  : out std_logic_vector(7 downto 0);
    -- ctrl tx
    ctrl_valid_i : in  std_logic;
    ctrl_ready_o : out std_logic;
    ctrl_last_i  : in  std_logic;
    ctrl_data_i  : in  std_logic_vector(7 downto 0));
end entity eth_udp;

architecture rtl of eth_udp is

    component fifo is
    generic (
        size_exp_g     : positive := 10;
        data_width_g   : positive := 8;
        use_reject_g   : boolean  := false;
        invert_full_g  : boolean  := false;
        invert_empty_g : boolean  := false);
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        -- write port
        data_i   : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i     : in  std_logic;
        store_i  : in  std_logic;
        reject_i : in  std_logic;
        full_o   : out std_logic;
        -- read port
        data_o   : out std_logic_vector(data_width_g-1 downto 0);
        rd_i     : in  std_logic;
        empty_o  : out std_logic);
    end component fifo;

    constant length_counter_reset_val_c : unsigned(15 downto 0) := to_unsigned(7, 16);

    type tx_fsm_t is (idle_s, packet_nr_s, total_length_s, src_port_s,
                      dst_port_s, length_s, checksum_s, payload_s);

    signal rx_offset_counter_r     : unsigned(5 downto 0) := (others => '0');
    signal rx_shift_r              : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_port_valid_r         : std_logic := '0';
    signal rx_total_length_r       : unsigned(16 downto 0) := (others => '1');
    signal rx_packet_number_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ctrl_valid_r         : std_logic := '0';
    signal rx_send_packet_number_r : std_logic := '0';
    signal rx_fifo_not_full        : std_logic;
    signal rx_fifo_not_empty       : std_logic;
    signal rx_fifo_wr_data         : std_logic_vector(8 downto 0);
    signal rx_fifo_rd_data         : std_logic_vector(8 downto 0);

    signal tx_ctrl_ready_r         : std_logic := '1';
    signal tx_fifo_wr_data         : std_logic_vector(8 downto 0);
    signal tx_fifo_rd_data         : std_logic_vector(8 downto 0);
    signal tx_fifo_not_full        : std_logic;
    signal tx_fifo_not_empty       : std_logic;
    signal tx_fifo_wr_en           : std_logic;
    signal tx_fifo_rd_en           : std_logic;
    signal tx_fifo_rd_en_r         : std_logic := '0';
    signal tx_length_counter_r     : unsigned(15 downto 0) := length_counter_reset_val_c;
    signal tx_en_r                 : std_logic := '1';
    signal tx_fsm_r                : tx_fsm_t := idle_s;
    signal tx_length_sel_r         : std_logic_vector(1 downto 0) := (others => '0');
    signal tx_port_sel_r           : std_logic_vector(1 downto 0) := (others => '0');
    signal tx_checksum_sel_r       : std_logic := '0';
    signal tx_valid_r              : std_logic := '0';

begin

    rx_fifo_wr_data <= '0' & rx_packet_number_r when (rx_send_packet_number_r = '1') else
                   udp_last_i & udp_data_i;

    i_rx_fifo : fifo
    generic map (
        size_exp_g     => 11,
        data_width_g   => 9,
        use_reject_g   => false,
        invert_full_g  => true,
        invert_empty_g => true)
    port map (
        clk_i    => clk_i,
        reset_i  => reset_i,
        -- write port
        data_i   => rx_fifo_wr_data,
        wr_i     => rx_ctrl_valid_r,
        store_i  => '0',
        reject_i => '0',
        full_o   => rx_fifo_not_full,
        -- read port
        data_o   => rx_fifo_rd_data,
        rd_i     => ctrl_ready_i,
        empty_o  => rx_fifo_not_empty);

    rx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            rx_send_packet_number_r <= '0';

            if ((udp_valid_i = '1') and (rx_fifo_not_full = '1')) then
                if (udp_last_i = '1') then
                    rx_offset_counter_r <= (others => '0');
                elsif (rx_offset_counter_r(rx_offset_counter_r'high) = '0') then
                    rx_offset_counter_r <= rx_offset_counter_r + 1;
                end if;
                rx_shift_r <= rx_shift_r(rx_shift_r'high-8 downto 0) & udp_data_i;
                if (udp_last_i = '1') then
                    rx_port_valid_r <= '0';
                    rx_ctrl_valid_r <= '0';
                end if;
                if (rx_offset_counter_r = to_unsigned(1, rx_offset_counter_r'length)) then
                    rx_packet_number_r <= rx_shift_r(7 downto 0);
                end if;
                if (rx_offset_counter_r = to_unsigned(5, rx_offset_counter_r'length)) then
                    if (ctrl_port_g = rx_shift_r) then
                        rx_port_valid_r <= '1';
                    end if;
                end if;
                if (rx_offset_counter_r = to_unsigned(7, rx_offset_counter_r'length)) then
                    rx_total_length_r <= '0' & (unsigned(rx_shift_r) - to_unsigned(7, rx_shift_r'length));
                elsif (rx_total_length_r(rx_total_length_r'high) = '0') then
                    rx_total_length_r <= rx_total_length_r - 1;
                end if;
                if (rx_total_length_r = to_unsigned(1, rx_total_length_r'length)) then
                    rx_ctrl_valid_r <= '0';
                elsif ((rx_offset_counter_r = to_unsigned(7, rx_offset_counter_r'length)) and
                       (rx_total_length_r /= to_unsigned(2, rx_total_length_r'length))) then
                    rx_send_packet_number_r <= rx_port_valid_r;
                    rx_ctrl_valid_r <= rx_port_valid_r;
                end if;
            end if;
        end if;
    end process rx_proc;

    tx_fifo_wr_data <= ctrl_last_i & ctrl_data_i;
    tx_fifo_rd_en <= udp_ready_i and tx_fifo_rd_en_r;
    tx_fifo_wr_en <= ctrl_valid_i and tx_en_r;

    i_tx_fifo : fifo
    generic map (
        size_exp_g     => 11,
        data_width_g   => 9,
        use_reject_g   => true,
        invert_full_g  => true,
        invert_empty_g => true)
    port map (
        clk_i    => clk_i,
        reset_i  => reset_i,
        -- write port
        data_i   => tx_fifo_wr_data,
        wr_i     => tx_fifo_wr_en,
        store_i  => ctrl_last_i,
        reject_i => '0',
        full_o   => tx_fifo_not_full,
        -- read port
        data_o   => tx_fifo_rd_data,
        rd_i     => tx_fifo_rd_en,
        empty_o  => tx_fifo_not_empty);

    tx_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (ctrl_last_i = '1') then
                tx_en_r <= '0';
            elsif (tx_fifo_rd_data(tx_fifo_rd_data'high) = '1') then
                tx_en_r <= '1';
            end if;
            if (tx_fifo_rd_data(tx_fifo_rd_data'high) = '1') then
                tx_length_counter_r <= length_counter_reset_val_c;
            elsif ((tx_fifo_wr_en = '1') and (tx_fifo_not_full = '1')) then
                tx_length_counter_r <= tx_length_counter_r + 1;
            end if;

            case (tx_fsm_r) is
                when idle_s =>
                    if ((tx_en_r = '0') and (tx_fifo_not_empty = '1')) then
                        tx_fifo_rd_en_r <= '1';
                        tx_fsm_r <= packet_nr_s;
                    end if;

                when packet_nr_s =>
                        tx_valid_r <= '1';
                        if (udp_ready_i = '1') then
                            tx_fifo_rd_en_r <= '0';
                            tx_length_sel_r(1) <= '1';
                            tx_fsm_r <= total_length_s;
                        end if;

                when total_length_s =>
                    if (udp_ready_i = '1') then
                        tx_length_sel_r(1) <= '0';
                        tx_length_sel_r(0) <= '1';
                        tx_fsm_r <= src_port_s;
                    end if;

                when src_port_s =>
                    if (udp_ready_i = '1') then
                        tx_length_sel_r(0) <= '0';
                        if (tx_port_sel_r(1) = '0') then
                            tx_port_sel_r(1) <= '1';
                        else
                            tx_port_sel_r(1) <= '0';
                            tx_port_sel_r(0) <= '1';
                            tx_fsm_r <= dst_port_s;
                        end if;
                    end if;

                when dst_port_s =>
                    if (udp_ready_i = '1') then
                        if (tx_port_sel_r(1) = '0') then
                            tx_port_sel_r(1) <= '1';
                            tx_port_sel_r(0) <= '0';
                        else
                            tx_port_sel_r(1) <= '0';
                            tx_port_sel_r(0) <= '1';
                            tx_fsm_r <= length_s;
                        end if;
                    end if;

                when length_s =>
                    if (udp_ready_i = '1') then
                        tx_port_sel_r(0) <= '0';
                        if (tx_length_sel_r(1) = '0') then
                            tx_length_sel_r(1) <= '1';
                        else
                            tx_length_sel_r(1) <= '0';
                            tx_length_sel_r(0) <= '1';
                            tx_fsm_r <= checksum_s;
                        end if;
                    end if;

                when checksum_s =>
                    if (udp_ready_i = '1') then
                        tx_length_sel_r(0) <= '0';
                        tx_checksum_sel_r <= '1';
                        if (tx_checksum_sel_r = '1') then
                            tx_fsm_r <= payload_s;
                        end if;
                    end if;

                when payload_s =>
                    if (udp_ready_i = '1') then
                        tx_checksum_sel_r <= '0';
                        if (tx_fifo_rd_data(tx_fifo_rd_data'high) = '1') then
                            tx_valid_r <= '0';
                            tx_fifo_rd_en_r <= '0';
                            tx_fsm_r <= idle_s;
                        else
                            tx_fifo_rd_en_r <= '1';
                        end if;
                    end if;

            end case;
        end if;
    end process tx_proc;

    -- rx
    udp_ready_o <= rx_fifo_not_full;
    ctrl_valid_o <= rx_fifo_not_empty;
    ctrl_last_o <= rx_fifo_rd_data(rx_fifo_rd_data'high);
    ctrl_data_o <= rx_fifo_rd_data(7 downto 0);

    -- tx
    ctrl_ready_o <= tx_fifo_not_full and tx_en_r;
    udp_valid_o <= tx_valid_r;
    udp_last_o <= tx_fifo_rd_data(tx_fifo_rd_data'high);
    udp_data_o <= std_logic_vector(tx_length_counter_r(15 downto 8)) when (tx_length_sel_r(1) = '1') else
                  std_logic_vector(tx_length_counter_r(7 downto 0)) when (tx_length_sel_r(0) = '1') else
                  ctrl_port_g(15 downto 8) when (tx_port_sel_r(1) = '1') else
                  ctrl_port_g(7 downto 0) when (tx_port_sel_r(0) = '1') else
                  x"00" when (tx_checksum_sel_r = '1') else
                  tx_fifo_rd_data(7 downto 0);

end rtl;
