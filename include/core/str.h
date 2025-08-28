/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef _STR_H_
#define _STR_H_

#include <stdio.h>

size_t sized_strncpy(char *dest, const char *src, size_t n);

char *strchrnul(const char *s, int c);

#endif
