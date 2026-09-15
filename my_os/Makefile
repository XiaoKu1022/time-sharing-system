# Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
# SPDX-License-Identifier: GPL-3.0-or-later

AS = i686-elf-as
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -fno-pie -fno-stack-protector -I.

# Kernel C sources and their object files.
C_SOURCES = kernel/kernel.c drivers/vga.c lib/string.c
C_OBJECTS = $(C_SOURCES:.c=.o)

all: os.img

# Build the boot sector.
bootsect.bin: boot/bootsect.s
	$(AS) -o bootsect.o boot/bootsect.s
	$(LD) -Ttext 0x7c00 --oformat binary -o bootsect.bin bootsect.o

# Build the setup image.
setup.bin: boot/setup.s
	$(AS) -o setup.o boot/setup.s
	$(LD) -Ttext 0x7e00 --oformat binary -o setup.bin setup.o

# Compile C sources.
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Link and extract the kernel image.
kernel.bin: $(C_OBJECTS) kernel.ld
	$(LD) -T kernel.ld -o kernel.elf $(C_OBJECTS)
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	truncate -s 5120 kernel.bin

# Combine all images into a floppy disk image.
os.img: bootsect.bin setup.bin kernel.bin
	cat bootsect.bin setup.bin kernel.bin > os.img
	truncate -s 1474560 os.img

run: os.img
	qemu-system-i386 -drive format=raw,file=os.img

clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.img" \) -delete

.PHONY: all run clean