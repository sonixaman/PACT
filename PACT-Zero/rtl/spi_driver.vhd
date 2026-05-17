library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_driver is
    generic (
        CLK_DIV : integer := 5; --   CLK_DIV  — SCK = clk / (CLK_DIV × 2)
        NUM_BITS : integer := 6  -- max bits of transaction
        );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        start : in std_logic;
        done  : out std_logic;
        busy : out std_logic;

        tx_data : in std_logic_vector(NUM_BITS-1 downto 0);
        rx_data : out std_logic_vector(NUM_BITS-1 downto 0);
        
        cs_sel : in std_logic_vector(1 downto 0); -- to chose the device , you can add more if you want to increase the number of devices 

        --spi interface
        mosi : out std_logic;
        miso : in std_logic;
        sck : out std_logic;
        cs_n : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of spi_driver is

    type state_type is
        ( 
        IDLE, -- start no transaction yet
        CS_LOW, -- sets the cs of the slave low 
        SCK_HIGH,
        SCK_LOW,
        CS_HIGH, -- releases the cs 
        DONE_ST -- transaction complete sends ack 
        );

        signal state : state_type := IDLE;
        signal clk_cnt : integer range 0 to CLK_DIV-1 := 0;
        signal bit_cnt : integer range 0 to NUM_BITS-1 := 0;
        signal tx_shift : std_logic_vector(NUM_BITS-1 downto 0);
        signal rx_shift : std_logic_vector(NUM_BITS -1 downto 0);
        signal sck_int : std_logic := '0';
        signal cs_n_int: std_logic_vector(3 downto 0) := "1111";

begin   
    process(clk)
    begin 
        if rising_edge(clk) then
            if reset = '1' then 
                state <= IDLE;
                sck_int <= '0';
                cs_n_int <= "1111";
                mosi <= '0';
                busy <= '0';
                done <= '0';
                clk_cnt <= 0;
                bit_cnt <= 0;
            else 
                done <= '0';

                case state is 

                when IDLE => 
                    busy <= '0';
                    sck_int <= '0';
                    cs_n_int <= "1111";

                    if start = '1' then 
                        -- take tx data and lock cs_sel
                        tx_shift <= tx_data;
                        rx_shift <= (others => '0');

                        --decode cs_sel and enable cs_n (selecting slave)
                        case cs_sel is 
                            when "00" => cs_n_int <= "1110";
                            when "01" => cs_n_int <= "1101";
                            when "10" => cs_n_int <= "1011";
                            when others => cs_n_int <= "0111";
                        end case;

                        busy <= '1';
                        bit_cnt <= NUM_BITS-1;
                        clk_cnt <= 0;
                        state <= CS_LOW;
                    end if;
                
                when CS_LOW =>
                    -- intiation of transfer 
                    mosi <= tx_shift(NUM_BITS-1);
                    clk_cnt <= clk_cnt + 1;

                    if clk_cnt = CLK_DIV-1 then 
                        clk_cnt <= 0;
                        sck_int <= '1';
                        state <= SCK_HIGH;
                    end if;

                when SCK_HIGH =>
                
                    clk_cnt <= clk_cnt +1;
                    if clk_cnt = CLK_DIV-1 then 
                        clk_cnt <= 0;
                        --read
                        rx_shift <= rx_shift(NUM_BITS-2 downto 0) & miso;
                        sck_int <= '0';
                        state <= SCK_LOW;
                    end if;
                    
                when SCK_LOW =>
                    clk_cnt <= clk_cnt + 1;
                    if clk_cnt = CLK_DIV-1 then
                        clk_cnt <= 0;
                        if bit_cnt = 0 then -- completed data transaction
                            state <= CS_HIGH;
                        else 
                            bit_cnt <= bit_cnt - 1;
                            tx_shift <= tx_shift(NUM_BITS-2 downto 0) & '0';
                            mosi <= tx_shift(NUM_BITS-2);
                            sck_int <= '1';
                            state <= SCK_HIGH;
                        end if;
                    end if;
                
                when CS_HIGH =>
                    cs_n_int <= "1111"; --cs reset
                    sck_int <= '0'; --clock reset
                    clk_cnt <= clk_cnt + 1;

                    if clk_cnt = CLK_DIV-1 then 
                        clk_cnt <= 0;
                        rx_data <= rx_shift;
                        state <= DONE_ST;
                    end if;
                
                when DONE_ST => 
                    done <= '1';
                    busy <= '0';
                    state <= IDLE;

                end case;
            end if;
        end if;
    end process;
    sck <= sck_int;
    cs_n <= cs_n_int;
end architecture;
