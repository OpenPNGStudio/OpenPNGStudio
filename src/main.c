#include "filedialog.h"
#include <raylib.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <string.h>

#include <raylib-nuklear.h>

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

    int width = 1024;

    filedialog_register_icon(UP_IMG, LoadNuklearImage("../assets/up.png"));
    filedialog_register_icon(DIR_IMG, LoadNuklearImage("../assets/directory.png"));
    filedialog_register_icon(FILE_IMG, LoadNuklearImage("../assets/file.png"));
    filedialog_register_icon(IMG_IMG, LoadNuklearImage("../assets/image.png"));

    SetTargetFPS(60);

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
            ClearBackground(RAYWHITE);

            DrawNuklear(ctx);

        EndDrawing();
    }

    UnloadNuklear(ctx);

    CloseWindow();

    filedialog_deinit(&d);

    return 0;
}
