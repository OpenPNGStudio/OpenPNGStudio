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
    DefaultRandom rng;
    Vector2 current, offset;
    Time start;
    ulong id;
    int start_range, end_range, delay, easing_id;
    bool done, play;
}

fn Animation new(int start_range = -5, int end_range = 5, ulong delay = 100)
{
    Shake *s = malloc(Shake.sizeof);
    s.current = { 0, 0 };
    s.start_range = start_range;
    s.end_range = end_range;
    random::seed(&s.rng, time::now());
    s.offset = s.gen_pos();
    
    s.id = animation::new_id();
    s.delay = (int) time::ms(delay);
    s.done = true;
    s.easing_id = 0;
    return s;
}

fn ulong Shake.get_id(&self) @dynamic => self.id;

fn void Shake.tick(&self, Time delta) @dynamic
{
    float percentage = ((float) (delta - self.start)) / (float) self.delay;
    if (percentage > 1.0f) {
        percentage = 1.0f;
        self.done = true;
    }

    if (percentage <= 0.5f) {
        float t = percentage / 0.5f;
        float e = easings::ease(self.easing_id, t, 0.0f, 1.0f, 1.0f);
        self.current.x = self.offset.x * e;
        self.current.y = self.offset.y * e;
    } else {
        float t = (percentage - 0.5f) / 0.5f;
        float e = easings::ease(self.easing_id, t, 0.0f, 1.0f, 1.0f);
        float returnFactor = 1.0f - e;
        self.current.x = self.offset.x * returnFactor;
        self.current.y = self.offset.y * returnFactor;
    }
}

fn bool Shake.is_done(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.done;

    self.done = (bool) toggle;
    return self.done;
}

fn bool Shake.can_play(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.play;

    self.play = (bool) toggle;
    return self.play;
}

fn void Shake.reset(&self, Time now) @dynamic
{
    self.start = now;
    self.offset = self.gen_pos();
    self.done = false;
}

fn Properties Shake.animate(&self, StaticLayer *layer) @dynamic
{
    Properties copy = layer.props;
    copy.offset.x += self.current.x;
    copy.offset.y += self.current.y;
    return copy;
}

fn void Shake.config(&self, nk::Context *ctx) @dynamic
{
    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "Start range:", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    int old_range = self.start_range;
    nk::property_int(ctx, "Start: ", int.min, &self.start_range, 0, 1, 1);

    if (old_range != self.start_range) {
        self.is_done(SET_TRUE);
    }
    nk::layout_row_end(ctx);

    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "End range:", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    old_range = self.end_range;
    nk::property_int(ctx, "End: ", 0, &self.end_range, int.max, 1, 1);

    if (old_range != self.end_range) {
        self.is_done(SET_TRUE);
    }
    nk::layout_row_end(ctx);

    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "Length:", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    int delay = self.delay / 1000;
    nk::property_int(ctx, "Time (ms): ", 10, &delay, int.max, 1, 1);

    if ((delay * 1000) != self.delay) {
        self.is_done(SET_TRUE);
        self.delay = delay * 1000;
    }

    nk::layout_row_end(ctx);
}

fn Vector2 Shake.gen_pos(&self) @local
{
    float cx = (float) ((double) self.start_range + self.end_range) / 2.0;
    float radius = math::abs((float) self.end_range - self.start_range) / 2.0;
    float theta = (double) random::next_float(&self.rng) * 2 * math::PI;
    float r = radius * math::sqrt(random::next_float(&self.rng));
    float x = cx + r * math::cos(theta);
    float y = r * math::sin(theta);
    return { x, y };
}

// fn void Spinner.config(&self, nk::Context *ctx) @dynamic
// {
//
//     nk::layout_row_end(ctx);
//
// }

fn int Shake.easing(&self, bool set, int easing_id) @dynamic
{
    if (set) self.easing_id = easing_id;

    return self.easing_id;
}
