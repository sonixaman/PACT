# RTL — Programmable Logic

VHDL source files for PACT-Zero FPGA implementation on Zynq ZC702/Basys3.

## Shared Files (Configuration A + B)
| File | Description |
|------|-------------|
| axi_slave.vhd | AXI4-Lite slave — steering angle registers (0x00, 0x04) and CMD_REG (0x20) |
| spi_driver.vhd | 6-bit SPI master for HMC649A phase shifter ICs |

## Configuration A — Hardware CORDIC Beamformer
PS writes azimuth/elevation via AXI → CORDIC computes phase offsets in hardware → SPI drives phase shifter ICs

| File | Description |
|------|-------------|
| pact_zero_top.vhd | Top level — AXI → CORDIC → sequencer FSM → SPI |
| phase_compute.vhd | Phase offset computation using 3× CORDIC pipeline |
| cordic_calc.vhd | 16-stage pipelined CORDIC sin/cos calculator |

## Configuration B — PicoRV32 Softcore Beamformer
PS writes angles via AXI CMD_REG → PicoRV32 computes offsets in firmware → offset registers → SPI drives phase shifter ICs

| File | Description |
|------|-------------|
| picorv32_top.vhd | Top level — AXI → PicoRV32 → offset registers → sequencer FSM → SPI |
| mem_intercon.vhd | PicoRV32 memory bus address decoder and router |
| offset_reg.vhd | Memory-mapped phase offset register file (4× 8-bit) |

## Memory Map — Configuration B
| Address | Peripheral |
|---------|-----------|
| 0x00000000 | RAM (16KB) — firmware |
| 0x10000000 | UART — simulation debug |
| 0x20000004 | CMD_REG — reads steering angles from PS |
| 0x20000010 | offset_reg_00 — phase offset element (0,0) |
| 0x20000014 | offset_reg_10 — phase offset element (1,0) |
| 0x20000018 | offset_reg_01 — phase offset element (0,1) |
| 0x2000001C | offset_reg_11 — phase offset element (1,1) |
