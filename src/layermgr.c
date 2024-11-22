#include "console.h"
#include "line_edit.h"
#include "raylib-nuklear.h"
#include "raylib.h"
#include <float.h>
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
    struct nk_rect bounds = nk_window_get_content_region(ctx);
    int res = 0;
    if (mgr->selected_index != -1) {
        bounds.h /= 2;
        bounds.h -= 10;
        nk_layout_row_dynamic(ctx, bounds.h, 1);
        res = nk_group_begin(ctx, "Layer", 0);
    }

    for (int i = 0; i < mgr->layer_count; i++) {
        nk_layout_row_dynamic(ctx, 30, 1);
        struct model_layer *layer = mgr->layers + i;
        struct nk_rect bounds = nk_layout_widget_bounds(ctx);
        bounds.h *= 2;

        line_edit_draw(&layer->name, ctx);
        /* UI controls */
        nk_layout_row_dynamic(ctx, 30, 3);
        if (i == 0)
            nk_widget_disable_begin(ctx);

        if (nk_button_label(ctx, "UP")) {
            struct model_layer prev = mgr->layers[i - 1];
            *(mgr->layers + i - 1) = *layer;
            *(mgr->layers + i) = prev;
            mgr->selected_index = -1;
        }

        if (i == 0)
            nk_widget_disable_end(ctx);

        if (i == mgr->layer_count - 1)
            nk_widget_disable_begin(ctx);

        if (nk_button_label(ctx, "DOWN")) {
            struct model_layer next = mgr->layers[i + 1];
            *(mgr->layers + i + 1) = *layer;
            *(mgr->layers + i) = next;
            mgr->selected_index = -1;
        }

        if (i == mgr->layer_count - 1)
            nk_widget_disable_end(ctx);

        if (nk_button_label(ctx, "DEL"))
            layer->delete = true;

        if (nk_input_mouse_clicked(&ctx->input, NK_BUTTON_LEFT, bounds) && ctx->last_widget_state == 4)
            mgr->selected_index = i;
    }

    if (res)
        nk_group_end(ctx);

    if (mgr->selected_index != -1) {
        if (nk_group_begin(ctx, "Layer Property Editor", 0)) {
            struct model_layer *layer = mgr->layers + mgr->selected_index;
            nk_layout_row_dynamic(ctx, 30, 1);
            nk_label(ctx, "Position:", NK_TEXT_LEFT);
            nk_layout_row_dynamic(ctx, 30, 2);
            nk_property_float(ctx, "X", -FLT_MAX, &layer->position_offset.x, FLT_MAX, 0.1f, 0.1f);
            nk_property_float(ctx, "Y", -FLT_MAX, &layer->position_offset.y, FLT_MAX, 0.1f, 0.1f);
            nk_layout_row_dynamic(ctx, 30, 1);
            nk_label(ctx, "Rotation:", NK_TEXT_LEFT);
            nk_layout_row_static(ctx, 40, 40, 1);
            nk_knob_float(ctx, 0, &layer->rotation, 360, 0.1, NK_DOWN, 0.0f);
            nk_group_end(ctx);
        }
    }

    /* TODO cleanup */
}

void layer_manager_draw_layers(struct layer_manager *mgr)
{
    float width = GetScreenWidth();
    float height = GetScreenHeight();

    for (int i = 0; i < mgr->layer_count; i++) {
        struct model_layer *layer = mgr->layers + i;
        Texture2D texture = layer->texture;
        DrawTexturePro(texture, (Rectangle) {
            .x = 1,
            .y = 1,
            .width = texture.width - 2,
            .height = texture.height - 2,
        }, (Rectangle) {
            .x = width / 2.0f + layer->position_offset.x,
            .y = height / 2.0f + -layer->position_offset.y,
            .width = texture.width,
            .height = texture.height,
        }, (Vector2) {
            .x = texture.width / 2.0f,
            .y = texture.height / 2.0f,
        }, layer->rotation - 180, WHITE);
    }
}