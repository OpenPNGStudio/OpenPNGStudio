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
import raylib5::rl;
import openpngstudio::animation;
import openpngstudio::core::mask;
import openpngstudio::ui::line_edit;

interface Layer {
    fn void draw(rl::Vector2 anchor);
    /* TODO: fn void configure(); */
    fn String stringify();
    fn Properties animate();
    /* TODO: fn void free(); */
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

    int time_to_live;
    bool active;
    bool is_toggled;
    bool prepare_for_deletion;
    bool is_toggle_timer_ticking;
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

fn void start_animation(StaticLayer *layer) @export("start_animation")
{
    if (layer.state.animation) layer.state.animation.can_play(TRUE);
}

fn void stop_animation(StaticLayer *layer) @export("stop_animation")
{
    if (layer.state.animation) {
        if (layer.state.animation.can_play(GET)) {
            layer.state.animation.is_done(TRUE);
        }
        layer.state.animation.can_play(FALSE);
    }
}

fn Properties updated_properties(StaticLayer *layer) @export("layer_updated_properties")
{
    Layer l;
    if (layer.props.is_animated) {
        l = (AnimatedLayer*) layer;
    } else {
        l = layer;
    }

    return l.animate();
}
