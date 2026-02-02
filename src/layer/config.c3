/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import openpngstudio::ui::wm;
import openpngstudio::animation;
import nk;

struct Config (wm::Window) {
    Layer selected;
}

fn void Config.init(&self)
{
    self.selected = null;
}

fn void Config.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    if (self.selected == null) return;

    self.selected.config(ctx);
}
