/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::shake;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import std::math, std::math::random;
import std::io;
import raylib5::rl;
import nk;

struct Shake (Animation) {
    BasicAnimation base;
    DefaultRandom rng;
    Vector2 current, offset;
    int start, end;
    ulong length;
}

fn void Shake.init(&self, ulong length)
{
    self.base.init();
    random::seed(&self.rng, time::now());
    self.start = -50;
    self.end = 50;
    self.current = { 0, 0 };
    self.offset = self.gen_pos();
    self.length = length;
}

fn void Shake.reset(&self) @dynamic => self.current = { 0, 0 };

fn void Shake.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.offset = self.gen_pos();
        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }

    if (per <= 0.5f) {
        float t = per / 0.5f;
        float e = easings::ease(0, t, 0.0f, 1.0f, 1.0f);
        self.current.x = self.offset.x * e;
        self.current.y = self.offset.y * e;
    } else {
        float t = (per - 0.5f) / 0.5f;
        float e = easings::ease(0, t, 0.0f, 1.0f, 1.0f);
        float returnFactor = 1.0f - e;
        self.current.x = self.offset.x * returnFactor;
        self.current.y = self.offset.y * returnFactor;
    }
}

fn void Shake.animate(&self, Origin *origin) @dynamic
{
    origin.position.x += self.current.x;
    origin.position.y += self.current.y;
}

fn BasicAnimation *Shake.get_base(&self) @dynamic => &self.base;

fn void Shake.config(&self, nk::Context *ctx) @dynamic
{
    // float win_width = nk::window_get_width(ctx);
    // float min_width = math::max(win_width * 0.49f, 250.0f);
    //
    // nk::layout_row_template_begin(ctx, 35);
    // nk::layout_row_template_push_dynamic(ctx);
    // nk::layout_row_template_push_variable(ctx, min_width);
    // nk::layout_row_template_end(ctx);
    //
    // int old_range = self.start_range;
    //
    // nk::label(ctx, "Start Range:", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Start Range", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     nk::property_int(ctx, "Start: ", int.min, &self.start_range, 0, 1, 1);
    //
    //     if (old_range != self.start_range) {
    //         self.is_done(SET_TRUE);
    //     }
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "End Range:", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "End Range", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     old_range = self.end_range;
    //     nk::property_int(ctx, "End: ", 0, &self.end_range, int.max, 1, 1);
    //
    //     if (old_range != self.end_range) {
    //         self.is_done(SET_TRUE);
    //     }
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "Length:", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Length", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     int delay = self.delay / 1000;
    //     nk::property_int(ctx, "Time (ms): ", 10, &delay, int.max, 1, 1);
    //
    //     if ((delay * 1000) != self.delay) {
    //         self.is_done(SET_TRUE);
    //         self.delay = delay * 1000;
    //     }
    //     nk::group_end(ctx);
    // }
}

fn Vector2 Shake.gen_pos(&self) @local
{
    float cx = (float) ((double) self.start + self.end) / 2.0;
    float radius = math::abs((float) self.end - self.start) / 2.0;
    float theta = (double) random::next_float(&self.rng) * 2 * math::PI;
    float r = radius * math::sqrt(random::next_float(&self.rng));
    float x = cx + r * math::cos(theta);
    float y = r * math::sin(theta);
    return { x, y };
}
