/* SPDX-License-Identifier: GPL-3.0-or-later */
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
    defaults(l);

    return l;
}

fn void StaticLayer.draw(&self, rl::Vector2 anchor) @dynamic =>
    draw(self, anchor);

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

fn Properties *StaticLayer.get_properties(&self) @dynamic => &self.props;
fn State *StaticLayer.get_state(&self) @dynamic => &self.state;

fn Properties StaticLayer.animate(&self) @dynamic
{
    if (self.state.animation) {
        if (self.state.animation.is_done() &&
            !self.state.animation.can_play()) return self.props;
        return self.state.animation.animate(&self.props);
    }

    return self.props;
}

fn void StaticLayer.free(&self) @dynamic
{
    if (self.state.active) return;

    mem::free(self);
}
