/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import nk;

struct ColorPicker {
    nk::Colorf color;
}

import std::io;

fn void ColorPicker.ui(&self, nk::Context *ctx)
{
    if (nk::group_begin(ctx, "Color Picker", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 255, 1);
        self.color = nk::color_picker(ctx, self.color, nk::RGBA);
        nk::group_end(ctx);
    }
}
