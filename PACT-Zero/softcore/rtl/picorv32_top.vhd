library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity picorv32_top is 
    port
    (
        clk : in std_logic;
        resetn : in std_logic;
        --out from picorv
        azimuth_out : out std_logic_vector(15 downto 0);
        elevation_out : out std_logic_vector(15 downto 0)
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

signal phase_valid : std_logic;
signal phase_ready : std_logic ;

-- for continous steering functionality 
--  add cmd_reg signals when cmd_reg.vhd is ready
-- Uncomment "%" lines to enable , remove "%" before uncommenting 
-- % signal cmd_valid : std_logic;
-- % signal cmd_ready : std_logic;

begin
    cpu : entity work.picorv32
    generic map (
    COMPRESSED_ISA => 1
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

        phase_valid => phase_valid,
        phase_ready => phase_ready

        --for continous steering functionality
        -- add cmd_reg connections when ready
        -- Uncomment "%" lines to enable
        -- remove "%" before uncommenting
        -- add ',' to line above before uncommenting
        -- % cmd_valid => cmd_valid,
        -- % cmd_ready => cmd_ready
        
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

    phase_inst : entity work.phase_reg
    port map 
    (
        clk     => clk,
        valid   => phase_valid,

        wdata   => mem_wdata,
        wstrb   => mem_wstrb,
        
        ready   => phase_ready,

        azimuth_out =>  azimuth_out,
        elevation_out => elevation_out
    );

     --for continous steering functionality
    -- instantiate cmd_reg here when ready
    -- Uncomment "%" lines to enable , remove "%" before uncommenting
    -- % cmd_inst : entity work.cmd_reg
    -- %     port map (
    -- %         clk       => clk,
    -- %         valid     => cmd_valid,
    -- %         rdata     => mem_rdata,
    -- %         ready     => cmd_ready
    -- %     );

    

end architecture;


--picorv32   → clk, resetn, mem_valid, mem_ready, mem_addr, mem_wdata, mem_wstrb, mem_rdata
--mem_intercon → all the mem_* and ram_*/uart_*/phase_* signals
--ram        → clk, valid, addr, wdata, wstrb, rdata, ready
--uart_sim   → clk, valid, wdata, wstrb, ready
--phase_reg  → clk, valid, wdata, wstrb, ready, azimuth_out, elevation_out
