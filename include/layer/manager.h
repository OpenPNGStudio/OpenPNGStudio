/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <animations.h>
#include <layer/layer.h>
#include <ui/window.h>

struct layer_manager {
    struct animation_manager *anims;
    struct layer **layers;
    struct window cfg_win;
    uint64_t layer_count;
    uint64_t selected_layer;
};

void layer_manager_cleanup(struct layer_manager *mgr);
void layer_manager_add_layer(struct layer_manager *mgr, struct layer *layer);

void layer_manager_ui(struct layer_manager *mgr, struct nk_context *ctx);
void layer_manager_render(struct layer_manager *mgr);
