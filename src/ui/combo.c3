/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio::ui::icons;
import nk;

macro combo_begin(nk::Context *ctx, CChar *label, nk::Vec2 size) =>
    nk::combo_begin_image_label(ctx, label,
        &&(nk::Image[2]){icons::get(COMBO_OPEN), icons::get(COMBO)},
        size);
