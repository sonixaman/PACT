# PS Driver — Linux Kernel Module

AXI4-Lite kernel driver for PACT-Zero beamformer control.

| File | Description |
|------|-------------|
| beamformer.c | Linux kernel driver — writes steering angles via /dev/beamformer |
| beamformer.bb | PetaLinux Yocto recipe for kernel module integration |
| Makefile | Kernel module build system |

## Usage
```
echo "30 20" > /dev/beamformer    # steer to az=30°, el=20°
```
