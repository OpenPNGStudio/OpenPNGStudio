/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::spinner;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import std::io;
import nk;

struct Spinner (Animation) {
    Time start;
    float rotation, end_rotation;
    ulong id;
    int delay, easing_id;
    bool done, play;
}

fn Animation new(float rotation, ulong delay)
{
    Spinner *s = malloc(Spinner.sizeof);
    s.id = animation::new_id();
    s.end_rotation = rotation;
    s.delay = (int) time::ms(delay);
    s.done = true;
    s.easing_id = 0;
    return s;
}

fn ulong Spinner.get_id(&self) @dynamic => self.id;

fn void Spinner.tick(&self, Time delta) @dynamic
{
    float percentage = ((float) (delta - self.start)) / (float) self.delay; 
    if (percentage > 1.0) {
        percentage = 1.0;
        self.done = true;
    }

    self.rotation = easings::ease(self.easing_id, percentage, 0, self.end_rotation, 1.0);
}

fn bool Spinner.is_done(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.done;

    self.done = (bool) toggle;
    return self.done;
}

fn bool Spinner.can_play(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.play;

    self.play = (bool) toggle;
    return self.play;
}

fn void Spinner.reset(&self, Time now) @dynamic
{
    self.start = now;
    self.done = false;
}

fn Properties Spinner.animate(&self, Properties *props) @dynamic
{
    Properties copy = *props;
    copy.rotation += self.rotation;
    return copy;
}

fn void Spinner.config(&self, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    float old_rotation = self.end_rotation;

    nk::label(ctx, "Rotation: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Rotation", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::property_float(ctx, "Rotation: ", 0, &self.end_rotation, 360f, 0.1f, 0.2f);

        if (old_rotation != self.end_rotation) {
            self.is_done(SET_TRUE);
        }
        nk::group_end(ctx);
    }

    nk::label(ctx, "Length:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Rotation", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        int delay = self.delay / 1000;
        nk::property_int(ctx, "Time (ms): ", 10, &delay, int.max, 1, 1);

        if ((delay * 1000) != self.delay) {
            self.is_done(SET_TRUE);
            self.delay = delay * 1000;
        }
        nk::group_end(ctx);
    }
}

fn int Spinner.easing(&self, bool set, int easing_id) @dynamic
{
    if (set) self.easing_id = easing_id;

    return self.easing_id;
}
