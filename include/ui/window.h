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

#pragma once

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <raylib-nuklear.h>
#include <stdbool.h>

enum window_state {
    HIDE,
    SHOW,
    CLOSE,
};

struct window {
    struct nk_rect geometry;
    const char *title;
    struct nk_context *ctx;
    enum window_state state;
    bool focus;
    bool show;
};

void window_init(struct window *win, struct nk_context *ctx,
    const char *title);
bool window_begin(struct window *win, nk_flags flags);
void window_end(struct window *win);
