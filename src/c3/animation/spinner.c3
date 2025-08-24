/*
 * This file is part of OpenPNGStudio. 
 * Copyright (C) 2024-2025 LowByteFox
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
module openpngstudio::animation::spinner;

import std::time;
import std::core::mem;
import std::math::easing;
import openpngstudio::layer;
import std::io;

struct Spinner (Animation) {
    float rotation, end_rotation;
    ulong delay;
    Time start;
    bool done, play;
}

fn Animation new(float rotation, ulong delay) @export("spinner_new")
{
    Spinner *s = malloc(Spinner.sizeof);
    s.end_rotation = rotation;
    s.delay = (ulong) time::ms(delay);
    s.done = true;
    return s;
}

fn void Spinner.tick(&self, Time delta) @dynamic
{
    float percentage = ((float) (delta - self.start)) / (float) self.delay; 
    if (percentage > 1.0) {
        percentage = 1.0;
        self.done = true;
    }

    self.rotation = easing::expo_inout(percentage, 0, self.end_rotation, 1.0);
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

fn Properties Spinner.animate(&self, StaticLayer *layer) @dynamic
{
    Properties copy = layer.props;
    copy.rotation += self.rotation;
    return copy;
}
