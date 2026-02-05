/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::spinner;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import std::io;
import nk;

struct Spinner (Animation) {
    BasicAnimation base;
    float rotation, target_rotation;
    ulong length;
}

fn void Spinner.init(&self, float rotation, ulong length)
{
    self.base.init();
    self.target_rotation = rotation;
    self.length = length;
}

fn void Spinner.reset(&self) @dynamic => self.rotation = 0;

fn void Spinner.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.base.running = false;
        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }
    
    self.rotation = easings::ease(self.base.easing, per, 0.0,
        self.target_rotation, 1.0);
}

fn void Spinner.animate(&self, Origin *origin) @dynamic => 
    origin.rotation += self.rotation;

fn BasicAnimation *Spinner.get_base(&self) @dynamic => &self.base;

fn void Spinner.config(&self, nk::Context *ctx) @dynamic
{
    // float win_width = nk::window_get_width(ctx);
    // float min_width = max(win_width * 0.49f, 250.0f);
    //
    // nk::layout_row_template_begin(ctx, 35);
    // nk::layout_row_template_push_dynamic(ctx);
    // nk::layout_row_template_push_variable(ctx, min_width);
    // nk::layout_row_template_end(ctx);
    //
    // float old_rotation = self.end_rotation;
    //
    // nk::label(ctx, "Rotation: ", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Rotation", nk::WINDOW_NO_SCROLLBAR)) {
    //     nk::layout_row_dynamic(ctx, 30, 1);
    //     nk::property_float(ctx, "Rotation: ", 0, &self.end_rotation, 360f, 0.1f, 0.2f);
    //
    //     if (old_rotation != self.end_rotation) {
    //         self.is_done(SET_TRUE);
    //     }
    //     nk::group_end(ctx);
    // }
    //
    // nk::label(ctx, "Length:", nk::TEXT_LEFT);
    // if (nk::group_begin(ctx, "Rotation", nk::WINDOW_NO_SCROLLBAR)) {
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
