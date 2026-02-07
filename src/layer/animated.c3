/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::animated;

import std::core::string;
import std::core::mem;
import std::io;
import nk;
import ev;
import raylib5::rl;
import openpngstudio::animation;
import openpngstudio::image;
import openpngstudio::layer::static_layer;

struct AnimatedLayer (Layer) {
    StaticLayer base;
    isz frame_idx, prev_idx;
    int[] delays;

    Timer{AnimatedLayer*} timer;
    bitstruct : char {
        bool animating;
        bool stop;
    }
}

fn void AnimatedLayer.init(&self, Allocator alloc, ZString name,
    image::Image *img, int[] delays)
{
    self.base.init(alloc, name, img);
    self.delays = delays;
    self.frame_idx = 0;
    self.prev_idx = -1;
    self.animating = true;
    self.stop = false;

    ev::Loop *loop = &openpngstudio::get_ctx().loop;

    self.timer.init(loop, delays[0], self, fn (timer) {
        AnimatedLayer *layer = timer.ctx;
        layer.prev_idx = layer.frame_idx;
        timer.set_timeout(layer.delays[layer.frame_idx]);
        layer.frame_idx = (layer.frame_idx + 1) % layer.delays.len;

        if (layer.stop) {
            layer.animating = false;
            return DISARM;
        }

        return REARM;
    });

    loop.add(&self.timer);
}

fn void AnimatedLayer.free(&self) @dynamic
{
    free(self.delays.ptr);
    self.base.free();
}

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
{
    layer::Command cmd = static_layer::entry(&self.base, ctx);
    if (cmd.type != NONE) {
        cmd.layer = self;
    }

    return cmd;
}

fn void AnimatedLayer.config(&self, nk::Context *ctx) @dynamic =>
    static_layer::config(&self.base, ctx);

fn bool AnimatedLayer.can_cleanup(&self) @dynamic
{
    self.stop = true;
    return self.base.can_cleanup() || self.animating;
}
