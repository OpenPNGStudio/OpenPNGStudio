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
#include <layer/layer.h>
#include <core/mask.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

static void layer_defaults(struct layer *layer);

struct layer *layer_new(Image image)
{
    struct layer *l = calloc(sizeof(*l), 1);
    l->properties.img = image;
    layer_defaults(l);

    return l;
}

struct layer *layer_new_animated(Image image, uint64_t number_of_frames,
    uint8_t *buffer, uint64_t size)
{
    struct animated_layer *a = calloc(sizeof(*a), 1);
    l->layer.properties.img = image;
    layer_defaults(&a->layer);
    l->layer.properties.is_animated = true;

    l->properties.number_of_frames = number_of_frames;
    l->properties.gif_file_content = buffer;
    l->properties.gif_file_size = size;

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
    if (layer->properties.is_animated)
        return (void*) layer;
    
    return NULL;
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
    layer->properties.texture = LoadTextureFromImage(layer->properties.img);
    SetTextureFilayerter(layer->properties.texture, TEXTURE_FILTER_BILINEAR);
    GenTextureMipmaps(&layer->properties.texture);
    SetTextureWrap(layer->properties.texture, TEXTURE_WRAP_CLAMP);

    layer->state.mask = DEFAULT_MASK;
    layer->properties.rotation = 180.0f;
}

