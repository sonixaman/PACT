library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parallel_bus is 
    port
    (
        clk : in std_logic  ; 
        reset : in std_logic ;
        addr : in std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        we : in std_logic; 
        re : in std_logic;
        ack : out std_logic;
        steering_azimuth : out std_logic_vector(31 downto 0);
        steering_elevation : out std_logic_vector(31 downto 0);
        phase_0 : out std_logic_vector(31 downto 0);
        phase_1 : out std_logic_vector(31 downto 0);
        phase_2 : out std_logic_vector(31 downto 0);
        phase_3 : out std_logic_vector(31 downto 0);
        status : out std_logic_vector(31 downto 0) ; 
        control : out std_logic_vector(31 downto 0)
        -- for continuous steering functionality 
        -- add cmd_reg port for continuous softcore steering
        -- Uncomment "%" lines to enable, remove "%" before uncommenting
        -- add ',' to the line above before uncommenting
        -- % cmd_out : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of parallel_bus is
signal reg_azimuth : std_logic_vector (31 downto 0) := (others => '0');
signal reg_elevation : std_logic_vector (31 downto 0) := (others => '0');
signal reg_phase_0 : std_logic_vector (31 downto 0) := (others => '0');
signal reg_phase_1 : std_logic_vector (31 downto 0) := (others => '0');
signal reg_phase_2 : std_logic_vector (31 downto 0) := (others => '0');
signal reg_phase_3 : std_logic_vector (31 downto 0) := (others => '0');
signal reg_control : std_logic_vector (31 downto 0) := (others => '0');
signal reg_status : std_logic_vector (31 downto 0) := (others => '0');
-- for continuous steering functionality
-- add cmd register signal
-- remove "%" before uncommenting
-- % signal reg_cmd : std_logic_vector(31 downto 0) := (others => '0');

begin 
    sync : process (clk)
    begin
        if rising_edge(clk) then 
            if reset = '1' then
                reg_azimuth <= (others => '0');
                reg_elevation <= (others => '0');
                reg_control <= (others => '0');
                reg_status <= (others => '0');
                reg_phase_0 <= (others => '0');
                reg_phase_1 <= (others => '0');
                reg_phase_2 <= (others => '0');
                reg_phase_3 <= (others => '0');
                -- for continuous steering functionality
                -- remove "%" before uncommenting
                -- % reg_cmd <= (others => '0');
                ack <= '0';
            else
                --main code starts here
                ack <= '0';
                if we = '1' then 
                    case addr is 
                        when x"00" => 
                            reg_azimuth <= data_in;
                        when  x"04" =>  
                            reg_elevation <= data_in;
                        when  x"08" =>  
                            reg_phase_0 <= data_in;
                        when x"0C" =>  
                            reg_phase_1 <= data_in;
                        when x"10" => 
                            reg_phase_2 <= data_in;
                        when x"14" => 
                            reg_phase_3 <= data_in;
                        when x"18" => 
                            reg_control <= data_in;
                        -- for continuous steering functionality ; uncomment % statements
                        -- add CMD register write
                        -- address 0x20 — PicoRV32 reads this
                        -- % when x"20" => reg_cmd <= data_in;
                        when others => 
                            null; 
                    end case;
                    ack <= '1';
                end if;

                if re = '1' then 
                    case addr is 
                        when x"00" => 
                            data_out <= reg_azimuth;
                         when x"04" => 
                            data_out <= reg_elevation;
                        when x"08" => 
                            data_out <= reg_phase_0;
                        when x"0C" => 
                            data_out <= reg_phase_1;
                        when x"10" => 
                            data_out <= reg_phase_2;
                        when x"14" => 
                            data_out <= reg_phase_3;
                        when x"1C" => 
                            data_out <= reg_status;
                        when x"18" => 
                            data_out <= reg_control;
                        -- for continuous steering functionality ; uncomment % statements
                        -- add CMD register read
                        -- % when x"20" => data_out <= reg_cmd;   
                        when others => 
                            null; 
                    end case;
                    ack <= '1';
                end if;

            end if; 
    end process sync; 
    -- to add linking signal with register output 
    steering_azimuth <= reg_azimuth;
    steering_elevation <= reg_elevation;
    control <= reg_control;
    status <= reg_status;
    phase_0 <= reg_phase_0;
    phase_1 <= reg_phase_1;
    phase_2 <= reg_phase_2;
    phase_3 <= reg_phase_3;
    -- for continuous steering functionality ; uncomment % statements
    -- PACT One: connect cmd register output
    -- % cmd_out <= reg_cmd;
end architecture;

