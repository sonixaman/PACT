library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_accumulator is
    port(
            clk : in std_logic; 
            reset : in std_logic;
            phase_inc : in std_logic_vector(31 downto 0);
            offset : in std_logic_vector( 31 downto 0) ;
            phase_out : out std_logic_vector( 31 downto 0)
    );
end entity phase_accumulator ; 

architecture rtl1 of phase_accumulator is 
    signal accumulator : unsigned(31 downto 0) := (others=> '0');
begin 
    sync : process (clk)
    begin 
        if rising_edge(clk) then 
            if reset = '1' then
                accumulator <= (others => '0');
            else
                 accumulator <= accumulator+ unsigned(phase_inc);
            end if;
        end if;
    end process sync;
    phase_out <= std_logic_vector(accumulator + unsigned(offset));
end architecture rtl1;
