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

/* 4294967295 - 10 characters + 2 backup */
#define INT_MAX_STR_SZ 12

#include <layer/manager.h>
#include <ui/window.h>

struct gif_configurator {
    struct window win;
    struct animated_layer *layer;
    char **inputs;
    int *lengths;
    bool global_delay;
};

void gif_configurator_prepare(struct gif_configurator *cfg,
    struct animated_layer *layer);

void gif_configurator_draw(struct gif_configurator *cfg,
    struct nk_context *ctx, bool *ui_focused);
