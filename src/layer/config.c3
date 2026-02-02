/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import openpngstudio::ui::wm;
import openpngstudio::animation;
import nk;

struct Config (wm::Window) {
    Layer selected;
    int id;
}

fn void Config.init(&self, int id)
{
    self.id = id;
    self.selected = null;
}

fn int Config.get_id(&self) @dynamic => self.id;

fn void Config.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    if (self.selected == null) return;

    self.selected.config(ctx);
}
