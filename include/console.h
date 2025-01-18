/*
 * This file is part of OpenPNGStudio. 
 * Copyright (C) 2024-2025 LowByteFox
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef _CONSOLE_H_
#define _CONSOLE_H_

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <stddef.h>
#include <raylib-nuklear.h>

void console_init();
void console_deinit();

void console_show();
void console_draw(struct nk_context *ctx, bool *ui_focused);

void console_debug(const char *fn, size_t line, const char *fmt, ...);
void console_info(const char *fn, size_t line, const char *fmt, ...);
void console_warn(const char *fn, size_t line, const char *fmt, ...);
void console_error(const char *fn, size_t line, const char *fmt, ...);

#ifndef NDEFBUG
#define LOG(fmt, ...) console_debug(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#else
#define LOG(fmt, ...) 
#endif
#define LOG_I(fmt, ...) console_info(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#define LOG_W(fmt, ...) console_warn(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)
#define LOG_E(fmt, ...) console_error(__FUNCTION__, __LINE__, fmt, __VA_ARGS__)

#endif
