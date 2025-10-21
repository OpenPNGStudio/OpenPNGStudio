/* SPDX-License-Identifier: GPL-3.0-or-later */

#include <console.h>
#include <context.h>
#include <core/icon_db.h>
#include <ui/line_edit.h>
#include <core/mask.h>
#include <raylib-nuklear.h>
#include <raylib.h>
#include <unuv.h>
#include <limits.h>
#include <float.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <layer/manager.h>
#include <string.h>

extern struct context ctx;

void draw_props(struct layer_manager *mgr, struct nk_context *ctx, bool *ui_focused);

void start_animation(struct layer *);
void stop_animation(struct layer *);

void draw_props(struct layer_manager *mgr, struct nk_context *ctx, bool *ui_focused)
{
    if (window_begin(&mgr->cfg_win, NK_WINDOW_TITLE | NK_WINDOW_MOVABLE |
        NK_WINDOW_SCALABLE | NK_WINDOW_BORDER | NK_WINDOW_MINIMIZABLE |
        NK_WINDOW_CLOSABLE)) {

        struct layer *layer = mgr->layers[mgr->selected_layer];

        configure_mask(&layer->state.mask, layer->state.input_key_buffer,
            &layer->state.input_key_len, ctx, "Mask:");

        animation_manager_selector(mgr->anims, layer, ctx);
    } else
        mgr->selected_layer = -1;

    if (mgr->cfg_win.state != HIDE)
        window_end(&mgr->cfg_win);
}
