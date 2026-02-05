/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import openpngstudio::layer;
import std::collections::list;
import std::time, std::io;
import std::core::mem;
import openpngstudio::core::mask;
import openpngstudio::animation::spinner;
import openpngstudio::animation::shake;
import openpngstudio::animation::fade;
import openpngstudio::animation::easings;
import nk;


// fn void Manager.animation_selector(&self, Layer layer, nk::Context *ctx)
// {
//
//     nk::layout_row_dynamic(ctx, 4, 1);
//     nk::spacer(ctx);
//     nk::layout_row_dynamic(ctx, 2, 1);
//     nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
//     nk::layout_row_dynamic(ctx, 4, 1);
//     nk::spacer(ctx);
//
//     if (layer_state.animation) {
//         nk::layout_row_dynamic(ctx, 30, 2);
//         nk::label(ctx, "Animation Config: ", nk::TEXT_LEFT);
//         nk::label_colored(ctx, "(By updating values, you may reset the animation)",
//             nk::TEXT_RIGHT, nk::rgb(0xFF,0xFF,0x33));
//
//         layer_state.animation.config(ctx);
//     }
// }
