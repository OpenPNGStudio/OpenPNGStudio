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
module openpngstudio::animation::manager;

import openpngstudio::animation;
import openpngstudio::layer;
import std::collections::list;
import std::time, std::io;
import std::core::mem;
import openpngstudio::core::mask;
import openpngstudio::animation::spinner;
import openpngstudio::animation::shake;
import openpngstudio::animation::fade;
import openpngstudio::animation::easings;
import openpngstudio::ui::window;
import nk;

struct Manager {
    List{Animation} animations;
    Animation global_animation;
    Mask global_anim_mask;
    char[2] global_input_key_buffer;
    int global_input_key_len;
    int selected;
    window::Window cfg_win;
}

const CChar*[] ANIMATIONS = {"None", "Spinner", "Shake", "Fade"};

fn Manager *new_manager() @export("animation_manager_new")
{
    Manager *m = calloc(Manager.sizeof);
    m.animations.init(mem);
    m.global_animation = null;
    m.selected = 0;
    m.global_anim_mask = mask::DEFAULT_LAYER_MASK;

    return m;
}

fn void Manager.tick(&self) @export("animation_manager_tick")
{
    Time now = time::now();

    foreach (anim : self.animations) {
        if (!anim.can_play()) continue;
        if (anim.is_done()) anim.reset(now);

        anim.tick(now);
    }
}

fn void Manager.show(&self) @export("animation_manager_show")
{
    self.cfg_win.show = true;
}

fn void Manager.global_anim(&self, nk::Context *ctx) @export("animation_manager_global_anim")
{
    if (self.cfg_win.ctx == null) {
        window::window_init(&self.cfg_win, ctx, "Global Animation Config");
    }

    if (window::window_begin(&self.cfg_win, nk::WINDOW_TITLE | nk::WINDOW_MOVABLE |
        nk::WINDOW_SCALABLE | nk::WINDOW_BORDER | nk::WINDOW_MINIMIZABLE | 
        nk::WINDOW_CLOSABLE)) {
        nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
        nk::layout_row_push(ctx, 0.75f);
        nk::label(ctx, "Animation: ", nk::TEXT_LEFT);
        nk::layout_row_push(ctx, 0.24f);

        int old = self.selected;
        int current = nk::combo(ctx, ANIMATIONS.ptr, ANIMATIONS.len, old, 30,
            nk::vec2(200, 200));
        self.selected = current;
        if (old != current) {
            if (self.global_animation) {
                ulong id = self.global_animation.get_id();
                Animation prev = self.global_animation;
                self.global_animation = null;
                self.del_animation(id);
                free(prev);
            }
            if (current == 2) {
                self.global_animation = shake::new();
                self.animations.push(self.global_animation);
            } else if (current == 1) {
                self.global_animation = spinner::new(360, 2500);
                self.animations.push(self.global_animation);
            } else if (current == 3) {
                self.global_animation = fade::new(250);
                self.animations.push(self.global_animation);
            }
        }

        nk::layout_row_end(ctx);
        nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
        nk::layout_row_push(ctx, 0.75f);
        nk::label(ctx, "Easing: ", nk::TEXT_LEFT);
        nk::layout_row_push(ctx, 0.24f);

        old = 0;

        if (self.global_animation) {
            old = self.global_animation.easing();
        } else {
            nk::widget_disable_begin(ctx);
        }

        if (self.global_animation) {
            Animation anim = self.global_animation;
        } else {
            nk::widget_disable_begin(ctx);
        }

        current = nk::combo(ctx, easings::NAMES.ptr, easings::NAMES.len, old,
            30, nk::vec2(200, 200));

        if (self.global_animation) {
            self.global_animation.easing(true, current);
        } else {
            nk::widget_disable_end(ctx);
        }
        nk::layout_row_end(ctx);

        nk::layout_row_dynamic(ctx, 2, 1);
        nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

        mask::configure(&self.global_anim_mask, &self.global_input_key_buffer,
            &self.global_input_key_len, ctx, "Animation Mask:");

        nk::layout_row_dynamic(ctx, 2, 1);
        nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

        if (self.global_animation) {
            nk::layout_row_dynamic(ctx, 30, 2);
            nk::label(ctx, "Animation Config: ", nk::TEXT_LEFT);
            nk::label_colored(ctx, "(By updating values, you may reset the animation)",
                nk::TEXT_RIGHT, nk::rgb(0xFF,0xFF,0x33));

            self.global_animation.config(ctx);
        }
    }

    if (self.cfg_win.state != HIDE) window::window_end(&self.cfg_win);
}

fn Properties Manager.animate_global(&self, StaticLayer *layer, Properties prev) @export("animation_manager_animate_global")
{
    if (self.global_animation) {
        if (mask::cmp(mask::get(), self.global_anim_mask)) {
            self.global_animation.can_play(SET_TRUE);

            Properties old = layer.props;
            layer.props = prev;
            Properties new = self.global_animation.animate(layer);
            layer.props = old;
            return new;
        } else {
            if (self.global_animation.is_done()) {
                if (self.global_animation.can_play()) {
                    self.global_animation.is_done(SET_TRUE);
                }
                self.global_animation.can_play(SET_FALSE);
            }
        }
    }

    return prev;
}

fn void Manager.animation_selector(&self, StaticLayer *layer, nk::Context *ctx) @export("animation_manager_selector")
{
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "Animation: ", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    int old = layer.state.selected_animation;
    int current = nk::combo(ctx, ANIMATIONS.ptr, ANIMATIONS.len, old, 30, nk::vec2(200, 200)
        );
    layer.state.selected_animation = current;

    if (old != current) {
        if (layer.state.animation) {
            ulong id = layer.state.animation.get_id();
            Animation prev = layer.state.animation;
            layer.state.animation = null;
            self.del_animation(id);
            free(prev);
        }
        if (current == 2) {
            self.add_animation(layer, shake::new());
        } else if (current == 1) {
            self.add_animation(layer, spinner::new(360, 2500));
        } else if (current == 3) {
            self.add_animation(layer, fade::new(250));
        }
    }

    nk::layout_row_end(ctx);
    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "Easing: ", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    old = 0;

    if (layer.state.animation) {
        old = layer.state.animation.easing();
    } else {
        nk::widget_disable_begin(ctx);
    }

    if (layer.state.animation) {
        Animation anim = layer.state.animation;
    } else {
        nk::widget_disable_begin(ctx);
    }

    current = nk::combo(ctx, easings::NAMES.ptr, easings::NAMES.len, old,
        30, nk::vec2(200, 200));

    if (layer.state.animation) {
        layer.state.animation.easing(true, current);
    } else {
        nk::widget_disable_end(ctx);
    }
    nk::layout_row_end(ctx);

    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

    mask::configure(&layer.state.anim_mask, &layer.anim_input_key_buffer,
        &layer.anim_input_key_len, ctx, "Animation Mask:");

    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

    if (layer.state.animation) {
        nk::layout_row_dynamic(ctx, 30, 2);
        nk::label(ctx, "Animation Config: ", nk::TEXT_LEFT);
        nk::label_colored(ctx, "(By updating values, you may reset the animation)",
            nk::TEXT_RIGHT, nk::rgb(0xFF,0xFF,0x33));

        layer.state.animation.config(ctx);
    }
}

fn void Manager.add_animation(&self, StaticLayer *layer, Animation animation) @export("animation_manager_add")
{
    layer.state.animation = animation;
    self.animations.push(animation);
}

fn void Manager.del_animation(&self, ulong id)
{
    self.animations.remove_using_test(fn bool(Animation *a, any id) {
        return ((*(int*) id) == a.get_id());
    }, &id);
}
