--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 04.01.2020
-- Filename  : slave_interconnect_tb.vhd
-- Changelog : 04.01.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpga_pkg.all;

entity slave_interconnect_tb is
end entity slave_interconnect_tb;

architecture rtl of slave_interconnect_tb is

    component slave_interconnect is
    generic (
        address_map_g          : std_logic_array;
        master_data_width_g    : positive;
        master_address_width_g : positive;
        master_burst_size_g    : positive);
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        -- master
        master_address_i    : in  std_logic_vector(master_address_width_g-1 downto 0);
        master_data_i       : in  std_logic_vector(master_data_width_g-1 downto 0);
        master_data_o       : out std_logic_vector(master_data_width_g-1 downto 0);
        master_burst_size_i : in  std_logic_vector(log2ceil(master_burst_size_g)-1 downto 0);
        master_strobe_i     : in  std_logic;
        master_write_i      : in  std_logic;
        master_ack_o        : out std_logic;
        -- slave
        slave_address_o     : out std_logic_array;
        slave_data_i        : in  std_logic_array;
        slave_data_o        : out std_logic_array;
        slave_burst_size_o  : out std_logic_array;
        slave_strobe_o      : out std_logic_vector;
        slave_write_o       : out std_logic_vector;
        slave_ack_i         : in  std_logic_vector);
    end component slave_interconnect;

    constant address_map_c : std_logic_array := (0 => "000000000000----",
                                                 1 => "000000000001----",
                                                 2 => "000000000010----");

    signal clk            : std_logic := '0';
    signal clk_en         : boolean := true;

    signal slave_address    : std_logic_array(2 downto 0, 3 downto 0);
    signal slave_data_in    : std_logic_array(2 downto 0, 31 downto 0) := (x"00000000", x"00000000", x"00000000");
    signal slave_data_out   : std_logic_array(2 downto 0, 31 downto 0);
    signal slave_burst_size : std_logic_array(2 downto 0, 4 downto 0);
    signal slave_strobe     : std_logic_vector(2 downto 0);
    signal slave_write      : std_logic_vector(2 downto 0);
    signal slave_ack_r      : std_logic_vector(2 downto 0) := (others => '0');

    signal master_address_r    : std_logic_vector(15 downto 0) := (others => '0');
    signal master_read_data    : std_logic_vector(31 downto 0);
    signal master_burst_size_r : std_logic_vector(4 downto 0) := (others => '0');
    signal master_write_data_r : std_logic_vector(31 downto 0) := (others => '0');
    signal master_strobe_r     : std_logic := '0';
    signal master_write_r      : std_logic := '0';
    signal master_ack          : std_logic;

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        if (clk_en) then
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end if;
    end process clkgen_proc;

    i_interconnect : slave_interconnect
    generic map (
        address_map_g          => address_map_c,
        master_data_width_g    => 32,
        master_address_width_g => 16,
        master_burst_size_g    => 32)
    port map (
        clk_i               => clk,
        reset_i             => '0',
        -- master
        master_address_i    => master_address_r,
        master_data_i       => master_write_data_r,
        master_data_o       => master_read_data,
        master_burst_size_i => master_burst_size_r,
        master_strobe_i     => master_strobe_r,
        master_write_i      => master_write_r,
        master_ack_o        => master_ack,
        -- slave
        slave_address_o     => slave_address,
        slave_data_i        => slave_data_in,
        slave_data_o        => slave_data_out,
        slave_burst_size_o  => slave_burst_size,
        slave_strobe_o      => slave_strobe,
        slave_write_o       => slave_write,
        slave_ack_i         => slave_ack_r);

    slave_gen : for i in 0 to 2 generate
        signal register_r      : std_logic_array_32(3 downto 0) := (others => (others => '0'));
        signal read_data_r     : std_logic_vector(31 downto 0) := (others => '0');
        signal burst_counter_r : unsigned(4 downto 0) := (others => '0');
        signal write_r         : std_logic := '0';
        signal address_r       : integer := 0;
    begin
        slave_proc : process (clk)
            variable read_error_v : std_logic_vector(31 downto 0) := x"deadbeef";
        begin
            if (rising_edge(clk)) then
                slave_ack_r(i) <= '0';
                read_data_r <= x"deadbeef";
                if (slave_strobe(i) = '1') then
                    if (vector_or(std_logic_vector(burst_counter_r)) = '0') then
                        burst_counter_r <= unsigned(array_extract(i, slave_burst_size));
                        write_r <= slave_write(i);
                        address_r <= to_integer(unsigned(array_extract(i, slave_address))) + 1;

                        -- first word
                        if (slave_write(i) = '1') then
                            if (to_integer(unsigned(array_extract(i, slave_address))) < 4) then
                                register_r(to_integer(unsigned(array_extract(i, slave_address)))) <= array_extract(i, slave_data_out);
                            end if;
                            if (vector_or(std_logic_vector(unsigned(array_extract(i, slave_burst_size)))) = '0') then
                                slave_ack_r(i) <= '1';
                            end if;
                        else
                            if (to_integer(unsigned(array_extract(i, slave_address))) < 4) then
                                read_data_r <= register_r(to_integer(unsigned(array_extract(i, slave_address))));
                            end if;
                            slave_ack_r(i) <= '1';
                        end if;
                    end if;

                    -- burst write
                    if ((vector_or(std_logic_vector(burst_counter_r)) = '1') and (write_r = '1')) then
                        burst_counter_r <= burst_counter_r - 1;
                        address_r <= address_r + 1;
                        if (address_r < 4) then
                            register_r(address_r) <= array_extract(i, slave_data_out);
                        end if;
                        if (burst_counter_r = to_unsigned(1, burst_counter_r'length)) then
                            slave_ack_r(i) <= '1';
                        end if;
                    end if;
                end if;
                -- burst read
                if ((vector_or(std_logic_vector(burst_counter_r)) = '1') and (write_r = '0') and (slave_ack_r(i) = '0')) then
                    burst_counter_r <= burst_counter_r - 1;
                    address_r <= address_r + 1;
                    if (address_r < 4) then
                        read_data_r <= register_r(address_r);
                    end if;
                    slave_ack_r(i) <= '1';
                end if;
            end if;
        end process slave_proc;
        data_gen : for j in read_data_r'range generate
            slave_data_in(i, j) <= read_data_r(j);
        end generate data_gen;
    end generate slave_gen;

    ctrl_proc : process
        procedure write_word (address : in  std_logic_vector;
                              data    : in  std_logic_vector;
                              size    : in  positive) is
        begin
            master_address_r <= address;
            master_burst_size_r <= std_logic_vector(to_unsigned(size-1, master_burst_size_r'length));
            for i in 0 to size-1 loop
                master_write_data_r <= std_logic_vector(unsigned(data) + i);
                master_strobe_r <= '1';
                if (i=0) then
                    master_write_r <= '1';
                else
                    master_write_r <= '0';
                end if;
                wait until rising_edge(clk);
                master_address_r <= (others => '0');
                master_write_data_r <= (others => '0');
                master_strobe_r <= '0';
                master_write_r <= '0';
                if (i /= size-1) then
                    wait until rising_edge(clk);
                end if;
            end loop;
            if (master_ack = '0') then
                wait until master_ack = '1';
            end if;
            wait until rising_edge(clk);
        end procedure write_word;       
        procedure read_word (address : in  std_logic_vector;
                             size    : in  positive) is
        begin
            master_address_r <= address;
            master_burst_size_r <= std_logic_vector(to_unsigned(size-1, master_burst_size_r'length));
            master_strobe_r <= '1';
            master_write_r <= '0';
            wait until rising_edge(clk);
            master_address_r <= (others => '0');
            master_write_data_r <= (others => '0');
            master_strobe_r <= '0';
            for i in 0 to size-1 loop
                if (master_ack = '0') then
                    wait until master_ack = '1';
                end if;
                wait until rising_edge(clk);
            end loop;
        end procedure read_word;

    begin
        wait for 200 ns;
        wait until rising_edge(clk);

        -- write to slave 1
        write_word(x"0001", x"11223344", 1);
        -- write to slave 2
        write_word(x"0011", x"12345678", 1);
        -- write to slave 3
        write_word(x"0021", x"aabbccdd", 1);
        -- read from slave 1
        read_word(x"0001", 1);
        -- read from slave 2
        read_word(x"0011", 1);
        -- read from slave 3
        read_word(x"0021", 1);
        -- write to slave 1
        write_word(x"0000", x"00112233", 1);
        -- write to slave 1
        write_word(x"0002", x"22334455", 1);
        -- write to slave 1
        write_word(x"0003", x"33445566", 1);
        -- write burst to slave 2
        write_word(x"0010", x"abcd1234", 4);
        -- read burst from slave 2
        read_word(x"0010", 4);
        -- end of test
        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en <= false;
        wait;
    end process ctrl_proc;

end rtl;
