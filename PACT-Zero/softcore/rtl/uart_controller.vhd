library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_controller is
    port 
    (
        clk : in std_logic ;

        valid : in std_logic ;
        wdata : in std_logic_vector(31 downto 0);
        wstrb : in std_logic_vector(3 downto 0);
        ready : out std_logic
    );
end entity;

architecture rtl of uart_controller is

begin
    process(clk)
    begin 
        if rising_edge(clk) then 
            ready <= '0';
            if valid = '1' and wstrb(0) = '1' then
                report ""&character'val(to_integer(unsigned(wdata(7 downto 0))));
                ready <= '1';
            end if;
        end if;
    end process;
end architecture;
