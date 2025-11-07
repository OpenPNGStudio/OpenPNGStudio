/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import nk;

enum WindowState : const CInt {
    HIDE,
    SHOW,
    CLOSE,
}

struct Window {
    nk::Rect geometry;
    char *title;
    nk::Context *ctx;
    WindowState state;
    bool focus, show;
}

extern fn void window_init(Window *win, nk::Context *ctx,
    char *title);
extern fn bool window_begin(Window *win, nk::Flags flags);
extern fn void window_end(Window *win);
