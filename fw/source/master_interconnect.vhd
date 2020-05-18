--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 18.05.2020
-- Filename  : master_interconnect.vhd
-- Changelog : 18.05.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity master_interconnect is
generic (
    number_of_masters_g : positive := 2;
    data_width_g        : positive := 32;
    address_width_g     : positive := 16;
    burst_size_g        : positive := 32);
port (
    clk_i               : in std_logic;
    reset_i             : in std_logic;
    -- master
    master_address_i    : in  std_logic_array;
    master_data_i       : in  std_logic_array;
    master_data_o       : out std_logic_array;
    master_burst_size_i : in  std_logic_array;
    master_strobe_i     : in  std_logic_vector;
    master_write_i      : in  std_logic_vector;
    master_ack_o        : out std_logic_vector;
    -- slave
    slave_address_o     : out std_logic_vector(address_width_g-1 downto 0);
    slave_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
    slave_data_o        : out std_logic_vector(data_width_g-1 downto 0);
    slave_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    slave_strobe_o      : out std_logic;
    slave_write_o       : out std_logic;
    slave_ack_i         : in  std_logic);
end entity master_interconnect;

architecture rtl of master_interconnect is

    component fifo is
    generic (
        size_exp_g     : positive;
        data_width_g   : positive;
        use_reject_g   : boolean;
        invert_full_g  : boolean;
        invert_empty_g : boolean);
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        -- write port
        data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        wr_i         : in  std_logic;
        store_i      : in  std_logic;
        reject_i     : in  std_logic;
        full_o       : out std_logic;
        -- read port
        data_o       : out std_logic_vector(data_width_g-1 downto 0);
        rd_i         : in  std_logic;
        empty_o      : out std_logic);
    end component fifo;

    signal master_sel_r            : std_logic_vector(number_of_masters_g-1 downto 0) := std_logic_vector(to_unsigned(1, number_of_masters_g));
    signal master_write_r          : std_logic_vector(number_of_masters_g-1 downto 0) := (others => '0');
    signal master_burst_size_r     : std_logic_array(number_of_masters_g-1 downto 0, log2ceil(burst_size_g)-1 downto 0) := (others => (others => '0'));
    signal master_address_r        : std_logic_array(number_of_masters_g-1 downto 0, address_width_g-1 downto 0) := (others => (others => '0'));
    signal master_data             : std_logic_array(number_of_masters_g-1 downto 0, data_width_g-1 downto 0);
    signal master_data_available_r : std_logic_vector(number_of_masters_g-1 downto 0) := (others => '0');

    signal slave_address_a         : std_logic_vector(address_width_g-1 downto 0);
    signal slave_address_r         : std_logic_vector(address_width_g-1 downto 0) := (others => '0');
    signal slave_burst_size_a      : std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
    signal slave_burst_size_r      : std_logic_vector(log2ceil(burst_size_g)-1 downto 0) := (others => '0');
    signal slave_write_a           : std_logic;
    signal slave_write_r           : std_logic := '0';
    signal slave_write_data        : std_logic_vector(data_width_g-1 downto 0);
    signal slave_ack               : std_logic_vector(number_of_masters_g-1 downto 0);

    signal fifo_empty              : std_logic_vector(number_of_masters_g-1 downto 0);
    signal fifo_empty_a            : std_logic;
    signal fifo_read_r             : std_logic_vector(number_of_masters_g-1 downto 0) := (others => '0');

    signal burst_counter_r         : unsigned(log2ceil(burst_size_g)-1 downto 0) := (others => '0');
    signal burst_in_progress_r     : std_logic := '0';

    signal read_data               : std_logic_array(number_of_masters_g-1 downto 0, data_width_g-1 downto 0);

begin

    master_gen : for i in 0 to number_of_masters_g-1 generate
        signal fifo_read_data : std_logic_vector(data_width_g-1 downto 0);
        signal write_data     : std_logic_vector(data_width_g-1 downto 0);
    begin
        write_data <= array_extract(i, master_data_i);

        i_fifo : fifo
        generic map (
            size_exp_g     => 8,
            data_width_g   => data_width_g,
            use_reject_g   => false,
            invert_full_g  => false,
            invert_empty_g => false)
        port map (
            clk_i    => clk_i,
            reset_i  => reset_i,
            -- write port
            data_i   => write_data,
            wr_i     => master_strobe_i(i),
            store_i  => '0',
            reject_i => '0',
            full_o   => open,
            -- read port
            data_o   => fifo_read_data,
            rd_i     => fifo_read_r(i),
            empty_o  => fifo_empty(i));

        master_data_gen : for j in 0 to log2ceil(burst_size_g)-1 generate
            master_data(i, j) <= fifo_read_data(j);
        end generate master_data_gen;

        data_proc : process (clk_i)
        begin
            if (rising_edge(clk_i)) then
                if ((master_data_available_r(i) = '0') and (master_strobe_i(i) = '1')) then
                    master_write_r(i) <= master_write_i(i);
                    for j in 0 to log2ceil(burst_size_g)-1 loop
                        master_burst_size_r(i, j) <= master_burst_size_i(i, j);
                    end loop;
                    for j in 0 to address_width_g-1 loop
                        master_address_r(i, j) <= master_address_i(i, j);
                    end loop;
                    master_data_available_r(i) <= '1';
                end if;
                if ((burst_in_progress_r = '1') and (vector_or(burst_counter_r) = '0') and (master_sel_r(i) = '1')) then
                    master_data_available_r(i) <= '0';
                end if;
            end if;
        end process data_proc;
    end generate master_gen;

    select_async_proc : process(master_sel_r, master_address_r, master_burst_size_r, master_write_r, fifo_empty)
    begin
        slave_address_a <= array_extract(0, master_address_r);
        slave_burst_size_a <= array_extract(0, master_burst_size_r);
        slave_write_a <= master_write_r(0);
        fifo_empty_a <= fifo_empty(0);
        for i in 0 to number_of_masters_g-1 loop
            if (master_sel_r(i) = '1') then
                slave_address_a <= array_extract(i, master_address_r);
                slave_burst_size_a <= array_extract(i, master_burst_size_r);
                slave_write_a <= master_write_r(i);
                fifo_empty_a <= fifo_empty(i);
            end if;
        end loop;
    end process select_async_proc;

    select_proc : process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (vector_or(master_data_available_r and master_sel_r) = '0') then
                master_sel_r <= master_sel_r(master_sel_r'high-1 downto 0) & master_sel_r(master_sel_r'high);
            else
                for i in 0 to number_of_masters_g-1 loop
                    if (master_sel_r(i) = '1') then
                        slave_address_r <= slave_address_a;
                        slave_burst_size_r <= slave_burst_size_a;
                        slave_write_r <= slave_write_a;
                    end if;
                end loop;
            end if;
        end if;
    end process select_proc;

    transfer_proc : process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            fifo_read_r <= (others => '0');
            if (vector_or(master_data_available_r and master_sel_r) = '1') then
                -- burst count
                if ((vector_or(burst_counter_r) = '0') and (burst_in_progress_r = '0')) then
                    burst_counter_r <= unsigned(slave_burst_size_a);
                    burst_in_progress_r <= '1';
                elsif (vector_or(burst_counter_r) = '1') then
                    if (((fifo_empty_a = '0') and (slave_write_a = '1')) or ((slave_write_a = '0') and (slave_ack_i = '1'))) then
                        burst_counter_r <= burst_counter_r - 1;
                    end if;
                else
                    burst_in_progress_r <= '0';
                end if;
                -- read command / data
                if (fifo_empty_a = '0') then
                    fifo_read_r <= master_sel_r;
                end if;
            end if;
        end if;
    end process transfer_proc;

    write_data_proc : process (master_data, master_sel_r)
    begin
        slave_write_data <= array_extract(0, master_data);
        for i in 0 to number_of_masters_g-1 loop
            if (master_sel_r(i) = '1') then
                slave_write_data <= array_extract(i, master_data);
            end if;
        end loop;
    end process write_data_proc;

    read_data_proc : process (slave_data_i)
    begin
        for i in 0 to number_of_masters_g-1 loop
            for j in 0 to data_width_g-1 loop
                read_data(i, j) <= slave_data_i(j);
            end loop;
        end loop;
    end process read_data_proc;

    ack_proc : process (master_sel_r, slave_ack_i)
    begin
        slave_ack <= (others => '0');
        for i in 0 to number_of_masters_g-1 loop
            if (master_sel_r(i) = '1') then
                slave_ack(i) <= slave_ack_i;
            end if;
        end loop;
    end process ack_proc;

    master_data_o <= read_data;
    master_ack_o <= slave_ack;

    slave_data_o <= slave_write_data;
    slave_address_o <= slave_address_r;
    slave_burst_size_o <= slave_burst_size_r;
    slave_write_o <= slave_write_r;
    slave_strobe_o <= vector_or(fifo_read_r);

end rtl;
