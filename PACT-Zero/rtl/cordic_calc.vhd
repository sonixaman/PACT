library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordic_calc is
    port(
        clk : in std_logic ;
        reset : in std_logic;
        phase_input : in std_logic_vector(15 downto 0);
        sin_value : out std_logic_vector(15 downto 0) ;
        cos_value : out std_logic_vector(15 downto 0) 


    );
    end entity cordic_calc;

architecture sincostan of cordic_calc is 
    signal angle_inst : signed(15 downto 0) := (others => '0') ;
    type t_arctan is array (0 to 15) of signed (15 downto 0);
    constant ATAN_TABLE : t_arctan := 
        (
        to_signed(8192,  16),  -- arctan(2^0)  = 45° resolution convert 
        to_signed(4836,  16),  -- arctan(2^-1) = 26.57°
        to_signed(2555,  16),  -- arctan(2^-2) = 14.04°
        to_signed(1297,  16),  -- arctan(2^-3) = 7.13°
        to_signed(651,   16),  -- arctan(2^-4) = 3.58°
        to_signed(326,   16),  -- arctan(2^-5) = 1.79°
        to_signed(163,   16),  -- arctan(2^-6) = 0.895°
        to_signed(81,    16),  -- arctan(2^-7) = 0.448°
        to_signed(41,    16),  -- arctan(2^-8)
        to_signed(20,    16),  -- arctan(2^-9)
        to_signed(10,    16),  -- arctan(2^-10)
        to_signed(5,     16),  -- arctan(2^-11)
        to_signed(3,     16),  -- arctan(2^-12)
        to_signed(1,     16),  -- arctan(2^-13)
        to_signed(1,     16),  -- arctan(2^-14)
        to_signed(0,     16)   -- arctan(2^-15)
        );

    type t_pipe is array (0 to 16) of signed(15 downto 0);
    signal x_pipe : t_pipe;
    signal y_pipe : t_pipe;
    signal z_pipe : t_pipe;
    signal negate_sin : std_logic := '0';
    signal negate_cos : std_logic := '0';
    signal adj_phase : signed(15 downto 0) := (others => '0');
    constant cordic_gain : signed(15 downto 0) := to_signed(19898, 16);

begin 
    sync : process(clk)
    begin 
        if rising_edge(clk) then 
            if reset = '1' then 
                sin_value <= (others => '0');
                cos_value <= (others => '0');
                x_pipe <= (others => (others => '0'));
                y_pipe <= (others => (others => '0'));
                z_pipe <= (others => (others => '0'));
            else 
                --main code runs here 
                -- firstly we will divide for quadrants 
                --theere is another wway to do it using symmetry but for now for simplicity ill use this 

                -- Rule 2: sin sign based on original phase
                if signed(phase_input) < 0 then
                    negate_sin <= '1';
                else
                    negate_sin <= '0';
                end if;

                -- Rule 1: fold into -90 to +90
                if signed(phase_input) > 16384 then
                    adj_phase  <= to_signed(32768, 16) - signed(phase_input);
                    negate_cos <= '1';
                elsif signed(phase_input) < -16384 then
                    adj_phase <= to_signed(-32768, 16) - signed(phase_input);
                    negate_cos <= '1';
                else
                    adj_phase  <= signed(phase_input);
                    negate_cos <= '0';
                end if;

                -- CORDIC Pipeline 
                x_pipe(0) <= cordic_gain;
                y_pipe(0) <= (others => '0');
                z_pipe(0) <= adj_phase;

                for i in 0 to 15 loop 
                    if z_pipe(i) >= 0 then
                        x_pipe(i+1) <= x_pipe(i) - shift_right(y_pipe(i), i) ;
                        y_pipe(i+1) <= y_pipe(i) + shift_right(x_pipe(i), i) ; 
                        z_pipe(i+1) <= z_pipe(i) - ATAN_TABLE(i);
                    else 
                        x_pipe(i+1) <= x_pipe(i) + shift_right(y_pipe(i), i) ;
                        y_pipe(i+1) <= y_pipe(i) - shift_right(x_pipe(i), i) ; 
                        z_pipe(i+1) <= z_pipe(i) + ATAN_TABLE(i);
                    end if;
                end loop;
                
                if negate_cos = '1' then
                    cos_value <= std_logic_vector(-x_pipe(16));
                else
                    cos_value <= std_logic_vector(x_pipe(16));
                end if;

                if negate_sin = '1' then
                    sin_value <= std_logic_vector(-y_pipe(16));
                else
                    sin_value <= std_logic_vector(y_pipe(16));
                end if;
            end if;
        end if; 
    end process; 
end architecture; 