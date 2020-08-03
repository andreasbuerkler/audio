--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 03.08.2020
-- Filename  : interconnect_tb.vhd
-- Changelog : 03.08.2020 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fpga_pkg.all;

entity interconnect_tb is
end entity interconnect_tb;

architecture rtl of interconnect_tb is

    component interconnect is
    generic (
        data_width_g    : positive;
        address_width_g : positive;
        burst_size_g    : positive);
    port (
        clk_i                : in std_logic;
        reset_i              : in std_logic;
        -- master 0
        master0_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        master0_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        master0_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        master0_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        master0_strobe_i     : in  std_logic;
        master0_write_i      : in  std_logic;
        master0_ack_o        : out std_logic;
        -- master 1
        master1_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        master1_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        master1_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        master1_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        master1_strobe_i     : in  std_logic;
        master1_write_i      : in  std_logic;
        master1_ack_o        : out std_logic;
        -- slave 0
        slave0_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave0_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave0_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave0_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave0_strobe_o      : out std_logic;
        slave0_write_o       : out std_logic;
        slave0_ack_i         : in  std_logic;
        -- slave 1
        slave1_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave1_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave1_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave1_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave1_strobe_o      : out std_logic;
        slave1_write_o       : out std_logic;
        slave1_ack_i         : in  std_logic;
        -- slave 2
        slave2_address_o     : out std_logic_vector(address_width_g-1 downto 0);
        slave2_data_i        : in  std_logic_vector(data_width_g-1 downto 0);
        slave2_data_o        : out std_logic_vector(data_width_g-1 downto 0);
        slave2_burst_size_o  : out std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        slave2_strobe_o      : out std_logic;
        slave2_write_o       : out std_logic;
        slave2_ack_i         : in  std_logic);
    end component interconnect;

    component registerbank is
    generic (
        register_count_g : positive;
        register_init_g  : std_logic_array_32;
        register_mask_g  : std_logic_array_32;
        read_only_g      : std_logic_vector;
        data_width_g     : positive;
        address_width_g  : positive;
        burst_size_g     : positive);
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        -- register
        data_i            : in  std_logic_array_32(register_count_g-1 downto 0);
        data_strb_i       : in  std_logic_vector(register_count_g-1 downto 0);
        data_o            : out std_logic_array_32(register_count_g-1 downto 0);
        data_strb_o       : out std_logic_vector(register_count_g-1 downto 0);
        -- ctrl bus
        ctrl_address_i    : in  std_logic_vector(address_width_g-1 downto 0);
        ctrl_data_i       : in  std_logic_vector(data_width_g-1 downto 0);
        ctrl_data_o       : out std_logic_vector(data_width_g-1 downto 0);
        ctrl_burst_size_i : in  std_logic_vector(log2ceil(burst_size_g)-1 downto 0);
        ctrl_strobe_i     : in  std_logic;
        ctrl_write_i      : in  std_logic;
        ctrl_ack_o        : out std_logic);
    end component registerbank;

    constant register_count_c : positive := 32;
    constant read_only_c      : std_logic_vector(register_count_c-1 downto 0) := (others => '0');
    constant register_init_c  : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    constant register_mask_c : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '1'));

    signal clk     : std_logic := '0';
    signal clk_en0 : boolean := true;
    signal clk_en1 : boolean := true;

    signal register_read_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    signal register_read_strb : std_logic_vector(register_count_c-1 downto 0) := (others => '0');

    -- ctrl bus master 0
    signal m0_address    : std_logic_vector(23 downto 0) := (others => '0');
    signal m0_read_data  : std_logic_vector(31 downto 0);
    signal m0_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal m0_burst_size : std_logic_vector(log2ceil(16)-1 downto 0) := (others => '0');
    signal m0_strobe     : std_logic := '0';
    signal m0_write      : std_logic := '0';
    signal m0_ack        : std_logic;

    -- ctrl bus master 1
    signal m1_address    : std_logic_vector(23 downto 0) := (others => '0');
    signal m1_read_data  : std_logic_vector(31 downto 0);
    signal m1_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal m1_burst_size : std_logic_vector(log2ceil(16)-1 downto 0) := (others => '0');
    signal m1_strobe     : std_logic := '0';
    signal m1_write      : std_logic := '0';
    signal m1_ack        : std_logic;

    -- ctrl bus slave 0
    signal s0_address    : std_logic_vector(23 downto 0);
    signal s0_read_data  : std_logic_vector(31 downto 0);
    signal s0_write_data : std_logic_vector(31 downto 0);
    signal s0_burst_size : std_logic_vector(log2ceil(16)-1 downto 0);
    signal s0_strobe     : std_logic;
    signal s0_write      : std_logic;
    signal s0_ack        : std_logic;

    -- ctrl bus slave 1
    signal s1_address    : std_logic_vector(23 downto 0);
    signal s1_read_data  : std_logic_vector(31 downto 0);
    signal s1_write_data : std_logic_vector(31 downto 0);
    signal s1_burst_size : std_logic_vector(log2ceil(16)-1 downto 0);
    signal s1_strobe     : std_logic;
    signal s1_write      : std_logic;
    signal s1_ack        : std_logic;

    -- ctrl bus slave 2
    signal s2_address    : std_logic_vector(23 downto 0);
    signal s2_read_data  : std_logic_vector(31 downto 0);
    signal s2_write_data : std_logic_vector(31 downto 0);
    signal s2_burst_size : std_logic_vector(log2ceil(16)-1 downto 0);
    signal s2_strobe     : std_logic;
    signal s2_write      : std_logic;
    signal s2_ack        : std_logic;

    -- register reference
    shared variable slave0_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    shared variable slave1_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));
    shared variable slave2_data : std_logic_array_32(register_count_c-1 downto 0) := (others => (others => '0'));

begin

    -- 50 MHz
    clkgen_proc : process
    begin
        if (clk_en0 or clk_en1) then
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end if;
    end process clkgen_proc;

    i_dut : interconnect
    generic map (
        data_width_g    => 32,
        address_width_g => 24,
        burst_size_g    => 16)
    port map (
        clk_i                => clk,
        reset_i              => '0',
        -- master 0
        master0_address_i    => m0_address,
        master0_data_i       => m0_write_data,
        master0_data_o       => m0_read_data,
        master0_burst_size_i => m0_burst_size,
        master0_strobe_i     => m0_strobe,
        master0_write_i      => m0_write,
        master0_ack_o        => m0_ack,
        -- master 1
        master1_address_i    => m1_address,
        master1_data_i       => m1_write_data,
        master1_data_o       => m1_read_data,
        master1_burst_size_i => m1_burst_size,
        master1_strobe_i     => m1_strobe,
        master1_write_i      => m1_write,
        master1_ack_o        => m1_ack,    
        -- slave 0
        slave0_address_o     => s0_address,
        slave0_data_i        => s0_read_data,
        slave0_data_o        => s0_write_data,
        slave0_burst_size_o  => s0_burst_size,
        slave0_strobe_o      => s0_strobe,
        slave0_write_o       => s0_write,
        slave0_ack_i         => s0_ack,
        -- slave 1
        slave1_address_o     => s1_address,
        slave1_data_i        => s1_read_data,
        slave1_data_o        => s1_write_data,
        slave1_burst_size_o  => s1_burst_size,
        slave1_strobe_o      => s1_strobe,
        slave1_write_o       => s1_write,
        slave1_ack_i         => s1_ack,
        -- slave 2
        slave2_address_o     => s2_address,
        slave2_data_i        => s2_read_data,
        slave2_data_o        => s2_write_data,
        slave2_burst_size_o  => s2_burst_size,
        slave2_strobe_o      => s2_strobe,
        slave2_write_o       => s2_write,
        slave2_ack_i         => s2_ack);

    i_registerbank0 : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => read_only_c,
        data_width_g     => 32,
        address_width_g  => 20,
        burst_size_g     => 16)
    port map (
        clk_i             => clk,
        reset_i           => '0',
        -- register
        data_i            => register_read_data,
        data_strb_i       => register_read_strb,
        data_o            => open,
        data_strb_o       => open,
        -- ctrl bus
        ctrl_address_i    => s0_address(21 downto 2),
        ctrl_data_i       => s0_write_data,
        ctrl_data_o       => s0_read_data,
        ctrl_burst_size_i => s0_burst_size,
        ctrl_strobe_i     => s0_strobe,
        ctrl_write_i      => s0_write,
        ctrl_ack_o        => s0_ack);

    i_registerbank1 : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => read_only_c,
        data_width_g     => 32,
        address_width_g  => 20,
        burst_size_g     => 16)
    port map (
        clk_i             => clk,
        reset_i           => '0',
        -- register
        data_i            => register_read_data,
        data_strb_i       => register_read_strb,
        data_o            => open,
        data_strb_o       => open,
        -- ctrl bus
        ctrl_address_i    => s1_address(21 downto 2),
        ctrl_data_i       => s1_write_data,
        ctrl_data_o       => s1_read_data,
        ctrl_burst_size_i => s1_burst_size,
        ctrl_strobe_i     => s1_strobe,
        ctrl_write_i      => s1_write,
        ctrl_ack_o        => s1_ack);

    i_registerbank2 : registerbank
    generic map (
        register_count_g => register_count_c,
        register_init_g  => register_init_c,
        register_mask_g  => register_mask_c,
        read_only_g      => read_only_c,
        data_width_g     => 32,
        address_width_g  => 20,
        burst_size_g     => 16)
    port map (
        clk_i             => clk,
        reset_i           => '0',
        -- register
        data_i            => register_read_data,
        data_strb_i       => register_read_strb,
        data_o            => open,
        data_strb_o       => open,
        -- ctrl bus
        ctrl_address_i    => s2_address(21 downto 2),
        ctrl_data_i       => s2_write_data,
        ctrl_data_o       => s2_read_data,
        ctrl_burst_size_i => s2_burst_size,
        ctrl_strobe_i     => s2_strobe,
        ctrl_write_i      => s2_write,
        ctrl_ack_o        => s2_ack);

    master0_proc : process
        procedure write_word (address : in  std_logic_vector;
                              data    : in  std_logic_array_32;
                              size    : in  positive) is
        begin
            m0_address <= address;
            m0_burst_size <= std_logic_vector(to_unsigned(size-1, m0_burst_size'length));
            for i in 0 to size-1 loop
                m0_write_data <= std_logic_vector(unsigned(data(i)));
                m0_strobe <= '1';
                if (i=0) then
                    m0_write <= '1';
                else
                    m0_write <= '0';
                end if;
                wait until rising_edge(clk);
                m0_address <= (others => '0');
                m0_write_data <= (others => '0');
                m0_strobe <= '0';
                m0_write <= '0';
            end loop;
            if (m0_ack = '0') then
                wait until m0_ack = '1';
            end if;
        end procedure write_word;

        procedure read_word (address : in  std_logic_vector;
                             data    : out std_logic_array_32;
                             size    : in  positive) is
        begin
            m0_address <= address;
            m0_burst_size <= std_logic_vector(to_unsigned(size-1, m0_burst_size'length));
            m0_strobe <= '1';
            m0_write <= '0';
            wait until rising_edge(clk);
            m0_address <= (others => '0');
            m0_write_data <= (others => '0');
            m0_strobe <= '0';
            for i in 0 to size-1 loop
                if (m0_ack = '0') then
                    wait until m0_ack = '1';
                end if;
                wait until rising_edge(clk);
                data(i) := m0_read_data;
            end loop;
        end procedure read_word;

        procedure get_data(data  : out   std_logic_vector;
                           seed0 : inout integer;
                           seed1 : inout integer;
                           rand  : inout real) is
            variable range_v : integer;
        begin
            if (data'length >= 32) then
                range_v := (2**31)-1; -- integer is only 32bit
            else
                range_v := (2**data'length)-1;
            end if;
            uniform(seed0, seed1, rand);
            data := std_logic_vector(to_unsigned(natural(rand*real(range_v)), data'length));
        end procedure get_data;

        variable temp_data_v     : std_logic_array_32(15 downto 0);
        variable temp_addr_v     : std_logic_vector(23 downto 0) := (others => '0');
        variable temp_rw_sel_v   : std_logic_vector(0 downto 0);
        variable temp_length_v   : std_logic_vector(3 downto 0);
        variable seed0_v         : integer := 2;
        variable seed1_v         : integer := 3;
        variable rand_v          : real;
        variable expected_data_v : std_logic_vector(31 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);

        for i in 0 to 999 loop
            -- get random data
            for j in 0 to 15 loop
                get_data(temp_data_v(j), seed0_v, seed1_v, rand_v);
            end loop;
            get_data(temp_addr_v(23 downto 22), seed0_v, seed1_v, rand_v); -- slave select
            get_data(temp_addr_v(4 downto 2), seed0_v, seed1_v, rand_v); -- address
            get_data(temp_rw_sel_v, seed0_v, seed1_v, rand_v); -- read or write
            get_data(temp_length_v, seed0_v, seed1_v, rand_v); -- burst length
            if (temp_addr_v(23) = '1') then
                temp_addr_v(22) := '0'; -- there are only 3 slaves, nothing is at address beginning with "11"
            end if;
            
            if (temp_rw_sel_v(0) = '0') then
                -- write
                write_word(temp_addr_v, temp_data_v, to_integer(unsigned(temp_length_v))+1);
                for j in 0 to to_integer(unsigned(temp_length_v)) loop
                    case (temp_addr_v(23 downto 22)) is
                        when "00" => slave0_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                        when "01" => slave1_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                        when others => slave2_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                    end case;
                end loop;
                wait until rising_edge(clk);
            else
                --read
                read_word(temp_addr_v, temp_data_v, to_integer(unsigned(temp_length_v))+1);
                for j in 0 to to_integer(unsigned(temp_length_v)) loop
                    case (temp_addr_v(23 downto 22)) is
                        when "00" => expected_data_v := slave0_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                        when "01" => expected_data_v := slave1_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                        when others => expected_data_v := slave2_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                    end case;
                    assert (temp_data_v(j) = expected_data_v) report "master 0 read data error" &
                        ", expected " & integer'image(to_integer(unsigned(expected_data_v))) &
                        ", got " & integer'image(to_integer(unsigned(temp_data_v(j)))) &
                        ", index " & integer'image(j) severity error;
                end loop;
            end if;
        end loop;

        report "done";
        clk_en0 <= false;
        wait;
    end process master0_proc;

    master1_proc : process
        procedure write_word (address : in  std_logic_vector;
                              data    : in  std_logic_array_32;
                              size    : in  positive) is
        begin
            m1_address <= address;
            m1_burst_size <= std_logic_vector(to_unsigned(size-1, m1_burst_size'length));
            for i in 0 to size-1 loop
                m1_write_data <= std_logic_vector(unsigned(data(i)));
                m1_strobe <= '1';
                if (i=0) then
                    m1_write <= '1';
                else
                    m1_write <= '0';
                end if;
                wait until rising_edge(clk);
                m1_address <= (others => '0');
                m1_write_data <= (others => '0');
                m1_strobe <= '0';
                m1_write <= '0';
            end loop;
            if (m1_ack = '0') then
                wait until m1_ack = '1';
            end if;
        end procedure write_word;

        procedure read_word (address : in  std_logic_vector;
                             data    : out std_logic_array_32;
                             size    : in  positive) is
        begin
            m1_address <= address;
            m1_burst_size <= std_logic_vector(to_unsigned(size-1, m1_burst_size'length));
            m1_strobe <= '1';
            m1_write <= '0';
            wait until rising_edge(clk);
            m1_address <= (others => '0');
            m1_write_data <= (others => '0');
            m1_strobe <= '0';
            for i in 0 to size-1 loop
                if (m1_ack = '0') then
                    wait until m1_ack = '1';
                end if;
                wait until rising_edge(clk);
                data(i) := m1_read_data;
            end loop;
        end procedure read_word;

        procedure get_data(data  : out   std_logic_vector;
                           seed0 : inout integer;
                           seed1 : inout integer;
                           rand  : inout real) is
            variable range_v : integer;
        begin
            if (data'length >= 32) then
                range_v := (2**31)-1; -- integer is only 32bit
            else
                range_v := (2**data'length)-1;
            end if;
            uniform(seed0, seed1, rand);
            data := std_logic_vector(to_unsigned(natural(rand*real(range_v)), data'length));
        end procedure get_data;

        variable temp_data_v     : std_logic_array_32(15 downto 0);
        variable temp_addr_v     : std_logic_vector(23 downto 0) := (others => '0');
        variable temp_rw_sel_v   : std_logic_vector(0 downto 0);
        variable temp_length_v   : std_logic_vector(3 downto 0);
        variable seed0_v         : integer := 3;
        variable seed1_v         : integer := 2;
        variable rand_v          : real;
        variable expected_data_v : std_logic_vector(31 downto 0);
    begin
        wait for 200 ns;
        wait until rising_edge(clk);

        for i in 0 to 999 loop
            -- get random data
            for j in 0 to 15 loop
                get_data(temp_data_v(j), seed0_v, seed1_v, rand_v);
            end loop;
            get_data(temp_addr_v(23 downto 22), seed0_v, seed1_v, rand_v); -- slave select
            get_data(temp_addr_v(4 downto 2), seed0_v, seed1_v, rand_v); -- address
            get_data(temp_rw_sel_v, seed0_v, seed1_v, rand_v); -- read or write
            get_data(temp_length_v, seed0_v, seed1_v, rand_v); -- burst length
            if (temp_addr_v(23) = '1') then
                temp_addr_v(22) := '0'; -- there are only 3 slaves, nothing is at address beginning with "11"
            end if;
            
            if (temp_rw_sel_v(0) = '0') then
                -- write
                write_word(temp_addr_v, temp_data_v, to_integer(unsigned(temp_length_v))+1);
                for j in 0 to to_integer(unsigned(temp_length_v)) loop
                    case (temp_addr_v(23 downto 22)) is
                        when "00" => slave0_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                        when "01" => slave1_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                        when others => slave2_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j) := temp_data_v(j);
                    end case;
                end loop;
                wait until rising_edge(clk);
            else
                --read
                read_word(temp_addr_v, temp_data_v, to_integer(unsigned(temp_length_v))+1);
                for j in 0 to to_integer(unsigned(temp_length_v)) loop
                    case (temp_addr_v(23 downto 22)) is
                        when "00" => expected_data_v := slave0_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                        when "01" => expected_data_v := slave1_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                        when others => expected_data_v := slave2_data(to_integer(unsigned(temp_addr_v(4 downto 2)))+j);
                    end case;
                    assert (temp_data_v(j) = expected_data_v) report "master 1 read data error" &
                        ", expected " & integer'image(to_integer(unsigned(expected_data_v))) &
                        ", got " & integer'image(to_integer(unsigned(temp_data_v(j)))) &
                        ", index " & integer'image(j) severity error;
                end loop;
            end if;
        end loop;

        -- end of test
        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;
        report "done";
        clk_en1 <= false;
        wait;
    end process master1_proc;

end rtl;
