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

struct Manager {
    List{Animation} animations;
}

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
        if (!anim.can_play(GET)) continue;
        if (anim.is_done(GET)) anim.reset(now);

        anim.tick(now);
    }
}

fn void Manager.add_animation(&self, StaticLayer *layer, Animation animation) @export("animation_manager_add")
{
    layer.state.animation = animation;
    self.animations.push(animation);
}
