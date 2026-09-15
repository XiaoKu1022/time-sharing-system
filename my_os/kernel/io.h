/*
 * Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef KERNEL_IO_H
#define KERNEL_IO_H

#include <stdint.h>

// Write one byte to an x86 I/O port.
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ __volatile__(
        "outb %0, %1" 
        : 
        : "a"(val), "Nd"(port)
    );
}

// Read one byte from an x86 I/O port.
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