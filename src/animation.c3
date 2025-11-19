/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import openpngstudio::layer;
import std::time;
import nk;

ulong id @local = 0;

enum StateBool : const char {
    SET_FALSE = (StateBool) false,
    SET_TRUE = (StateBool) true,
    GET,
}

interface Animation {
    fn ulong get_id();
    fn void tick(Time delta);
    fn bool is_done(StateBool toggle = GET);
    fn bool can_play(StateBool toggle = GET);
    fn void reset(Time now);
    fn Properties animate(Properties *props);
    fn void config(nk::Context *ctx);
    fn int easing(bool set = false, int easing_id = 0);
}

fn ulong new_id()
{
    defer id++;
    return id;
}
