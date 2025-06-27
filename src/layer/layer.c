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
#include "unuv.h"
#include <layer/layer.h>
#include <core/mask.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

static void layer_defaults(struct layer *layer);
static enum un_action update_animation(un_timer *timer);
static enum un_action after_timeout(un_timer *timer);
static enum un_action after_toggle(un_timer *timer);

struct layer *layer_new(Image image)
{
    struct layer *l = calloc(sizeof(*l), 1);
    l->properties.image = image;
    layer_defaults(l);

    return l;
}

struct layer *layer_new_animated(Image image, uint64_t number_of_frames,
    uint8_t *buffer, uint64_t size)
{
    struct animated_layer *a = calloc(sizeof(*a), 1);
    a->layer.properties.image = image;
    layer_defaults(&a->layer);
    a->layer.properties.is_animated = true;

    a->properties.number_of_frames = number_of_frames;
    a->properties.gif_file_content = buffer;
    a->properties.gif_file_size = size;

    return &a->layer;
}

void layer_override_name(struct layer *layer, char *name)
{
    layer->properties.name.len = strlen(name);
    layer->properties.name.cleanup = false;
    layer->properties.name.buffer = name;
}

struct animated_layer *layer_get_animated(struct layer *layer)
{
    assert(layer->properties.is_animated == true && "layer is not animated");
    return (void*) layer;
}

void layer_animated_start(struct animated_layer *layer, un_loop *loop)
{
    un_timer *timer = un_timer_new(loop);
    un_timer_set_data(timer, layer);
    uint32_t delay = layer->properties.frame_delays[0];
    un_timer_start(timer, delay, delay, update_animation);
}

void layer_start_timeout(struct layer *layer, un_loop *loop)
{
    layer->state.active = true;
    un_timer *timer = un_timer_new(loop);
    un_timer_set_data(timer, layer);
    un_timer_start(timer, layer->state.time_to_live, 0, after_timeout);
}

void layer_toggle(struct layer *layer, un_loop *loop)
{
    layer->state.is_toggled = !layer->state.is_toggled;
    layer->state.is_toggle_timer_ticking = true;
    un_timer *timer = un_timer_new(loop);
    un_timer_set_data(timer, layer);
    un_timer_start(timer, 250, 0, after_toggle);
}

/* C3 types */
struct c3_layer {
    double x, y, rotation;
    mask_t mask;
    int time_to_live;
    bool has_toggle;
};

struct c3_anim_layer {
    struct c3_layer layer;
    uint64_t number_of_frames;
    uint32_t *frame_delays;
};

extern char *layer_stringify_static(struct c3_layer layer);
extern char *layer_stringify_anim(struct c3_anim_layer layer);

char *layer_stringify(struct layer *layer)
{
    if (layer->properties.is_animated) {
        struct animated_layer *al = layer_get_animated(layer);

        return layer_stringify_anim((struct c3_anim_layer) {
                .layer = (struct c3_layer) { .x = layer->properties.offset.x,
                    .y = layer->properties.offset.y,
                    .rotation = layer->properties.rotation,
                    .mask = layer->state.mask,
                    .time_to_live = layer->state.time_to_live,
                    .has_toggle = layer->properties.has_toggle
                }, .number_of_frames = al->properties.number_of_frames,
                .frame_delays = al->properties.frame_delays
            });
    }

    return layer_stringify_static((struct c3_layer) { .x = layer->properties.offset.x,
        .y = layer->properties.offset.y, .rotation = layer->properties.rotation,
        .mask = layer->state.mask, .time_to_live = layer->state.time_to_live,
        .has_toggle = layer->properties.has_toggle
    });
}

void layer_cleanup(struct layer *layer)
{
    assert(0 && "Not implemented yet!");
}

static void layer_defaults(struct layer *layer)
{
    layer->properties.texture = LoadTextureFromImage(layer->properties.image);
    SetTextureFilter(layer->properties.texture, TEXTURE_FILTER_BILINEAR);
    GenTextureMipmaps(&layer->properties.texture);
    SetTextureWrap(layer->properties.texture, TEXTURE_WRAP_CLAMP);

    layer->state.mask = DEFAULT_MASK;
    layer->properties.rotation = 180.0f;
}

static enum un_action update_animation(un_timer *timer)
{
    struct animated_layer *layer = un_timer_get_data(timer);

    layer->properties.previous_frame_index = layer->properties.current_frame_index;
    un_timer_set_repeat(timer, layer->properties.frame_delays[layer->properties.current_frame_index]);
    layer->properties.current_frame_index = (layer->properties.current_frame_index + 1) %
        layer->properties.number_of_frames;

    if (layer->layer.state.prepare_for_deletion) {
        if (!layer->layer.state.active) {
            layer_cleanup(&layer->layer);
            return DISARM;
        }
    }

    return REARM;
}

static enum un_action after_timeout(un_timer *timer)
{
    struct layer *layer = un_timer_get_data(timer);
    layer->state.active = false;

    if (layer->state.prepare_for_deletion) {
        if (!layer->properties.is_animated)
            layer_cleanup(layer); /* not a GIF */
    }

    return DISARM;
}

static enum un_action after_toggle(un_timer *timer)
{
    struct layer *layer = un_timer_get_data(timer);
    layer->state.is_toggle_timer_ticking = false;

    return DISARM;
}
