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
import openpngstudio::animation::spinner;
import openpngstudio::animation::easings;
import nk;

struct Manager {
    List{Animation} animations;
}

const CChar*[] ANIMATIONS = {"None", "Spinner"};

fn Manager *new_manager() @export("animation_manager_new")
{
    Manager *m = malloc(Manager.sizeof);
    m.animations.init(mem);
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

fn void Manager.animation_selector(&self, StaticLayer *layer, nk::Context *ctx) @export("animation_manager_selector")
{
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 2);
    nk::layout_row_push(ctx, 0.75f);
    nk::label(ctx, "Animation: ", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.24f);

    int old = layer.state.selected_animation;
    int current = nk::combo(ctx, ANIMATIONS.ptr, 2, old, 30, nk::vec2(200, 200)
        );
    layer.state.selected_animation = current;

    if (old != current) {
        if (current == 1) {
            self.add_animation(layer, spinner::new(360, 2500));
        } else if (current == 0) {
            if (layer.state.animation) {
                ulong id = layer.state.animation.get_id();
                defer free(layer.state.animation);
                layer.state.animation = null;
                self.del_animation(id);
            }
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
