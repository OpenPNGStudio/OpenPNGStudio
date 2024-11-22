#include "layermgr.h"
#include <raylib-nuklear.h>
#include <editor.h>
#include <stdbool.h>
#include <nk.h>

void editor_draw(struct editor *editor, struct nk_context *ctx, bool *ui_focused)
{
    if (editor->geometry.x == 0 && editor->geometry.y == 0 &&
        editor->geometry.w == 0 && editor->geometry.h == 0) {

        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 45.0f;
        float h = height / 100.0f * 85.0f;
        float x = width - w - 40;
        float y = 60;

        editor->geometry = nk_rect(x, y, w, h);
    }

    if (!editor->hide) {
        if (nk_begin(ctx, "Editor", editor->geometry, NK_WINDOW_TITLE |
            NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE | NK_WINDOW_BORDER |
            NK_WINDOW_MINIMIZABLE )) {
            if (nk_input_is_mouse_hovering_rect(&ctx->input, nk_window_get_bounds(ctx)))
                *ui_focused = true;

            const char *names[] = {"Overview", "Layers", "Scripts"};
            const int name_count = 3;
            
            nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
            nk_style_push_float(ctx, &ctx->style.button.rounding, 0);
            nk_layout_row_begin(ctx, NK_STATIC, 40, name_count);

            for (int i = 0; i < name_count; ++i) {
                Vector2 size = MeasureTextEx(get_nk_font(), names[i], 16, 16 / 10.0f);
                size.x += 16;
                float text_width = size.x;

                float widget_width = text_width + name_count * ctx->style.button.padding.x;
                nk_layout_row_push(ctx, widget_width);
                    if (editor->current_tab == i) {
                        struct nk_style_item button_color = ctx->style.button.normal;
                        ctx->style.button.normal = ctx->style.button.active;
                        editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;
                        ctx->style.button.normal = button_color;
                    } else
                        editor->current_tab = nk_button_label(ctx, names[i]) ? i: editor->current_tab;

            }
            nk_style_pop_float(ctx);

            struct nk_rect bounds = nk_window_get_content_region(ctx);

            nk_layout_row_dynamic(ctx, bounds.h - 50, 1);
            if (nk_group_begin(ctx, "Notebook", 0)) {
                nk_style_pop_vec2(ctx);

                switch (editor->current_tab) {
                case OVERVIEW:
                    nk_layout_row_dynamic(ctx, 40, 1);
                    nk_label(ctx, "Model Information: ", NK_TEXT_LEFT);
                    break;
                case LAYERS:
                    layer_manager_draw_ui(&editor->layer_manager, ctx);
                    break;
                case SCRIPTS:
                    nk_layout_row_dynamic(ctx, 40, 1);
                    nk_label(ctx, "Comming Soon :3", NK_TEXT_LEFT);
                    break;
                }

                nk_group_end(ctx);
            }
        }

        nk_end(ctx);
    }
}