#include "archive.h"
#include "archive_entry.h"
#include "console.h"
#include "editor.h"
#include "gif_config.h"
#include "layermgr.h"
#include <fcntl.h>
#include <filedialog.h>
#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <raylib.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <pathbuf.h>
#include <nk.h>

#include <raylib-nuklear.h>
#include "line_edit.h"
#include "mask.h"
#include "raymath.h"
#include "rlgl.h"
#include <context.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <sys/mman.h>
#else
#include <mman.h>
#endif
#include <sys/stat.h>
#include <unistd.h>
#include <unuv.h>
#include <uv.h>

#define PATH_START "../"
#define DEFAULT_MULTIPLIER 2500
#define DEFAULT_TIMER_TTL 2000
#define DEFAULT_MASK (QUIET | TALK | PAUSE)

static char image_filter[] = "png;bmp;jpg;jpeg;gif";
struct context ctx = {0};

struct gif_progress {
    struct layer_manager *mgr;
    int i;
};

static enum un_action update(un_idle *task);
static enum un_action draw(un_idle *task);
static void draw_menubar(bool *ui_focused);
static void load_layer();
static void write_model();

/* to be replaced */
static void load_layer_file(uv_work_t *req);
static void after_layer_loaded(uv_work_t *req, int status);
static enum un_action update_gif(un_timer *timer);
static void set_key_mask(uint64_t *mask);
static void handle_key_mask(uint64_t *mask);


static void onAudioData(ma_device* device, void* output, const void* input, ma_uint32 frameCount) {
    struct microphone_data* data = device->pUserData;
    float* inputData = (float*)input;

    float sum = 0.0f;
    for (ma_uint32 i = 0; i < frameCount; i++) {
        sum += inputData[i] * inputData[i];
    }

    atomic_store(&data->volume, sqrtf(sum / frameCount) * atomic_load(&data->multiplier));
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
#ifdef _WIN32
    SetEnvironmentVariable("UV_THREADPOOL_SIZE", cpubuff);
#else
    setenv("UV_THREADPOOL_SIZE", cpubuff, 1);
#endif
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
    ctx.editor.mic = &ctx.mic;
    ctx.editor.microphone_trigger = 40;
    ctx.editor.timer_ttl = DEFAULT_TIMER_TTL;
    ctx.editor.layer_manager.mask |= QUIET;

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
    ctx.mic.multiplier = DEFAULT_MULTIPLIER;
    atomic_store(&ctx.mic.multiplier, DEFAULT_MULTIPLIER);
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

    ctx.editor.background_color = (Color) { 0x18, 0x18, 0x18, 0xFF };

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
    inverted.r -= ctx.editor.background_color.r;
    inverted.g -= ctx.editor.background_color.g;
    inverted.b -= ctx.editor.background_color.b;

    ClearBackground(ctx.editor.background_color);

    if (ctx.mode == EDIT_MODE)
        draw_grid(1, 60, inverted);

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
    handle_key_mask(&ctx.editor.layer_manager.mask);

    bool ui_focused = false;
    struct nk_context *nk_ctx = ctx.ctx;

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    UpdateNuklear(nk_ctx);
    ctx.width = GetScreenWidth();
    ctx.height = GetScreenHeight();

    set_key_mask(&ctx.editor.layer_manager.mask);

    if (!ctx.hide_ui)
        draw_menubar(&ui_focused);

    filedialog_run(&ctx.dialog, nk_ctx, &ui_focused);

    if (!ctx.hide_ui) {
        if (ctx.mode == EDIT_MODE)
            editor_draw(&ctx.editor, nk_ctx, &ui_focused);
        else
            editor_draw_stream(&ctx.editor, nk_ctx, &ui_focused);
    }

    editor_apply_mask(&ctx.editor);

    gif_configurator_draw(&ctx.gif_cfg, nk_ctx, &ui_focused);

    if (ctx.configuring_gif && !ctx.gif_cfg.win.show) {
        LOG_I("GIF Configured", NULL);
        /* reset state */
        ctx.configuring_gif = false;
        ctx.gif_cfg.global_delay = false;
        free(ctx.gif_cfg.lengths);
        ctx.gif_cfg.lengths = NULL;

        for (int i = 0; i < ctx.gif_cfg.layer->frames_count; i++)
            free(ctx.gif_cfg.inputs[i]);
        free(ctx.gif_cfg.inputs);
        ctx.gif_cfg.inputs = NULL;

        struct gif_progress *prog = calloc(1, sizeof(struct gif_progress));
        prog->i = ctx.editor.layer_manager.layer_count - 1;
        prog->mgr = &ctx.editor.layer_manager;

        un_timer *timer = un_timer_new(ctx.loop);
        un_timer_set_data(timer, prog);
        uint32_t delay = ctx.gif_cfg.layer->delays[0];
        un_timer_start(timer, delay, delay, update_gif);
        ctx.gif_cfg.layer = NULL;
    }

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    if (!ctx.hide_ui)
        console_draw(nk_ctx, &ui_focused);

    if (!ctx.dialog.win.show) {
        if (ctx.dialog.selected_index != -1) {
            if (ctx.loading_state == SELECTING_IMAGE) {
                load_layer();
            } else if (ctx.loading_state == WRITING_MODEL) {
                write_model();
            }
        }
    }

    if (!ui_focused) {
        if (IsKeyPressed(KEY_TAB)) {
            if (ctx.mode == EDIT_MODE) 
                ctx.mode = STREAM_MODE;
            else
                ctx.mode = EDIT_MODE;
        }

        if (IsKeyPressed(KEY_SPACE)) {
            ctx.hide_ui = !ctx.hide_ui;
        }

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
    if (ctx.image_work_queue != NULL && ctx.image_work_queue->ready &&
        !ctx.configuring_gif) {
        struct image_load_req *work = ctx.image_work_queue;
        struct model_layer layer = {0};
        LOG_I("Sending image \"%s\" to the GPU", work->name);
        layer.texture = LoadTextureFromImage(work->img);
        SetTextureFilter(layer.texture, TEXTURE_FILTER_BILINEAR);
        layer.name.len = strlen(work->name);
        layer.name.cleanup = false;
        layer.name.buffer = work->name;
        layer.rotation = 180.0f;
        layer.img = work->img;
        layer.frames_count = work->frames_count;
        layer.previous_frame = 0;
        layer.current_frame = 0;
        layer.mask = DEFAULT_MASK;
        layer.gif_buffer = work->gif_buffer;
        layer.gif_size = work->size;
        LOG_I("Loaded layer \"%s\"", work->name);

        struct model_layer *l = layer_manager_add_layer(&ctx.editor.layer_manager, &layer);

        if (layer.frames_count > 0) {
            ctx.configuring_gif = true;
            ctx.gif_cfg.layer = l;
            ctx.gif_cfg.inputs = calloc(layer.frames_count, sizeof(char*));
            ctx.gif_cfg.lengths = calloc(layer.frames_count, sizeof(int));
            /* 4294967295 - 10 characters + 2 backup */
            for (int i = 0; i < layer.frames_count; i++)
                ctx.gif_cfg.inputs[i] = calloc(12, sizeof(char));

            ctx.gif_cfg.layer->delays = calloc(layer.frames_count,
                sizeof(uint32_t));

            ctx.gif_cfg.win.show = true;
        }

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
            if (nk_menu_item_label(nk_ctx, "Save As", NK_TEXT_LEFT)) {
                ctx.dialog.open_for_write = true;
                ctx.dialog.filter = NULL;
                filedialog_refresh(&ctx.dialog);
                ctx.dialog.win.title = "Save Model As";
                filedialog_show(&ctx.dialog);

                ctx.loading_state = WRITING_MODEL;
            }

            if (ctx.mode == EDIT_MODE) {
                nk_layout_row_dynamic(nk_ctx, 2, 1);
                nk_rule_horizontal(nk_ctx, nk_ctx->style.window.border_color,
                    false);
                nk_layout_row_dynamic(nk_ctx, 25, 1);

                if (nk_menu_item_label(nk_ctx, "Load Image", NK_TEXT_LEFT)) {
                    ctx.dialog.open_for_write = false;
                    ctx.dialog.filter = image_filter;
                    filedialog_refresh(&ctx.dialog);
                    ctx.dialog.win.title = "Open Image File";
                    filedialog_show(&ctx.dialog);
                    
                    ctx.loading_state = SELECTING_IMAGE;
                }
            }

            nk_menu_end(nk_ctx);
        }

        nk_menubar_end(nk_ctx);
    }

    nk_end(nk_ctx);
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

static void write_model()
{
    if (ctx.dialog.selected_index == -2) {
        path_append_file(&ctx.dialog.current_directory,
            strdup(ctx.dialog.file_out_name.buffer));
        size_t sz = path_bufsz(&ctx.dialog.current_directory);
        char tmpbuf[sz + 1];
        memset(tmpbuf, 0, sz + 1);
        path_str(&ctx.dialog.current_directory, sz, tmpbuf);

#ifdef _WIN32
        *tmpbuf = ctx.dialog.current_drive_letter;
#endif
        filedialog_up(&ctx.dialog);
        struct archive *a = archive_write_new();
        struct archive_entry *en = archive_entry_new();

        archive_write_add_filter_zstd(a);
        archive_write_set_format_pax_restricted(a);
        archive_write_open_filename(a, tmpbuf);

        /* write */
        char *out = editor_tomlify(&ctx.editor);
        int str_len = strlen(out);
        archive_entry_set_pathname(en, "manifest.toml");
        archive_entry_set_size(en, str_len);
        archive_entry_set_filetype(en, AE_IFREG);
        archive_entry_set_perm(en, 0644);
        archive_write_header(a, en);
        archive_write_data(a, out, str_len);
        archive_entry_free(en);

        free(out);

        en = archive_entry_new();
        archive_entry_set_pathname(en, "layers");
        archive_entry_set_filetype(en, AE_IFDIR);
        archive_entry_set_perm(en, 0755);
        archive_write_header(a, en);
        archive_entry_free(en);

        for (int i = 0; i < ctx.editor.layer_manager.layer_count; i++) {
            struct model_layer *layer = ctx.editor.layer_manager.layers + i;
            {
                out = layer_tomlify(layer);
                str_len = strlen(out);
                int file_len = snprintf(NULL, 0, "layers/%s-%d.toml",
                        layer->name.buffer, i + 1);
                char name[file_len + 1];
                memset(name, 0, file_len + 1);
                snprintf(name, file_len + 1, "layers/%s-%d.toml",
                        layer->name.buffer, i + 1);

                en = archive_entry_new();
                archive_entry_set_pathname(en, name);
                archive_entry_set_size(en, str_len);
                archive_entry_set_filetype(en, AE_IFREG);
                archive_entry_set_perm(en, 0644);
                archive_write_header(a, en);
                archive_write_data(a, out, str_len);
                archive_write_finish_entry(a);
                archive_entry_free(en);

                free(out);
            }

            if (layer->frames_count == 0) {
                int file_len = snprintf(NULL, 0, "layers/%s-%d.png",
                        layer->name.buffer, i + 1);
                char name[file_len + 1];
                memset(name, 0, file_len + 1);
                snprintf(name, file_len + 1, "layers/%s-%d.png",
                        layer->name.buffer, i + 1);

                int filesize;
                uint8_t *exported = ExportImageToMemory(layer->img, ".png",
                    &filesize);

                en = archive_entry_new();
                archive_entry_set_pathname(en, name);
                archive_entry_set_filetype(en, AE_IFREG);
                archive_entry_set_size(en, filesize);
                archive_entry_set_perm(en, 0644);
                archive_write_header(a, en);
                archive_write_data(a, exported, filesize);
                archive_write_finish_entry(a);
                archive_entry_free(en);

                free(exported);
            } else {
                int file_len = snprintf(NULL, 0, "layers/%s-%d.gif",
                        layer->name.buffer, i + 1);
                char name[file_len + 1];
                memset(name, 0, file_len + 1);
                snprintf(name, file_len + 1, "layers/%s-%d.gif",
                        layer->name.buffer, i + 1);

                en = archive_entry_new();
                archive_entry_set_pathname(en, name);
                archive_entry_set_filetype(en, AE_IFREG);
                archive_entry_set_size(en, layer->gif_size);
                archive_entry_set_perm(en, 0644);
                archive_write_header(a, en);
                archive_write_data(a, layer->gif_buffer, layer->gif_size);
                archive_write_finish_entry(a);
                archive_entry_free(en);
            }
        }

        archive_write_close(a);
        archive_write_free(a);

        ctx.dialog.file_out_name.cleanup = true;
    } else {
        LOG_E("Selection not yet implemented!", 0);
    }
}

static void load_layer_file(uv_work_t *req)
{
    struct image_load_req *work = req->data;
    if (strcmp(work->ext, ".gif") == 0) {
        work->img = LoadImageAnimFromMemory(work->ext, work->buffer,
            work->size, &work->frames_count);
        memcpy(work->gif_buffer, work->buffer, work->size);
    }
    else
        work->img = LoadImageFromMemory(work->ext, work->buffer, work->size);
}

static void after_layer_loaded(uv_work_t *req, int status)
{
    struct image_load_req *work = req->data;
    work->ready = true;
    LOG_I("Image \"%s\" loaded, now to turn it into a layer", work->name);
}

static enum un_action update_gif(un_timer *timer)
{
    struct gif_progress *prog = un_timer_get_data(timer);
    struct model_layer *layer = prog->mgr->layers + prog->i;

    layer->previous_frame = layer->current_frame;
    un_timer_set_repeat(timer, layer->delays[layer->current_frame]);
    layer->current_frame = (layer->current_frame + 1) % layer->frames_count;

    return REARM;
}

static void set_key_mask(uint64_t *mask)
{
    int key = GetKeyPressed();
    if (key >= 'A' && key <= 'Z')
        *mask |= 1ULL << (key - 'A' + KEY_START);

    if (IsKeyPressed(KEY_LEFT_SHIFT) || IsKeyPressed(KEY_RIGHT_SHIFT))
        *mask |= SHIFT;

    if (IsKeyPressed(KEY_LEFT_CONTROL) || IsKeyPressed(KEY_RIGHT_CONTROL))
        *mask |= CTRL;

    if (IsKeyPressed(KEY_LEFT_SUPER) || IsKeyPressed(KEY_RIGHT_SUPER))
        *mask |= SUPER;

    if (IsKeyPressed(KEY_LEFT_ALT) || IsKeyPressed(KEY_RIGHT_ALT))
        *mask |= META;
}

static void handle_key_mask(uint64_t *mask)
{
    uint64_t m = *mask;
    uint64_t new_mask = 0;

    for (int i = 0; i <= 26; i++) {
        uint64_t bit = (1ULL << (i + KEY_START));
        if (m & bit) {
            if (IsKeyDown(i + 'A'))
                new_mask |= bit;
        }
    }

    if (IsKeyDown(KEY_LEFT_SHIFT) || IsKeyDown(KEY_RIGHT_SHIFT))
        new_mask |= SHIFT;

    if (IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_RIGHT_CONTROL))
        new_mask |= CTRL;

    if (IsKeyDown(KEY_LEFT_SUPER) || IsKeyDown(KEY_RIGHT_SUPER))
        new_mask |= SUPER;

    if (IsKeyDown(KEY_LEFT_ALT) || IsKeyDown(KEY_RIGHT_ALT))
        new_mask |= META;

    for (int i = 0; i < 3; i++)
        new_mask |= 1ULL << i;

    *mask &= new_mask;
}
