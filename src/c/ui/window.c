/* SPDX-License-Identifier: GPL-3.0-or-later */

#include <ui/window.h>

void window_init(struct window *win, struct nk_context *ctx,
    const char *title)
{
    win->ctx = ctx;
    win->title = title != 0 ? title : "Window";
}

bool window_begin(struct window *win, nk_flags flags)
{
    win->focus = false;

    if (win->geometry.x == 0 && win->geometry.y == 0 &&
        win->geometry.w == 0 && win->geometry.h == 0) {

        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 80.0f;
        float h = height / 100.0f * 80.0f;
        float x = (width - w) / 2.0f;
        float y = (height - h) / 2.0f;

        win->geometry = nk_rect(x, y, w, h);
    }

    if (win->show) {
        if (nk_begin(win->ctx, win->title, win->geometry, flags)) {
            struct nk_vec2 pos = nk_window_get_position(win->ctx);
            nk_window_set_position(win->ctx, win->title, pos);

            win->state = SHOW;
            if (nk_input_is_mouse_hovering_rect(&win->ctx->input,
                nk_window_get_bounds(win->ctx))) {
                win->focus = true;
            }

            return true;
        } else {
            struct nk_vec2 wprop = nk_window_get_position(win->ctx);
            win->geometry.x = wprop.x;
            win->geometry.y = wprop.y;

            wprop = nk_window_get_size(win->ctx);
            win->geometry.w = wprop.x;
            win->geometry.h = wprop.y;

            win->show = false;
            win->state = CLOSE;
            win->focus = false;
            return false;
        }
    }
    win->state = HIDE;
    return false;
}

void window_end(struct window *win)
{
    nk_end(win->ctx);
}
