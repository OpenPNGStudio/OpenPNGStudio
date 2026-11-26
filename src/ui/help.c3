/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import std::math, std::io;

import nk;

typedef Help (wm::Window) = int;

fn void Help.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float height = nk::window_get_content_region(ctx).h;
    nk::layout_row_dynamic(ctx, 22, 1);
    nk::label(ctx, "A list of user manuals and troubleshooting guides", nk::TEXT_ALIGN_LEFT);

    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

    nk::layout_row_dynamic(ctx, height - 40, 1);
    nk::label_wrap(ctx, "As of now it's completely empty, this is due to the release candidate and not enough documentation"
        " being written yet, this will change as assets are made and documentation with manuals are written. This release "
        "candidate took longer than expected to be released, just wanted to get something out. Thank you for understanding!");
}