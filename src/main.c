#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <pathbuf.h>
#include <string.h>

#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include <raylib-nuklear.h>

int main()
{
    struct path path = {0};
    append_dir(&path, "home");
    append_dir(&path, "jany");
    append_dir(&path, "Downloads");
    append_file(&path, "wallpaper.png");

    size_t to_alloc = path_bufsz(&path);
    char str_path[to_alloc + 1];
    memset(str_path, 0, to_alloc + 1);

    path_str(&path, to_alloc, str_path);

    printf("Path: %s\n", str_path);

    deinit_path(&path, false);

    return 0;

    InitWindow(640, 480, "raylib-nuklear example");

    int fontSize = 10;
    struct nk_context *ctx = InitNuklear(fontSize);

    while (!WindowShouldClose()) {
        UpdateNuklear(ctx);

        if (nk_begin(ctx, "Nuklear", nk_rect(100, 100, 220, 220),
                NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_CLOSABLE)) {
            nk_layout_row_static(ctx, 50, 150, 1);
            if (nk_button_label(ctx, "Button")) {
                printf("Hello World!\n");
            }
        }
        nk_end(ctx);

        BeginDrawing();
            ClearBackground(RAYWHITE);

            DrawNuklear(ctx);

        EndDrawing();
    }

    UnloadNuklear(ctx);

    CloseWindow();

    return 0;
}
