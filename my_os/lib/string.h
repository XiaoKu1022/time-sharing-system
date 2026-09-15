/*
 * Copyright (C) 2026 YUNG-EN KU / XiaoKu1022
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef LIB_STRING_H
#define LIB_STRING_H

#include <stddef.h>
#include <stdint.h>

size_t strlen(const char* str);
void* memset(void* dest, int val, size_t count);
void* memcpy(void* dest, const void* src, size_t count);
char* itoa(int value, char* str, int base);

#endif