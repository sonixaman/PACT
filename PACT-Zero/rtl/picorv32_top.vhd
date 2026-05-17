library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity picorv32_top is 
    generic (
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 8
    );
    port
    (
        clk : in std_logic;
        resetn : in std_logic;

        --axi standard 
        S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID : in  std_logic;
        S_AXI_AWREADY : out std_logic;
        S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
        S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB   : in  std_logic_vector(3 downto 0);
        S_AXI_WVALID  : in  std_logic;
        S_AXI_WREADY  : out std_logic;
        S_AXI_BRESP   : out std_logic_vector(1 downto 0);
        S_AXI_BVALID  : out std_logic;
        S_AXI_BREADY  : in  std_logic;
        S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID : in  std_logic;
        S_AXI_ARREADY : out std_logic;
        S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
        S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP   : out std_logic_vector(1 downto 0);
        S_AXI_RVALID  : out std_logic;
        S_AXI_RREADY  : in  std_logic;

        --spi 
        --interaction PL -> phase shifter IC
        sck  : out std_logic;
        cs_n : out std_logic_vector(3 downto 0);
        mosi : out std_logic;
        miso :  in std_logic
    );

end entity;

architecture rtl of picorv32_top is

--these sort of work as global variables and are connected over here in this file 

signal mem_valid : std_logic ;
signal mem_ready : std_logic ;
signal mem_addr : std_logic_vector(31 downto 0);
signal mem_wdata : std_logic_vector(31 downto 0);
signal mem_wstrb : std_logic_vector(3 downto 0);
signal mem_rdata : std_logic_vector(31 downto 0);

signal ram_valid : std_logic ; 
signal ram_ready : std_logic ;
signal ram_rdata : std_logic_vector(31 downto 0);

signal uart_valid : std_logic ;
signal uart_ready : std_logic ;

signal int_cmd_data : std_logic_vector(31 downto 0);
signal int_cmd_write :  std_logic; --driven by axi 
signal int_cmd_valid : std_logic; -- mem intercon drives this 

--from offset_reg.vhdl -> spi_driver.vhdl
signal int_offset_00 : std_logic_vector(7 downto 0); 
signal int_offset_01 : std_logic_vector(7 downto 0);
signal int_offset_10 : std_logic_vector(7 downto 0);
signal int_offset_11 : std_logic_vector(7 downto 0); 

signal int_offset_valid : std_logic;
signal int_offset_ready : std_logic;

signal reset : std_logic ; 

--spi_driver 
signal top_spi_busy : std_logic;
signal top_spi_start : std_logic;
signal top_spi_done : std_logic;
signal top_spi_tx_data : std_logic_vector(5 downto 0); --change according to data width (IC limit)
signal top_spi_cs_sel : std_logic_vector(1 downto 0);

type seq_state_type is (
    send_0, wait_0,     --for each IC 
    send_1, wait_1,
    send_2, wait_2,
    send_3, wait_3 );

--chunking fsm 
signal sequencer_state :  seq_state_type;
    

    


begin
    reset <= not resetn;

    cpu : entity work.picorv32
    generic map (
    COMPRESSED_ISA => 1,
    ENABLE_MUL => 1,
    ENABLE_DIV => 1
    )
    port map 
    (
        clk => clk,
        resetn => resetn,
        mem_valid => mem_valid,
        mem_ready => mem_ready,
        mem_addr => mem_addr,
        mem_wdata => mem_wdata,
        mem_wstrb => mem_wstrb,
        mem_rdata => mem_rdata,
        
        -- unused outputs - tie to open
        trap       => open,
        mem_instr  => open,
        mem_la_read  => open,
        mem_la_write => open,
        mem_la_addr  => open,
        mem_la_wdata => open,
        mem_la_wstrb => open,
        pcpi_valid => open,
        pcpi_insn  => open,
        pcpi_rs1   => open,
        pcpi_rs2   => open,
        eoi        => open,

        -- unused inputs - tie to zero
        pcpi_wr    => '0',
        pcpi_rd    => (others => '0'),
        pcpi_wait  => '0',
        pcpi_ready => '0',
        irq        => (others => '0')

    );

    intercon : entity work.mem_intercon
    port map 
    (
        mem_valid   => mem_valid, 
        mem_ready   => mem_ready,
        mem_addr    => mem_addr, 
        mem_wdata   => mem_wdata,
        mem_wstrb   => mem_wstrb, 
        mem_rdata   => mem_rdata, 

        ram_valid   => ram_valid, 
        ram_ready   => ram_ready,
        ram_rdata   => ram_rdata,

        uart_valid  => uart_valid, 
        uart_ready  => uart_ready,

        --for continous steering functionality
        -- add cmd_reg connections when ready
        -- Uncomment "%" lines to enable
        -- remove "%" before uncommenting
        -- add ',' to line above before uncommenting
        --ignore lines above already implemented 
        cmd_valid => int_cmd_valid, 
        cmd_data => int_cmd_data,


        --from offset_reg
        offset_ready => int_offset_ready,
        offset_valid => int_offset_valid
        
    );

    ram_inst : entity work.ram
    port map
    (
        clk => clk,
        valid => ram_valid,
        addr => mem_addr,
        wdata => mem_wdata,
        wstrb => mem_wstrb,
        rdata => ram_rdata,
        ready => ram_ready
    );

    uart_inst : entity work.uart_controller
    port map
    (
        clk     => clk,
        valid   => uart_valid,
        wdata   => mem_wdata,
        wstrb   => mem_wstrb,
        ready   => uart_ready

    );

    axi : entity work.axi_beamformer_slave
    port map
    (
        S_AXI_ACLK => clk,
        S_AXI_ARESETN => resetn,

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

        STEERING_AZIMUTH => open,
        STEERING_ELEVATION => open,

        cmd_data => int_cmd_data,
        cmd_write => int_cmd_write
    );

    offsets : entity work.offset_reg
    port map 
    (
        clk => clk,
        reset => reset,

        valid   => int_offset_valid ,
        addr    => mem_addr(3 downto 0) ,
        wdata   => mem_wdata,
        wstrb   => mem_wstrb,
        ready   => int_offset_ready,
        
        offset_00 => int_offset_00 ,
        offset_01 => int_offset_01 ,
        offset_10 => int_offset_10 ,
        offset_11 => int_offset_11  

    );

    spi : entity work.spi_driver
    port map 
    (
        clk   => clk,
        reset => reset,
        start => top_spi_start,
        done  => top_spi_done,
        busy => top_spi_busy,
        tx_data => top_spi_tx_data,
        rx_data => open,
        cs_sel => top_spi_cs_sel,

        mosi    => mosi,          
        miso    => miso,          
        sck     => sck,           
        cs_n    => cs_n 
    );

    --sequencer 
    fsm_spi : process(clk)
    begin    
        if rising_edge (clk) then
            if resetn = '0' then --active low 
            sequencer_state <= send_0;
            top_spi_start  <= '0';
            top_spi_cs_sel <= "00";
            top_spi_tx_data <= (others => '0');
                
            else 
                top_spi_start <= '0';
                case sequencer_state is 
                    when send_0 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= int_offset_00(7 downto 2);
                        top_spi_cs_sel <= "00";
                        sequencer_state <= wait_0;

                    when wait_0=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then  --condition holds till spi is free
                            sequencer_state <= send_1;
                        end if;


                    when send_1 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= int_offset_01(7 downto 2);
                        top_spi_cs_sel <= "01";
                        sequencer_state <= wait_1;
                        

                    when wait_1=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then 
                            sequencer_state <= send_2;
                        end if;

                    when send_2 =>
                        top_spi_start <= '1';
                        top_spi_tx_data <= int_offset_10(7 downto 2);
                        top_spi_cs_sel <= "10";
                        sequencer_state <= wait_2;

                        

                    when wait_2=>
                        top_spi_start <= '0';
                        if top_spi_done = '1' then 
                            sequencer_state <= send_3;
                        end if;

                    when send_3 =>
                        top_spi_tx_data <= int_offset_11(7 downto 2);
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


--picorv32   → clk, resetn, mem_valid, mem_ready, mem_addr, mem_wdata, mem_wstrb, mem_rdata
--mem_intercon → all the mem_* and ram_*/uart_*/phase_* signals
--ram        → clk, valid, addr, wdata, wstrb, rdata, ready
--uart_sim   → clk, valid, wdata, wstrb, ready

