/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::static_layer;

import raylib5::rl;
import nk;
import std::math;
import openpngstudio::core::mask;

fn void defaults(StaticLayer *layer)
{
    layer.props.texture = rl::loadTextureFromImage(layer.props.image);
    rl::setTextureFilter(layer.props.texture, BILINEAR);
    rl::genTextureMipmaps(&layer.props.texture);
    rl::setTextureWrap(layer.props.texture, TextureWrap.CLAMP.ordinal);

    layer.state.mask = mask::DEFAULT_LAYER_MASK;
    layer.state.anim_mask = mask::DEFAULT_LAYER_MASK;
    layer.props.rotation = 0f;
    layer.props.tint = rl::WHITE;
    layer.state.animation = null;
    layer.state.selected_animation = 0;
}

fn bool draw(StaticLayer *layer, rl::Vector2 anchor)
{
    rl::Image *img = &layer.props.image;
    rl::Texture2D texture = layer.props.texture;

    bool mask_test = mask::cmp(mask::get(), layer.state.mask);

    if ((layer.state.active || layer.state.is_toggled) || mask_test) {
        Properties props = layer.animate();
        rl::drawTexturePro(texture, {
            .x = 0, .y = 0, .width = texture.width, .height = texture.height,
        }, {
            .x = anchor.x + props.offset.x,
            .y = anchor.y + (-props.offset.y),
            .width = texture.width, .height = texture.height,
        }, {
            .x = texture.width / 2.0f, .y = texture.height / 2.0f,
        }, props.rotation, props.tint);
        start_animation(layer);

        // TODO: LIBUV
        // if (!layer->properties.has_toggle) {
        //     /* spawn live timeout */
        //     if (!layer->state.active && layer->state.time_to_live > 0)
        //         layer_start_timeout(layer, ctx.loop);
        // } else {
        //     if (!layer->state.is_toggle_timer_ticking && mask_test)
        //         layer_toggle(layer, ctx.loop);
        // }
        return true;
    }
    stop_animation(layer);

    return false;
}

fn void configure(StaticLayer *layer, nk::Context *ctx)
{
    bool holding_shift = nk::input_is_key_down(&ctx.input, nk::KEY_SHIFT);
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);
    float off = holding_shift ? 1.0f : 0.1f;

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Position: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Position Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 2);

        if (holding_shift) {
            layer.props.offset.x = math::round(layer.props.offset.x);
            layer.props.offset.y = math::round(layer.props.offset.y);
        }

        nk::property_float(ctx, "X:", float.min, &layer.props.offset.x,
            float.max, off, off);
        nk::property_float(ctx, "Y:", float.min, &layer.props.offset.y,
            float.max, off, off);

        nk::group_end(ctx);
    }

    nk::label(ctx, "Rotation:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Rotation Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        if (holding_shift) {
            layer.props.rotation = math::round(layer.props.rotation);
        }

        nk::property_float(ctx, "##Rotation Angle", float.min,
            &layer.props.rotation, float.max, off, off);

        nk::group_end(ctx);
    }

    nk::label(ctx, "Toggle mode:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Toggle Mode Goup", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_template_begin(ctx, 30);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 75);
        nk::layout_row_template_end(ctx);

        nk::spacing(ctx, 1);
        nk::checkbox_label(ctx, "Enable", &layer.props.has_toggle);

        nk::group_end(ctx);
    }

    nk::label(ctx, "Timeout (ms):", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Timeout Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        if (layer.props.has_toggle) nk::widget_disable_begin(ctx);

        nk::property_int(ctx, "##Timeout", 0, &layer.state.time_to_live,
            int.max, 1, 1);

        if (layer.props.has_toggle) nk::widget_disable_end(ctx);

        nk::group_end(ctx);
    }

    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);

    mask::configure(&layer.state.mask, &layer.state.input_key_buffer,
        &layer.state.input_key_length, ctx, "Layer activation: ");

    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);
}

fn void start_animation(StaticLayer *layer) @local
{
    if (layer.state.animation) {
        if (mask::cmp(mask::get(), layer.state.anim_mask)) {
            layer.state.animation.can_play(SET_TRUE);
        } else {
            if (layer.state.animation.is_done()) stop_animation(layer);
        }
    }
}

fn void stop_animation(StaticLayer *layer) @local
{
    if (layer.state.animation) {
        if (layer.state.animation.can_play()) {
            layer.state.animation.is_done(SET_TRUE);
        }
        layer.state.animation.can_play(SET_FALSE);
    }
}
