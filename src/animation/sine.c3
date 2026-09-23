/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation::sine;

import std::time;
import openpngstudio::ui;
import std::core::mem;
import std::math;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import openpngstudio::util;
import std::io;
import opng;
import nk;

enum SineDir : const int {
    VERTICAL,
    HORIZONTAL
}

struct Sine (Animation) {
    BasicAnimation base;
    float amount;
    float target_amount @AnimData;
    ulong length @AnimData;
    SineDir dir @AnimData;
}

fn void Sine.init(&self, float amount = 50, SineDir dir = HORIZONTAL, ulong length = 500)
{
    self.base.init();
    self.target_amount = amount;
    self.length = length;
}

fn void Sine.reset(&self) @dynamic => self.amount = 0;

fn void Sine.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }

    float adj = (float) math::sin(per * 2.0 * math::PI);

    self.amount = easings::ease(self.base.easing, adj, 0.0, self.target_amount, 1.0);
}

fn void Sine.animate(&self, Origin *origin) @dynamic
{
    if (self.dir == VERTICAL) {
        origin.position.y -= self.amount;
    } else {
        origin.position.x += self.amount;
    }
}

fn BasicAnimation *Sine.get_base(&self) @dynamic => &self.base;

const CChar*[] MODES = {"Vertical", "Horizontal"};

fn void Sine.config(&self, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Direction: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "#Direction", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::Rect b = nk::widget_bounds(ctx);

        int old = (int) self.dir;
        self.dir = (SineDir) ui::combo(ctx, MODES.ptr, MODES.len, old, 30, nk::vec2(b.w, 200));
        nk::group_end(ctx);
    }

    float old_amount = self.target_amount;

    nk::label(ctx, "Amount: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Amount", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::property_float(ctx, "#Amount: ", 0, &self.target_amount, float.max, 0.1f, 0.2f);

        if (old_amount != self.target_amount) self.reset();
        nk::group_end(ctx);
    }

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