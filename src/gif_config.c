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
#include <ui/window.h>
#include <assert.h>
#include <limits.h>
#include <gif_config.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static nk_bool nk_filter_delay(const struct nk_text_edit *box, nk_rune unicode);

void gif_configurator_prepare(struct gif_configurator *cfg,
    struct animated_layer *layer)
{
    uint64_t frame_count = layer->properties.number_of_frames;

    cfg->layer = layer;
    cfg->inputs = calloc(sizeof(char*), frame_count);
    cfg->lengths = calloc(sizeof(int), frame_count);

    for (uint64_t i = 0; i < frame_count; i++)
        cfg->inputs = calloc(sizeof(char), INT_MAX_STR_SZ);

    layer->properties.frame_delays = calloc(sizeof(uint32_t), frame_count);
    cfg->win.show = true;
}

void gif_configurator_draw(struct gif_configurator *cfg,
    struct nk_context *ctx, bool *ui_focused)
{
    if (cfg->win.ctx == NULL) {
        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 90.0f;
        float h = height / 100.0f * 85.0f;
        float x = 40;
        float y = 40;

        cfg->win.geometry = nk_rect(x, y, w, h);
        window_init(&cfg->win, ctx, "Gif Configuration");
    }

    if (window_begin(&cfg->win, NK_WINDOW_TITLE | NK_WINDOW_MOVABLE |
        NK_WINDOW_SCALABLE | NK_WINDOW_BORDER)) {
        if (cfg->win.focus)
            *ui_focused = true;

        nk_layout_row_dynamic(ctx, 30, 2);
        nk_label(ctx, "Configure GIF frame delays", NK_TEXT_LEFT);
        nk_checkbox_label_align(ctx, "Toggle same delay", &cfg->global_delay, 
        NK_WIDGET_ALIGN_RIGHT, NK_TEXT_RIGHT);

        struct nk_rect total = nk_window_get_content_region(ctx);

        nk_layout_row_begin(ctx, NK_DYNAMIC, total.h - 80, 1);

        nk_layout_row_push(ctx, NK_UNDEFINED);
        struct nk_rect bounds = nk_layout_space_bounds(ctx);
        bounds.h += 30;

        if (nk_group_begin(ctx, "Frames", NK_WINDOW_BORDER)) {
            nk_layout_row_dynamic(ctx, 30, 2);
            for (int i = 0; i < cfg->layer->properties.number_of_frames; i++) {
                char name_buffer[32] = {0};
                snprintf(name_buffer, 32, "Frame %d", i + 1);

                if (cfg->global_delay) {
                    nk_label(ctx, "Delay ", NK_TEXT_LEFT);
                    if (i > 0)
                        nk_widget_disable_begin(ctx);

                    nk_edit_string(ctx, NK_EDIT_FIELD, cfg->inputs[0],
                        cfg->lengths + 0, 12, nk_filter_delay);

                    if (i > 0)
                        nk_widget_disable_end(ctx);
                } else {
                    nk_label(ctx, name_buffer, NK_TEXT_LEFT);
                    nk_edit_string(ctx, NK_EDIT_FIELD, cfg->inputs[i],
                        cfg->lengths + i, 12, nk_filter_delay);
                }

                int len = cfg->lengths[i];
                if (len == 0) {
                    memcpy(cfg->inputs[i], "0", 1);
                    len = 1;
                    cfg->lengths[i] = 1;
                }

                cfg->inputs[i][len] = 0;
                int64_t value = atoll(cfg->inputs[i]);
                assert(value < UINT_MAX &&
                    "User needs to see the error, TODO");
                if (cfg->global_delay)
                    cfg->layer->properties.frame_delays[i] = (uint32_t)
                        atoll(cfg->inputs[0]);
                else
                    cfg->layer->properties.frame_delays[i] = (uint32_t) value;
            }
            nk_group_end(ctx);
        }

        nk_layout_row_end(ctx);
        nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
        nk_layout_row_push(ctx, 0.85f);
        nk_spacing(ctx, 1);

        nk_layout_row_push(ctx, 0.149f);
        if (nk_button_label(ctx, "Done"))
            cfg->win.show = false;
    }

    if (cfg->win.state != HIDE)
        window_end(&cfg->win);
}

static nk_bool nk_filter_delay(const struct nk_text_edit *box, nk_rune unicode)
{
    if ((unicode < '0' || unicode > '9'))
        return nk_false;
    else return nk_true;
}
