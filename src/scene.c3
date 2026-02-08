/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::ui;
import openpngstudio::ui::wm;
import nk;
import raylib5::rl;

struct Scene (wm::Window) {
    rl::Color background;
    ColorPicker picker;

    bool toggle_transparency;
}

extern fn nk::Colorf color_to_nk_f(rl::Color color) @extern("ColorToNuklearF");
extern fn rl::Color color_from_nk_f(nk::Colorf color) 
    @extern("ColorFromNuklearF");

import libc;    

fn void Scene.init(&self)
{
    self.background = { 0x88, 0x88, 0x88, 0xFF };
    self.picker.color = color_to_nk_f(self.background);
    libc::sprintf(&self.picker.buffer, "%2x%2x%2x", self.background.r, 
        self.background.g, self.background.b);
    self.picker.buffer_len = 6;
    self.picker.res = false;
}

import std::io;

fn void Scene.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Toggle Transparency:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Toggle transparency group", 
        nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_template_begin(ctx, 30);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 75);
        nk::layout_row_template_end(ctx);

        nk::spacing(ctx, 1);
        bool has_toggle = self.toggle_transparency;
        nk::checkbox_label(ctx, "Enable", &has_toggle);

        if (has_toggle != self.toggle_transparency && has_toggle) {
            self.background = { 0, 0, 0, 0 };
        }

        self.toggle_transparency = has_toggle;

        nk::group_end(ctx);
    }

    nk::layout_row_template_begin(ctx, 256);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 256);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Background Color:", nk::TEXT_ALIGN_LEFT);
    self.picker.ui(ctx);

    if (!self.toggle_transparency) {
        self.background = color_from_nk_f(self.picker.color);
    }
}
