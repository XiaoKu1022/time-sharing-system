# Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
# SPDX-License-Identifier: GPL-3.0-or-later

# 16-bit boot sector: load setup and kernel through BIOS.
.code16
.global _start
.section .text

_start:
    # Initialize real-mode segments and stack.
    cli
    xorw    %ax, %ax
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %ss
    movw    $0x7c00, %sp
    sti

    # Preserve the BIOS boot drive number.
    movb    %dl, boot_drive

    movw    $msg_boot, %si
    call    print_string

    # Load setup.s from sectors 2-5 to 0x0000:0x7E00.
load_setup:
    movb    $0x02, %ah
    movb    $4, %al
    movb    $0, %ch
    movb    $2, %cl
    movb    $0, %dh
    movb    boot_drive, %dl
    xorw    %bx, %bx
    movw    %bx, %es
    movw    $0x7e00, %bx
    int     $0x13
    jc      disk_error

    # Load kernel from sectors 6-15 to 0x1000:0x0000.
load_kernel:
    movb    $0x02, %ah
    movb    $10, %al
    movb    $0, %ch
    movb    $6, %cl
    movb    $0, %dh
    movb    boot_drive, %dl
    movw    $0x1000, %bx
    movw    %bx, %es
    xorw    %bx, %bx
    int     $0x13
    jc      disk_error

    movw    $msg_loaded, %si
    call    print_string

    # Transfer control to setup.s.
    ljmp    $0x0000, $0x7e00


print_string:
    cld
1:
    lodsb
    orb     %al, %al
    jz      2f
    movb    $0x0e, %ah
    movw    $0x0007, %bx
    int     $0x10
    jmp     1b
2:
    ret


disk_error:
    movw    $msg_disk_error, %si
    call    print_string
halt:
    hlt
    jmp     halt


boot_drive:      .byte 0
msg_boot:        .asciz "Booting OS from bootsect...\r\n"
msg_loaded:      .asciz "Setup and Kernel loaded. Jumping to setup.s...\r\n"
msg_disk_error:  .asciz "Disk read error! System halted.\r\n"


.fill 510 - (. - _start), 1, 0
.word 0xaa55