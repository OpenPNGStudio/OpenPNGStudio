/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import std::core::string;
import std::core::mem;
import raylib5::rl;
import openpngstudio::animation;
import openpngstudio::core::mask;
import openpngstudio::ui::line_edit;
import nk;

interface Layer {
    fn void draw(rl::Vector2 anchor);
    fn void configure(nk::Context *ctx);
    fn String stringify();
    fn Properties *get_properties();
    fn State *get_state();

    fn Properties animate();
    fn void free();
}

struct Properties {
    rl::Image image;
    rl::Texture2D texture;

    rl::Vector2 offset;
    float rotation;
    rl::Color tint;

    LineEdit name;

    bool has_toggle;
    bool is_animated;
}

struct State {
    Animation animation;
    Mask mask;
    Mask anim_mask;

    int time_to_live;
    bool active;
    bool is_toggled;
    bool prepare_for_deletion;
    bool is_toggle_timer_ticking;

    int selected_animation;
    char[2] input_key_buffer;
    int input_key_length;

    char[2] anim_input_key_buffer;
    int anim_input_key_length;
}

fn char *stringify(StaticLayer *layer) @export("layer_stringify")
{
    char *res;
    @pool() {
        Layer l;
        if (layer.props.is_animated) {
            l = (AnimatedLayer*) layer;
        } else {
            l = layer;
        }

        String str = l.stringify();
        usz len = str.len;
        res = malloc(len + 1);
        mem::copy(res, str.ptr, len);
        res[len] = 0;
    };
    return res;
}
