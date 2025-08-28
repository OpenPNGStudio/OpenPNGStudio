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

#ifndef _EDITOR_H_
#define _EDITOR_H_

#include <archive.h>
#include <core/microphone.h>
#include "ui/window.h"
#include <layer/manager.h>
#if 0
#include <lua_ctx.h>
#endif
#include <raylib-nuklear.h>
#include <stdint.h>

enum editor_tab_id {
    OVERVIEW = 0,
    LAYERS = 1,
    MICROPHONE = 1,
    SCRIPTS = 2,
    SCENE = 2,
};

struct editor {
    /* TABS */
    struct layer_manager layer_manager;
#if 0
    struct script_mgr script_manager;
#endif

    /* STATE */
    enum editor_tab_id current_tab;
    struct window win;
    struct microphone_data *mic;
    size_t previous_volume;
    size_t microphone_trigger;
    Color background_color;
    char bg_color_in[7];
    int bg_color_len;
    int timer_ttl;

    bool talk_timer_running;
    bool pause_timer_running;
};

void editor_draw(struct editor *editor, struct nk_context *ctx, bool *ui_focused);
void editor_draw_stream(struct editor *editor, struct nk_context *ctx,
    bool *ui_focused);
void editor_apply_mask(struct editor *editor);

#endif
