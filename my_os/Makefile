AS = i686-elf-as
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -fno-pie -fno-stack-protector -I.

# 自動收集所有 C 語言原始碼與對應的 .o
C_SOURCES = kernel/kernel.c drivers/vga.c lib/string.c
C_OBJECTS = $(C_SOURCES:.c=.o)

all: os.img

# bootsect
bootsect.bin: boot/bootsect.S
	$(AS) -o bootsect.o boot/bootsect.S
	$(LD) -Ttext 0x7c00 --oformat binary -o bootsect.bin bootsect.o

# setup
setup.bin: boot/setup.s
	$(AS) -o setup.o boot/setup.s
	$(LD) -Ttext 0x7e00 --oformat binary -o setup.bin setup.o

# 編譯所有 C 模組
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 連結所有 C 模組為核心 binary
kernel.bin: $(C_OBJECTS) kernel.ld
	$(LD) -T kernel.ld -o kernel.elf $(C_OBJECTS)
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	truncate -s 5120 kernel.bin

# 合併產出磁碟映像檔
os.img: bootsect.bin setup.bin kernel.bin
	cat bootsect.bin setup.bin kernel.bin > os.img
	truncate -s 1474560 os.img

run: os.img
	qemu-system-i386 -drive format=raw,file=os.img

clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.img" \) -delete

.PHONY: all run clean