#ifndef KERNEL_IO_H
#define KERNEL_IO_H

#include <stdint.h>

// 向指定 Port 寫入 1 byte
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ __volatile__(
        "outb %0, %1" 
        : 
        : "a"(val), "Nd"(port)
    );
}

// 從指定 Port 讀取 1 byte
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ __volatile__(
        "inb %1, %0" 
        : "=a"(ret) 
        : "Nd"(port)
    );
    return ret;
}

#endif