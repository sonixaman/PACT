# PACT-Zero — Phased Array Control & Tracking

A 2×2 Uniform Planar Array beamformer implemented on **Zynq ZC702** FPGA, targeting phased array signal processing for detector electronics applications.

PACT-Zero implements two independent beamforming configurations on the same hardware platform, demonstrating both hardware-accelerated (CORDIC) and softcore CPU-based approaches to phase offset computation.

---

## Architecture Overview

### Configuration A — Hardware CORDIC Beamformer

```
PS (Linux userspace)
    ↓ write(az, el) → /dev/beamformer
Linux Kernel Driver (beamformer.c)
    ↓ iowrite32 → AXI4-Lite (M_AXI_GP0)
axi_beamformer_slave.vhd
    → reg_azimuth (0x00), reg_elevation (0x04)
    → STEERING_AZIMUTH, STEERING_ELEVATION (×182 scaled)
phase_compute.vhd
    → 3× 16-stage pipelined CORDIC (cordic_calc.vhd)
    → delta_x = (sin(az+el) + sin(az-el)) / 2
    → delta_y = sin(el)
    → offset_00=0, offset_10, offset_01, offset_11
sequencer FSM (pact_zero_top.vhd)
    → cycles through 4 array elements
spi_driver.vhd
    → 6-bit SPI master
HMC649A Phase Shifter ICs (×4)
    → 2×2 antenna array steered to (az, el)
```

**Simulation status: Simulated in Vivado XSim, Complete Functionality Simulated (Input Target Angle -> Sending SPI pipeline command)**

---

### Configuration B — PicoRV32 Softcore Beamformer

```
PS (Linux userspace)
    ↓ write(az, el) → /dev/beamformer
Linux Kernel Driver (beamformer.c)
    ↓ iowrite32 → AXI4-Lite CMD_REG (0x20)
axi_beamformer_slave.vhd
    → reg_cmd = (elevation[31:16] | azimuth[15:0])
    → cmd_data output
mem_intercon.vhd
    → routes 0x20000004 → cmd_data → PicoRV32 mem_rdata
PicoRV32 RV32IMC softcore (picorv32.v)
    → main.c polling loop reads CMD_REG
    → compute_offsets(az, el) using sin lookup table
    → writes to memory-mapped offset registers:
        0x20000010 → offset_reg_00
        0x20000014 → offset_reg_10
        0x20000018 → offset_reg_01
        0x2000001C → offset_reg_11
offset_reg.vhd
    → stores 4× 8-bit phase offsets
sequencer FSM (picorv32_top.vhd)
    → cycles through 4 array elements
spi_driver.vhd
    → 6-bit SPI master
HMC649A Phase Shifter ICs (×4)
```

---

## Memory Map

### AXI Register Map (axi_beamformer_slave.vhd)
| Offset | Register | Description |
|--------|----------|-------------|
| 0x00 | STEERING_AZIMUTH | Azimuth angle (Config A) |
| 0x04 | STEERING_ELEVATION | Elevation angle (Config A) |
| 0x08–0x14 | PHASE_REG_0–3 | Phase registers (placeholder) |
| 0x18 | CONTROL_REG | Control register (placeholder) |
| 0x1C | STATUS_REG | Status register |
| 0x20 | CMD_REG | Packed angles for Config B (el[31:16] \| az[15:0]) |

### PicoRV32 Address Space (Configuration B)
| Address | Peripheral |
|---------|-----------|
| 0x00000000 | RAM (16KB) — firmware |
| 0x10000000 | UART — simulation debug stub |
| 0x20000004 | CMD_REG — reads steering angles from PS via AXI |
| 0x20000010 | offset_reg_00 — phase offset element (0,0) |
| 0x20000014 | offset_reg_10 — phase offset element (1,0) |
| 0x20000018 | offset_reg_01 — phase offset element (0,1) |
| 0x2000001C | offset_reg_11 — phase offset element (1,1) |

---

## Repository Structure

```
PACT-Zero/
├── rtl/                            ← Synthesisable VHDL
│   ├── axi_slave.vhd               ← AXI4-Lite slave (shared Config A + B)
│   ├── spi_driver.vhd              ← 6-bit SPI master (shared Config A + B)
│   ├── pact_zero_top.vhd           ← Config A top level
│   ├── phase_compute.vhd           ← Config A: phase offset computation
│   ├── cordic_calc.vhd             ← Config A: 16-stage pipelined CORDIC
│   ├── picorv32_top.vhd            ← Config B top level
│   ├── mem_intercon.vhd            ← Config B: PicoRV32 memory bus router
│   └── offset_reg.vhd              ← Config B: memory-mapped offset registers
│
├── tb/                             ← Simulation only (not synthesisable)
│   ├── tb_top_pact_zero.vhd        ← Config A testbench 
│   ├── ram_simulation.vhd          ← BRAM simulation model (loads firmware.hex)
│   └── uart_controller.vhd         ← UART simulation stub (prints to Tcl console)
│
├── softcore/
│   ├── core/                       ← PicoRV32 RV32IMC softcore (YosysHQ submodule)
│   └── fw/                         ← PicoRV32 firmware
│       ├── main.c                  ← Sin lookup table, compute_offsets(), CMD_REG polling
│       ├── startup.S               ← Bare metal startup: stack init, jump to main
│       ├── linker.ld               ← Memory layout: 16KB RAM at 0x00000000
│       ├── makehex.py              ← Converts firmware.bin → firmware.hex (Yosys format)
│       └── firmware.hex            ← Compiled firmware loaded into BRAM at simulation
│
├── driver/                         ← Linux PS driver (shared Config A + B)
│   ├── beamformer.c                ← Linux kernel character device driver
│   ├── beamformer.bb               ← PetaLinux/Yocto recipe
│   └── Makefile                    ← Kernel module build system
│
└── docs/                           ← Documentation
```

---

## Key Design Decisions

### CORDIC Scaling (Config A)
Input angles from AXI are in raw degrees (30 = 30°). The CORDIC core uses an internal scaling where 16384 = 90°. The scaling factor applied in `phase_compute.vhd` is:

```
scaled = angle_degrees × 182    (182 ≈ 16384/90)
```

### Phase Offset Formula
For a 2×2 UPA with element spacing d = λ/2:

```
delta_x = (sin(az+el) + sin(az-el)) / 2
delta_y = sin(el)

offset_00 = 0           (reference element)
offset_10 = delta_x
offset_01 = delta_y
offset_11 = delta_x + delta_y
```

### SPI Protocol
The HMC649A accepts 6-bit phase commands (5.625° per step = 360°/64). The sequencer FSM cycles through all 4 elements, asserting individual CS_N lines:

```
cs_n = 1110 → element (0,0)
cs_n = 1101 → element (1,0)
cs_n = 1011 → element (0,1)
cs_n = 0111 → element (1,1)
```

### Config B Firmware — Sin Lookup Table
PicoRV32 has no FPU. Phase offsets are computed using a 91-entry sin lookup table (0–90°, scaled by 256) with quadrant handling:

```c
if (angle >= 0   && angle <= 90)  → sin_lookup[angle]
if (angle > 90   && angle <= 180) → sin_lookup[180 - angle]
if (angle >= -90 && angle < 0)    → -sin_lookup[-angle]
if (angle < -90)                  → -sin_lookup[180 + angle]
```

---

## Simulation — Configuration A

**Requirements:** Vivado 2024.1

**Design sources:**
```
axi_slave.vhd, phase_compute.vhd, cordic_calc.vhd,
spi_driver.vhd, pact_zero_top.vhd
```

**Simulation source:**
```
tb_top_pact_zero.vhd
```

**Result:** For az=30°, el=20°:
```
offset_00 = 0x00    cs_n = 1110    MOSI = 000000
offset_10 = 0x3C    cs_n = 1101    MOSI = 001111
offset_01 = 0x2B    cs_n = 1011    MOSI = 001010
offset_11 = 0x67    cs_n = 0111    MOSI = 011001
```

---

## Simulation — Configuration B

**Requirements:** Vivado 2024.1, RISC-V GCC toolchain (RV32IMC)

**Design sources:**
```
picorv32.v, picorv32_top.vhd, axi_slave.vhd,
mem_intercon.vhd, offset_reg.vhd, spi_driver.vhd,
ram_simulation.vhd, uart_controller.vhd
```

**Simulation source:**
```
tb_picorv32.vhd
```

**Firmware compilation:**
```bash
riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 \
    -nostdlib -nostartfiles -ffreestanding \
    -T linker.ld startup.S main.c -o firmware.elf

riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin
python3 makehex.py firmware.bin 4096 > firmware.hex
```

---

## Hardware

| Component | Details |
|-----------|---------|
| FPGA | Xilinx Zynq ZC702 (xc7z020clg484) or Basys |
| Phase Shifter IC | Any 6-bit Phase Shifter IC (5.625°/step) |
| Array | 2×2 Uniform Planar Array |
| PS | ARM Cortex-A9 dual-core @ 666MHz |
| PL Clock | 100MHz |
| OS | PetaLinux 2024.1 |

---

## Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Vivado | 2024.1 | Synthesis, simulation, bitstream |
| PetaLinux | 2024.1 | Linux build for PS |
| RISC-V GCC | 10.2.0 (rv32imc) | Firmware compilation |
| PicoRV32 | YosysHQ | RV32IMC softcore CPU |
| GHDL | — | VHDL linting |

---

## License

MIT License — Copyright (c) 2026 Aman Soni

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
