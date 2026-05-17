library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity ram is
    port (
        clk   : in  std_logic;
        valid : in  std_logic;
        addr  : in  std_logic_vector(31 downto 0);
        wdata : in  std_logic_vector(31 downto 0);
        wstrb : in  std_logic_vector( 3 downto 0);
        rdata : out std_logic_vector(31 downto 0);
        ready : out std_logic
    );
end entity;

architecture rtl of ram is

    type ram_type is array(0 to 4095) of std_logic_vector(31 downto 0);

    impure function init_ram return ram_type is
        file f     : text open read_mode is "firmware.hex";
        variable l : line;
        variable r : ram_type := (others => (others => '0'));
        variable v : std_logic_vector(31 downto 0);
    begin
        for i in ram_type'range loop
            exit when endfile(f);
            readline(f, l);
            hread(l, v);
            r(i) := v;
        end loop;
        return r;
    end function;

    signal mem : ram_type := init_ram;

begin

    process(clk)
        variable idx : integer;
    begin
        if rising_edge(clk) then
            ready <= '0';
            if valid = '1' then
                idx := to_integer(unsigned(addr(13 downto 2)));
                if wstrb = "0000" then
                    rdata <= mem(idx);
                    ready <= '1';
                else
                    if wstrb(0) = '1' then mem(idx)( 7 downto  0) <= wdata( 7 downto  0); end if;
                    if wstrb(1) = '1' then mem(idx)(15 downto  8) <= wdata(15 downto  8); end if;
                    if wstrb(2) = '1' then mem(idx)(23 downto 16) <= wdata(23 downto 16); end if;
                    if wstrb(3) = '1' then mem(idx)(31 downto 24) <= wdata(31 downto 24); end if;
                    ready <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;