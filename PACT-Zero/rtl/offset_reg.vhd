library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity offset_reg is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        
        -- from the cpu (file : mem_intercon , cpu raises valid)
        valid    : in  std_logic;
        addr     : in  std_logic_vector(3 downto 0);  -- lower 4 bits of address
        wdata    : in  std_logic_vector(31 downto 0);
        wstrb    : in  std_logic_vector(3 downto 0);
        ready    : out std_logic;

        -- to the sequencer 
        offset_00 : out std_logic_vector(7 downto 0);
        offset_10 : out std_logic_vector(7 downto 0);
        offset_01 : out std_logic_vector(7 downto 0);
        offset_11 : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of offset_reg is

    signal int_ready : std_logic := '0';
    signal int_offset_00 : std_logic_vector(7 downto 0):= (others => '0');
    signal int_offset_10 : std_logic_vector(7 downto 0):= (others => '0');
    signal int_offset_01 : std_logic_vector(7 downto 0):= (others => '0');
    signal int_offset_11 : std_logic_vector(7 downto 0):= (others => '0');
begin 
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then 
                --reset defaults 
                int_ready <= '0';
                int_offset_00 <= (others => '0');
                int_offset_10 <= (others => '0');
                int_offset_01 <= (others => '0');
                int_offset_11 <= (others => '0');
 
            else 
                int_ready <= '0';
                if valid = '1' then
                    case addr is 
                        when x"0" =>
                            if wstrb(0) = '1' then 
                                int_offset_00 <= wdata(7 downto 0);
                                int_ready <= '1';
                            end if;
                        when x"4" =>
                            if wstrb(0) = '1' then 
                                int_offset_01 <= wdata(7 downto 0);
                                int_ready <= '1';
                            end if;
                        when x"8" =>
                            if wstrb(0) = '1' then 
                                int_offset_10 <= wdata(7 downto 0);
                                int_ready <= '1';
                            end if;
                        when x"C" =>
                            if wstrb(0) = '1' then 
                                int_offset_11 <= wdata(7 downto 0);
                                int_ready <= '1';
                            end if;
                        when others => null;
                    end case ;
                end if;
            end if;
        end if;
    end process;

    ready <= int_ready;
    offset_00 <= int_offset_00;
    offset_10 <= int_offset_10;
    offset_01 <= int_offset_01;
    offset_11 <= int_offset_11;

end architecture;