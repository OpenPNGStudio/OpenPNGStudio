/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::ui;
import openpngstudio::ui::window_v2;
import nk;

enum FileLoadState {
    NOTHING,
    SELECTING_IMAGE,
    SELECTING_SCRIPT,
    WRITING_MODEL,
    LOADING_MODEL,
}

/* NOT C context !! */
struct Context {
    FileDialog file_dialog;
    WindowManager wm;

    ui::Panel panel;
    nk::Context *nk_ctx;

    /* State */
    FileLoadState loading_state;
    int width, height;

    ZString model_output;
    bool override_save;
}

fn void set_nk_context(Context *ctx, nk::Context *nk_ctx) @export("c3_nk")
{
    ctx.nk_ctx = nk_ctx;
}
