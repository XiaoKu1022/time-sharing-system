# bootsect.S - 16-bit v8086 mode
.code16
.global _start
.section .text

_start:
    # 1. 關閉中斷並初始化段暫存器
    cli
    xorw    %ax, %ax        # ax <- 0x0
    movw    %ax, %ds        # data segm
    movw    %ax, %es        # extra segm
    movw    %ax, %ss        # stack segm
    movw    $0x7c00, %sp    # 0x7C00 向下增長（0x0500~0x7BFF 是安全的自由空間）
    sti

    # 2. 保存開機磁碟機代號
    movb    %dl, boot_drive

    # 3. 
    movw    $msg_boot, %si
    call    print_string

    # 4. load setup.s (磁區2~5，共4個磁區) -> 0x0000:0x7E00
load_setup:
    movb    $0x02, %ah          # [Set] BIOS IVT 讀磁區功能代號
    movb    $4, %al             # [Set] 讀取 4 個磁區
    movb    $0, %ch             # [Set] Cylinder 0
    movb    $2, %cl             # [Set] Sector 2 (從第 2 磁區開始)
    movb    $0, %dh             # [Set] Head 0
    movb    boot_drive, %dl     # [Set] 磁碟機代號
    xorw    %bx, %bx
    movw    %bx, %es            # [Set] ES = 0x0000
    movw    $0x7e00, %bx        # [Set] ES:BX = 0x0000:0x7E00
    int     $0x13               # Call BIOS Int Service
    jc      disk_error          # if CF = 1 -> fail

    # 5. load kernel (磁區 6~15，共10個磁區) -> 0x1000:0x0000 (線性位址 0x10000)
load_kernel:
    movb    $0x02, %ah
    movb    $10, %al
    movb    $0, %ch
    movb    $6, %cl             # Sector 6 (接在 setup 後面)
    movb    $0, %dh
    movb    boot_drive, %dl
    movw    $0x1000, %bx
    movw    %bx, %es            # ES = 0x1000
    xorw    %bx, %bx            # ES:BX = 0x1000:0x0000
    int     $0x13
    jc      disk_error

    # 6. 印出成功訊息並跳轉至 setup.s
    movw    $msg_loaded, %si
    call    print_string

    # 長跳躍到 setup.s (CS = 0x0000, IP = 0x7E00)
    ljmp    $0x0000, $0x7e00


print_string:
    cld                         # 清除方向旗標 -> lodsb 向前讀取
1:
    lodsb                       # 載入 %ds:(%si) 到 %al，並將 %si + 1
    orb     %al, %al            # 檢查是否讀到結尾 0
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