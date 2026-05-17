library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pact_zero_top is 
    generic 
    (
        C_S_AXI_ADDR_WIDTH : integer := 8 ;
        C_S_AXI_DATA_WIDTH : integer :=32 
    );
    port
    (
        top_clk : in std_logic;
        top_resetn : in std_logic;

        --standard axi-4 lite signals defined under ARM IHI 0022E ID022613 for axi_slave.vhd
        --interaction PS -> PL 
        S_AXI_AWADDR : in std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWREADY : out  std_logic;
        S_AXI_AWVALID : in std_logic;
        S_AXI_AWPROT : in std_logic_vector (2 downto 0);
        S_AXI_WDATA : in std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB : in std_logic_vector (3 downto 0); 
        S_AXI_WVALID : in std_logic;
        S_AXI_WREADY:out std_logic;
        S_AXI_BRESP :out std_logic_vector(1 downto 0);
        S_AXI_BVALID : out std_logic ;
        S_AXI_BREADY: in std_logic ;
        S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID : in std_logic;
        S_AXI_ARREADY : out std_logic;
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);
        S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP : out std_logic_vector(1 downto 0);
        S_AXI_RVALID : out std_logic;
        S_AXI_RREADY : in std_logic;

        --spi 
        --interaction PL -> phase shifter IC
        sck  : out std_logic;
        cs_n : out std_logic_vector(3 downto 0);
        mosi : out std_logic;
        miso :  in std_logic
    );
end entity;

architecture rtl of pact_zero_top is

    signal top_reset : std_logic;
    -- axi + phase compute common
    signal top_steering_azimuth : std_logic_vector(15 downto 0);
    signal top_steering_elevation : std_logic_vector(15 downto 0);
   
    
    --phase compute -> sequencer 
    signal top_offset_00 : std_logic_vector(7 downto 0);
    signal top_offset_01 : std_logic_vector(7 downto 0);
    signal top_offset_10 : std_logic_vector(7 downto 0);
    signal top_offset_11 : std_logic_vector(7 downto 0);

    -- sequencer -> spi driver 
    signal top_spi_busy : std_logic;
    signal top_spi_start : std_logic;
    signal top_spi_done : std_logic;
    signal top_spi_tx_data : std_logic_vector(5 downto 0); --change according to data width (IC limit)
    signal top_spi_cs_sel : std_logic_vector(1 downto 0);

    -- sequencer 
    --spi is generic , but has to be fed each data one by one as all phase shifter ic are on the same spi bus
    
    type seq_state_type is (
    send_0, wait_0,     --for each IC 
    send_1, wait_1,
    send_2, wait_2,
    send_3, wait_3 );

    --chunking fsm 
    signal sequencer_state :  seq_state_type;

begin

    top_reset <= not top_resetn;
    --interconnecting modules 
    axi : entity work.axi_beamformer_slave
    port map
    (
        S_AXI_ACLK => top_clk,
        S_AXI_ARESETN => top_resetn,

        S_AXI_AWADDR => S_AXI_AWADDR ,
        S_AXI_AWREADY => S_AXI_AWREADY,
        S_AXI_AWVALID => S_AXI_AWVALID,
        S_AXI_AWPROT => S_AXI_AWPROT,
        S_AXI_WDATA => S_AXI_WDATA,
        S_AXI_WSTRB => S_AXI_WSTRB,
        S_AXI_WVALID => S_AXI_WVALID,
        S_AXI_WREADY => S_AXI_WREADY,
        S_AXI_BRESP => S_AXI_BRESP,
        S_AXI_BVALID => S_AXI_BVALID,
        S_AXI_BREADY => S_AXI_BREADY,
        S_AXI_ARADDR => S_AXI_ARADDR,
        S_AXI_ARVALID => S_AXI_ARVALID,
        S_AXI_ARREADY => S_AXI_ARREADY,
        S_AXI_ARPROT => S_AXI_ARPROT,
        S_AXI_RDATA => S_AXI_RDATA,
        S_AXI_RRESP => S_AXI_RRESP,
        S_AXI_RVALID => S_AXI_RVALID,
        S_AXI_RREADY => S_AXI_RREADY,

        STEERING_AZIMUTH => top_steering_azimuth,
        STEERING_ELEVATION => top_steering_elevation,

        cmd_data => open,
        cmd_write => open
    );
    
    phase_compute : entity work.phase_compute 
    port map 
    (
        clk => top_clk,
        reset => top_reset,

        steering_azimuth => top_steering_azimuth,
        steering_elevation => top_steering_elevation,

        offset_00 => top_offset_00,
        offset_01 => top_offset_01,
        offset_10 => top_offset_10,
        offset_11 => top_offset_11
    );

    spi : entity work.spi_driver
    port map 
    (
        clk   => top_clk,
        reset => top_reset,
        start => top_spi_start,
        done  => top_spi_done,
        busy => top_spi_busy,
        tx_data => top_spi_tx_data,
        rx_data => open,
        cs_sel => top_spi_cs_sel,
        mosi => mosi,
        miso => miso,
        sck => sck,
        cs_n => cs_n
    );

    -- fsm for phase compute -> spi ; chunking data into spi  
    fsm_spi : process(top_clk)
    begin    
        if rising_edge (top_clk) then
            if top_resetn = '0' then --active low 
            sequencer_state <= send_0;
            top_spi_start  <= '0';
            top_spi_cs_sel <= "00";
            top_spi_tx_data <= (others => '0');
                
            else 
                top_spi_start <= '0';
                case sequencer_state is 
                    when send_0 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= top_offset_00(7 downto 2);
                        top_spi_cs_sel <= "00";
                        sequencer_state <= wait_0;

                    when wait_0=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then  --condition holds till spi is free
                            sequencer_state <= send_1;
                        end if;


                    when send_1 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= top_offset_01(7 downto 2);
                        top_spi_cs_sel <= "01";
                        sequencer_state <= wait_1;
                        

                    when wait_1=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then 
                            sequencer_state <= send_2;
                        end if;

                    when send_2 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= top_offset_10(7 downto 2);
                        top_spi_cs_sel <= "10";
                        sequencer_state <= wait_2;

                        

                    when wait_2=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then 
                            sequencer_state <= send_3;
                        end if;

                    when send_3 =>
                        top_spi_tx_data <= top_offset_11(7 downto 2);
                        top_spi_start <= '1';
                        top_spi_cs_sel <= "11";
                        sequencer_state <= wait_3;
                        

                    when wait_3=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then 
                            sequencer_state <= send_0;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture;