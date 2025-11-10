/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::animated;

import std::core::string;
import std::core::mem;
import std::io;
import nk;
import unuv;
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
}

fn AnimatedLayer *animated_layer_new(rl::Image image, usz number_of_frames,
    char *buffer, usz size, int *delays) @export("layer_new_animated")
{
    AnimatedLayer *l = mem::new(AnimatedLayer);
    l.layer.props.image = image;
    static_layer::defaults(&l.layer);
    l.layer.props.is_animated = true;

    l.props.number_of_frames = number_of_frames;
    l.props.gif_file_content = buffer;
    l.props.gif_file_size = size;
    l.props.frame_delays = (uint*) delays;

    return l;
}

fn void AnimatedLayer.draw(&self, rl::Vector2 anchor) @dynamic
{
    rl::Image *img = &self.layer.props.image;
    if (self.props.previous_frame_index != self.props.current_frame_index) {
        usz off = (usz) img.width * img.height * 4 *
            self.props.current_frame_index;
        
        rl::updateTexture(self.layer.props.texture, img.data + off);
        self.props.previous_frame_index = self.props.current_frame_index;
    }

    if (!static_layer::draw(&self.layer, anchor)) {
        self.props.previous_frame_index = 0;
        self.props.current_frame_index = 0;
    }
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

fn Properties *AnimatedLayer.get_properties(&self) @dynamic => &self.layer.props;
fn State *AnimatedLayer.get_state(&self) @dynamic => &self.layer.state;

fn Properties AnimatedLayer.animate(&self) @dynamic
{
    Animation anim = self.layer.state.animation;
    if (anim) {
        if (anim.is_done() && !anim.can_play()) return self.layer.props;
        return anim.animate(&self.layer.props);
    }

    return self.layer.props;
}

fn void AnimatedLayer.free(&self) @dynamic {}

fn void AnimatedLayer.configure(&self, nk::Context *ctx) @dynamic
{
    static_layer::configure(&self.layer, ctx);
}

<*
@require s.props.is_animated == true : "layer is not animated"
*>
fn AnimatedLayer *get_animated(StaticLayer *s)
    @export("layer_get_animated") => (void*) s;


fn void start_animating(AnimatedLayer *layer, unuv::UnLoop *loop)
    @export("layer_animated_start")
{
    unuv::UnTimer *timer = unuv::timer_new(loop);
    unuv::timer_set_data(timer, layer);
    uint delay = layer.props.frame_delays[0];
    unuv::timer_start(timer, delay, delay, &update_animation);
}


fn unuv::UnAction update_animation(unuv::UnTimer *timer) @local
{
    AnimatedLayer *layer = unuv::timer_get_data(timer);

    layer.props.previous_frame_index = layer.props.current_frame_index;
    unuv::timer_set_repeat(timer, layer.props.frame_delays[layer.props.current_frame_index]);
    layer.props.current_frame_index = (layer.props.current_frame_index + 1) %
        layer.props.number_of_frames;

    if (layer.layer.state.prepare_for_deletion) {
        if (!layer.layer.state.active) {
            static_layer::cleanup(&layer.layer);
            return unuv::DISARM;
        }
    }

    return unuv::REARM;
}
