/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::core;
import openpngstudio::ui;
import openpngstudio::ui::wm;
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
    Model model;

    ui::Panel panel;
    nk::Context *nk_ctx;

    /* State */
    FileLoadState loading_state;
    int width, height;
    Microphone microphone;

    ZString model_output;
    bool override_save;
}

fn void set_nk_context(Context *ctx, nk::Context *nk_ctx) @export("c3_nk")
{
    ctx.nk_ctx = nk_ctx;
}

fn void Context.add_layer(&self, StaticLayer *layer) @export("layer_manager_add_layer")
{
    self.model.mgr.add_layer(layer);
}

fn void Context.render(&self, void *loop) @export("layer_manager_render")
{
    self.model.mgr.render(loop);
}
