-- ============================================================
-- cmd_reg.vhd
-- Shared command register between Linux PS and PicoRV32
--
-- Linux PS writes azimuth/elevation (packed 32-bit) via beamformer.c
-- PicoRV32 reads it via memory address 0x20000004
--
-- Status: NOT YET TESTED — requires physical Zynq hardware
-- Planned for continous steering functionality 
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cmd_reg is
    port (
        clk   : in std_logic;

        -- from memory interconnect (PicoRV32 reads)
        valid : in  std_logic;
        wstrb : in  std_logic_vector( 3 downto 0);
        rdata : out std_logic_vector(31 downto 0);
        ready : out std_logic;

        -- from parallel_bus (Linux PS writes)
        ps_write : in std_logic;
        ps_data  : in std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of cmd_reg is
    signal cmd_val : std_logic_vector(31 downto 0) := (others => '0');
begin

    -- Linux PS writes to this register via parallel_bus
    process(clk)
    begin
        if rising_edge(clk) then
            if ps_write = '1' then
                cmd_val <= ps_data;
            end if;
        end if;
    end process;

    -- PicoRV32 reads from this register
    process(clk)
    begin
        if rising_edge(clk) then
            ready <= '0';
            if valid = '1' and wstrb = "0000" then
                rdata <= cmd_val;
                ready <= '1';
            end if;
        end if;
    end process;

end architecture;
