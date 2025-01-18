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

#ifndef _LAYERMGR_H_
#define _LAYERMGR_H_

#include <stddef.h>
#include <stdint.h>
#include "line_edit.h"
#include "raylib.h"

struct model_layer {
    Image img;
    Texture2D texture;
    Vector2 position_offset;
    float rotation;
    struct line_edit name;
    bool delete;
    uint64_t mask;
    char input_key[2];
    int input_len;
    int ttl;
    bool alive;

    /* GIF related fields */
    uint8_t *gif_buffer; /* since stb cannot export GIF to mem, I will copy the file over */
    size_t gif_size;
    uint32_t *delays;
    int frames_count;
    int current_frame;
    int previous_frame;
};

struct layer_manager {
    size_t layer_count;
    struct model_layer **layers;
    int selected_index;

    uint64_t mask;
};

void layer_manager_deinit(struct layer_manager *mgr);

struct model_layer *layer_manager_add_layer(struct layer_manager *mgr, struct model_layer *layer);

void layer_manager_draw_ui(struct layer_manager *mgr, struct nk_context *ctx);
void layer_manager_draw_layers(struct layer_manager *mgr);
char *layer_tomlify(struct model_layer *layer);
void cleanup_layer(struct model_layer *layer);

#endif
