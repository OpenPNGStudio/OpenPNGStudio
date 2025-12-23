/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include "console.h"
#include "editor.h"
#include <fcntl.h>
#include <sys/types.h>
#include <raylib.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <core/nk.h>
#include <core/icon_db.h>

#include <raylib-nuklear.h>
#include <ui/line_edit.h>
#include <core/mask.h>
#include <raymath.h>
#include <rlgl.h>
#include <context.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <unistd.h>
#include <sys/mman.h>
#else
#include <mman.h>
#endif
#include <sys/stat.h>
#include <unuv.h>
#include <uv.h>
#include <ui/filedialog.h>
#if 0
#include <lua_ctx.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#endif

#ifndef NDEBUG
#define PATH_START "../"
#else
#define PATH_START "./"
#endif
#define DEFAULT_MULTIPLIER 2500
#define DEFAULT_TIMER_TTL 2000
#define DEFAULT_MASK (QUIET | TALK | PAUSE)

#define TOML_ERR_LEN UINT8_MAX

static const char *fdialog_open_filter = "qoi;png;bmp;jpg;jpeg;tga;psd;dds;gif;opng";

static char image_filter[] = "png;bmp;jpg;jpeg;gif;";
static char script_filter[] = "lua;";
static char model_filter[] = "opng;";
struct context ctx = {0};
void *c_ctx = &ctx;

static enum un_action c_update(un_idle *task);
static enum un_action draw(un_idle *task);
static void draw_menubar(bool *ui_focused);

static void load_layer();
static void write_model();
static void load_model();

static void load_script();

static void action(void *ctx);

/* to be replaced */
static void load_layer_file(uv_work_t *req);
static void after_layer_loaded(uv_work_t *req, int status);
static void load_script_file(uv_work_t *req);
static void after_script_loaded(uv_work_t *req, int status);

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

void opng_style_apply(struct nk_context *ctx);

void update(void *c3_ctx, bool ui_on);
void quit_openpngstudio();
void c3_nk(void *c3_ctx, struct nk_context *nk_ctx);

int c_main(void *c3_ctx)
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

    console_init();

    LOG_I("Using %d threads", uv_available_parallelism());

    ctx.camera.zoom = 1.0f;
    ctx.editor.mic = &ctx.mic;
    ctx.editor.microphone_trigger = 40;
    ctx.editor.timer_ttl = DEFAULT_TIMER_TTL;
    ctx.mask |= QUIET;
    ctx.c3_ctx = c3_ctx;

    /* scheduler */
    ctx.sched.loop = ctx.loop;

    int flags = FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT;

#ifndef _WIN32
    const char *desktop = NULL;

    if (getenv("ENABLE_DECORATIONS") == NULL &&
        (desktop = getenv("XDG_CURRENT_DESKTOP")) != NULL &&
        strcasecmp(desktop, "gnome") == 0) {
        flags |= FLAG_WINDOW_UNDECORATED;
        LOG_W("This app is not fully supported on this desktop", 0);
        LOG_W("Enable decorations by setting ENABLE_DECORATIONS env", 0);
    }
#endif

    SetConfigFlags(flags);
    InitWindow(1024, 640, "OpenPNGStudio");

    SetExitKey(KEY_NULL);
    Font font = LoadFont(PATH_START "assets/fonts/VarelaRound-Regular.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_BILINEAR);

    register_icon(UP_ICON, LoadNuklearImage(PATH_START "assets/icons/up.png"));
    register_icon(DOWN_ICON,
        LoadNuklearImage(PATH_START "assets/icons/down.png"));
    register_icon(LEFT_ICON,
        LoadNuklearImage(PATH_START "assets/icons/back.png"));
    register_icon(RIGHT_ICON,
        LoadNuklearImage(PATH_START "assets/icons/forward.png"));
    register_icon(LOOP_ICON,
        LoadNuklearImage(PATH_START "assets/icons/loop.png"));
    register_icon(TRASH_ICON,
        LoadNuklearImage(PATH_START "assets/icons/trash.png"));
    register_icon(SELECT_ICON,
        LoadNuklearImage(PATH_START "assets/icons/select.png"));
    register_icon(CFG_ICON,
        LoadNuklearImage(PATH_START "assets/icons/cfg.png"));
    register_icon(CANCEL_ICON,
        LoadNuklearImage(PATH_START "assets/icons/cancel.png"));
    register_icon(CHECK_ICON,
        LoadNuklearImage(PATH_START "assets/icons/check.png"));
    register_icon(MINIMIZE_ICON,
        LoadNuklearImage(PATH_START "assets/icons/minimize.png"));
    register_icon(MAXIMIZE_ICON,
        LoadNuklearImage(PATH_START "assets/icons/maximize.png"));
    register_icon(OPEN_ICON,
        LoadNuklearImage(PATH_START "assets/icons/open.png"));
    register_icon(SAVE_ICON,
        LoadNuklearImage(PATH_START "assets/icons/save.png"));
    register_icon(SAVE_AS_ICON,
        LoadNuklearImage(PATH_START "assets/icons/save-as.png"));
    register_icon(LAYERS_ICON,
        LoadNuklearImage(PATH_START "assets/icons/layers.png"));
    register_icon(SHORTCUTS_ICON,
        LoadNuklearImage(PATH_START "assets/icons/shortcuts.png"));
    register_icon(HELP_ICON,
        LoadNuklearImage(PATH_START "assets/icons/help.png"));
    register_icon(QUIT_ICON,
        LoadNuklearImage(PATH_START "assets/icons/stop.png"));

    register_icon(DIR_ICON,
        LoadNuklearImage(PATH_START "assets/images/dir.png"));
    register_icon(FILE_ICON,
        LoadNuklearImage(PATH_START "assets/images/file.png"));
    register_icon(DRIVE_ICON,
        LoadNuklearImage(PATH_START "assets/images/drive.png"));

    ctx.ctx = InitNuklearEx(font, 18);
    set_nk_font(font);
    opng_style_apply(ctx.ctx);

    c3_nk(c3_ctx, ctx.ctx);

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

    /* LUA */
#if 0
    context_init_lua(&ctx);

    lua_getglobal(ctx.L, "package");
    lua_getfield(ctx.L, -1, "searchers");
    const size_t length = lua_rawlen(ctx.L, -1);
    lua_pushcfunction(ctx.L, lua_script_loader);
    lua_rawseti(ctx.L, -2, length + 1);
    lua_pop(ctx.L, 2);

    expand_import_path(ctx.L, ";" PATH_START "lua/?/init.lua");
    expand_import_path(ctx.L, ";" PATH_START "lua/?/init.so");
    expand_import_path(ctx.L, ";" PATH_START "lua/?/init.dll");
    bind_logger_functions(ctx.L);
    lua_register(ctx.L, LUA_PRIV_PREFIX "script_load_req",
        lua_script_load_req);

    if (luaL_dofile(ctx.L, PATH_START "lua/rt.lua")) {
        LOG_E("Lua error: %s", lua_tostring(ctx.L, -1));
        lua_pop(ctx.L, 1);
    } else
        LOG_I("Lua runtime loaded successfuly!", 0);
#endif
    ctx.editor.background_color = (Color) { 0x88, 0x88, 0x88, 0xFF };

    SetTargetFPS(60);

    /* event loop */
    un_run_idle(ctx.loop, draw);
    un_run_idle(ctx.loop, c_update);

    un_loop_run(ctx.loop);
    un_loop_del(ctx.loop);

    cleanup_icons();
    ma_device_uninit(&ctx.mic.device);
    console_deinit();
    UnloadNuklear(ctx.ctx);
    CloseWindow();

    return 0;
}

void quit_openpngstudio()
{
    uv_stop((uv_loop_t*) ctx.loop);
}
    
void layer_manager_render(void *c3_ctx, un_loop *loop);

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
    if (ctx.c3_ctx != NULL) layer_manager_render(ctx.c3_ctx, ctx.loop);
    EndMode2D();

    DrawNuklear(ctx.ctx);
    EndDrawing();

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

void draw_props(struct layer_manager *mgr, struct nk_context *ctx, bool *ui_focused);

static enum un_action c_update(un_idle *task)
{
    mask_t mask = get_current_mask();
    handle_key_mask(&mask);
    bool ui_focused = false;
    struct nk_context *nk_ctx = ctx.ctx;

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    UpdateNuklear(nk_ctx);
    ctx.width = GetScreenWidth();
    ctx.height = GetScreenHeight();

    if (IsKeyPressed(KEY_TAB)) {
        if (ctx.mode == EDIT_MODE) 
            ctx.mode = STREAM_MODE;
        else
            ctx.mode = EDIT_MODE;
    }

    set_key_mask(&mask);
    set_current_mask(mask);

    if (!ctx.hide_ui) {
        if (ctx.mode == EDIT_MODE)
            editor_draw(&ctx.editor, nk_ctx, &ui_focused);
        else
            editor_draw_stream(&ctx.editor, nk_ctx, &ui_focused);

        // if (ctx.editor.layer_manager->anims != NULL)
        //     animation_manager_global_anim(ctx.editor.layer_manager->anims,
        //         nk_ctx);
    }

    update(ctx.c3_ctx, ctx.hide_ui);

    editor_apply_mask(&ctx.editor);

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    if (!ctx.hide_ui) {
        console_draw(nk_ctx, &ui_focused);
        context_about(&ctx, nk_ctx);
        context_keybindings(&ctx, nk_ctx);
    }

    context_welcome(&ctx, nk_ctx);

    if (!ui_focused) {
        if (IsKeyPressed(KEY_SPACE)) {
            ctx.hide_ui = !ctx.hide_ui;
        }

        if (IsMouseButtonDown(MOUSE_BUTTON_MIDDLE)) {
            Vector2 delta = GetMouseDelta();
            delta = Vector2Scale(delta, -1.0f/ctx.camera.zoom);
            ctx.camera.target = Vector2Add(ctx.camera.target, delta);
        }

        float wheel = GetMouseWheelMove();
        static float target_zoom = 1.0;
        if (wheel != 0) {
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), ctx.camera);
            ctx.camera.offset = GetMousePosition();
            ctx.camera.target = mouseWorldPos;

            float scaleFactor = 1.0f + (0.1f * fabsf(wheel));
            if (wheel < 0) scaleFactor = 1.0f / scaleFactor;
            target_zoom = Clamp(ctx.camera.zoom * scaleFactor, 0.125f, 4.0f);
        }

        ctx.camera.zoom = Lerp(ctx.camera.zoom, target_zoom, 0.35f);
    }

    work_scheduler_run(&ctx.sched);

    /* execute lua once */
#if 0
    lua_getglobal(ctx.L, LUA_PRIV_PREFIX "rt_spin_once");

    if (lua_isfunction(ctx.L, -1)) {
        if (lua_pcall(ctx.L, 0, 0, 0) != LUA_OK) {
            LOG_E("Something went wrong: %s", lua_tostring(ctx.L, -1));
            lua_pop(ctx.L, 1);
        }
    } else {
        LOG_E("Something happened with %s! Abort!", LUA_PRIV_PREFIX "rt_spin_once");
        abort();
    }
#endif

    /* check for pending work */
    if (ctx.image_work_queue != NULL && ctx.image_work_queue->ready)
        context_after_img_load(&ctx, ctx.image_work_queue);
#if 0
    if (ctx.script_work_queue != NULL && ctx.script_work_queue->ready) {
        struct script_load_req *work = ctx.script_work_queue;
        struct lua_script script = {0};
        script.name.len = strlen(work->name);
        script.name.cleanup = false;
        script.name.buffer = work->name;
        script.buffer_size = work->size;
        script.buffer = (char*) work->buffer;
        script.is_mmapped = work->is_mmapped;
        LOG_I("Loaded script \"%s\"", work->name);

        script_manager_add_script(&ctx.editor.script_manager, &script);

        /* cleanup */
        ctx.script_work_queue = work->next;
        ctx.loading_state = NOTHING;
        close(work->fd);
        free(work);
    }
#endif

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

// static void draw_menubar(bool *ui_focused)
// {
//     struct nk_context *nk_ctx = ctx.ctx;
//
//     if (nk_begin(nk_ctx, "Menu", nk_rect(0, 0, ctx.width, 25),
//             NK_WINDOW_NO_SCROLLBAR)) {
//         if (nk_input_is_mouse_hovering_rect(&nk_ctx->input, nk_window_get_bounds(nk_ctx)))
//             *ui_focused = true;
//
//         nk_menubar_begin(nk_ctx);
//
//         nk_layout_row_static(nk_ctx, 20, 40, 2);
//
//                 if (nk_menu_item_label(nk_ctx, "Quit", NK_TEXT_LEFT)) {
//                     uv_stop((void*) ctx.loop);
//                 }
//             }
//
//             nk_menu_end(nk_ctx);
//         }
//
//         if (nk_menu_begin_label(nk_ctx, "Help", NK_TEXT_LEFT, nk_vec2(200, 200))) {
//             nk_layout_row_dynamic(nk_ctx, 25, 1);
//             if (nk_menu_item_label(nk_ctx, "Keybindings", NK_TEXT_LEFT))
//                 ctx.keybindings_win.show = true;
//
//             if (nk_menu_item_label(nk_ctx, "About", NK_TEXT_LEFT))
//                 ctx.about_win.show = true;
//
//             nk_menu_end(nk_ctx);
//         }
//
//         nk_menubar_end(nk_ctx);
//     }
//
//     nk_end(nk_ctx);
// }

void c_load_layer(char *path)
{
    /* submit to queue */
    struct stat s;

    if (stat(path, &s) == -1) {
        perror("stat");
        abort();
    }

    int fd = open(path, O_RDONLY);

    LOG_I("Preparing layer to be loaded", NULL);

    context_load_image(&ctx, strrchr(path, PATH_SEPARATOR) + 1, fd,
        s.st_size, load_layer_file, after_layer_loaded);
}

static void load_model()
{
    // char **selection = fdialog_get_selection(ctx.fdialog);
    // char *buffer = selection[0];
    //
    // model_load(ctx.loop, &ctx.model, buffer);
}

static void load_script()
{
    // /* submit to queue */
    // struct stat s;
    // char **selection = fdialog_get_selection(ctx.fdialog);
    // char *buffer = selection[0];
    //
    // if (stat(buffer, &s) == -1) {
    //     perror("stat");
    //     abort();
    // }
    //
    // int fd = open(buffer, O_RDONLY);
    //
    // LOG_I("Preparing script of size %ld to be loaded", s.st_size);
    //
    // context_load_script(&ctx, strrchr(buffer, PATH_SEPARATOR) + 1, fd,
    //     s.st_size, load_script_file, after_script_loaded);
}

static void load_layer_file(uv_work_t *req)
{
    struct image_load_req *work = req->data;
    if (strcmp(work->ext, ".gif") == 0) {
        work->img = LoadImageAnimFromMemory(work->ext, work->buffer,
            work->size, &work->frames_count, &work->delays);
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

static void load_script_file(uv_work_t *req)
{
    struct script_load_req *work = req->data;
    if (!work->is_mmapped)
        read(work->fd, work->buffer, work->size);
}

static void after_script_loaded(uv_work_t *req, int status)
{
    struct script_load_req *work = req->data;
    work->ready = true;
    LOG_I("Script \"%s\" loaded, now to hook it up", work->name);
}

un_loop *get_loop()
{
    return ctx.loop;
}
