#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

// Physical base address of the GPIO peripheral on Raspberry Pi Zero
#define GPIO_BASE 0x3F200000

// Size of the GPIO memory mapping
#define GPIO_SIZE 4096

// Offset for the GPIO Function Select register 1 (controls pins 10-19)
#define GPFSEL1_OFFSET 0x04

// Offset for the GPIO Pin Level register 0 (controls pins 0-31)
#define GPLEV0_OFFSET 0x34

// Function select value for input
#define FSEL_INPUT 0b000

int main() {
    int fd;
    volatile uint32_t *gpio_map;
    int pin_to_read = 19;
    int reg_index = pin_to_read / 10;
    int bit_offset_fsel = (pin_to_read % 10) * 3;
    int bit_offset_plev = pin_to_read % 32;

    // Open /dev/gpiomem
    if ((fd = open("/dev/gpiomem", O_RDWR | O_SYNC)) < 0) {
        perror("Failed to open /dev/gpiomem");
        return 1;
    }

    // Map GPIO memory
    gpio_map = (volatile uint32_t *)mmap(NULL, GPIO_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    if (gpio_map == MAP_FAILED) {
        perror("Failed to map GPIO memory");
        return 1;
    }

    // Configure GPIO pin 19 as input
    volatile uint32_t *gpfsel_reg = gpio_map + (GPFSEL1_OFFSET / 4);
    uint32_t fsel_value = *gpfsel_reg;
    uint32_t mask = ~(7 << bit_offset_fsel);
    *gpfsel_reg = (fsel_value & mask) | (FSEL_INPUT << bit_offset_fsel);

    // Read the level of GPIO pin 19
    volatile uint32_t *gplev_reg = gpio_map + (GPLEV0_OFFSET / 4);
    uint32_t level = *gplev_reg;
    int pin_level = (level >> bit_offset_plev) & 1;

    printf("GPIO %d level: %d\n", pin_to_read, pin_level);

    // Unmap GPIO memory
    if (munmap((void *)gpio_map, GPIO_SIZE) < 0) {
        perror("Failed to unmap GPIO memory");
        return 1;
    }

    return 0;
}
