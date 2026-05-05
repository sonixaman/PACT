library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_picorv32 is
end entity;

architecture tb of  tb_picorv32 is

    constant CLK_PERIOD : time := 10 ns ;

    signal clk          : std_logic := '0';
    signal resetn       : std_logic := '0'; 
    signal azimuth_out  : std_logic_vector(15 downto 0) := (others => '0');
    signal elevation_out: std_logic_vector(15 downto 0) := (others => '0');

begin 

    dut : entity work.picorv32_top
        port map
        (
            clk         => clk,
            resetn      => resetn,
            azimuth_out => azimuth_out,
            elevation_out=> elevation_out
        );

    clk <= not clk after CLK_PERIOD/2 ;

    process
    begin 
        resetn <= '0';
        wait for CLK_PERIOD * 4;

        resetn <= '1';
        wait for CLK_PERIOD * 2000; --for booting 

        assert azimuth_out = std_logic_vector(to_signed(30,16))
            report "TEST FAILED - AZIMUTH WRONG"
            severity failure;

        assert elevation_out = std_logic_vector(to_signed(20,16))
            report "TEST FAILED - Elevation wrong"
            severity failure;

        report "TEST PASSED ";

        wait;
    end process;
end architecture;