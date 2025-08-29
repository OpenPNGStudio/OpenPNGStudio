/* SPDX-License-Identifier: GPL-3.0-or-later */
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
    struct layer_manager *layer_manager;
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
