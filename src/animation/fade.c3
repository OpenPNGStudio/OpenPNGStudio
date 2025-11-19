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
    Time start;
    FadeMode mode;
    char opacity, target_opacity_in, target_opacity_out;
    ulong id;
    int delay, easing_id;
    bool done, finished, repeat, play;
}

fn Animation new(ulong delay)
{
    Fade *s = malloc(Fade.sizeof);
    s.id = animation::new_id();
    s.mode = OUT;
    s.opacity = 255;
    s.target_opacity_in = 255;
    s.target_opacity_out = 0;
    s.delay = (int) time::ms(delay);
    s.done = true;
    s.finished = false;
    s.repeat = true;
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
    }

    if (self.finished && !self.repeat) return;
    if (percentage == 1.0) self.finished = true;

    switch (self.mode) {
    case IN:
        self.opacity = (char) $$round(easings::ease(self.easing_id, percentage, 0, self.target_opacity_in, 1.0));
    case OUT:
        self.opacity = (char) $$round(255 - easings::ease(self.easing_id, percentage, 0, 255.0f - self.target_opacity_out, 1.0));
    }
}

fn bool Fade.is_done(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.done;

    switch (self.mode) {
    case IN:
        self.opacity = 255 - self.target_opacity_in;
    case OUT:
        self.opacity = 255 - self.target_opacity_out;
    }

    self.done = (bool) toggle;
    return self.done;
}

fn bool Fade.can_play(&self, StateBool toggle) @dynamic
{
    if (toggle == GET) return self.play;

    self.play = (bool) toggle;
    if (!self.play && self.finished) self.finished = false;
    return self.play;
}

fn void Fade.reset(&self, Time now) @dynamic
{
    self.start = now;
    self.done = false;
}

fn Properties Fade.animate(&self, Properties *props) @dynamic
{
    Properties copy = *props;
    copy.tint.a = self.opacity;
    return copy;
}

const CChar*[] MODES = {"Fade In", "Fade Out"};

fn void Fade.config(&self, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);
    
    float old_f = self.target_opacity_in / 255.0f;
    float current_f = old_f;
    char current;

    nk::label(ctx, "Fade In Limit: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Fade In Limit", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::property_float(ctx, "in limit: ", 0.0f, &current_f, 1.0f, 0.01f, 0.01f);
        current = (char) $$round(current_f * 255.0f);

        if (current != self.target_opacity_in) {
            self.is_done(SET_TRUE);
            self.target_opacity_in = current;
        }

        nk::group_end(ctx);
    }

    nk::label(ctx, "Fade Out Limit: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Fade Out Limit", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        old_f = self.target_opacity_out / 255.0f;
        current_f = old_f;
        nk::property_float(ctx, "out limit: ", 0.0f, &current_f, 1.0f, 0.01f, 0.01f);
        current = (char) $$round(current_f * 255.0f);

        if (current != self.target_opacity_out) {
            self.is_done(SET_TRUE);
            self.target_opacity_out = current;
        }

        nk::group_end(ctx);
    }

    nk::label(ctx, "Mode: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Mode", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::Rect b = nk::widget_bounds(ctx);

        int old = (int) self.mode;
        self.mode = (FadeMode) nk::combo(ctx, MODES.ptr, MODES.len, old, 30,
            nk::vec2(b.w, 200));
        nk::group_end(ctx);
    }

    nk::label(ctx, "Repeat: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Repeat", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        nk::checkbox_label(ctx, "Toggle repeat", &self.repeat);
        nk::group_end(ctx);
    }


    nk::label(ctx, "Length: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Length", nk::WINDOW_NO_SCROLLBAR)) {
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

fn int Fade.easing(&self, bool set, int easing_id) @dynamic
{
    if (set) self.easing_id = easing_id;

    return self.easing_id;
}

