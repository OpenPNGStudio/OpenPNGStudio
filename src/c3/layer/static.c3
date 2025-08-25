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
module openpngstudio::layer::static_layer;

import std::core::mem;
import openpngstudio::layer;
import openpngstudio::core::mask;
import raylib5::rl;

struct StaticLayer (Layer) {
    Properties props;
    State state;

    char[2] input_key_buffer;
    int input_key_len;

    char[2] anim_input_key_buffer;
    int anim_input_key_len;
}

fn StaticLayer *new_static(rl::Image image) @export("layer_new")
{
    StaticLayer *l = mem::new(StaticLayer);
    l.props.image = image;
    static_layer_defaults(l);

    return l;
}

fn void static_layer_defaults(StaticLayer *layer)
{
    layer.props.texture = rl::loadTextureFromImage(layer.props.image);
    rl::setTextureFilter(layer.props.texture, BILINEAR);
    rl::genTextureMipmaps(&layer.props.texture);
    rl::setTextureWrap(layer.props.texture, TextureWrap.CLAMP.ordinal);

    layer.state.mask = mask::DEFAULT_LAYER_MASK;
    layer.state.anim_mask = mask::DEFAULT_LAYER_MASK;
    layer.props.rotation = 180.0f;
    layer.props.tint = rl::WHITE;
    layer.state.animation = null;
    layer.state.selected_animation = 0;
}

fn void StaticLayer.draw(&self, rl::Vector2 anchor) @dynamic
{
}

fn String StaticLayer.stringify(&self) @dynamic
{
    return string::tformat(`[layer]
offset.x = %f
offset.y = %f
rotation = %f
mask = %d
ttl = %d
has_toggle = %s
`, self.props.offset.x, self.props.offset.y, self.props.rotation,
    self.state.mask, self.state.time_to_live,
    self.props.has_toggle ? "true" : "false");
}

fn Properties StaticLayer.animate(&self) @dynamic
{
    if (self.state.animation) {
        if (self.state.animation.is_done() &&
            !self.state.animation.can_play()) return self.props;
        return self.state.animation.animate(self);
    }

    return self.props;
}
