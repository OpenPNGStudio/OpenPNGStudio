#include <raylib.h>
#include <stdio.h>

#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include <raylib-nuklear.h>

int main()
{
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
}

