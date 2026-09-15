# Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
# SPDX-License-Identifier: GPL-3.0-or-later

# Switch from real mode to 32-bit protected mode.
.code16
.global _start
.section .text

_start:
    cli

    # Enable the A20 line through the fast A20 gate.
    inb     $0x92, %al
    orb     $0x02, %al
    outb    %al, $0x92

    lgdt    gdt_descriptor

    # Enable protected mode in CR0.
    movl    %cr0, %eax
    orl     $0x01, %eax
    movl    %eax, %cr0

    # Reload CS with the 32-bit code selector.
    ljmp    $0x08, $protected_mode_entry


.code32
protected_mode_entry:
    # Load the 32-bit data selector into all data segments.
    movw    $0x10, %ax
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %fs
    movw    %ax, %gs
    movw    %ax, %ss

    # Set the protected-mode stack.
    movl    $0x90000, %esp

    # Display a protected-mode marker.
    movw    $0x2F50, 0xb8000    # 'P'
    movw    $0x2F4D, 0xb8002    # 'M'

    # Enter the kernel at its linked address.
    call    0x10000

    # The kernel should not return.
halt_loop:
    hlt
    jmp     halt_loop


/* Flat-model GDT with a 4 GB limit. */
.align 4
gdt_start:
    # Null descriptor.
    .quad 0x0000000000000000

    # 32-bit kernel code segment, selector 0x08.
    .word 0xffff
    .word 0x0000
    .byte 0x00
    .byte 0x9a
    .byte 0xcf
    .byte 0x00

    # 32-bit kernel data segment, selector 0x10.
    .word 0xffff
    .word 0x0000
    .byte 0x00
    .byte 0x92
    .byte 0xcf
    .byte 0x00
gdt_end:

# Descriptor used by lgdt.
gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start


# Pad setup.bin to four sectors.
.fill 2048 - (. - _start), 1, 0