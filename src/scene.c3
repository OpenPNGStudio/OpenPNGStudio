/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::ui;
import openpngstudio::ui::wm;
import nk;
import raylib5::rl;

struct Scene (wm::Window) {
    rl::Color background;
    ColorPicker picker;
}

extern fn nk::Colorf color_to_nk_f(rl::Color color) @extern("ColorToNuklearF");
extern fn rl::Color color_from_nk_f(nk::Colorf color) 
    @extern("ColorFromNuklearF");

fn void Scene.init(&self)
{
    self.background = { 0x88, 0x88, 0x88, 0xFF };
    self.picker.color = color_to_nk_f(self.background);
}

import std::io;

fn void Scene.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    nk::layout_row_template_begin(ctx, 256);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 256);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_end(ctx);

    nk::spacer(ctx);
    self.picker.ui(ctx);
    nk::spacer(ctx);

    self.background = color_from_nk_f(self.picker.color);
}
