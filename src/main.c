#include "console.h"
#include "layermgr.h"
#include "messagebox.h"
#include <fcntl.h>
#include <filedialog.h>
#include <raylib.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <nk.h>

#include <raylib-nuklear.h>
#include <context.h>

#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <uv.h>

static char image_filter[] = "png;bmp;jpg;jpeg;gif;psd";

void on_file_read(uv_fs_t *req)
{
    struct context *ctx = req->data;
    if (req->result > 0) {
        ctx->f.ready = true;
    }
}

void on_file_open(uv_fs_t *req)
{
    struct context *ctx = req->data;
    if (req->result != -1) {
        uv_fs_read(ctx->loop, &ctx->f.read_req, req->result, &ctx->f.buffer,
            1, 0, on_file_read);
    }
}

void update(uv_idle_t *idle)
{
    struct context *ctx = idle->data;
    struct nk_context *nk_ctx = ctx->ctx;

    if (WindowShouldClose())
        uv_stop(ctx->loop);

    UpdateNuklear(nk_ctx);
    ctx->width = GetScreenWidth();
    ctx->height = GetScreenHeight();

    if (nk_begin(nk_ctx, "Menu", nk_rect(0, 0, ctx->width, 25),
            NK_WINDOW_NO_SCROLLBAR)) {
        nk_menubar_begin(nk_ctx);

        nk_layout_row_static(nk_ctx, 20, 40, 1);

        if (nk_menu_begin_label(nk_ctx, "File", NK_TEXT_LEFT, nk_vec2(200, 200))) {
            nk_layout_row_dynamic(nk_ctx, 25, 1);
            if (nk_menu_item_label(nk_ctx, "Open", NK_TEXT_LEFT))
                LOG("I don't do anything yet", 0);
            if (nk_menu_item_label(nk_ctx, "Save", NK_TEXT_LEFT))
                LOG("I don't do anything yet", 0);
            if (nk_menu_item_label(nk_ctx, "Save As", NK_TEXT_LEFT))
                LOG("I don't do anything yet", 0);

            nk_layout_row_dynamic(nk_ctx, 2, 1);
            nk_rule_horizontal(nk_ctx, nk_ctx->style.window.border_color, false);
            nk_layout_row_dynamic(nk_ctx, 25, 1);

            if (nk_menu_item_label(nk_ctx, "Load Image", NK_TEXT_LEFT)) {
                ctx->dialog.filter = image_filter;
                ctx->dialog.title = "Open Image File";
                filedialog_show(&ctx->dialog);

                ctx->loading_state = LOADING_IMAGE;
            }

            nk_menu_end(nk_ctx);
        }

        nk_menubar_end(nk_ctx);
    }

    nk_end(nk_ctx);

    filedialog_run(&ctx->dialog, nk_ctx);

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    console_draw(nk_ctx);

    if (!ctx->dialog.show) {
        if (ctx->dialog.selected_index != -1) {
            if (ctx->loading_state == LOADING_IMAGE) {
                ctx->loading_state = NOTHING;
                struct stat s;
                size_t sz = filedialog_selsz(&ctx->dialog);
                char buffer[sz + 1];
                memset(buffer, 0, sz + 1);
                filedialog_selected(&ctx->dialog, sz, buffer);

                if (stat(buffer, &s) == -1) {
                    perror("stat");
                    abort();
                }

                ctx->f.buffer = uv_buf_init(malloc(s.st_size), s.st_size);
                ctx->f.ready = false;
                ctx->f.open_req.data = ctx;
                ctx->f.read_req.data = ctx;
                ctx->f.close_req.data = ctx;
                uv_fs_open(ctx->loop, &ctx->f.open_req, buffer, O_RDONLY, 0,
                    on_file_open);
            }

            if (ctx->f.ready) {
                Image loaded = LoadImageFromMemory(".png", (unsigned char*) ctx->f.buffer.base, ctx->f.buffer.len);
                struct model_layer layer = {0};
                layer.texture = LoadTextureFromImage(loaded);
                layer.name = ":3";
                UnloadImage(loaded);

                LOG_I("Loaded layer", 0);

                layer_manager_add_layer(&ctx->mgr, &layer);
                ctx->f.ready = false;
            }
        }
    }

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

    layer_manager_draw_layers(&ctx->mgr);

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
    console_init();

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

    filedialog_deinit(&ctx.dialog);
    console_deinit();
    UnloadNuklear(ctx.ctx);
    CloseWindow();

    return 0;
}
