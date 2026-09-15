/*
 * Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "../drivers/vga.h"

__attribute__((section(".entry"))) void kernel_main(void) {
    vga_init();

    const char *str = "Hello World\n";
    vga_puts(str);

    for (;;) {
        __asm__ __volatile__("hlt");
    }
}