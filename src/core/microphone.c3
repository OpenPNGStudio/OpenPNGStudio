/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::microphone;

import std::atomic::types;
import openpngstudio::ui::wm;
import openpngstudio::core::mask;
import std::math @public;
import ev;
import std::io;
import std::core::mem;
import nk;

alias MicTimer = Timer{Microphone*};

struct Device @local {
    ZString name;
    void *data; /* ma_audio opaque */
}

struct Microphone (wm::Window) {
    Atomic{usz} volume;
    Atomic{int} multiplier;

    /* Private State */
    Device[] devices;
    ZString[] device_names;
    MicTimer pause_timer, talk_timer;
    int current_device;
    
    usz previous_volume, trigger;
    bitstruct : char {
        bool talk_timer_running;
        bool pause_timer_running;
    }
}

const DEFAULT_MULTIPLIER = 2500;
const DEFAULT_TRIGGER = 40;
const DEFAULT_TIMER_TTL = 2000;

extern fn void mic_setup(Microphone *self);
extern fn void mic_free();
extern fn void switch_device(Microphone *self, Device target);

extern fn Device *mic_enumerate(int *len);

fn void Microphone.init(&self)
{
    self.multiplier.store(DEFAULT_MULTIPLIER);
    self.trigger = DEFAULT_TRIGGER;
    self.talk_timer_running = false;
    self.pause_timer_running = false;
    mic_setup(self);

    int len;
    Device *devices = mic_enumerate(&len);

    if (devices != null) {
        self.devices = devices[:len];
        self.device_names = mem::new_array(ZString, self.devices.len);

        foreach (i, d : self.devices) {
            self.device_names[i] = d.name;
        }
    }
}

fn void Microphone.free(&self) => mic_free();

fn void Microphone.internal_update(&self, ev::Loop *loop)
{
    usz volume = self.volume.load();
    volume = (usz) math::lerp(volume, (float) self.previous_volume, 0.75f);

    int percentage = ((int) volume * 100) / 200;
    Mask mask = mask::get();

    if (percentage > self.trigger) {
        mask &= ~mask::QUIET;
        if (!self.talk_timer_running) {
            mask |= mask::TALK;
            int delay = DEFAULT_TIMER_TTL / 2;

            self.talk_timer.init(loop, delay, self, fn (timer) {
                Microphone *self = timer.ctx;

                int percentage = (int) (self.previous_volume * 100) / 200;
                if (percentage > self.trigger) return REARM;

                self.talk_timer_running = false;

                Mask mask = mask::get();
                mask &= ~mask::TALK;
                mask::set(mask);

                return DISARM;
            });

            loop.add(&self.talk_timer);
            self.talk_timer_running = true;
        }

        if (!self.pause_timer_running) {
            mask |= mask::PAUSE;
            int delay = DEFAULT_TIMER_TTL;

            self.pause_timer.init(loop, delay, self, fn (timer) {
                Microphone *self = timer.ctx;

                int percentage = (int) (self.previous_volume * 100) / 200;
                if (percentage > self.trigger) return REARM;

                self.pause_timer_running = false;
                Mask mask = mask::get();
                mask |= mask::QUIET;
                mask &= ~mask::PAUSE;
                mask &= ~mask::TALK;
                mask::set(mask);

                return DISARM;
            });
            
            loop.add(&self.pause_timer);
            self.pause_timer_running = true;
        }
    }

    mask::set(mask);
}

fn void Microphone.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Input Device:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Microphones",nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        
        nk::Rect b = nk::widget_bounds(ctx);
        int old = self.current_device;

        int current = ui::combo(ctx, (CChar**) self.device_names.ptr, 
            self.device_names.len, old, 30, nk::vec2(b.w, 200));

        if (old != current) {
            self.current_device = current;
            switch_device(self, self.devices[current]);
        }
        nk::group_end(ctx);
    }

    nk::label(ctx, "Microphone Volume:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Microphone Volume",nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        usz volume = self.volume.load();
        volume = (usz) math::lerp((double) volume, (double) self.previous_volume,
            0.75);
        self.previous_volume = volume;

        int percentage = ((int) volume * 100) / 200;
        if (percentage > self.trigger) {
            nk::style_push_color(ctx,
                &ctx.style.progress.cursor_normal.data.color, 
                nk::rgb(0xFF, 0, 0));
        }
    
        nk::progress(ctx, (uint*) &volume, 200, false);
    
        if (percentage > self.trigger) {
            nk::style_pop_color(ctx);
        }
        
        nk::group_end(ctx);
    }

    nk::label(ctx, "Microphone Trigger:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Microphone Trigger",
        nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        nk::progress(ctx, (uint*) &self.trigger, 100, true);
        
        nk::group_end(ctx);
    }

    nk::label(ctx, "Microphone Sensitivity:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Microphone Sensitivity",
        nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        int multiplier = self.multiplier.load();
        nk::slider_int(ctx, 0, &multiplier, 25000, 100);
        self.multiplier.store(multiplier);
        
        nk::group_end(ctx);
    }
}
