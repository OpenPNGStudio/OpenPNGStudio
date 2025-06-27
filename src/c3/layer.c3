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
module openpngstudio::layer;

import std::core::string;
import std::core::mem;

struct Layer {
    double x, y, rotation;
    ulong mask;
    int time_to_live;
    bool has_toggle;
}

struct AnimatedLayer {
    Layer layer;
    ulong number_of_frames;
    uint *frame_delays;
}

fn String stringify_base(Layer layer)
{
    return string::tformat(`[layer]
offset.x = %f
offset.y = %f
rotation = %f
mask = %d
ttl = %d
has_toggle = %s
`, layer.x, layer.y, layer.rotation, layer.mask, layer.time_to_live, layer.has_toggle ? "true" : "false");
}

fn char *stringify(Layer layer) @export("layer_stringify_static")
{
    char *res;
    @pool() {
        String str = stringify_base(layer);
        usz len = str.len;
        res = malloc(len + 1);
        mem::copy(res, str.ptr, len);
        res[len] = 0;
    };
    return res;
}

fn char *stringify_anim(AnimatedLayer layer) @export("layer_stringify_anim")
{
    char *res;
    uint[] delays = layer.frame_delays[:layer.number_of_frames];

    @pool() {
        String str = stringify_base(layer.layer);
        str = str.tconcat(string::tformat(`[animation]
frame_count = %d
delays = [ `, layer.number_of_frames));

        uint[] without_last = delays[:delays.len - 1];

        foreach (uint delay : without_last) {
            str = str.tconcat(string::tformat("%d, ", delay));
        }

        str = str.tconcat(string::tformat("%d ]\n", delays[delays.len - 1]));
        usz len = str.len;
        res = malloc(len + 1);
        mem::copy(res, str.ptr, len);
        res[len] = 0;
    };

    return res;
}
