#include "console.h"
#include "editor.h"
#include "layermgr.h"
#include <fcntl.h>
#include <filedialog.h>
#include <raylib.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <nk.h>

#include <raylib-nuklear.h>
#include "raymath.h"
#include "rlgl.h"
#include <context.h>

#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <unuv.h>
#include <uv.h>

#define PATH_START "../"

static char image_filter[] = "png;bmp;jpg;jpeg;gif";
struct context ctx = {0};

static enum un_action update(un_idle *task);
static enum un_action draw(un_idle *task);
static void draw_menubar(bool *ui_focused);
static void load_layer();

/* to be replaced */
static void load_layer_file(uv_work_t *req);
static void after_layer_loaded(uv_work_t *req, int status);

static void onAudioData(ma_device* device, void* output, const void* input, ma_uint32 frameCount) {
    struct microphone_data* data = device->pUserData;
    float* inputData = (float*)input;

    float sum = 0.0f;
    for (ma_uint32 i = 0; i < frameCount; i++) {
        sum += inputData[i] * inputData[i];
    }

    data->volume = sqrtf(sum / frameCount) * 100;
}

static void draw_grid(int line_width, int spacing, Color color)
{
    float width = GetScreenWidth();
float height = GetScreenHeight();

    float width_total = width / spacing;
    int width_count = width / spacing;
    float width_pad_half = (width_total - width_count) / 2;

    for (int i = width_pad_half * spacing; i < width; i += spacing) {
        DrawLineEx((Vector2) { i, 0 }, (Vector2) { i, height }, line_width, color);
    }
    
    float height_total = height / spacing;
    int height_count = height / spacing;
    float height_pad_half = (height_total - height_count) / 2;

    for (int i = height_pad_half * spacing; i < height; i += spacing) {
        DrawLineEx((Vector2) { 0, i }, (Vector2) { width, i }, line_width, color);
    }
}

int main()
{
    char cpubuff[4] = {0};
    snprintf(cpubuff, 3, "%d", uv_available_parallelism());
    setenv("UV_THREADPOOL_SIZE", cpubuff, 1);
    /* CFG */
    ctx.loop = un_loop_new();
    filedialog_init(&ctx.dialog, 0);
    console_init();

    LOG_I("Using %d threads", uv_available_parallelism());

#ifdef _WIN32
    path_append_dir(&ctx.dialog.current_directory, strdup("users"));
    path_append_dir(&ctx.dialog.current_directory, strdup(getenv("USERNAME")));
#else
    path_append_dir(&ctx.dialog.current_directory, strdup("home"));
    path_append_dir(&ctx.dialog.current_directory, strdup(getlogin()));
#endif
    filedialog_refresh(&ctx.dialog);

    ctx.camera.zoom = 1.0f;
    ctx.editor.layer_manager.selected_index = -1;

    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT | FLAG_VSYNC_HINT);
    InitWindow(1024, 640, "OpenPNGStudio");
    Font font = LoadFont(PATH_START "assets/Ubuntu-R.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_TRILINEAR);

    filedialog_register_icon(UP_IMG, LoadNuklearImage(PATH_START "assets/up.png"));
    filedialog_register_icon(DRIVE_IMG, LoadNuklearImage(PATH_START "assets/drive.png"));
    filedialog_register_icon(REFRESH_IMG, LoadNuklearImage(PATH_START "assets/refresh.png"));
    filedialog_register_icon(DIR_IMG, LoadNuklearImage(PATH_START "assets/directory.png"));
    filedialog_register_icon(FILE_IMG, LoadNuklearImage(PATH_START "assets/file.png"));
    filedialog_register_icon(IMG_IMG, LoadNuklearImage(PATH_START "assets/image.png"));

    ctx.ctx = InitNuklearEx(font, 16);
    set_nk_font(font);

    /* MINIAUDIO */
    ma_result result;
    ma_device_config deviceConfig = ma_device_config_init(ma_device_type_capture);
    deviceConfig.capture.format = ma_format_f32;
    deviceConfig.capture.channels = 1; // Use 1 channel for microphone
    deviceConfig.sampleRate = 44100;
    deviceConfig.dataCallback = onAudioData;

    result = ma_device_init(NULL, &deviceConfig, &ctx.mic.device);
    if (result != MA_SUCCESS) {
        LOG_E("Failed to initialize device.\n", 0);
        return -1;
    }

    ctx.mic.device.pUserData = &ctx.mic;

    result = ma_device_start(&ctx.mic.device);
    if (result != MA_SUCCESS) {
        LOG_E("Failed to start device.\n", 0);
        return -1;
    }

    ctx.background_color = (Color) { 0x18, 0x18, 0x18, 0xFF };

    SetTargetFPS(60);

    /* event loop */
    un_run_idle(ctx.loop, draw);
    un_run_idle(ctx.loop, update);

    un_loop_run(ctx.loop);
    un_loop_del(ctx.loop);

    ma_device_uninit(&ctx.mic.device);
    filedialog_deinit(&ctx.dialog);
    console_deinit();
    UnloadNuklear(ctx.ctx);
    CloseWindow();

    return 0;
}

static enum un_action draw(un_idle *task)
{
    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    BeginDrawing();

    Color inverted = {255, 255, 255, 255};
    inverted.r -= ctx.background_color.r;
    inverted.g -= ctx.background_color.g;
    inverted.b -= ctx.background_color.b;

    draw_grid(1, 60, inverted);

    ClearBackground(ctx.background_color);

    BeginMode2D(ctx.camera);

    layer_manager_draw_layers(&ctx.editor.layer_manager);

    EndMode2D();

    DrawNuklear(ctx.ctx);
    EndDrawing();

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

static enum un_action update(un_idle *task)
{
    bool ui_focused = false;
    struct nk_context *nk_ctx = ctx.ctx;

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    UpdateNuklear(nk_ctx);
    ctx.width = GetScreenWidth();
    ctx.height = GetScreenHeight();

    draw_menubar(&ui_focused);

    nk_end(nk_ctx);

    filedialog_run(&ctx.dialog, nk_ctx, &ui_focused);
    editor_draw(&ctx.editor, ctx.ctx, &ui_focused);

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    console_draw(nk_ctx, &ui_focused);

    if (!ctx.dialog.win.show) {
        if (ctx.dialog.selected_index != -1) {
            if (ctx.loading_state == SELECTING_IMAGE) {
                load_layer();
            }
        }
    }

    if (!ui_focused) {
        if (IsMouseButtonDown(MOUSE_BUTTON_MIDDLE)) {
            Vector2 delta = GetMouseDelta();
            delta = Vector2Scale(delta, -1.0f/ctx.camera.zoom);
            ctx.camera.target = Vector2Add(ctx.camera.target, delta);
        }

        float wheel = GetMouseWheelMove();
        if (wheel != 0) {
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), ctx.camera);
            ctx.camera.offset = GetMousePosition();
            ctx.camera.target = mouseWorldPos;

            float scaleFactor = 1.0f + (0.1f * fabsf(wheel));
            if (wheel < 0) scaleFactor = 1.0f / scaleFactor;
            ctx.camera.zoom = Clamp(ctx.camera.zoom * scaleFactor, 0.125f, 64.0f);
        }
    }

    /* check for pending work */
    if (ctx.image_work_queue != NULL && ctx.image_work_queue->ready) {
        struct image_load_req *work = ctx.image_work_queue;
        struct model_layer layer;
        LOG_I("Sending image \"%s\" to the GPU", work->name);
        layer.texture = LoadTextureFromImage(work->img);
        SetTextureFilter(layer.texture, TEXTURE_FILTER_BILINEAR);
        layer.name.len = strlen(work->name);
        layer.name.cleanup = false;
        layer.name.buffer = work->name;
        layer.rotation = 180.0f;
        layer.img = work->img;
        layer.frames_count = work->frames_count;
        LOG_I("Loaded layer \"%s\"", work->name);

        layer_manager_add_layer(&ctx.editor.layer_manager, &layer);

        /* cleanup */
        ctx.image_work_queue = work->next;
        ctx.loading_state = NOTHING;
        munmap(work->buffer, work->size);
        close(work->fd);
        free(work);
    }

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

static void draw_menubar(bool *ui_focused)
{
    struct nk_context *nk_ctx = ctx.ctx;

    if (nk_begin(nk_ctx, "Menu", nk_rect(0, 0, ctx.width, 25),
            NK_WINDOW_NO_SCROLLBAR)) {
        if (nk_input_is_mouse_hovering_rect(&nk_ctx->input, nk_window_get_bounds(nk_ctx)))
            *ui_focused = true;

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
                ctx.dialog.filter = image_filter;
                filedialog_refresh(&ctx.dialog);
                ctx.dialog.win.title = "Open Image File";
                filedialog_show(&ctx.dialog);
                
                ctx.loading_state = SELECTING_IMAGE;
            }

            nk_menu_end(nk_ctx);
        }

        nk_menubar_end(nk_ctx);
    }
}

static void load_layer()
{
    /* submit to queue */
    struct stat s;
    size_t sz = filedialog_selsz(&ctx.dialog);
    char buffer[sz + 1];
    memset(buffer, 0, sz + 1);
    filedialog_selected(&ctx.dialog, sz, buffer);

    if (stat(buffer, &s) == -1) {
        perror("stat");
        abort();
    }

    int fd = open(buffer, O_RDONLY);

    LOG_I("Preparing layer to be loaded", NULL);

    context_load_image(&ctx, strrchr(buffer, PATH_SEPARATOR) + 1, fd,
        s.st_size, load_layer_file, after_layer_loaded);
}

static void load_layer_file(uv_work_t *req)
{
    struct image_load_req *work = req->data;
    if (strcmp(work->ext, ".gif") == 0)
        work->img = LoadImageAnimFromMemory(work->ext, work->buffer,
            work->size, &work->frames_count);
    else
        work->img = LoadImageFromMemory(work->ext, work->buffer, work->size);
}

static void after_layer_loaded(uv_work_t *req, int status)
{
    struct image_load_req *work = req->data;
    work->ready = true;
    LOG_I("Image \"%s\" loaded, now to turn it into a layer", work->name);
}
