/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::static_layer;

import raylib5::rl;
import nk;
import unuv;
import std::math;
import openpngstudio::core::mask;
import libc;

// fn void defaults(StaticLayer *layer)
// {
//     layer.props.texture = rl::loadTextureFromImage(layer.props.image);
//     rl::setTextureFilter(layer.props.texture, BILINEAR);
//     rl::genTextureMipmaps(&layer.props.texture);
//     rl::setTextureWrap(layer.props.texture, TextureWrap.CLAMP.ordinal);
// }

// fn void start_timeout(StaticLayer *layer, unuv::UnLoop *loop)
//     @export("layer_start_timeout")
// {
//     layer.state.active = true;
//     unuv::UnTimer *timer = unuv::timer_new(loop);
//     unuv::timer_set_data(timer, layer);
//     unuv::timer_start(timer, layer.state.time_to_live, 0, &after_timeout);
// }
//
// fn void toggle(StaticLayer *layer, unuv::UnLoop *loop)
//     @export("layer_toggle")
// {
//     layer.state.is_toggled = !layer.state.is_toggled;
//     layer.state.is_toggle_timer_ticking = true;
//     unuv::UnTimer *timer = unuv::timer_new(loop);
//     unuv::timer_set_data(timer, layer);
//     unuv::timer_start(timer, 250, 0, &after_toggle);
// }
//
// fn unuv::UnAction after_timeout(unuv::UnTimer *timer) @local
// {
//     StaticLayer *layer = unuv::timer_get_data(timer);
//     layer.state.active = false;
//
//     if (layer.state.prepare_for_deletion) {
//         if (!layer.props.is_animated) {
//             cleanup(layer); /* not a GIF */
//         }
//     }
//
//     return unuv::DISARM;
// }
//
// fn unuv::UnAction after_toggle(unuv::UnTimer *timer)
// {
//     StaticLayer *layer = unuv::timer_get_data(timer);
//     layer.state.is_toggle_timer_ticking = false;
//
//     return unuv::DISARM;
// }
