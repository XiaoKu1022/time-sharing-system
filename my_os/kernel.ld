# Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
# SPDX-License-Identifier: GPL-3.0-or-later

ENTRY(kernel_main)

SECTIONS
{
    /* Kernel load address. */
    . = 0x10000;

    .text : ALIGN(4) {
        *(.entry)       /* Place kernel_main first. */
        *(.text*)
    }

    .rodata : ALIGN(4) {
        *(.rodata*)
    }

    .data : ALIGN(4) {
        *(.data*)
    }

    .bss : ALIGN(4) {
        *(COMMON)
        *(.bss*)
    }
}