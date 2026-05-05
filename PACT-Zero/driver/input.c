/*
 * Continuous beam steering userspace application
 *
 * Feeds azimuth/elevation angles to the Linux kernel driver
 * (beamformer.c) via /dev/beamformer device file.
 *
 * Usage:
 *   gcc -o input input.c
 *   ./input                              <- manual input
 *   echo "30 20" | ./input               <- single command
 *   cat angles.txt | ./input             <- sequence from file
 * 
 *
 * Note: This uses the Linux PS driver path (beamformer.c).
 * The PicoRV32 softcore path (softcore/fw/main.c) uses
 * hardcoded values for simulation verification.
 */

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#define DEVICE "/dev/beamformer"

int main() {
    int fd = open(DEVICE, O_WRONLY);
    if (fd < 0) {
        perror("Failed to open /dev/beamformer");
        return -1;
    }

    int angles[2];
    printf("Enter azimuth and elevation (e.g. 30,20). Ctrl+C to stop.\n");

    while(scanf("%d,%d", &angles[0], &angles[1]) == 2) {
        if (write(fd, angles, sizeof(angles)) < 0) {
            perror("Write failed");
            close(fd);
            return -1;
        }
        printf("Steering: azimuth=%d elevation=%d\n", angles[0], angles[1]);
    }

    close(fd);
    return 0;
}
