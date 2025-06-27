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
module openpngstudio::model;

import std::core::string;
import std::core::mem;

struct SerializeLayer {
    ZString name;
    uint index;
    bool is_animated;
}

struct Model {
    ulong layer_count;
    usz microphone_trigger;
    int sensitivity;
    uint color;
    SerializeLayer *layers;
}

fn char *serialize(Model model) @export("model_serialize_manifest")
{
    char *res;
    @pool() {
        String str = string::tformat(`[model]
layer_count = %d
[microphone]
trigger = %d
sensitivity = %d
[scene]
bg_color = 0x%06X`, model.layer_count, model.microphone_trigger,
    model.sensitivity, model.color);

        SerializeLayer[] layers = model.layers[:model.layer_count];

        foreach (SerializeLayer layer : layers) {
            str = str.tconcat(string::tformat(`
[[layer]]
name = "%s"
index = %d
is_animated = %s
`, layer.name, layer.index, layer.is_animated ? "true" : "false"));
        }

        usz len = str.len;
        res = malloc(len + 1);
        mem::copy(res, str.ptr, len);
        res[len] = 0;
    };
    return res;
}
