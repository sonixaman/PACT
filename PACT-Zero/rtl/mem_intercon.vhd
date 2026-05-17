--configB only file
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

        --phase_valid : buffer std_logic;
        --phase_ready : in std_logic;

        --to write values (continous steering )
        cmd_valid : buffer std_logic ;
        cmd_data : in std_logic_vector(31 downto 0);

        offset_ready : in std_logic ; 
        offset_valid : buffer std_logic

    );
end entity;

architecture rtl of mem_intercon is 
begin 
    process(mem_valid , mem_addr)
    begin 
        ram_valid <= '0';
        uart_valid <= '0';
        --phase_valid <='0';
        -- for continous steering functionality 
        --ignore  above statement (already implemented)
        cmd_valid <= '0';
        offset_valid <= '0';

        if mem_valid = '1' then
            
            if mem_addr(31 downto 14) = "000000000000000000" then  --00000000
                ram_valid <= '1';
            
            elsif mem_addr = x"10000000" then
                uart_valid <= '1';

             -- Uncomment to enable continuous steering
             -- Requires: cmd_reg.vhd to be implemented
             -- uncomment lines with "%" to enable
             --ignore above three comments (already implemented)

            -- a bit inconsistant but avoids clashes with writing angle once ability  
            elsif mem_addr = x"20000004" then
                cmd_valid <= '1';

            elsif mem_addr(31 downto 4) = x"2000001" then 
                offset_valid <= '1';
                
                
            
            end if;
        end if;
    end process ;

    mem_ready <= ram_ready when ram_valid = '1' else
                 uart_ready when uart_valid = '1' else
                --phase_ready when phase_valid = '1' else
                 -- for continous steering functionality 
                 -- add cmd_ready when cmd_reg.vhd ready
                 -- uncomment lines with "%" to enable
                 --ignore lines above (already implememted)
                '1'  when cmd_valid   = '1' else
                '1' when offset_valid = '1' else
                '0' ;

    mem_rdata <= ram_rdata when ram_valid = '1' else 
                cmd_data when cmd_valid = '1' else
                (others => '0');

end architecture;
