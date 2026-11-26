/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import std::math, std::io;
import std::os::process;

import nk;

typedef About (wm::Window) = int;

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

    if (nk::button_label(ctx, "Website")) open_browser("https://opng.dev");
    nk::spacer(ctx);
    if (nk::button_label(ctx, "License")) open_browser("https://opng.dev/license");
    nk::spacer(ctx);
    if (nk::button_label(ctx, "Third-Party")) open_browser("https://opng.dev/third-party");
}

extern fn void shellExecute(void *a, ZString action, ZString url, void *b, void *c, int showcmd) @if(env::WIN32) @cname("ShellExecuteA");

fn void open_browser(String url) @local => @pool()
{
    $if env::WIN32:
        shellExecute(null, "open", url.zstr_tcopy(), null, null, 1);
    $else
        (void) process::spawn({"xdg-open", url}, INHERIT_ENV);
    $endif
}
