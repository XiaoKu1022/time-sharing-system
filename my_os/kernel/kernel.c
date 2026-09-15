#include "../drivers/vga.h"

__attribute__((section(".entry"))) void kernel_main(void) {
    /* init vga device */
    vga_init();

    /* vga_puts test */
    const char *str = "Hello World\n";
    vga_puts(str);
    

    /* goto die ~~ */
    for (;;) {
        __asm__ __volatile__("hlt");
    }
}