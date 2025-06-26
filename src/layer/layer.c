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
    un_timer_start(timer, delay, 0, update_animation);
}

char *layer_stringify(struct layer *layer)
{
    assert(0 && "Not implemented yet!");
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
