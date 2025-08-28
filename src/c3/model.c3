/* SPDX-License-Identifier: GPL-3.0-or-later */
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
