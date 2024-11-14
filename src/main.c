#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <pathbuf.h>
#include <string.h>
#include <stdlib.h>

#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include <raylib-nuklear.h>

int main()
{
    struct path p = {0};
    path_append_dir(&p, "protogens");
    path_append_dir(&p, "are");
    path_append_file(&p, "cute");
    size_t bufsz = path_bufsz(&p);

    char buf[bufsz + 1];
    memset(buf, 0, bufsz + 1);

    path_str(&p, bufsz, buf);

    printf("Full path: %s\n", buf);
    memset(buf, 0, bufsz + 1);

    bufsz = path_dirsz(&p);
    path_dir(&p, bufsz, buf);

    printf("Dir: %s\n", buf);
    memset(buf, 0, bufsz + 1);

    printf("Basename: %s\n", path_basename(&p));
    free(path_pop(&p));
    free(path_pop(&p));

    bufsz = path_bufsz(&p);
    path_str(&p, bufsz, buf);

    printf("New full path: %s\n", buf);

    path_deinit(&p, false);

    return 0;
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);

    InitWindow(1024, 512, "raylib-nuklear example");
    Font font = LoadFont("../assets/Ubuntu-R.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_TRILINEAR);

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
