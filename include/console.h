/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifndef _CONSOLE_H_
#define _CONSOLE_H_

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <stddef.h>
#include <raylib-nuklear.h>

void console_debug(const char *fn, size_t line, const char *fmt, ...);
void console_info(const char *fn, size_t line, const char *fmt, ...);
void console_warn(const char *fn, size_t line, const char *fmt, ...);
void console_error(const char *fn, size_t line, const char *fmt, ...);

#ifndef NDEBUG
#define LOG(fmt, ...) console_debug(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#else
#define LOG(fmt, ...) 
#endif
#define LOG_I(fmt, ...) console_info(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#define LOG_W(fmt, ...) console_warn(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#define LOG_E(fmt, ...) console_error(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)

#endif
