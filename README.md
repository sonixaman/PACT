# PACT — Phased Array Control & Tracking

A modular FPGA-based phased array beamforming platform designed for real-time beam steering in detector electronics and radar applications, implemented on Xilinx Zynq SoCs.

---

## Versions

### PACT-Zero — 2×2 Array Beamformer
**Status: Active Development**

Entry-level configuration implementing a 2×2 Uniform Planar Array beamformer on Zynq ZC702. Demonstrates dual beamforming approaches — hardware CORDIC pipeline and PicoRV32 softcore — with full PS/PL integration via AXI4-Lite and Linux kernel driver.

→ [See PACT-Zero documentation](./PACT-Zero/README.md)

---

### PACT-One — Large Array Beamformer
**Status: Planned**

Scaled implementation targeting larger array configurations with continuous beam steering, phased array communication, and real-time tracking capabilities. Building on the architecture established in PACT-Zero.

---

## Platform

| | Details |
|-|---------|
| FPGA | Xilinx Zynq ZC702 |
| Interface | AXI4-Lite, SPI |
| OS | PetaLinux 2024.1 |
| HDL | VHDL |

---

## License
MIT License — Copyright (c) 2025 Aman Soni
