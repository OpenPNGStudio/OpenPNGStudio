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
        bool holding_shift = nk_input_is_key_down(&ctx->input, NK_KEY_SHIFT);

        nk_layout_row_dynamic(ctx, 30, 1);
        nk_label(ctx, "Rotation:", NK_TEXT_LEFT);
        nk_layout_row_static(ctx, 40, 40, 1);

        nk_knob_float(ctx, 0, &layer->properties.rotation, 360, 0.1f, NK_DOWN, 0.0f);

        if (holding_shift)
            layer->properties.rotation = roundf(layer->properties.rotation / 15.0f) * 15.0f;

        nk_layout_row_dynamic(ctx, 30, 1);
        nk_checkbox_label(ctx, "Enable toggle mode", &layer->properties.has_toggle);

        if (layer->properties.has_toggle)
            nk_widget_disable_begin(ctx);

        nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 2);
        nk_layout_row_push(ctx, 0.5f);
        nk_label(ctx, "Time to live:", NK_TEXT_LEFT);
        nk_layout_row_push(ctx, 0.49f);
        nk_property_int(ctx, "timeout (ms)", 0, &layer->state.time_to_live, INT_MAX, 1, 0.1f);

        if (layer->properties.has_toggle)
            nk_widget_disable_end(ctx);

        nk_layout_row_dynamic(ctx, 2, 1);
        nk_rule_horizontal(ctx, ctx->style.window.border_color, false);

        configure_mask(&layer->state.mask, layer->state.input_key_buffer,
            &layer->state.input_key_len, ctx, "Mask:");

        animation_manager_selector(mgr->anims, layer, ctx);
    } else
        mgr->selected_layer = -1;

    if (mgr->cfg_win.state != HIDE)
        window_end(&mgr->cfg_win);
}
