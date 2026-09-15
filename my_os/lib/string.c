/*
 * Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "string.h"

size_t strlen(const char* str) {
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

void* memset(void* dest, int val, size_t count) {
    uint8_t* temp = (uint8_t*)dest;
    for (size_t i = 0; i < count; i++)
        temp[i] = (uint8_t)val;
    return dest;
}

void* memcpy(void* dest, const void* src, size_t count) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    for (size_t i = 0; i < count; i++)
        d[i] = s[i];
    return dest;
}

// Convert an integer to a string in the requested base.
char* itoa(int value, char* str, int base) {
    char* rc;
    char* ptr;
    char* low;
    if (base < 2 || base > 36) {
        *str = '\0';
        return str;
    }
    rc = ptr = str;
    if (value < 0 && base == 10) {
        *ptr++ = '-';
    }
    low = ptr;
    int sign = (value < 0 && base == 10) ? -1 : 1;
    do {
        *ptr++ = "0123456789abcdefghijklmnopqrstuvwxyz"[sign * (value % base)];
        value /= base;
    } while (value);
    *ptr-- = '\0';
    // Reverse the generated digits.
    while (low < ptr) {
        char tmp = *low;
        *low++ = *ptr;
        *ptr-- = tmp;
    }
    return rc;
}
