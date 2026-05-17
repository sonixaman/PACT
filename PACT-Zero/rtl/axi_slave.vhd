-- written from prespective of PL AXI Slave
-- writing and reading are from the prespective of PS (MASTER)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_beamformer_slave is
    generic(
        C_S_AXI_DATA_WIDTH : integer := 32;
        C_S_AXI_ADDR_WIDTH : integer := 8
        
    );
    port (
        S_AXI_ACLK : in std_logic;
        S_AXI_ARESETN : in std_logic;

        --write address 
        --address of where to store incoming data 
        S_AXI_AWADDR : in std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
        --address ready sent by PL->PS
        S_AXI_AWREADY : out  std_logic;
        --address valid sent by PS_>PL
        S_AXI_AWVALID : in std_logic;
       -- protection type 
        S_AXI_AWPROT : in std_logic_vector (2 downto 0);

        --write data 
        S_AXI_WDATA : in std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
        --write strobe 
        S_AXI_WSTRB : in std_logic_vector (3 downto 0); 
        --write valid sent by PS->PL 
        S_AXI_WVALID : in std_logic;
        --write ready sent by PL->PS
        S_AXI_WREADY:out std_logic;

        --write response PL -> PS 
        S_AXI_BRESP :out std_logic_vector(1 downto 0);
        -- write response valid 
        S_AXI_BVALID : out std_logic ;
        --write response ready 
        S_AXI_BREADY: in std_logic ;

        --read address 
        -- read process address sent by PS->PL
        S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        -- read process address valid PS-> PL  
        S_AXI_ARVALID : in std_logic;
        --read process address ready PL-> PS
        S_AXI_ARREADY : out std_logic;
        -- read process address protection 
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);

        --read process 
        -- read data 
        S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        -- read response PL -> PS 
        S_AXI_RRESP : out std_logic_vector(1 downto 0);
        -- PL->PS ask 
        S_AXI_RVALID : out std_logic;
        -- PS -> PS acknowledge 
        S_AXI_RREADY : in std_logic;

        --values to be sent to phase_compute
        STEERING_AZIMUTH : out std_logic_vector(15 downto 0);
        STEERING_ELEVATION : out std_logic_vector(15 downto 0);

        --configB/to be packed to mem_intercon 
        cmd_data  : out std_logic_vector(31 downto 0);
        cmd_write : out std_logic
    );
end entity ; 
    
architecture rtl of axi_beamformer_slave is
    -- Signal Declaration 

    signal int_awready : std_logic := '0';
    signal int_wready : std_logic := '0';

    --write response
    signal int_bresp : std_logic_vector(1 downto 0) := (others => '0');
    signal int_bvalid : std_logic; 

    signal int_arready : std_logic ;

    signal int_rvalid : std_logic ;
    signal int_rresp : std_logic_vector(1 downto 0);
    signal int_rdata : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    type write_state_type is (write_idle , write_data , write_response);
    signal write_state : write_state_type := write_idle;

    type read_state_type is (read_idle ,read_data);
    signal read_state : read_state_type := read_idle;
    
    --address fields 
    signal int_awaddr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal int_araddr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);

    signal reg_azimuth   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_elevation : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_phase_0   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_phase_1   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_phase_2   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_phase_3   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_control   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_status    : std_logic_vector(31 downto 0) := (others => '0');

    --for config B
    signal reg_cmd : std_logic_vector(31 downto 0) := (others => '0');
    
begin

    write_process : process(S_AXI_ACLK)
    begin 
        if rising_edge(S_AXI_ACLK) then 
            if S_AXI_ARESETN = '0' then --active low
                write_state <= write_idle;
                int_awready <= '0';
                int_wready <= '0';
                int_bvalid <= '0';
                int_bresp <= "00";
                int_awaddr <= (others => '0');
            else 
                case write_state is 

                    -- write_idle handles idle and transition into write address 
                    when write_idle => 
                        int_awready <= '0';
                        int_wready <= '0';
                        int_bvalid <= '0';
                        if S_AXI_AWVALID = '1' then
                           -- raise address write ready 
                           int_awready <= '1';
                            --latch write address
                            int_awaddr <= S_AXI_AWADDR;

                            write_state <= write_data;
                        end if;   
                    
                    when write_data => 
                        int_awready <= '0';
                        if S_AXI_WVALID = '1' then 
                            --raise address write ready 
                            --raise the write ready
                            int_wready <= '1';
                            case int_awaddr is 
    
                                when x"00" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_azimuth( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_azimuth(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_azimuth(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_azimuth(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"04" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_elevation( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_elevation(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_elevation(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_elevation(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"08" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_phase_0( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_phase_0(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_phase_0(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_phase_0(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"0C" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_phase_1( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_phase_1(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_phase_1(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_phase_1(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"10" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_phase_2( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_phase_2(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_phase_2(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_phase_2(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"14" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_phase_3( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_phase_3(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_phase_3(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_phase_3(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"18" => 
                                    if S_AXI_WSTRB(0) = '1' then reg_control( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_control(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_control(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_control(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;
                                when x"20" =>
                                    if S_AXI_WSTRB(0) = '1' then reg_cmd( 7 downto  0) <= S_AXI_WDATA( 7 downto  0); end if;
                                    if S_AXI_WSTRB(1) = '1' then reg_cmd(15 downto  8) <= S_AXI_WDATA(15 downto  8); end if;
                                    if S_AXI_WSTRB(2) = '1' then reg_cmd(23 downto 16) <= S_AXI_WDATA(23 downto 16); end if;
                                    if S_AXI_WSTRB(3) = '1' then reg_cmd(31 downto 24) <= S_AXI_WDATA(31 downto 24); end if;        
                                when others => null;
                            end case;
                            write_state <= write_response;
                        end if;
                    when write_response => 
                       int_wready <= '0';
                       int_bvalid <= '1';
                       int_bresp <= "00";
                       if S_AXI_BREADY = '1' then 
                            int_bvalid <= '0';
                            write_state <= write_idle;
                       end if;                        
                end case;
            end if;
        end if;                        
    end process;

    read_process : process (S_AXI_ACLK)
    begin 
        if rising_edge(S_AXI_ACLK) then 
            int_arready <= '0';
            if S_AXI_ARESETN = '0' then 
                --the defaults 
                read_state <= read_idle;
                int_araddr <= (others => '0');
                int_arready <= '0';        
                int_rvalid  <= '0';        
                int_rresp   <= "00";       
                int_rdata   <= (others => '0');
            else 
                case read_state is 

                    when read_idle => 
                        if S_AXI_ARVALID = '1' then
                            --PL tells PS it is ready
                            int_arready <= '1';
                            -- PL latches onto address sent by PS
                            int_araddr <= S_AXI_ARADDR;
                            --go to next state 
                            read_state <= read_data;
                        end if;
                    when read_data =>
                        --release address read ready 
                        int_arready <= '0'; 
                        --raise rvalid 
                        int_rvalid <= '1';
                        --OK response / internal error handling not implemented 
                        int_rresp <= "00";
                        -- parse data to be sent into rdata
                        case int_araddr is 
                            when x"00" => int_rdata <= reg_azimuth;
                            when x"04" => int_rdata <= reg_elevation;
                            when x"08" => int_rdata <= reg_phase_0;
                            when x"0C" => int_rdata <= reg_phase_1;
                            when x"10" => int_rdata <= reg_phase_2;
                            when x"14" => int_rdata <= reg_phase_3;
                            when x"18" => int_rdata <= reg_control;
                            when x"1C" => int_rdata <= reg_status;
                            when x"20" => int_rdata <= reg_cmd;
                            when others => int_rdata <= (others => '0');
                        end case; 
                        --end of transaction state change condition 
                        if S_AXI_RREADY = '1' then 
                            int_rvalid <= '0';
                            read_state <= read_idle;
                        end if;
                end case;
            end if;
        end if;
    end process;

    S_AXI_AWREADY <= int_awready;
    S_AXI_WREADY  <= int_wready;
    S_AXI_BRESP   <= int_bresp;
    S_AXI_BVALID  <= int_bvalid;
    S_AXI_ARREADY <= int_arready;
    S_AXI_RVALID  <= int_rvalid;
    S_AXI_RRESP   <= int_rresp;
    S_AXI_RDATA   <= int_rdata;
    STEERING_AZIMUTH   <= reg_azimuth(15 downto 0);
    STEERING_ELEVATION <= reg_elevation(15 downto 0);
    cmd_data  <= reg_cmd;
    cmd_write <= '1' when (write_state = write_response and int_awaddr = x"20") else '0';
end architecture;