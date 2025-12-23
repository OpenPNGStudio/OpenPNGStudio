/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import openpngstudio::ui::wm;
import openpngstudio::animation;
import nk;

struct Config (wm::Window) {
    animation::Manager *anim_manager;
    Layer selected;
    int id;
}

fn void Config.init(&self, int id, animation::Manager *ref)
{
    self.id = id;
    self.selected = null;
    self.anim_manager = ref;
}

fn int Config.get_id(&self) @dynamic => self.id;

fn void Config.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    if (self.selected == null) return;

    self.selected.configure(ctx);
    self.anim_manager.animation_selector(self.selected, ctx);
}
