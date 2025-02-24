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

#include <layer/layer.h>

struct layer_manager {
    struct layer **layers;
    uint64_t layer_count;
    uint64_t selected_layer;
};

void layer_manager_cleanup(struct layer_manager *mgr);
void layer_manager_add_layer(struct layer_manager *mgr, struct layer *layer);

void layer_manager_ui(struct layer_manager *mgr, struct nk_context *ctx);
void layer_manager_render(struct layer_manager *mgr);
