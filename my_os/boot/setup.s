# setup.s - 16-bit v8086 mode -> 32-bit PM
.code16
.global _start
.section .text

_start:
    # 1. 停用中斷 (PM 下 IVT 失效)
    cli

    # 2. 啟用 A20 位址線 (Fast A20 Gate, Port 0x92)
    inb     $0x92, %al
    orb     $0x02, %al
    outb    %al, $0x92

    # 3. Load GDT
    lgdt    gdt_descriptor

    # 4. Set CR0 - Protection Enable
    movl    %cr0, %eax
    orl     $0x01, %eax
    movl    %eax, %cr0

    # 5. Far Jump to .code32 
    # 0x08: GDT - Code Segment Selector
    ljmp    $0x08, $protected_mode_entry


.code32
protected_mode_entry:
    # 6. init all 32-bits Segment Regs
    # 0x10: GDT - Data Segment Selector
    movw    $0x10, %ax
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %fs
    movw    %ax, %gs
    movw    %ax, %ss

    # 7. set 32-bits 保護模式堆疊 (0x90000)
    movl    $0x90000, %esp

    # 8. pm test msg
    movw    $0x2F50, 0xb8000    # 'P'
    movw    $0x2F4D, 0xb8002    # 'M'

    # 9. goto kernel enter pointer: 0x10000)
    call    0x10000

    # if kernel ret -> die loop (Wwwwww
halt_loop:
    hlt
    jmp     halt_loop


/*
 GDT - Global Descriptor Table
 (Flat Model), base: 0，limit: 4GB
*/
.align 4
gdt_start:
    # 描述元 0：空描述元 (Null Descriptor，CPU 規範硬性要求)
    .quad 0x0000000000000000

    # 描述元 1：32 位元核心程式碼段 (Code Segment Selector: 0x08)
    # Base = 0x00000000, Limit = 0xFFFFF
    # Flags: Granularity=4KB (G=1), 32-bit (D=1), Present (P=1), Code, Readable
    .word 0xffff            # Limit [15:0]
    .word 0x0000            # Base [15:0]
    .byte 0x00              # Base [23:16]
    .byte 0x9a              # Access Byte (P=1, DPL=00, S=1, Type=1010b)
    .byte 0xcf              # Flags (G=1, D=1) + Limit [19:16] (0xF)
    .byte 0x00              # Base [31:24]

    # 描述元 2：32 位元核心資料段 (Data Segment Selector: 0x10)
    # Base = 0x00000000, Limit = 0xFFFFF
    # Flags: Granularity=4KB (G=1), 32-bit (B=1), Present (P=1), Data, Writable
    .word 0xffff            # Limit [15:0]
    .word 0x0000            # Base [15:0]
    .byte 0x00              # Base [23:16]
    .byte 0x92              # Access Byte (P=1, DPL=00, S=1, Type=0010b)
    .byte 0xcf              # Flags (G=1, D=1) + Limit [19:16] (0xF)
    .byte 0x00              # Base [31:24]
gdt_end:

# GDT 暫存器指標結構 (供 lgdt 指令載入)
gdt_descriptor:
    .word gdt_end - gdt_start - 1   # GDT 界限大小 (16 位元)
    .long gdt_start                 # GDT 實體線性位址 (32 位元)


# 補齊至 4 個磁區大小 (4 * 512 = 2048 位元組)
.fill 2048 - (. - _start), 1, 0