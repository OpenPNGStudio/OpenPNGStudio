/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::fade;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import std::io, std::math;
import nk;

enum FadeMode : const int {
    IN,
    OUT
}

struct Fade (Animation) {
    BasicAnimation base;
    FadeMode mode;
    char opacity_change;
    ulong length;
    bool finished;
}

fn void Fade.init(&self, ulong length)
{
    self.base.init();
    self.mode = OUT;
    self.opacity_change = 0;
    self.length = length;
    self.finished = false;
}

fn void Fade.reset(&self) @dynamic
{
    self.opacity_change = 0;
    self.finished = false;
}

fn void Fade.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.finished = true;
        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }

    if (self.finished) return;

    self.opacity_change = (char) $$round(easings::ease(self.base.easing, per,
        0.0, 255.0, 1.0));
}

fn void Fade.animate(&self, Origin *origin) @dynamic =>
    origin.tint.a = self.opacity_change;

fn BasicAnimation *Fade.get_base(&self) @dynamic => &self.base;

const CChar*[] MODES = {"Fade In", "Fade Out"};

fn void Fade.config(&self, nk::Context *ctx) @dynamic
{
    // float win_width = nk::window_get_width(ctx);
    // float min_width = max(win_width * 0.49f, 250.0f);
    //
    // nk::layout_row_template_begin(ctx, 35);
    // nk::layout_row_template_push_dynamic(ctx);
    // nk::layout_row_template_push_variable(ctx, min_width);
    // nk::layout_row_template_end(ctx);
    //
    // float old_f = self.target_opacity_in / 255.0f;
    // float current_f = old_f;
    // char current;
    //
    // nk::label(ctx, "Fade In Limit: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Fade In Limit", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     nk::property_float(ctx, "in limit: ", 0.0f, &current_f, 1.0f, 0.01f, 0.01f);
    //     current = (char) $$round(current_f * 255.0f);
    //
    //     if (current != self.target_opacity_in) {
    //         self.is_done(SET_TRUE);
    //         self.target_opacity_in = current;
    //     }
    //
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "Fade Out Limit: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Fade Out Limit", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     old_f = self.target_opacity_out / 255.0f;
    //     current_f = old_f;
    //     nk::property_float(ctx, "out limit: ", 0.0f, &current_f, 1.0f, 0.01f, 0.01f);
    //     current = (char) $$round(current_f * 255.0f);
    //
    //     if (current != self.target_opacity_out) {
    //         self.is_done(SET_TRUE);
    //         self.target_opacity_out = current;
    //     }
    //
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "Mode: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Mode", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     nk::Rect b = nk::widget_bounds(ctx);
    //
    //     int old = (int) self.mode;
    //     self.mode = (FadeMode) nk::combo(ctx, MODES.ptr, MODES.len, old, 30,
    //         nk::vec2(b.w, 200));
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "Repeat: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Repeat", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //
    //     nk::checkbox_label(ctx, "Toggle repeat", &self.repeat);
    //     nk::group_end(ctx);
    // }
    //
    //
    // nk::label(ctx, "Length: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Length", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //
    //     int delay = self.delay / 1000;
    //     nk::property_int(ctx, "Time (ms): ", 10, &delay, int.max, 1, 1);
    //
    //     if ((delay * 1000) != self.delay) {
    //         self.is_done(SET_TRUE);
    //         self.delay = delay * 1000;
    //     }
    //
    //     nk::group_end(ctx);
    // }
}
