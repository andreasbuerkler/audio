--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 24.11.2018
-- Filename  : eth_icmp.vhd
-- Changelog : 24.11.2018 - file created
--           : 02.12.2018 - checksum calculation and length counter fixed
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity eth_icmp is
port (
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    -- icmp tx
    icmp_valid_o : out std_logic;
    icmp_ready_i : in  std_logic;
    icmp_last_o  : out std_logic;
    icmp_data_o  : out std_logic_vector(7 downto 0);
    -- icmp rx
    icmp_valid_i : in  std_logic;
    icmp_ready_o : out std_logic;
    icmp_last_i  : in  std_logic;
    icmp_data_i  : in  std_logic_vector(7 downto 0));
end entity eth_icmp;

architecture rtl of eth_icmp is

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

    constant icmp_echo_c : std_logic_vector(7 downto 0) := x"08";
    constant icmp_reply_c : std_logic_vector(7 downto 0) := x"00";

    signal length_counter_r   : unsigned(15 downto 0) := (others => '1');
    signal send_en_r          : std_logic := '0';
    signal is_request_r       : std_logic := '0';
    signal checksum_r         : std_logic_vector(15 downto 0) := (others => '0');
    signal send_counter_r     : unsigned(3 downto 0) := (others => '0');
    signal fifo_read_enable_r : std_logic := '0';
    signal fifo_full          : std_logic;
    signal fifo_empty         : std_logic;
    signal fifo_data_in       : std_logic_vector(8 downto 0);
    signal fifo_wr_en         : std_logic;
    signal fifo_rd_en         : std_logic;
    signal fifo_data_out      : std_logic_vector(8 downto 0);
    signal fifo_store         : std_logic;
    signal fifo_reject        : std_logic;

begin

    echo_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if ((icmp_valid_i = '1') and (fifo_full = '1') and (send_en_r = '0')) then
                length_counter_r <= length_counter_r + 1;
                if (length_counter_r = to_unsigned(0, length_counter_r'length) and (icmp_data_i = icmp_echo_c)) then
                    is_request_r <= '1';
                end if;
                if (length_counter_r = to_unsigned(2, length_counter_r'length) ) then
                    checksum_r(15 downto 8) <= icmp_data_i;
                end if;
                if (length_counter_r = to_unsigned(3, length_counter_r'length) ) then
                    checksum_r(7 downto 0) <= icmp_data_i;
                end if;
                if (icmp_last_i = '1') then
                    send_en_r <= is_request_r;
                    is_request_r <= '0';
                    fifo_read_enable_r <= is_request_r;
                    checksum_r <= not checksum_add((not checksum_r), x"F7FF");
                end if;
            end if;

            if ((send_en_r = '1') and (icmp_ready_i = '1') and (fifo_empty = '1')) then
                if (send_counter_r(send_counter_r'high) = '0') then
                    send_counter_r <= send_counter_r + 1;
                end if;
                if (send_counter_r = to_unsigned(0, send_counter_r'length)) then
                    fifo_read_enable_r <= '0';
                end if;
                if (send_counter_r = to_unsigned(2, send_counter_r'length)) then
                    fifo_read_enable_r <= '1';
                end if;
                if (fifo_data_out(8) = '1') then
                    send_counter_r <= (others => '0');
                    send_en_r <= '0';
                    fifo_read_enable_r <= '0';
                    length_counter_r <= (others => '1');
                end if;
            end if;
        end if;
    end process echo_proc;

    fifo_store <= icmp_last_i and is_request_r;
    fifo_reject <= icmp_last_i and (not is_request_r);
    fifo_wr_en <= icmp_valid_i and (not send_en_r);
    fifo_data_in <= icmp_last_i & icmp_data_i;
    fifo_rd_en <= icmp_ready_i and fifo_read_enable_r;

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
        data_i   => fifo_data_in,
        wr_i     => fifo_wr_en,
        store_i  => fifo_store,
        reject_i => fifo_reject,
        full_o   => fifo_full,
        -- read port
        data_o   => fifo_data_out,
        rd_i     => fifo_rd_en,
        empty_o  => fifo_empty);

    -- icmp rx
    icmp_ready_o <= fifo_full and (not send_en_r);

    -- icmp tx
    icmp_valid_o <= send_en_r and fifo_empty;
    icmp_last_o <= fifo_data_out(8) and fifo_read_enable_r;
    icmp_data_o <= std_logic_vector(length_counter_r(15 downto 8)) when (send_counter_r = to_unsigned(1, send_counter_r'length)) else
                   std_logic_vector(length_counter_r(7 downto 0)) when (send_counter_r = to_unsigned(2, send_counter_r'length)) else
                   icmp_reply_c when (send_counter_r = to_unsigned(3, send_counter_r'length)) else
                   checksum_r(15 downto 8) when (send_counter_r = to_unsigned(5, send_counter_r'length)) else
                   checksum_r(7 downto 0) when (send_counter_r = to_unsigned(6, send_counter_r'length)) else
                   fifo_data_out(7 downto 0);

end rtl;
