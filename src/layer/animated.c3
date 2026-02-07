/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::animated;

import std::core::string;
import std::core::mem;
import std::io;
import nk;
import unuv;
import raylib5::rl;
import openpngstudio::animation;
import openpngstudio::image;
import openpngstudio::layer::static_layer;

struct AnimatedLayer (Layer) {
    StaticLayer base;
    isz frame_idx, prev_idx;
    int[] delays;
}

fn void AnimatedLayer.init(&self, Allocator alloc, ZString name,
    image::Image *img, int[] delays)
{
    self.base.init(alloc, name, img);
    self.delays = delays;
    self.frame_idx = 0;
    self.prev_idx = -1;
}

fn void AnimatedLayer.free(&self) @dynamic => self.base.free();

fn bool AnimatedLayer.draw(&self, Origin origin) @dynamic
{
    rl::Image *img = &self.base.image.image;
    if (self.prev_idx != self.frame_idx) {
        usz off = (usz) img.width * img.height * 4 *
            self.frame_idx;
        
        rl::updateTexture(self.base.image.texture, img.data + off);
        self.prev_idx = self.frame_idx;
    }

    if (!static_layer::draw(&self.base, origin)) {
        self.prev_idx = -1;
        self.frame_idx = 0;
        return false;
    }

    return true;
}

fn layer::Command AnimatedLayer.layer_entry(&self, nk::Context *ctx) @dynamic
    => static_layer::entry(&self.base, ctx);

fn void AnimatedLayer.config(&self, nk::Context *ctx) @dynamic =>
    static_layer::config(&self.base, ctx);

fn bool AnimatedLayer.can_cleanup(&self) @dynamic => self.base.can_cleanup();

// fn void start_animating(AnimatedLayer *layer, unuv::UnLoop *loop)
//     @export("layer_animated_start")
// {
//     unuv::UnTimer *timer = unuv::timer_new(loop);
//     unuv::timer_set_data(timer, layer);
//     uint delay = layer.props.frame_delays[0];
//     unuv::timer_start(timer, delay, delay, &update_animation);
// }
//
//
// fn unuv::UnAction update_animation(unuv::UnTimer *timer) @local
// {
//     AnimatedLayer *layer = unuv::timer_get_data(timer);
//
//     layer.props.previous_frame_index = layer.props.current_frame_index;
//     unuv::timer_set_repeat(timer, layer.props.frame_delays[layer.props.current_frame_index]);
//     layer.props.current_frame_index = (layer.props.current_frame_index + 1) %
//         layer.props.number_of_frames;
//
//     if (layer.layer.state.prepare_for_deletion) {
//         if (!layer.layer.state.active) {
//             static_layer::cleanup(&layer.layer);
//             return unuv::DISARM;
//         }
//     }
//
//     return unuv::REARM;
// }
