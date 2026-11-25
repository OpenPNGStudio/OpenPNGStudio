/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import std::math, std::io;

import nk;

typedef About (wm::Window) = int;

extern fn void set_nuklear_scaling(nk::Context* ctx, float scaling) @cname("SetNuklearScaling");
extern fn float get_nuklear_scaling(nk::Context* ctx) @cname("GetNuklearScaling");

fn void About.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float height = nk::window_get_content_region(ctx).h;

    nk::layout_row_template_begin(ctx, 128);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 128);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_end(ctx);

    nk::spacer(ctx);
    nk::image(ctx, icons::get(LOGO));
    nk::spacer(ctx);

    nk::layout_row_dynamic(ctx, 32, 1);
    {
        nk::style_push_float(ctx, &ctx.style.font.height, 32);
        defer nk::style_pop_float(ctx);

        nk::label(ctx, "OpenPNGStudio", nk::TEXT_ALIGN_CENTERED);
    }

    nk::layout_row_dynamic(ctx, 30, 1);
    nk::label(ctx, "Create & stream PNGTuber models", nk::TEXT_ALIGN_CENTERED);

    nk::layout_row_dynamic(ctx, height - 250, 1);
    nk::spacer(ctx);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_static(ctx, 128);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 128);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 128);
    nk::layout_row_template_end(ctx);

    nk::button_label(ctx, "Website");
    nk::spacer(ctx);
    nk::button_label(ctx, "License");
    nk::spacer(ctx);
    nk::button_label(ctx, "Third-Party");
}