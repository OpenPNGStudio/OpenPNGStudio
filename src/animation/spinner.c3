/* spdx-license-identifier: gpl-3.0-or-later */
module openpngstudio::animation::spinner;

import std::time;
import std::core::mem;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import openpngstudio::util;
import std::io;
import opng;
import nk;

struct Spinner (Animation) {
    BasicAnimation base;
    float rotation, target_rotation;
    ulong length;
}

const DATA_SIZE = float.sizeof + ulong.sizeof;

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

        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }
    
    self.rotation = easings::ease(self.base.easing, per, 0.0,
        self.target_rotation, 1.0);
}

fn void Spinner.animate(&self, Origin *origin) @dynamic => 
    origin.rotation += self.rotation;

fn BasicAnimation *Spinner.get_base(&self) @dynamic => &self.base;

fn void? Spinner.pack(&self, Writer *wr, uint layer_id) @dynamic
{
    SQLAnimation base = animation::prepare_data(self);
    
    base.type = 1;
    base.layer_id = layer_id;
    base.data = malloc(DATA_SIZE);
    base.data_size = DATA_SIZE;   

    char[] buf = base.data[:DATA_SIZE];
    util::@copy_into(buf, self.target_rotation);
    util::@copy_into(buf[float.sizeof..], self.length);

    wr.add_animation(base)!;
}

fn void Spinner.unpack(&self, char[] data) @dynamic
{
    mem::copy(&self.target_rotation, data, float.sizeof);
    mem::copy(&self.length, data[float.sizeof..], ulong.sizeof);
    
    self.reset();
}

fn void Spinner.config(&self, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    float old_rotation = self.target_rotation;

    nk::label(ctx, "Rotation: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Rotation", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::property_float(ctx, "#Rotation: ", 0, &self.target_rotation, 360f, 0.1f, 0.2f);

        if (old_rotation != self.target_rotation) self.reset();
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
