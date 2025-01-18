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

#include "archive.h"
#include "console.h"
#include "context.h"
#include "layermgr.h"
#include "mask.h"
#include "raymath.h"
#include "ui/window.h"
#include "unuv.h"
#include <ctype.h>
#include <raylib-nuklear.h>
#include <editor.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <nk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern struct context ctx;

static enum un_action update_talk_mask(un_timer *timer);
static enum un_action update_pause_mask(un_timer *timer);
static void hex_str_to_color(const char *str, Color *color);

void editor_draw(struct editor *editor, struct nk_context *ctx, bool *ui_focused)
{
    if (editor->win.ctx == NULL) {
        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 45.0f;
        float h = height / 100.0f * 85.0f;
        float x = width - w - 40;
        float y = 60;

        editor->win.geometry = nk_rect(x, y, w, h);
        editor->win.show = true;
        window_init(&editor->win, ctx, "Editor");
    }

    if (window_begin(&editor->win, NK_WINDOW_TITLE | NK_WINDOW_MOVABLE |
        NK_WINDOW_SCALABLE | NK_WINDOW_BORDER | NK_WINDOW_MINIMIZABLE )) {

        if (editor->win.focus)
            *ui_focused = true;

        const char *names[] = {"Overview", "Layers", "Scripts"};
        const int name_count = 3;
        
        nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
        nk_style_push_float(ctx, &ctx->style.button.rounding, 0);
        nk_layout_row_begin(ctx, NK_STATIC, 30, name_count);

        for (int i = 0; i < name_count; ++i) {
            Vector2 size = MeasureTextEx(get_nk_font(), names[i], 16, 16 / 10.0f);
            size.x += 16;
            float text_width = size.x;

            float widget_width = text_width + name_count * ctx->style.button.padding.x;
            nk_layout_row_push(ctx, widget_width);
                if (editor->current_tab == i) {
                    struct nk_style_item button_color = ctx->style.button.normal;
                    ctx->style.button.normal = ctx->style.button.active;
                    editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;
                    ctx->style.button.normal = button_color;
                } else
                    editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;

        }

        nk_style_pop_float(ctx);

        struct nk_rect bounds = nk_window_get_content_region(ctx);

        nk_layout_row_dynamic(ctx, bounds.h - 50, 1);
        if (nk_group_begin(ctx, "Notebook", 0)) {
            nk_style_pop_vec2(ctx);

            switch (editor->current_tab) {
            case OVERVIEW:
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_label(ctx, "Model Information: ", NK_TEXT_LEFT);
                break;
            case LAYERS:
                layer_manager_draw_ui(&editor->layer_manager, ctx);
                break;
            case SCRIPTS:
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_label(ctx, "Comming Soon :3", NK_TEXT_LEFT);
                break;
            }

            nk_group_end(ctx);
        }
    } else
        editor->win.show = true; /* override hiding behavior */

    if (editor->win.state != HIDE)
        window_end(&editor->win);
}

void editor_draw_stream(struct editor *editor, struct nk_context *ctx,
    bool *ui_focused)
{
    if (editor->win.ctx == NULL) {
        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 45.0f;
        float h = height / 100.0f * 85.0f;
        float x = width - w - 40;
        float y = 60;

        editor->win.geometry = nk_rect(x, y, w, h);
        editor->win.show = true;
        window_init(&editor->win, ctx, "Editor");
    }

    if (window_begin(&editor->win, NK_WINDOW_TITLE | NK_WINDOW_MOVABLE |
        NK_WINDOW_SCALABLE | NK_WINDOW_BORDER | NK_WINDOW_MINIMIZABLE )) {

        if (editor->win.focus)
            *ui_focused = true;

        const char *names[] = {"Overview", "Microphone", "Scene"};
        const int name_count = 3;
        
        nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
        nk_style_push_float(ctx, &ctx->style.button.rounding, 0);
        nk_layout_row_begin(ctx, NK_STATIC, 30, name_count);

        for (int i = 0; i < name_count; ++i) {
            Vector2 size = MeasureTextEx(get_nk_font(), names[i], 16, 16 / 10.0f);
            size.x += 16;
            float text_width = size.x;

            float widget_width = text_width + name_count * ctx->style.button.padding.x;
            nk_layout_row_push(ctx, widget_width);
                if (editor->current_tab == i) {
                    struct nk_style_item button_color = ctx->style.button.normal;
                    ctx->style.button.normal = ctx->style.button.active;
                    editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;
                    ctx->style.button.normal = button_color;
                } else
                    editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;

        }

        nk_style_pop_float(ctx);
        struct nk_rect bounds = nk_window_get_content_region(ctx);

        nk_layout_row_dynamic(ctx, bounds.h - 50, 1);
        if (nk_group_begin(ctx, "Notebook", 0)) {
            nk_style_pop_vec2(ctx);

            switch (editor->current_tab) {
            case OVERVIEW:
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_label(ctx, "Model Information: ", NK_TEXT_LEFT);
                break;
            case MICROPHONE:
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_label(ctx, "Microphone Volume: ", NK_TEXT_LEFT);
                size_t volume = atomic_load(&editor->mic->volume);
                volume = Lerp(volume, editor->previous_volume, 0.75);

                int percentage = (volume * 100) / 200;

                if (percentage > editor->microphone_trigger)
                    nk_style_push_color(ctx, &ctx->style.progress.cursor_normal.data.color, nk_rgb(0xFF, 0, 0));

                nk_progress(ctx, &volume, 200, false);

                if (percentage > editor->microphone_trigger)
                    nk_style_pop_color(ctx);

                nk_label(ctx, "Microphone Sensitivity: ", NK_TEXT_LEFT);
                int multiplier = atomic_load(&editor->mic->multiplier);
                nk_slider_int(ctx, 0, &multiplier, 25000, 100);
                atomic_store(&editor->mic->multiplier, multiplier);

                nk_label(ctx, "Microphone Trigger: ", NK_TEXT_LEFT);
                nk_progress(ctx, &editor->microphone_trigger, 100, true);

                editor->previous_volume = volume;
                break;
            case SCENE:
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_label(ctx, "Scene background: ", NK_TEXT_LEFT);
                nk_layout_row_dynamic(ctx, 256, 1);
                struct nk_colorf color = ColorToNuklearF(
                    editor->background_color);

                color = nk_color_picker(ctx, color, NK_RGB);
                nk_layout_row_dynamic(ctx, 30, 1);
                nk_edit_string(ctx, NK_EDIT_FIELD, editor->bg_color_in,
                    &editor->bg_color_len, 7, nk_filter_hex);

                editor->background_color = ColorFromNuklearF(color);

                if (editor->bg_color_len == 6) {
                    editor->bg_color_in[6] = 0;
                    hex_str_to_color(editor->bg_color_in,
                        &editor->background_color);
                }
                break;
            }

            nk_group_end(ctx);
        }
    } else
        editor->win.show = true; /* override hiding behavior */

    if (editor->win.state != HIDE)
        window_end(&editor->win);
}

void editor_apply_mask(struct editor *editor)
{
    size_t volume = atomic_load(&editor->mic->volume);
    volume = Lerp(volume, editor->previous_volume, 0.75);

    int percentage = (volume * 100) / 200;

    if (percentage > editor->microphone_trigger) {
        editor->layer_manager.mask &= ~QUIET;
        if (!editor->talk_timer_running) {
            editor->layer_manager.mask |= TALK;
            un_timer *timer = un_timer_new(ctx.loop);
            un_timer_set_data(timer, editor);
            int delay = editor->timer_ttl / 2;
            un_timer_start(timer, delay, delay, update_talk_mask);
            editor->talk_timer_running = true;
        }

        if (!editor->pause_timer_running) {
            editor->layer_manager.mask |= PAUSE;
            un_timer *timer = un_timer_new(ctx.loop);
            un_timer_set_data(timer, editor);
            int delay = editor->timer_ttl;
            un_timer_start(timer, delay, delay, update_pause_mask);
            editor->pause_timer_running = true;
        }
    }
}

char *editor_tomlify(struct editor *editor)
{
    int sensitivity = atomic_load(&editor->mic->multiplier);
    const char *fmt = "[model]\n"
                      "layer_count = %ld\n"
                      "[microphone]\n"
                      "trigger = %ld\n"
                      "sensitivity = %d\n"
                      "[scene]\n"
                      "bg_color = 0x%06X\n";
    int color = 0;
    color |= editor->background_color.r << 16;
    color |= editor->background_color.g << 8;
    color |= editor->background_color.b;

    int len = snprintf(NULL, 0, fmt, editor->layer_manager.layer_count,
        editor->microphone_trigger, sensitivity, color);

    char *buffer = calloc(1, len + 1);
    snprintf(buffer, len + 1, fmt, editor->layer_manager.layer_count,
        editor->microphone_trigger, sensitivity, color);

    for (int i = 0; i < editor->layer_manager.layer_count; i++) {
        fmt = "\n[[layer]]\n"
              "name = \"%s\"\n"
              "index = %d\n"
              "is_animated = %s\n";
        struct model_layer *layer = editor->layer_manager.layers[i];
        int add_length = snprintf(NULL, 0, fmt, layer->name.buffer, i + 1,
            (layer->frames_count > 0) ? "true" : "false");
        buffer = realloc(buffer, len + add_length + 1);

        snprintf(buffer + len, add_length + 1, fmt, layer->name.buffer, i + 1,
            (layer->frames_count > 0) ? "true" : "false");
        len += add_length;
    }

    return buffer;
}

static enum un_action update_talk_mask(un_timer *timer)
{
    struct editor *ed = un_timer_get_data(timer);
    un_timer_set_repeat(timer, ed->timer_ttl / 2);

    int percentage = (ed->previous_volume * 100) / 200;
    if (percentage > ed->microphone_trigger)
        return REARM;

    ed->talk_timer_running = false;
    ed->layer_manager.mask &= ~TALK;

    return DISARM;
}

static enum un_action update_pause_mask(un_timer *timer)
{
    struct editor *ed = un_timer_get_data(timer);
    un_timer_set_repeat(timer, ed->timer_ttl);

    int percentage = (ed->previous_volume * 100) / 200;
    if (percentage > ed->microphone_trigger)
        return REARM;

    ed->pause_timer_running = false;
    ed->layer_manager.mask |= QUIET;
    ed->layer_manager.mask &= ~PAUSE;
    ed->layer_manager.mask &= ~TALK;

    return DISARM;
}

static int hex_char_to_num(char c)
{
    c = toupper(c);

    if (c >= '0' && c <= '9')
        return c - '0';
    else if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;

    return -1;
}

static void hex_str_to_color(const char *str, Color *color)
{
    color->r = hex_char_to_num(str[0]);
    color->r = (color->r << 4) + hex_char_to_num(str[1]);
    color->g = hex_char_to_num(str[2]);
    color->g = (color->g << 4) + hex_char_to_num(str[3]);
    color->b = hex_char_to_num(str[4]);
    color->b = (color->b << 4) + hex_char_to_num(str[5]);
}
