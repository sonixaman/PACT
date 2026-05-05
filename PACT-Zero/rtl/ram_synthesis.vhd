library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is 
    port
        (
            clk : in std_logic;

            valid : in std_logic;
            addr : in std_logic_vector(31 downto 0);
            wdata : in std_logic_vector(31 downto 0);
            wstrb : in std_logic_vector( 3 downto 0) ;
            
            rdata : out std_logic_vector(31 downto 0);
            ready : out std_logic
        );
end entity;

architecture rtl of ram is 

    type ram_type is array(0 to 4095) of std_logic_vector(31 downto 0);
    signal mem : ram_type := (others => (others => '0'));
    
begin 

    process(clk)
        variable idx : integer;
    begin 
        if rising_edge(clk) then
            ready <= '0'; --idle mode

            if valid = '1' then 
                --byte adress conversion 
                idx := to_integer(unsigned(addr(13 downto 2)));

                if wstrb = "0000" then 
                    rdata <= mem(idx);
                    ready <= '1'; -- now it ready 
                else 
                    if wstrb(0) = '1' then 
                        mem(idx)( 7 downto 0) <= wdata(7 downto 0);
                    end if;
                    if wstrb(1) = '1' then 
                        mem(idx)( 15 downto 8) <= wdata(15 downto 8);
                    end if;
                    if wstrb(2) = '1' then 
                        mem(idx)( 23 downto 16) <= wdata(23 downto 16);
                    end if;
                    if wstrb(3) = '1' then 
                        mem(idx)( 31 downto 24) <= wdata(31 downto 24);
                    end if;
                    ready <= '1';
                end if;
            end if;
        end if;
    end process;
end architecture;
