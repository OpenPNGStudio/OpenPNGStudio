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

    /* GIF related fields */
    uint32_t *delays;
    int frames_count;
    int current_frame;
    int previous_frame;
};

struct layer_manager {
    size_t layer_count;
    struct model_layer *layers;
    int selected_index;
};

void layer_manager_deinit(struct layer_manager *mgr);

struct model_layer *layer_manager_add_layer(struct layer_manager *mgr, struct model_layer *layer);

void layer_manager_draw_ui(struct layer_manager *mgr, struct nk_context *ctx);
void layer_manager_draw_layers(struct layer_manager *mgr);

#endif
