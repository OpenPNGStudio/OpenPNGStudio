#include <filedialog.h>
#include <raylib.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <nk.h>

#include <raylib-nuklear.h>
#include <context.h>

#include <uv.h>

void update(uv_idle_t *idle)
{
    struct context *ctx = idle->data;
    if (WindowShouldClose())
        uv_stop(ctx->loop);

    UpdateNuklear(ctx->ctx);
    ctx->width = GetScreenWidth();
    ctx->height = GetScreenHeight();

    if (nk_begin(ctx->ctx, "Menu", nk_rect(0, 0, ctx->width, 25),
            NK_WINDOW_NO_SCROLLBAR)) {
        nk_menubar_begin(ctx->ctx);

        nk_layout_row_static(ctx->ctx, 20, 40, 1);

        if (nk_menu_begin_label(ctx->ctx, "File", NK_TEXT_LEFT, nk_vec2(200, 200))) {
            nk_layout_row_dynamic(ctx->ctx, 25, 1);
            if (nk_menu_item_label(ctx->ctx, "New", NK_TEXT_LEFT)) {
            }
            nk_menu_end(ctx->ctx);
        }

        nk_menubar_end(ctx->ctx);
    }

    nk_end(ctx->ctx);

    filedialog_run(&ctx->dialog, ctx->ctx);

    if (WindowShouldClose())
        uv_stop(ctx->loop);
}

void draw(uv_idle_t *idle)
{
    struct context *ctx = idle->data;
    if (WindowShouldClose())
        uv_stop(ctx->loop);

    BeginDrawing();
    ClearBackground(RAYWHITE);

    DrawFPS(100, 100);

    DrawNuklear(ctx->ctx);
    EndDrawing();

    if (WindowShouldClose())
        uv_stop(ctx->loop);
}

int main()
{
    /* CFG */
    struct context ctx = {0};
    ctx.loop = uv_default_loop();
    filedialog_init(&ctx.dialog, 0);

    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(1024, 640, "OpenPNGStudio");
    Font font = LoadFont("../assets/Ubuntu-R.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_TRILINEAR);

    filedialog_register_icon(UP_IMG, LoadNuklearImage("../assets/up.png"));
    filedialog_register_icon(DRIVE_IMG, LoadNuklearImage("../assets/drive.png"));
    filedialog_register_icon(REFRESH_IMG, LoadNuklearImage("../assets/refresh.png"));
    filedialog_register_icon(DIR_IMG, LoadNuklearImage("../assets/directory.png"));
    filedialog_register_icon(FILE_IMG, LoadNuklearImage("../assets/file.png"));
    filedialog_register_icon(IMG_IMG, LoadNuklearImage("../assets/image.png"));

    ctx.ctx = InitNuklearEx(font, 16);
    set_nk_font(font);

    SetTargetFPS(60);

    /* event loop */
    uv_idle_t draw_handle;
    draw_handle.data = &ctx;
    uv_idle_init(ctx.loop, &draw_handle);
    uv_idle_start(&draw_handle, draw);

    uv_idle_t update_handle;
    update_handle.data = &ctx;
    uv_idle_init(ctx.loop, &update_handle);
    uv_idle_start(&update_handle, update);

    uv_run(ctx.loop, UV_RUN_DEFAULT);
    uv_loop_close(ctx.loop);

    uv_run(ctx.loop, UV_RUN_DEFAULT);
    uv_loop_close(ctx.loop);

    UnloadNuklear(ctx.ctx);

    CloseWindow();

    return 0;
}
