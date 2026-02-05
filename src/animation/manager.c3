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
//     State *layer_state = layer.get_state();
//     int current, old;
//
//     nk::label(ctx, "Animation: ", nk::TEXT_LEFT);
//
//     if (old != current) {
//         if (layer_state.animation) {
//             ulong id = layer_state.animation.get_id();
//             Animation prev = layer_state.animation;
//             layer_state.animation = null;
//             self.del_animation(id);
//             free(prev);
//         }
//         if (current == 2) {
//             self.add_animation(layer, shake::new());
//         } else if (current == 1) {
//             self.add_animation(layer, spinner::new(360, 2500));
//         } else if (current == 3) {
//             self.add_animation(layer, fade::new(250));
//         }
//     }
//
//     nk::label(ctx, "Animation Easing: ", nk::TEXT_LEFT);
//     if (nk::group_begin(ctx, "Animation Easing", nk::WINDOW_NO_SCROLLBAR)) {
//         nk::layout_row_dynamic(ctx, 30, 1);
//         nk::Rect b = nk::widget_bounds(ctx);
//         old = 0;
//
//         if (layer_state.animation) {
//             old = layer_state.animation.easing();
//         } else {
//             nk::widget_disable_begin(ctx);
//         }
//
//         if (layer_state.animation) {
//             Animation anim = layer_state.animation;
//         } else {
//             nk::widget_disable_begin(ctx);
//         }
//
//         current = nk::combo(ctx, easings::NAMES.ptr, easings::NAMES.len, old,
//             30, nk::vec2(b.w, 200));
//
//         if (layer_state.animation) {
//             layer_state.animation.easing(true, current);
//         } else {
//             nk::widget_disable_end(ctx);
//         }
//         nk::group_end(ctx);
//     }
//
//     mask::configure(&layer_state.anim_mask, &layer_state.anim_input_key_buffer,
//         &layer_state.anim_input_key_length, ctx, "Animation Mask:");
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
