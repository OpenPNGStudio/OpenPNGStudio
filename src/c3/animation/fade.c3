/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::fade;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import std::io, std::math;
import nk;

enum FadeMode {
    IN,
    OUT
}

struct Fade (Animation) {
    Time start;
    FadeMode mode;
    float opacity, target_opacity_in, target_opacity_out;
    ulong id;
    int delay, easing_id;
    bool done, finished, repeat, play;
}

fn Animation new(ulong delay)
{
    Fade *s = malloc(Fade.sizeof);
    s.id = animation::new_id();
    s.mode = OUT;
    s.target_opacity_in = 1.0f;
    s.target_opacity_out = 0.0f;
    s.delay = (int) time::ms(delay);
    s.done = true;
    s.finished = false;
    s.repeat = false;
    s.easing_id = 0;
    return s;
}

fn ulong Fade.get_id(&self) @dynamic => self.id;

fn void Fade.tick(&self, Time delta) @dynamic
{
    float percentage = ((float) (delta - self.start)) / (float) self.delay; 
    if (percentage > 1.0) {
        percentage = 1.0;
        self.done = true;
        self.finished = true;
    }

    if (self.finished && !self.repeat) return;

    switch (self.mode) {
    case IN:
        self.opacity = easings::ease(self.easing_id, percentage, 0, self.target_opacity_in, 1.0);
    case OUT:
        self.opacity = 1.0f - easings::ease(self.easing_id, percentage, self.target_opacity_out, 1.0f, 1.0);
    }
}

fn bool Fade.is_done(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.done;

    self.done = (bool) toggle;
    return self.done;
}

fn bool Fade.can_play(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.play;

    self.play = (bool) toggle;
    return self.play;
}

fn void Fade.reset(&self, Time now) @dynamic
{
    self.start = now;
    self.done = false;
}

fn Properties Fade.animate(&self, StaticLayer *layer) @dynamic
{
    Properties copy = layer.props;
    copy.tint.a = (char) $$round(self.opacity * 255);
    return copy;
}

fn void Fade.config(&self, nk::Context *ctx) @dynamic
{
    // nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    // nk::layout_row_push(ctx, 0.75f);
    // nk::label(ctx, "Rotation:", nk::TEXT_LEFT);
    // nk::layout_row_push(ctx, 0.24f);
    //
    // float old_rotation = self.end_rotation;
    // nk::property_float(ctx, "Rotation: ", 0, &self.end_rotation, 360f, 0.1f, 0.2f);
    //
    // if (old_rotation != self.end_rotation) {
    //     self.is_done(SET_TRUE);
    // }
    //
    // nk::layout_row_end(ctx);
    //
    // nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    // nk::layout_row_push(ctx, 0.75f);
    // nk::label(ctx, "Length:", nk::TEXT_LEFT);
    // nk::layout_row_push(ctx, 0.24f);
    //
    // int delay = self.delay / 1000;
    // nk::property_int(ctx, "Time (ms): ", 10, &delay, int.max, 1, 1);
    //
    // if ((delay * 1000) != self.delay) {
    //     self.is_done(SET_TRUE);
    //     self.delay = delay * 1000;
    // }
    //
    // nk::layout_row_end(ctx);
}

fn int Fade.easing(&self, bool set, int easing_id) @dynamic
{
    if (set) self.easing_id = easing_id;

    return self.easing_id;
}

