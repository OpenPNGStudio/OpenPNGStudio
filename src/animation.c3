/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import openpngstudio::core::mask;
import std::collections::list;
import openpngstudio::layer;
import std::io;
import nk;

/* Constants */
const CChar*[] ANIMATIONS = {"None", "Spinner", "Shake", "Fade"};

interface Animation {
    fn void update(ulong now);
    fn void animate(Origin *origin);
    fn BasicAnimation *get_base();
    fn void config(nk::Context *ctx);
    fn void reset();
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

fn void BasicAnimation.stop(&self, Animation a)
{
    if (!self.running) return;

    self.start_time = 0;
    self.running = false;
    a.reset();
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
        if (!b.enabled) {
            b.stop(a);
            continue;
        }

        if (mask::cmp(m, b.mask)) {
            b.start(now);
            a.update(now);
        } else {
            b.stop(a);
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

    int selected_animation;
    int selected_easing;
    CollapseStates custom_cfg_state;
}

fn void AnimationEntry.config(&self, nk::Context *ctx)
{
    float win_width = nk::window_get_width(ctx);
    float min_width = max(win_width * 0.49f, 250.0f);
    int current, old;

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Animation: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Animation", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::Rect b = nk::widget_bounds(ctx);

        old = self.selected_animation;
        current = nk::combo(ctx, ANIMATIONS.ptr, ANIMATIONS.len, old, 30,
            nk::vec2(b.w, 160));
        self.selected_animation = current;
        nk::group_end(ctx);
    }

    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();

    /* animation not set yet */
    if (self.a == null) {
        if (old == current) return;

        switch (current) {
        case 0:
            return;
        case 1:
            Spinner *spin = malloc(Spinner.sizeof);
            spin.init(360, 2500);
            self.a = spin;
            app_ctx.model.engine.add(spin);
        }
    } else {
        switch (current) {
        case 0:
            app_ctx.model.engine.del(self.a);
            self.a = null;
            return;
        }
    }
}
