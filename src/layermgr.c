#include "console.h"
#include "line_edit.h"
#include "mask.h"
#include "raylib-nuklear.h"
#include "raylib.h"
#include <ctype.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <layermgr.h>

static void reset_key_mask(uint64_t *mask);
static void draw_props(struct layer_manager *mgr, struct nk_context *ctx);
static nk_bool nk_filter_key(const struct nk_text_edit *box, nk_rune unicode);

void layer_manager_deinit(struct layer_manager *mgr)
{
    /* TODO */
}

struct model_layer *layer_manager_add_layer(struct layer_manager *mgr, struct model_layer *layer)
{
    mgr->layers = realloc(mgr->layers, (++mgr->layer_count) * sizeof(*layer));
    mgr->layers[mgr->layer_count - 1] = *layer;
    return (mgr->layers + (mgr->layer_count - 1));
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
        struct model_layer *layer = mgr->layers + i;
        struct nk_rect bounds = nk_layout_widget_bounds(ctx);
        bounds.h *= 2;

        nk_layout_row_template_begin(ctx, 32);
        nk_layout_row_template_push_static(ctx, 64);
        nk_layout_row_template_push_dynamic(ctx);
        nk_layout_row_template_end(ctx);

        if (nk_button_label(ctx, "SEL"))
            mgr->selected_index = i;

        line_edit_draw(&layer->name, ctx);

        /* UI controls */
        nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
        nk_layout_row_push(ctx, 0.33f);
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

        nk_layout_row_push(ctx, 0.33f);
        if (nk_button_label(ctx, "DOWN")) {
            struct model_layer next = mgr->layers[i + 1];
            *(mgr->layers + i + 1) = *layer;
            *(mgr->layers + i) = next;
            mgr->selected_index = -1;
        }

        if (i == mgr->layer_count - 1)
            nk_widget_disable_end(ctx);

        nk_layout_row_push(ctx, 0.33f);
        if (nk_button_label(ctx, "DEL"))
            layer->delete = true;
        nk_layout_row_end(ctx);
    }

    if (res)
        nk_group_end(ctx);

    if (mgr->selected_index != -1) {
        nk_layout_row_dynamic(ctx, 2, 1);
        nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
        nk_layout_row_dynamic(ctx, bounds.h, 1);
        if (nk_group_begin(ctx, "Layer Property Editor", 0))
            draw_props(mgr, ctx);
    }

    /* TODO cleanup */
}

void layer_manager_draw_layers(struct layer_manager *mgr)
{
    float width = GetScreenWidth();
    float height = GetScreenHeight();

    for (int i = 0; i < mgr->layer_count; i++) {
        struct model_layer *layer = mgr->layers + i;
        Image *img = &layer->img;
        Texture2D texture = layer->texture;

        if (layer->frames_count > 0) {
            if (layer->previous_frame != layer->current_frame) {
                size_t offset = img->width * img->height * 4 *
                    layer->current_frame;

                UpdateTexture(texture, ((unsigned char*) img->data) + offset);
                layer->previous_frame = layer->current_frame;
            }
        }

        DrawTexturePro(texture, (Rectangle) {
            .x = 1,
            .y = 1,
            .width = texture.width - 2,
            .height = texture.height - 2,
        }, (Rectangle) {
            .x = width / 2.0f + layer->position_offset.x,
            .y = height / 2.0f + (-layer->position_offset.y),
            .width = texture.width,
            .height = texture.height,
        }, (Vector2) {
            .x = texture.width / 2.0f,
            .y = texture.height / 2.0f,
        }, layer->rotation - 180, WHITE);
    }
}

static void draw_props(struct layer_manager *mgr, struct nk_context *ctx)
{
    struct model_layer *layer = mgr->layers + mgr->selected_index;
    bool holding_shift = nk_input_is_key_down(&ctx->input, NK_KEY_SHIFT);

    nk_layout_row_dynamic(ctx, 30, 1);
    nk_label(ctx, "Position:", NK_TEXT_LEFT);
    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 2);
    nk_layout_row_push(ctx, 0.5f);
    if (!holding_shift) {
        nk_property_float(ctx, "X", -FLT_MAX, &layer->position_offset.x, FLT_MAX, 0.1f, 0.1f);
        nk_layout_row_push(ctx, 0.49f);
        nk_property_float(ctx, "Y", -FLT_MAX, &layer->position_offset.y, FLT_MAX, 0.1f, 0.1f);
    } else {
        layer->position_offset.x = roundf(layer->position_offset.x);
        layer->position_offset.y = roundf(layer->position_offset.y);
        nk_property_float(ctx, "X", -FLT_MAX, &layer->position_offset.x, FLT_MAX, 1, 1);
        nk_layout_row_push(ctx, 0.49f);
        nk_property_float(ctx, "Y", -FLT_MAX, &layer->position_offset.y, FLT_MAX, 1, 1);
    }
    nk_layout_row_end(ctx);

    nk_layout_row_dynamic(ctx, 30, 1);
    nk_label(ctx, "Rotation:", NK_TEXT_LEFT);
    nk_layout_row_static(ctx, 40, 40, 1);

    nk_knob_float(ctx, 0, &layer->rotation, 360, 0.1f, NK_DOWN, 0.0f);

    if (holding_shift)
        layer->rotation = roundf(layer->rotation / 15.0f) * 15.0f;

    nk_layout_row_dynamic(ctx, 2, 1);
    nk_rule_horizontal(ctx, ctx->style.window.border_color, false);

    nk_layout_row_dynamic(ctx, 30, 1);
    nk_label(ctx, "Mask:", NK_TEXT_LEFT);
    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
    
    nk_layout_row_push(ctx, 0.33f);
    nk_checkbox_flags_label(ctx, "Normal", (unsigned int*) &layer->mask, QUIET);
    nk_layout_row_push(ctx, 0.33f);
    nk_checkbox_flags_label(ctx, "Talking", (unsigned int*) &layer->mask, TALK);
    nk_layout_row_push(ctx, 0.329f);
    nk_checkbox_flags_label(ctx, "Pause", (unsigned int*) &layer->mask, PAUSE);
    nk_layout_row_end(ctx);

    nk_layout_row_dynamic(ctx, 30, 1);
    nk_label(ctx, "Modifier keys:", NK_TEXT_LEFT);
    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 4);

    nk_layout_row_push(ctx, 0.25f);
    nk_checkbox_flags_label(ctx, "Shift", (unsigned int*) &layer->mask, SHIFT);
    nk_layout_row_push(ctx, 0.25f);
    nk_checkbox_flags_label(ctx, "Ctrl", (unsigned int*) &layer->mask, CTRL);
    nk_layout_row_push(ctx, 0.25f);
    nk_checkbox_flags_label(ctx, "Super", (unsigned int*) &layer->mask, SUPER);
    nk_layout_row_push(ctx, 0.249f);
    nk_checkbox_flags_label(ctx, "Alt", (unsigned int*) &layer->mask, META);
    nk_layout_row_end(ctx);

    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 2);
    nk_layout_row_push(ctx, 0.5f);
    nk_label(ctx, "Key press:", NK_TEXT_LEFT);
    nk_layout_row_push(ctx, 0.49f);
    nk_edit_string(ctx, NK_EDIT_SIMPLE, layer->input_key, &layer->input_len, 2,
        nk_filter_key);

    if (layer->input_len > 0) {
        layer->input_key[0] = toupper(layer->input_key[0]);
        layer->mask |= 1ULL << (layer->input_key[0] - 'A' + KEY_START);
    } else
        reset_key_mask(&layer->mask);

    nk_group_end(ctx);
}

static nk_bool nk_filter_key(const struct nk_text_edit *box, nk_rune unicode)
{
    if ((unicode >= 'a' && unicode <= 'z') || (unicode >= 'A' && unicode <= 'Z'))
        return nk_true;

    return nk_false;
}

static void reset_key_mask(uint64_t *mask)
{
    uint64_t new_mask = 0;
    for (int i = 0; i < 7; i++)
        new_mask |= 1ULL << i;

    *mask &= new_mask;
}
