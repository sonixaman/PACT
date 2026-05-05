library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_controller is
    port (
        clk       : in    std_logic;
        reset     : in    std_logic;
        sda       : inout std_logic;
        scl       : out   std_logic;
        start     : in    std_logic;
        addr      : in    std_logic_vector(6 downto 0);
        data      : in    std_logic_vector(7 downto 0);
        busy      : out   std_logic;
        ack_error : out   std_logic
    );
end entity i2c_controller;

architecture rtl of i2c_controller is

    type i2c_state is (IDLE, START_COND, SEND_BYTE, CHECK_ACK, STOP_COND);

    signal state      : i2c_state := IDLE;
    signal next_state : i2c_state := IDLE;

    signal bit_cnt       : integer range 0 to 7   := 0;
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal byte_cnt      : integer range 0 to 1   := 0;
    signal scl_int       : std_logic := '1';
    signal sda_out       : std_logic := '1';
    signal clk_div       : integer range 0 to 999 := 0;
    signal ack_error_int : std_logic := '0';
begin

    -- -------------------------------------------------------
    -- SYNC process: state register + clock divider counter
    -- Only job: register state and count clk_div
    -- -------------------------------------------------------
    sync : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state    <= IDLE;
                bit_cnt  <= 0;
                byte_cnt <= 0;
                scl_int  <= '1';
                sda_out  <= '1';
                clk_div  <= 0;
            else
                state <= next_state;
                if state /= next_state then
                    clk_div <= 0;
                else
                    clk_div <= clk_div + 1;
                end if;

                if state /= SEND_BYTE and next_state = SEND_BYTE then
                    if byte_cnt = 0 then 
                        shift_reg <= addr & '0';
                    else
                        shift_reg <= data;
                    end if;
                end if;                   

                if state = SEND_BYTE and clk_div = 870 then 
                    shift_reg <= shift_reg(6 downto 0) & '0' ; 
                    if bit_cnt = 7 then 
                        bit_cnt <= 0;
                    else
                        bit_cnt <=bit_cnt + 1;
                    end if;
                end if;
            
                if state = CHECK_ACK and clk_div = 470 then 
                    if sda = '0' then 
                        ack_error_int <= '0';
                    else 
                        ack_error_int <= '1';
                    end if;
                end if;

                if state = CHECK_ACK and next_state = SEND_BYTE then 
                    byte_cnt <= byte_cnt + 1;
                end if;
            end if;
        end if; 
    end process sync;

    -- -------------------------------------------------------
    -- COMB process: next-state logic + output logic
    -- Fill in each state below
    -- -------------------------------------------------------
    comb : process(state, start, addr, data, bit_cnt, byte_cnt, clk_div, sda, ack_error_int)
    begin
        -- defaults (prevent latches)
        next_state <= state;
        scl_int    <= '1';
        sda_out    <= '1';
        busy       <= '0';
        ack_error  <= '0';

        case state is

            when IDLE =>
                busy    <= '0';
                scl_int <= '1';
                sda_out <= '1';
                if start = '1' then
                    next_state <= START_COND;
                end if;

            when START_COND =>
                busy <= '1';
                scl_int <= '1';
                sda_out <= '0';
                -- SCL high, SDA low
                if clk_div >= 400 then 
                   next_state <= SEND_BYTE;
                end if;

            when SEND_BYTE =>
                    busy <= '1';
                    sda_out <= shift_reg(7);
                    if clk_div < 470 then 
                        scl_int <= '0';
                    elsif clk_div < 870 then 
                        scl_int <= '1';
                    else
                        scl_int <= '0';
                        if bit_cnt = 7 then 
                            next_state <= CHECK_ACK;
                        end if; 
                    end if; 

                -- load shift_reg with addr or data
                -- toggle SCL, shift bits out
                -- after 8 bits move to CHECK_ACK

            when CHECK_ACK =>
                -- TODO: fill in
                -- release SDA, check if slave pulls low
                sda_out <= 'Z';
                busy <= '1';
                if clk_div < 470 then 
                    scl_int <= '0';
                else 
                    scl_int <= '1';
                end if; 

                if clk_div >= 870 then
                    if ack_error_int = '1' then-- if nack: set ack_error, go to STOP_COND
                        next_state <= STOP_COND;
                    else 
                        if byte_cnt = 0 then  -- if ack: go to SEND_BYTE (byte_cnt=0) or STOP_COND (byte_cnt=1)
                            next_state <= SEND_BYTE;
                        else -- or elsif byte_cnt = 7 
                            next_state <= STOP_COND;
                        end if;
                    end if;
                end if;

            when STOP_COND =>
                busy    <= '1';
                scl_int <= '1';
                if clk_div < 400 then
                    sda_out <= '0';        -- SDA low, setup time
                elsif clk_div < 870 then
                    sda_out <= '1';        -- SDA goes HIGH = STOP condition
                               -- hold for 470 cycles = bus free time
                else
                    sda_out    <= '1';
                    next_state <= IDLE;    -- bus free time done, release
                end if;
        end case;
    end process comb;

    -- Drive output ports from internal signals
    scl <= scl_int;
    sda <= sda_out when (state = SEND_BYTE or state = START_COND or state = STOP_COND)
           else 'Z';
    ack_error <= ack_error_int;
end architecture rtl;
