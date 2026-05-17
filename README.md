# PACT — Phased Array Control & Tracking

A modular FPGA-based phased array beamforming platform designed for real-time beam steering in detector electronics and radar applications, implemented on Xilinx Zynq SoCs.

---

## Versions

### PACT-Zero — 2×2 Array Beamformer
**Status: Active Development**

Entry-level configuration implementing a 2×2 Uniform Planar Array beamformer on Zynq ZC702. Demonstrates dual beamforming approaches — hardware CORDIC pipeline and PicoRV32 softcore — with full PS/PL integration via AXI4-Lite and Linux kernel driver.

→ [See PACT-Zero documentation](./PACT-Zero/)

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
MIT License — Copyright (c) 2026 Aman Soni

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
