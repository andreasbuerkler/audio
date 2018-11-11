--------------------------------------------------------------------------------
-- Author    : Andreas Buerkler
-- Date      : 04.11.2018
-- Filename  : arp_table.vhd
-- Changelog : 04.11.2018 - file created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arp_table is
generic (
    size_exp_g : positive := 3);
port (
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    -- write
    mac_i        : in  std_logic_vector(47 downto 0);
    store_ip_i   : in  std_logic_vector(31 downto 0);
    store_i      : in  std_logic;
    done_o       : out std_logic;
    -- read
    request_ip_i : in  std_logic_vector(31 downto 0);
    request_i    : in  std_logic;
    mac_o        : out std_logic_vector(47 downto 0);
    mac_valid_o  : out std_logic);
end entity arp_table;

architecture rtl of arp_table is

    type mem_t is array(natural range <>) of std_logic_vector(32+48 downto 0);
    type fsm_t is (idle_s, get_wr_addr_s, wr_s, get_rd_addr_s, done_s);

    signal mem_r       : mem_t((2**size_exp_g)-1 downto 0) := (others => (others => '0'));
    signal rd_data_r   : std_logic_vector(32+48 downto 0) := (others => '0');
    signal wr_r        : std_logic := '0';
    signal wr_addr_r   : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');
    signal rd_addr_r   : std_logic_vector(size_exp_g-1 downto 0) := (others => '0');

    signal fsm_r       : fsm_t := idle_s;
    signal done_r      : std_logic := '0';
    signal mac_r       : std_logic_vector(47 downto 0) := (others => '0');
    signal mac_valid_r : std_logic := '0';

    attribute ramstyle : string;
    attribute ramstyle of mem_r : signal is "M9K";

begin

    ram_wr_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (wr_r = '1') then
                mem_r(to_integer(unsigned(wr_addr_r))) <= mac_i & store_ip_i & '1';
            end if;
        end if;
    end process ram_wr_proc;

    ram_rd_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            rd_data_r <= mem_r(to_integer(unsigned(rd_addr_r)));
        end if;
    end process ram_rd_proc;

    fsm_proc : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            case (fsm_r) is
                when idle_s =>
                    if (store_i = '1') then
                        rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);
                        fsm_r <= get_wr_addr_s;
                    elsif (request_i = '1') then
                        rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);
                        fsm_r <= get_rd_addr_s;
                    end if;

                when get_wr_addr_s =>
                    rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);    
                    if ((rd_data_r(32 downto 1) = store_ip_i) or (rd_data_r(0) = '0')) then -- TODO: check if table is full (and overwrite an entry) / add error flag output?
                        wr_addr_r <= std_logic_vector(unsigned(rd_addr_r) - 1);
                        fsm_r <= wr_s;
                    end if;                

                when wr_s =>
                    wr_r <= '1';
                    done_r <= '1';
                    fsm_r <= done_s;

                when get_rd_addr_s =>
                    rd_addr_r <= std_logic_vector(unsigned(rd_addr_r) + 1);
                    if ((rd_data_r(32 downto 1) = request_ip_i) and (rd_data_r(0) = '1')) then -- TODO: send arp request if address is not in table / wait for answer, timeout?
                        mac_r <= rd_data_r(80 downto 33);
                        mac_valid_r <= '1';
                        fsm_r <= done_s;
                    end if;

                when done_s =>
                    wr_r <= '0';
                    done_r <= '0';
                    mac_valid_r <= '0';
                    rd_addr_r <= (others => '0');
                    fsm_r <= idle_s;

            end case;
        end if;
    end process fsm_proc;

    done_o <= done_r;
    mac_o <= mac_r;
    mac_valid_o <= mac_valid_r;

end rtl;
