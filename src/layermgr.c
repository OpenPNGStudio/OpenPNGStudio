#include "raylib.h"
#include <stdlib.h>
#include <layermgr.h>

void layer_manager_deinit(struct layer_manager *mgr)
{
    /* TODO */
}

void layer_manager_add_layer(struct layer_manager *mgr, struct model_layer *layer)
{
    mgr->layers = realloc(mgr->layers, (++mgr->layer_count) * sizeof(*layer));
    mgr->layers[mgr->layer_count - 1] = *layer;
}

void layer_manager_draw_ui(struct layer_manager *mgr, struct nk_context *ctx)
{
    /* TOOD */
}

void layer_manager_draw_layers(struct layer_manager *mgr)
{
    int width = GetScreenWidth();
    int height = GetScreenHeight();

    for (int i = 0; i < mgr->layer_count; i++) {
        struct model_layer *layer = mgr->layers + i;
        DrawTexture(layer->texture, width / 2 - layer->texture.width / 2,
            height / 2 - layer->texture.height / 2, WHITE);
    }
}