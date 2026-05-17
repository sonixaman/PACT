library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_compute is 
    port
    (
        --system basics 
        reset : in std_logic;
        clk : in std_logic;
        --project required IOs
        steering_azimuth : in std_logic_vector(15 downto 0); 
        steering_elevation : in std_logic_vector(15 downto 0);
        offset_00 : out std_logic_vector (7 downto 0);
        offset_01 : out std_logic_vector (7 downto 0);
        offset_10 : out std_logic_vector (7 downto 0);
        offset_11 : out std_logic_vector (7 downto 0)
    );
end entity;

architecture rtl of phase_compute is 
    --calculation requirement 
    signal delta_x   : signed(15 downto 0) := (others => '0');
    signal delta_y   : signed(15 downto 0) := (others => '0');
    --output copies 
    signal offset_00_int : signed(15 downto 0) := (others=>'0');
    signal offset_01_int : signed(15 downto 0) := (others=>'0');
    signal offset_10_int : signed(15 downto 0) := (others=>'0');
    signal offset_11_int : signed(15 downto 0) := (others=>'0');

    --cordic connections and calculation requirements
    
    --scaling signals
    signal az_scaled : signed(15 downto 0);
    signal el_scaled : signed(15 downto 0);
    
    --declration for angles 
    signal azi_plus_ele : std_logic_vector(15 downto 0);
    signal azi_min_ele  : std_logic_vector(15 downto 0);

    --declaration for azimuth + elevation calc (internal process)
    signal sin_azi_plus_ele : std_logic_vector(15 downto 0);
    signal cos_azi_plus_ele : std_logic_vector(15 downto 0);

    --declaration for azimuth - elevation calc (internal process)
    signal sin_azi_min_ele : std_logic_vector(15 downto 0);
    signal cos_azi_min_ele : std_logic_vector(15 downto 0);

    -- declaration for elevation (internal calculation)
    signal sin_ele   : std_logic_vector(15 downto 0);
    signal cos_ele   : std_logic_vector(15 downto 0); --not required

begin 
    az_scaled <= resize(signed(steering_azimuth)* 182, 16);
    el_scaled <= resize(signed(steering_elevation)* 182, 16);
    azi_plus_ele <= std_logic_vector(az_scaled + el_scaled);
    azi_min_ele  <= std_logic_vector(az_scaled - el_scaled);
    -- cordic instantiation 
    CORDIC_AZI_PLUS_ELE : entity work.cordic_calc
    port map 
    (
        clk => clk,
        reset => reset,
        phase_input => azi_plus_ele,
        sin_value => sin_azi_plus_ele,
        cos_value => cos_azi_plus_ele
    );
    CORDIC_AZI_MIN_ELE : entity work.cordic_calc
    port map 
    (
        clk => clk,
        reset => reset,
        phase_input => azi_min_ele,
        sin_value => sin_azi_min_ele,
        cos_value => cos_azi_min_ele
    );
    CORDIC_ELE : entity work.cordic_calc
    port map 
    (
        clk => clk,
        reset => reset,
        phase_input => std_logic_vector(el_scaled),
        sin_value => sin_ele,
        cos_value => cos_ele
    );

    sync : process(clk)
    begin 
        if rising_edge(clk) then 
            if reset = '1' then 
                --reset effects here 
                
                offset_00_int <= (others => '0');
                offset_01_int <= (others => '0');
                offset_10_int <= (others => '0');
                offset_11_int <= (others => '0');
            else 
                --main code here 
                -- sin and cos can be calcualted with instantiating cordric
                -- calc del_x and del_y 
                delta_x <= shift_right(signed(sin_azi_plus_ele) + signed(sin_azi_min_ele), 9);
                delta_y <= shift_right(signed(sin_ele),8);
                --offset calculation 
                --offset_00_int = 0; --hardcoded always 0 saves calculation aliter 
                offset_01_int <= delta_y;
                offset_10_int <= delta_x;
                offset_11_int <= delta_x + delta_y;
            end if;
        end if;
    end process;
    --linking the outputs with signals
    offset_00 <= (others => '0');  -- always 0
    offset_10 <= std_logic_vector(offset_10_int(7 downto 0));
    offset_01 <= std_logic_vector(offset_01_int(7 downto 0));
    offset_11 <= std_logic_vector(offset_11_int(7 downto 0));
end architecture;
                

