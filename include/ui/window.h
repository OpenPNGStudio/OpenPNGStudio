#pragma once

#include <raylib-nuklear.h>
#include <stdbool.h>

enum window_state {
    HIDE,
    SHOW,
    CLOSE,
};

struct window {
    struct nk_rect geometry;
    const char *title;
    struct nk_context *ctx;
    enum window_state state;
    bool focus;
    bool show;
};

void window_init(struct window *win, struct nk_context *ctx,
    const char *title);
bool window_begin(struct window *win, nk_flags flags);
void window_end(struct window *win);
