#ifndef _LAYERMGR_H_
#define _LAYERMGR_H_

#include <stddef.h>
#include "messagebox.h"
#include "raylib.h"

struct model_layer {
    Texture2D texture;
    const char *name;
};

struct layer_manager {
    size_t layer_count;
    struct model_layer *layers;
};

void layer_manager_deinit(struct layer_manager *mgr);

void layer_manager_add_layer(struct layer_manager *mgr, struct model_layer *layer);

void layer_manager_draw_ui(struct layer_manager *mgr, struct nk_context *ctx);
void layer_manager_draw_layers(struct layer_manager *mgr);

#endif