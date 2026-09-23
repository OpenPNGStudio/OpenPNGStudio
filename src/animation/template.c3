/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation::template;

import std::time;
import std::core::mem;
import std::math;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import openpngstudio::util;
import std::io;
import opng;
import nk;

struct Template (Animation) {
    BasicAnimation base;
    ulong length @AnimData;
}

fn void Template.init(&self, ulong length = 250)
{
    self.base.init();
    self.length = length;
}

fn void Template.reset(&self) @dynamic {}

fn void Template.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }
}

fn void Template.animate(&self, Origin *origin) @dynamic {}
fn BasicAnimation *Template.get_base(&self) @dynamic => &self.base;

fn void Template.config(&self, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Length:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Length", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        int delay = (int) self.length;
        nk::property_int(ctx, "#Time (ms): ", 10, &delay, int.max, 1, 1);

        if (delay != self.length) {
            self.length = delay;
            self.reset();
        }
        nk::group_end(ctx);
    }
}