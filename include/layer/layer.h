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
#pragma once

#include "unuv.h"
#include <layer/properties.h>
#include <layer/state.h>
#include <layer/animated_properties.h>

struct layer {
    struct layer_properties properties;
    struct layer_state state;

    char input_key_buffer[2];
    int input_key_length;

    char anim_input_key_buffer[2];
    int anim_input_key_length;
};

struct animated_layer {
    struct layer layer;
    struct animated_layer_properties properties;
};

struct layer *layer_new(Image image);
struct layer *layer_new_animated(Image image, uint64_t number_of_frames,
    uint8_t *buffer, uint64_t size);

struct layer_properties layer_updated_properties(struct layer *layer);

void layer_start_timeout(struct layer *layer, un_loop *loop);
void layer_toggle(struct layer *layer, un_loop *loop);

void layer_override_name(struct layer *layer, char *name);

struct animated_layer *layer_get_animated(struct layer *layer);
void layer_animated_start(struct animated_layer *layer, un_loop *loop);

char *layer_stringify(struct layer *layer);
void layer_cleanup(struct layer *layer);
