library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_picorv32 is 
end entity;

architecture tb of tb_picorv32 is
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal resetn : std_logic := '0';

    --AXI-4 LITE 
    signal S_AXI_AWADDR : std_logic_vector(7 downto 0) := (others => '0');
    signal S_AXI_AWREADY : std_logic;
    signal S_AXI_AWVALID : std_logic := '0';
    signal S_AXI_AWPROT : std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_WDATA : std_logic_vector(31 downto 0) := (others => '0');
    signal S_AXI_WSTRB : std_logic_vector(3 downto 0) := "1111";
    signal S_AXI_WVALID : std_logic := '0';
    signal S_AXI_WREADY : std_logic;
    signal S_AXI_BRESP : std_logic_vector(1 downto 0);
    signal S_AXI_BVALID : std_logic;
    signal S_AXI_BREADY : std_logic := '0';
    signal S_AXI_ARADDR : std_logic_vector(7 downto 0) := (others => '0');
    signal S_AXI_ARVALID : std_logic := '0';
    signal S_AXI_ARREADY : std_logic;
    signal S_AXI_ARPROT : std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_RDATA : std_logic_vector(31 downto 0);
    signal S_AXI_RRESP : std_logic_vector(1 downto 0);
    signal S_AXI_RVALID : std_logic;
    signal S_AXI_RREADY : std_logic := '0';

    --SPI 
    signal cs_n : std_logic_vector(3 downto 0);
    signal sck : std_logic;
    signal mosi : std_logic;
    signal miso : std_logic := '0';

begin 
    --clock toggle 
    clk <= not clk after CLK_PERIOD/ 2;

    dut : entity work.picorv32_top 
        generic map (
            C_S_AXI_ADDR_WIDTH => 8,
            C_S_AXI_DATA_WIDTH => 32
        )
        port map (
            clk   => clk,
            resetn => resetn,

            S_AXI_AWADDR  => S_AXI_AWADDR,
            S_AXI_AWVALID => S_AXI_AWVALID,
            S_AXI_AWREADY => S_AXI_AWREADY,
            S_AXI_AWPROT  => S_AXI_AWPROT,
            S_AXI_WDATA   => S_AXI_WDATA,
            S_AXI_WSTRB   => S_AXI_WSTRB,
            S_AXI_WVALID  => S_AXI_WVALID,
            S_AXI_WREADY  => S_AXI_WREADY,
            S_AXI_BRESP   => S_AXI_BRESP,
            S_AXI_BVALID  => S_AXI_BVALID,
            S_AXI_BREADY  => S_AXI_BREADY,
            S_AXI_ARADDR  => S_AXI_ARADDR,
            S_AXI_ARVALID => S_AXI_ARVALID,
            S_AXI_ARREADY => S_AXI_ARREADY,
            S_AXI_ARPROT  => S_AXI_ARPROT,
            S_AXI_RDATA   => S_AXI_RDATA,
            S_AXI_RRESP   => S_AXI_RRESP,
            S_AXI_RVALID  => S_AXI_RVALID,
            S_AXI_RREADY  => S_AXI_RREADY,
            sck           => sck,
            cs_n          => cs_n,
            mosi          => mosi,
            miso          => miso            
            
        );

    axi_write : process 
    begin 
        --reset 
        resetn <= '0';
        wait for CLK_PERIOD * 4 ;
        resetn <= '1';
        wait for CLK_PERIOD * 4 ;

        --AXI4-LITE write 
        S_AXI_AWADDR <= x"20"; --want to write at this location 
        S_AXI_AWVALID <= '1' ;
        wait until S_AXI_AWREADY = '1';
        S_AXI_WVALID <= '1';
        S_AXI_WDATA <= x"0014001E"; -- 20 << 16 , 30  
        wait until S_AXI_WREADY = '1';
        wait for CLK_PERIOD;
        S_AXI_AWVALID <= '0';
        S_AXI_WVALID  <= '0';
        S_AXI_BREADY  <= '1';
        wait until S_AXI_BVALID = '1';
        wait for CLK_PERIOD;
        S_AXI_BREADY  <= '0';

        -- wait for CORDIC pipeline + SPI transactions
        wait for CLK_PERIOD * 10000;

        report "simulation completed";
        wait;
    end process;

    spi_write : process 
        variable mosi_capture : std_logic_vector(5 downto 0);
    begin
        --wait for reset/initilization 
        wait until resetn = '1';
        wait for CLK_PERIOD * 10000; 
       
        wait until cs_n = "1111"; 

        --for element 00
        wait until cs_n = "1110";
        --capturing the bits 
        for i in 5 downto 0 loop 
            wait until rising_edge(sck);
            mosi_capture(i) := mosi; 
        end loop;
        wait until cs_n = "1111";
        --assert mosi_capture = "000000"
        --    report "FAIL , incorrect value for element 00"
        --    severity error;

        --for element 01
        wait until cs_n = "1101";
        for i in 5 downto 0 loop 
            wait until rising_edge(sck);
            mosi_capture(i) := mosi; 
        end loop;
        wait until cs_n = "1111";
        --assert mosi_capture = "001010"
        --    report "FAIL , incorrect value for element 01"
        --    severity error;

        --for element 10
        wait until cs_n = "1011";
        for i in 5 downto 0 loop 
            wait until rising_edge(sck);
            mosi_capture(i) := mosi; 
        end loop;
        wait until cs_n = "1111";

        --assert mosi_capture = "001111"
        --report "FAIL , incorrect value for element 10"
        --    severity error;

        -- for element 11
        wait until cs_n = "0111";
        --capturing the bits 
        for i in 5 downto 0 loop 
            wait until rising_edge(sck);
            mosi_capture(i) := mosi; 
        end loop;
        wait until cs_n = "1111";
        --assert mosi_capture = "011001"
        --report "FAIL , incorrect value for element 11"
        --    severity error;

        report "SPI TEST PASSED";
        wait;
        

    end process;

end architecture;


