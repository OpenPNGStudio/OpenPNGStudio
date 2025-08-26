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
module openpngstudio::layer::animated;

import std::core::string;
import std::core::mem;
import raylib5::rl;
import openpngstudio::animation;
import openpngstudio::layer::static_layer;

struct AnimatedLayerProperties {
    char *gif_file_content;
    usz gif_file_size;
    uint *frame_delays;
    usz number_of_frames;
    usz current_frame_index;
    usz previous_frame_index;
}

struct AnimatedLayer (Layer) {
    StaticLayer layer;
    AnimatedLayerProperties props;
    Animation anim;
}

fn AnimatedLayer *animated_layer_new(rl::Image image, usz number_of_frames,
    char *buffer, usz size, int *delays) @export("layer_new_animated")
{
    AnimatedLayer *l = mem::new(AnimatedLayer);
    l.layer.props.image = image;
    static_layer::static_layer_defaults(&l.layer);
    l.layer.props.is_animated = true;

    l.props.number_of_frames = number_of_frames;
    l.props.gif_file_content = buffer;
    l.props.gif_file_size = size;
    l.props.frame_delays = (uint*) delays;

    return l;
}

fn void AnimatedLayer.draw(&self, rl::Vector2 anchor) @dynamic
{
}

fn String AnimatedLayer.stringify(&self) @dynamic
{
    char *res;
    uint[] delays = self.props.frame_delays[:self.props.number_of_frames];

    String str = self.layer.stringify();
    str = str.tconcat(string::tformat(`[animation]
frame_count = %d
delays = [ `, self.props.number_of_frames));

    uint[] without_last = delays[:delays.len - 1];

    foreach (uint delay : without_last) {
        str = str.tconcat(string::tformat("%d, ", delay));
    }

    str = str.tconcat(string::tformat("%d ]\n", delays[delays.len - 1]));
    
    return str;
}

fn Properties AnimatedLayer.animate(&self) @dynamic
{
    if (self.anim) {
        if (self.anim.is_done() && !self.anim.can_play()) return self.layer.props;
        return self.anim.animate(&self.layer);
    }

    return self.layer.props;
}
