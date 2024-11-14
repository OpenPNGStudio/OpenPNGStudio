#include "filedialog.h"
#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <pathbuf.h>
#include <string.h>

#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include <raylib-nuklear.h>

int main()
{
    struct filedialog d = {0};

    d.filter = NULL;

    filedialog_deinit(&d);

    return 0;
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);

    InitWindow(1024, 512, "raylib-nuklear example");
    Font font = LoadFont("../assets/Ubuntu-R.ttf");

    int fontSize = 16;
    struct nk_context *ctx = InitNuklearEx(font, fontSize);

    int width = 1024;

    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        UpdateNuklear(ctx);

        if (nk_begin(ctx, "Menu", nk_rect(0, 0, width, 30),
                NK_WINDOW_NO_SCROLLBAR)) {
            nk_menubar_begin(ctx);

            nk_layout_row_static(ctx, 20, 40, 1);

            if (nk_menu_begin_label(ctx, "File", NK_TEXT_LEFT, nk_vec2(200, 200))) {
                nk_layout_row_dynamic(ctx, 25, 1);
                if (nk_menu_item_label(ctx, "New", NK_TEXT_LEFT)) {
                    printf("Hello World!\n");
                }
                nk_menu_end(ctx);
            }

            nk_menubar_end(ctx);
        }

        nk_end(ctx);

        width = GetScreenWidth();

        BeginDrawing();
            ClearBackground(RAYWHITE);

            DrawNuklear(ctx);

        EndDrawing();
    }

    UnloadNuklear(ctx);

    CloseWindow();

    return 0;
}
