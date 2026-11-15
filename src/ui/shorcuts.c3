/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import std::math;

import nk;

typedef Shortcuts (wm::Window) = int;

fn void Shortcuts.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 200);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Switch between Edit and Stream modes", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Tab", &&3, 4, &nk::filter_default);

    nk::label(ctx, "Toggle the visibility of the UI while not actively hovering it", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Spacebar", &&8, 9, &nk::filter_default);

    nk::label(ctx, "Open console containing logs", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Shift + ~", &&9, 10, &nk::filter_default);

    nk::label(ctx, "Round up value when changing it by holding", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Shift", &&5, 6, &nk::filter_default);

    nk::label(ctx, "Change zoom level", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Mouse Wheel Scroll", &&18, 19, &nk::filter_default);

    nk::label(ctx, "Move around", nk::TEXT_ALIGN_LEFT);
    nk::edit_string(ctx, nk::EDIT_READ_ONLY, "Mouse Wheel Button", &&18, 19, &nk::filter_default);
}
