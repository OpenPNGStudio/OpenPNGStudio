#include "filedialog.h"
#include <raylib.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <nk.h>

#include <raylib-nuklear.h>
#include <string.h>

int main()
{
    struct filedialog d = {0};

    d.filter = NULL;
    d.title = "Open File";
    d.row_count = 4;

    filedialog_init(&d, false);

    filedialog_show(&d);

    SetConfigFlags(FLAG_WINDOW_RESIZABLE);

    InitWindow(1024, 512, "raylib-nuklear example");
    Font font = LoadFont("../assets/Ubuntu-R.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_TRILINEAR);

    int fontSize = 16;
    struct nk_context *ctx = InitNuklearEx(font, fontSize);
    set_nk_font(font);

    int width = 1024;

    filedialog_register_icon(UP_IMG, LoadNuklearImage("../assets/up.png"));
    filedialog_register_icon(REFRESH_IMG, LoadNuklearImage("../assets/refresh.png"));
    filedialog_register_icon(DIR_IMG, LoadNuklearImage("../assets/directory.png"));
    filedialog_register_icon(FILE_IMG, LoadNuklearImage("../assets/file.png"));
    filedialog_register_icon(IMG_IMG, LoadNuklearImage("../assets/image.png"));

    SetTargetFPS(60);

    Color bg = ColorFromNuklear(ctx->style.window.header.active.data.color);

    while (!WindowShouldClose()) {
        UpdateNuklear(ctx);

        if (nk_begin(ctx, "Menu", nk_rect(0, 0, width, 25),
                NK_WINDOW_NO_SCROLLBAR)) {
            nk_menubar_begin(ctx);

            nk_layout_row_static(ctx, 20, 40, 1);

            if (nk_menu_begin_label(ctx, "File", NK_TEXT_LEFT, nk_vec2(200, 200))) {
                nk_layout_row_dynamic(ctx, 25, 1);
                if (nk_menu_item_label(ctx, "New", NK_TEXT_LEFT)) {
                }
                nk_menu_end(ctx);
            }

            nk_menubar_end(ctx);
        }

        nk_end(ctx);

        width = GetScreenWidth();

        filedialog_run(&d, ctx);

        BeginDrawing();
            ClearBackground(bg);

            if (!d.show) {
                if (d.selected_index != -1) {
                    size_t sz = filedialog_selsz(&d);
                    char buffer[sz + 1];
                    memset(buffer, 0, sz + 1);
                    filedialog_selected(&d, sz, buffer);

                    DrawTextEx(font, buffer, (Vector2) { 64, 64, }, 24.0f, 24.0f / 10.0f, WHITE);
                }
            }

            DrawNuklear(ctx);
        EndDrawing();
    }

    UnloadNuklear(ctx);

    CloseWindow();

    filedialog_deinit(&d);

    return 0;
}
