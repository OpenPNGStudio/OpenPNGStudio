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

#ifndef _MESSAGEBOX_H_
#define _MESSAGEBOX_H_

#include <raylib-nuklear.h>

enum messagebox_type {
    MESSAGEBOX_INFO,
    MESSAGEBOX_WARN,
    MESSAGEBOX_ERROR,
    MESSAGEBOX_CUSTOM,
};

struct messagebox {
    const char *title;
    const char *body;
    enum messagebox_type type;
    int res;
    int (*custom)(struct nk_context *ctx, struct messagebox *box);
    void *userdata;
};

struct messagebox messagebox_info(const char *title, const char *body);
struct messagebox messagebox_warn(const char *title, const char *body);
struct messagebox messagebox_error(const char *title, const char *body);
struct messagebox messagebox_custom(const char *title,
    int (*fn)(struct nk_context *ctx, struct messagebox *box),
    void* userdata);

void messagebox_run(struct messagebox *messagebox, struct nk_context *ctx);

#endif
