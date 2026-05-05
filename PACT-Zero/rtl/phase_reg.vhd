library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_reg is
    port
    (
        clk : in std_logic; 

        azimuth_out : out std_logic_vector(15 downto 0);
        elevation_out : out std_logic_vector(15 downto 0);

        -- from/to the cpu
        valid : in  std_logic;
        wdata : in  std_logic_vector(31 downto 0); --read from here
        wstrb : in  std_logic_vector( 3 downto 0);
        ready : out std_logic
    );
end entity;

architecture rtl of phase_reg is
signal phase_reg_int : std_logic_vector(31 downto 0) := (others => '0');
begin
    process(clk)
    begin 
        if rising_edge(clk) then 
            ready <= '0';
            if valid = '1' and wstrb = "1111" then 
                phase_reg_int <= wdata;
                ready <= '1';
            end if;
        end if;
    end process;
    azimuth_out     <= phase_reg_int(15 downto 0);
    elevation_out   <= phase_reg_int(31 downto 16);
end architecture;