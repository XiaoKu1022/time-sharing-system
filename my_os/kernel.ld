ENTRY(kernel_main)

SECTIONS
{
    /* 核心程式碼載入的線性位址 */
    . = 0x10000;

    .text : ALIGN(4) {
        *(.entry)       /* 強制將 kernel_main 放最前面 */
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