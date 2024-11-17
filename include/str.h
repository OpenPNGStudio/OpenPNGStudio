#ifndef _STR_H_
#define _STR_H_

#include <stdio.h>

size_t sized_strncpy(char *dest, const char *src, size_t n);

#ifdef _WIN32
char *strchrnul(const char *s, int c);
#endif

#endif
