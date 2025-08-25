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

void reset_key_mask(uint64_t *mask);
void draw_props(struct layer_manager *mgr, struct nk_context *ctx, bool *ui_focused);
nk_bool nk_filter_key(const struct nk_text_edit *box, nk_rune unicode);

void layer_manager_cleanup(struct layer_manager *mgr)
{
    /* TODO */
}

void layer_manager_add_layer(struct layer_manager *mgr,
    struct layer *layer)
{
    mgr->layers = realloc(mgr->layers, (++mgr->layer_count) * sizeof(struct layer*));
    mgr->layers[mgr->layer_count - 1] = layer;
}

void start_animation(struct layer *);
void stop_animation(struct layer *);

void layer_manager_ui(struct layer_manager *mgr, struct nk_context *ctx)
{
    if (mgr->cfg_win.ctx == NULL)
        window_init(&mgr->cfg_win, ctx, "Layer Configuration");

    struct nk_rect bounds = nk_window_get_content_region(ctx);
    bounds.h -= 45;
    nk_layout_row_dynamic(ctx, bounds.h, 1);
    int res = nk_group_begin(ctx, "Layers", 0);

    for (int i = 0; i < mgr->layer_count; i++) {
        struct layer *layer = mgr->layers[i];
        struct nk_rect bounds = nk_layout_widget_bounds(ctx);
        bounds.h *= 2;

        if (i == mgr->selected_layer) {
            nk_layout_row_dynamic(ctx, 2, 1);
            nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
        }

        nk_layout_row_template_begin(ctx, 30);
        nk_layout_row_template_push_static(ctx, 30);
        nk_layout_row_template_push_dynamic(ctx);
        nk_layout_row_template_push_static(ctx, 30);
        nk_layout_row_template_end(ctx);

        if (nk_button_image(ctx, get_icon(SELECT_ICON))) {
            if (mgr->selected_layer == -1)
                mgr->selected_layer = i;
            else 
                mgr->selected_layer = -1;
        }

        line_edit_draw(&layer->properties.name, ctx);

        if (nk_button_image(ctx, get_icon(TRASH_ICON))) {
            layer->state.prepare_for_deletion = true;
            mgr->selected_layer = -1;
        }

        if (i == mgr->selected_layer) {
            nk_layout_row_dynamic(ctx, 2, 1);
            nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
        }
    }

    if (res)
        nk_group_end(ctx);

    if (mgr->selected_layer == -1)
        nk_widget_disable_begin(ctx);

    nk_layout_row_template_begin(ctx, 30);
    nk_layout_row_template_push_static(ctx, 30);
    nk_layout_row_template_push_static(ctx, 30);
    nk_layout_row_template_push_dynamic(ctx);
    nk_layout_row_template_end(ctx);

    int i = mgr->selected_layer;
    struct layer *layer = mgr->selected_layer != -1 ? mgr->layers[i] : NULL;

    if (i == 0)
        nk_widget_disable_begin(ctx);

    if (nk_button_image(ctx, get_icon(UP_ICON))) {
        struct layer *prev = mgr->layers[i - 1];
        mgr->layers[i - 1] = layer;
        mgr->layers[i] = prev;
        mgr->selected_layer = -1;
    }

    if (i == 0)
        nk_widget_disable_end(ctx);

    if (i == mgr->layer_count - 1)
        nk_widget_disable_begin(ctx);

    if (nk_button_image(ctx, get_icon(DOWN_ICON))) {
        struct layer *next = mgr->layers[i + 1];
        mgr->layers[i + 1] = layer;
        mgr->layers[i] = next;
        mgr->selected_layer = -1;
    }
    if (i == mgr->layer_count - 1)
        nk_widget_disable_end(ctx);

    if (mgr->selected_layer == -1)
        nk_widget_disable_end(ctx);


    if (mgr->selected_layer != -1) {
        struct layer *layer = mgr->layers[mgr->selected_layer];
        uint64_t old_mask = layer->state.mask;
        mgr->cfg_win.show = true;

        if (layer->state.mask != old_mask)
            layer->state.is_toggled = false;
    }

    for (int i = 0; i < mgr->layer_count;) {
        struct layer *layer = mgr->layers[i];

        if (layer->state.prepare_for_deletion) {
            if (i + 1 < mgr->layer_count)
                memcpy(mgr->layers + i, mgr->layers + i + 1,
                    sizeof(struct layer*) * (mgr->layer_count - i - 1));

            mgr->layer_count--;
            if (layer->state.active || layer->properties.is_animated)
                continue; /* it will get cleaned up in the respective fn */

            layer_cleanup(layer);
            continue;
        }

        /* if layer didn't get deleted */
        i++;
    }
}

void layer_manager_render(struct layer_manager *mgr)
{
    if (mgr->anims == NULL)
        mgr->anims = animation_manager_new();

    float width = GetScreenWidth();
    float height = GetScreenHeight();

    for (int i = 0; i < mgr->layer_count; i++) {
        struct layer *layer = mgr->layers[i];
        Image *img = &layer->properties.image;
        Texture2D texture = layer->properties.texture;

        if (layer->properties.is_animated) {
            struct animated_layer *al = layer_get_animated(layer);
            if (al->properties.previous_frame_index != al->properties.current_frame_index) {
                size_t offset = img->width * img->height * 4 *
                    al->properties.current_frame_index;

                UpdateTexture(texture, ((unsigned char*) img->data) + offset);
                al->properties.previous_frame_index = al->properties.current_frame_index;
            }
        }

        bool mask_test = test_masks(get_current_mask(), layer->state.mask);

        if ((layer->state.active || layer->state.is_toggled) || mask_test) {
            struct layer_properties props = layer_updated_properties(layer);
            DrawTexturePro(texture, (Rectangle) {
                .x = 0,
                .y = 0,
                .width = texture.width,
                .height = texture.height,
            }, (Rectangle) {
                .x = width / 2.0f + props.offset.x,
                .y = height / 2.0f + (-props.offset.y),
                .width = texture.width,
                .height = texture.height,
            }, (Vector2) {
                .x = texture.width / 2.0f,
                .y = texture.height / 2.0f,
            }, props.rotation - 180, props.tint);
            start_animation(layer);

            if (!layer->properties.has_toggle) {
                /* spawn live timeout */
                if (!layer->state.active && layer->state.time_to_live > 0)
                    layer_start_timeout(layer, ctx.loop);
            } else {
                if (!layer->state.is_toggle_timer_ticking && mask_test)
                    layer_toggle(layer, ctx.loop);
            }
        } else {
            stop_animation(layer);
        }
    }

    animation_manager_tick(mgr->anims);
}

void draw_props(struct layer_manager *mgr, struct nk_context *ctx, bool *ui_focused)
{
    if (window_begin(&mgr->cfg_win, NK_WINDOW_TITLE | NK_WINDOW_MOVABLE |
        NK_WINDOW_SCALABLE | NK_WINDOW_BORDER | NK_WINDOW_MINIMIZABLE |
        NK_WINDOW_CLOSABLE)) {

        if (nk_input_is_mouse_hovering_rect(&ctx->input, nk_window_get_bounds(ctx)))
            *ui_focused = true;
        struct layer *layer = mgr->layers[mgr->selected_layer];
        bool holding_shift = nk_input_is_key_down(&ctx->input, NK_KEY_SHIFT);

        nk_layout_row_dynamic(ctx, 30, 1);
        nk_label(ctx, "Position:", NK_TEXT_LEFT);
        nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 2);
        nk_layout_row_push(ctx, 0.5f);
        if (!holding_shift) {
            nk_property_float(ctx, "X", -FLT_MAX, &layer->properties.offset.x, FLT_MAX, 0.1f, 0.1f);
            nk_layout_row_push(ctx, 0.49f);
            nk_property_float(ctx, "Y", -FLT_MAX, &layer->properties.offset.y, FLT_MAX, 0.1f, 0.1f);
        } else {
            layer->properties.offset.x = roundf(layer->properties.offset.x);
            layer->properties.offset.y = roundf(layer->properties.offset.y);
            nk_property_float(ctx, "X", -FLT_MAX, &layer->properties.offset.x, FLT_MAX, 1, 1);
            nk_layout_row_push(ctx, 0.49f);
            nk_property_float(ctx, "Y", -FLT_MAX, &layer->properties.offset.y, FLT_MAX, 1, 1);
        }
        nk_layout_row_end(ctx);

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

        configure_mask(&layer->state.mask, layer->input_key_buffer,
            &layer->input_key_length, ctx, "Mask:");

        animation_manager_selector(mgr->anims, layer, ctx);
    } else
        mgr->selected_layer = -1;

    if (mgr->cfg_win.state != HIDE)
        window_end(&mgr->cfg_win);
}

void reset_key_mask(uint64_t *mask)
{
    uint64_t new_mask = 0;
    for (int i = 0; i < 7; i++)
        new_mask |= 1ULL << i;

    *mask &= new_mask;
}

nk_bool nk_filter_key(const struct nk_text_edit *box, nk_rune unicode)
{
    if ((unicode >= 'a' && unicode <= 'z') || (unicode >= 'A' && unicode <= 'Z'))
        return nk_true;

    return nk_false;
}
