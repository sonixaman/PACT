library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity mem_intercon is 
    
    
    port
    (
        mem_addr : in std_logic_vector (31 downto 0); --read from here 
        mem_valid : in std_logic;
        mem_wdata : in std_logic_vector(31 downto 0); --write to this
        mem_wstrb : in std_logic_vector(3 downto 0); --write this 
        mem_ready : out std_logic; --check if ready
        mem_rdata : out std_logic_vector (31 downto 0); -- read from here

        ram_ready : in std_logic ; --check if ram is idle
        ram_rdata : in std_logic_vector(31 downto 0);
        ram_valid : buffer std_logic;

        uart_valid : buffer std_logic;
        uart_ready : in std_logic;

        phase_valid : buffer std_logic;
        phase_ready : in std_logic
    );
end entity;

architecture rtl of mem_intercon is 
begin 
    process(mem_valid , mem_addr)
    begin 
        ram_valid <= '0';
        uart_valid <= '0';
        phase_valid <='0';

        if mem_valid = '1' then
            
            if mem_addr(31 downto 14) = (31 downto 14 => '0') then 
                ram_valid <= '1';
            
            elsif mem_addr = x"10000000" then
                uart_valid <= '1';

            elsif mem_addr = x"20000000" then
                phase_valid <= '1';
            end if;
        end if;
    end process ;

    mem_ready <= ram_ready when ram_valid = '1' else
                 uart_ready when uart_valid = '1' else
                phase_ready when phase_valid = '1' else
                '0' ;

    mem_rdata <= ram_rdata when ram_valid = '1' else
        ((others => '0') );

end architecture;
