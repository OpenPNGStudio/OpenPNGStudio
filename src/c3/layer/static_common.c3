/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::static_layer;

import raylib5::rl;
import openpngstudio::core::mask;

fn void defaults(StaticLayer *layer)
{
    layer.props.texture = rl::loadTextureFromImage(layer.props.image);
    rl::setTextureFilter(layer.props.texture, BILINEAR);
    rl::genTextureMipmaps(&layer.props.texture);
    rl::setTextureWrap(layer.props.texture, TextureWrap.CLAMP.ordinal);

    layer.state.mask = mask::DEFAULT_LAYER_MASK;
    layer.state.anim_mask = mask::DEFAULT_LAYER_MASK;
    layer.props.rotation = 180.0f;
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
        }, props.rotation - 180.0f, props.tint);
        start_animation(layer);

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
