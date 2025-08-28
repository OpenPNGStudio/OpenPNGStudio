/* SPDX-License-Identifier: GPL-3.0-or-later */

#include "raylib.h"
#include <core/nk.h>
#include <stddef.h>
#include <raylib-nuklear.h>
#include <ui/messagebox.h>
#include <stdio.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))

struct messagebox messagebox_info(const char *title, const char *body)
{
    struct messagebox box = {0};
    box.title = title;
    box.body = body;
    box.type = MESSAGEBOX_INFO;
    box.res = -1;
    box.userdata = NULL;

    return box;
}

struct messagebox messagebox_warn(const char *title, const char *body)
{
    struct messagebox box = messagebox_info(title, body);
    box.type = MESSAGEBOX_WARN;

    return box;
}

struct messagebox messagebox_error(const char *title, const char *body)
{
    struct messagebox box = messagebox_info(title, body);
    box.type = MESSAGEBOX_ERROR;

    return box;
}

struct messagebox messagebox_custom(const char *title,
    int (*fn)(struct nk_context *ctx, struct messagebox *box),
    void *userdata)
{
    struct messagebox box = messagebox_info(title, NULL);
    box.type = MESSAGEBOX_CUSTOM;
    box.custom = fn;
    box.userdata = userdata;

    return box;
}

void messagebox_run(struct messagebox *messagebox, struct nk_context *ctx)
{
    /* TODO: Icons */
    if (messagebox->res == -1) {
        struct nk_rect bounds = nk_window_get_content_region(ctx);
        int extra_flags = 0;

        Vector2 size = MeasureTextEx(get_nk_font(), messagebox->body, 16, 16 / 10.0f);
        size.x += 16;
        size.y += 16 + 50 + 30; /* height + spacing + text height */

        float w = size.x;
        float h = size.y;

        w = MAX(w, 200);

        if (messagebox->type == MESSAGEBOX_CUSTOM) {
            w = bounds.w / 100.0f * 80.0f;
            h = bounds.h / 100.0f * 80.0f;
        }

        float x = (bounds.w - w) / 2.0f;
        float y = (bounds.h - h) / 2.0f;

        if (messagebox->type != MESSAGEBOX_CUSTOM)
            extra_flags |= NK_WINDOW_NO_SCROLLBAR;

        if (nk_popup_begin(ctx, NK_POPUP_STATIC, messagebox->title,
            NK_WINDOW_TITLE | NK_WINDOW_CLOSABLE | NK_WINDOW_BORDER | extra_flags,
            nk_rect(x, y, w, h))) {

            struct nk_color text_color = {0};

            switch (messagebox->type) {
            case MESSAGEBOX_INFO:
                text_color = ctx->style.text.color;
                break;
            case MESSAGEBOX_WARN:
                text_color = nk_rgb(0xFF, 0xFF, 0x33);
                break;
            case MESSAGEBOX_ERROR:
                text_color = nk_rgb(0xFF, 0x33, 0x33);
                break;
            case MESSAGEBOX_CUSTOM:
                messagebox->res = messagebox->custom(ctx, messagebox);
                if (messagebox->res != -1)
                    nk_popup_close(ctx);

                nk_popup_end(ctx);
                return;
            }

            bounds = nk_window_get_content_region(ctx);
            if (messagebox->type != MESSAGEBOX_CUSTOM) {
                nk_layout_row_dynamic(ctx, bounds.h - 50.0f, 1);
                nk_label_colored_wrap(ctx, messagebox->body, text_color);

                nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);

                nk_layout_row_push(ctx, 0.1f);
                nk_spacing(ctx, 1);
                nk_layout_row_push(ctx, 0.35f);
                if (nk_button_label(ctx, "Ok")) {
                    messagebox->res = 0;
                    nk_popup_close(ctx);
                }

                nk_layout_row_push(ctx, 0.1f);
                nk_spacing(ctx, 1);
                nk_layout_row_push(ctx, 0.35f);
                if (nk_button_label(ctx, "Cancel")) {
                    messagebox->res = 1;
                    nk_popup_close(ctx);
                }
                nk_layout_row_push(ctx, 0.1f);
                nk_spacing(ctx, 1);
                nk_layout_row_end(ctx);
            }

            nk_popup_end(ctx);
        } else {
            messagebox->res = 0;
        }
    }
}
