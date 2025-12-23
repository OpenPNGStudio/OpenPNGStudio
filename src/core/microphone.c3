/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::microphone;

import std::atomic::types;
import openpngstudio::core::mask;
import std::math @public;
import unuv;
import std::io;

struct Microphone {
    Atomic{usz} volume;
    Atomic{int} multiplier;

    /* Private State */
    usz previous_volume, trigger;
    bool talk_timer, pause_timer;
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
    self.talk_timer = false;
    self.pause_timer = false;
    mic_setup(self);
}

fn void Microphone.free(&self) => mic_free();

fn void Microphone.update(&self, unuv::UnLoop *loop)
{
    usz volume = self.volume.load();
    volume = (usz) math::lerp(volume, (float) self.previous_volume, 0.75f);

    int percentage = ((int) volume * 100) / 200;
    Mask mask = mask::get();

    if (percentage > self.trigger) {
        mask &= ~mask::QUIET;
        if (!self.talk_timer) {
            mask |= mask::TALK;
            unuv::UnTimer *timer = unuv::timer_new(loop);
            unuv::timer_set_data(timer, self);
            int delay = DEFAULT_TIMER_TTL / 2;
            unuv::timer_start(timer, delay, delay, &update_talk);
            self.talk_timer = true;
        }

        if (!self.pause_timer) {
            mask |= mask::PAUSE;
            unuv::UnTimer *timer = unuv::timer_new(loop);
            unuv::timer_set_data(timer, self);
            int delay = DEFAULT_TIMER_TTL;
            unuv::timer_start(timer, delay, delay, &update_pause);
            self.pause_timer = true;
        }
    }

    mask::set(mask);
}

fn unuv::UnAction update_talk(unuv::UnTimer *timer) @local
{
    Microphone *self = unuv::timer_get_data(timer);
    unuv::timer_set_repeat(timer, DEFAULT_TIMER_TTL / 2);

    int percentage = (int) (self.previous_volume * 100) / 200;
    if (percentage > self.trigger) return unuv::REARM;

    self.talk_timer = false;
    Mask mask = mask::get();
    mask &= ~mask::TALK;
    mask::set(mask);

    return unuv::DISARM;
}

fn unuv::UnAction update_pause(unuv::UnTimer *timer) @local
{
    Microphone *self = unuv::timer_get_data(timer);
    unuv::timer_set_repeat(timer, DEFAULT_TIMER_TTL);

    int percentage = (int) (self.previous_volume * 100) / 200;
    if (percentage > self.trigger) return unuv::REARM;

    self.pause_timer = false;
    Mask mask = mask::get();
    mask |= mask::QUIET;
    mask &= ~mask::PAUSE;
    mask &= ~mask::TALK;
    mask::set(mask);

    return unuv::DISARM;
}
