/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation::bounce;

import std::time;
import std::core::mem;
import std::math;
import openpngstudio::layer;
import openpngstudio::animation::easings;
import openpngstudio::util;
import std::io;
import opng;
import nk;

struct Bounce (Animation) {
    BasicAnimation base;
    float amount, target_amount;
    ulong length;
}

const DATA_SIZE = float.sizeof + ulong.sizeof;

fn void Bounce.init(&self, float amount = 25, ulong length = 250)
{
    self.base.init();
    self.target_amount = amount;
    self.length = length;
}

fn void Bounce.reset(&self) @dynamic => self.amount = 0;

fn void Bounce.update(&self, ulong now) @dynamic
{
    ulong old = now;
    now -= self.base.start_time;

    float per = (float) now / self.length;
    if (per > 1.0) {
        per = 1.0;

        self.base.repeat ? self.base.start(old) : self.base.stop(self);
    }

    float y = (float) math::abs(math::sin(per * math::PI));

    self.amount = easings::ease(self.base.easing, y, 0.0, self.target_amount, 1.0);
}

fn void Bounce.animate(&self, Origin *origin) @dynamic => origin.position.y -= self.amount;

fn BasicAnimation *Bounce.get_base(&self) @dynamic => &self.base;

fn void? Bounce.pack(&self, Writer *wr, uint layer_id) @dynamic
{

}

fn void Bounce.unpack(&self, char[] data) @dynamic
{

}

fn void Bounce.config(&self, nk::Context *ctx) @dynamic
{
}