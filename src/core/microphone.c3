/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::microphone;

import std::atomic::types;
import openpngstudio::core::mask;
import std::math @public;
import ev;
import std::io;

alias MicTimer = Timer{Microphone*};

struct Microphone {
    Atomic{usz} volume;
    Atomic{int} multiplier;
    MicTimer pause_timer, talk_timer;

    /* Private State */
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

fn void Microphone.init(&self)
{
    self.multiplier.store(DEFAULT_MULTIPLIER);
    self.trigger = DEFAULT_TRIGGER;
    self.talk_timer_running = false;
    self.pause_timer_running = false;
    mic_setup(self);
}

fn void Microphone.free(&self) => mic_free();

fn void Microphone.update(&self, ev::Loop *loop)
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
