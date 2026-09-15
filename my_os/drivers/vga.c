#include "vga.h"
#include "../kernel/io.h"
#include "../lib/string.h"

#define VGA_ADDRESS 0xB8000
#define VGA_WIDTH   80
#define VGA_HEIGHT  25

static volatile uint16_t* const vga_buffer = (uint16_t*)VGA_ADDRESS;
static size_t terminal_row;
static size_t terminal_col;
static uint8_t terminal_color;

static inline uint8_t make_color(enum vga_color fg, enum vga_color bg) {
    return fg | (bg << 4);
}

static inline uint16_t make_vga_entry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

// 透過 I/O Port 0x3D4/0x3D5 更新 VGA 硬體游標位置
static void update_cursor(int x, int y) {
    uint16_t pos = y * VGA_WIDTH + x;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

// 畫面到底時，向上滾動一行
static void scroll(void) {
    for (size_t y = 0; y < VGA_HEIGHT - 1; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            vga_buffer[y * VGA_WIDTH + x] = vga_buffer[(y + 1) * VGA_WIDTH + x];
        }
    }
    // 清除最後一行
    uint16_t blank = make_vga_entry(' ', terminal_color);
    for (size_t x = 0; x < VGA_WIDTH; x++) {
        vga_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = blank;
    }
}

void vga_clear(void) {
    uint16_t blank = make_vga_entry(' ', terminal_color);
    for (size_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = blank;
    }
    terminal_row = 0;
    terminal_col = 0;
    update_cursor(0, 0);
}

void vga_init(void) {
    terminal_row = 0;
    terminal_col = 0;
    terminal_color = make_color(VGA_COLOR_WHITE, VGA_COLOR_BLUE);
    vga_clear();
}

void vga_set_color(enum vga_color fg, enum vga_color bg) {
    terminal_color = make_color(fg, bg);
}

void vga_putc(char c) {
    if (c == '\n') {
        terminal_col = 0;
        terminal_row++;
    } else if (c == '\r') {
        terminal_col = 0;
    } else if (c == '\t'){
        // pass
    } else {
        vga_buffer[terminal_row * VGA_WIDTH + terminal_col] = make_vga_entry(c, terminal_color);
        terminal_col++;
        if (terminal_col >= VGA_WIDTH) {
            terminal_col = 0;
            terminal_row++;
        }
    }

    if (terminal_row >= VGA_HEIGHT) {
        scroll();
        terminal_row = VGA_HEIGHT - 1;
    }
    update_cursor(terminal_col, terminal_row);
}

void vga_puts(const char* str) {
    for (size_t i = 0; str[i] != '\0'; i++) {
        vga_putc(str[i]);
    }
}

void vga_putint(int value, int base) {
    char buf[32];
    itoa(value, buf, base);
    vga_puts(buf);
}