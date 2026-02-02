/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import openpngstudio::core::mask;
import std::collections::list;
import openpngstudio::layer;
import nk;

interface Animation {
    fn void update(ulong now);
    fn void animate(Origin *origin);
    fn BasicAnimation *get_base();
    fn void config(nk::Context *ctx);
}

struct BasicAnimation {
    Mask mask;
    ulong start_time;
    int easing;
    bitstruct : char {
        bool running;
        bool repeat;
        bool enabled;
        bool run_once; /* set to false when not running and mask doesn't match */
    }
}

fn void BasicAnimation.init(&self)
{
    self.mask = mask::DEFAULT;
    self.start_time = 0;
    self.easing = 0;
    self.running = false;
    self.repeat = true;
    self.run_once = false;
    self.enabled = false;
}

fn void BasicAnimation.enable(&self, bool state) @inline => 
    self.enabled = state;

fn void BasicAnimation.start(&self, ulong now)
{
    if (self.running) return;

    self.start_time = now;
    self.running = true;
    if (!self.repeat) self.run_once = true;
}

fn void BasicAnimation.stop(&self)
{
    if (!self.running) return;
    self.start_time = 0;
    self.running = false;
}

struct Engine {
    List{Animation} animations;
}

fn void Engine.init(&self, Allocator alloc) => self.animations.init(alloc);

fn void Engine.tick(&self, ulong now)
{
    Mask m = mask::get();

    foreach (a : self.animations) {
        BasicAnimation *b = a.get_base();
        if (!b.enabled) continue;

        if (mask::cmp(m, b.mask)) {
            b.start(now);
            a.update(now);
        } else {
            b.stop();
        }
    }
}

fn void Engine.add(&self, Animation anim) => self.animations.push(anim);
fn void Engine.del(&self, Animation anim)
{
    self.animations.remove_item(anim);
    free(anim);
}

struct AnimationEntry {
    Animation a;
    char[2] input_buffer;
    int input_length;
}

fn void AnimationEntry.config(&self, nk::Context *ctx)
{
    
}
