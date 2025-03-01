/*
 * This file is part of OpenPNGStudio. 
 * Copyright (C) 2024-2025 LowByteFox
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include "archive.h"
#include "archive_entry.h"
#include "console.h"
#include "editor.h"
#include "gif_config.h"
#include <layer/manager.h>
#include "toml.h"
#include <fcntl.h>
#include <ui/filedialog.h>
#include <sys/types.h>
#include <raylib.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <core/pathbuf.h>
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
#include <model/model.h>
#ifndef _WIN32
#include <sys/mman.h>
#else
#include <mman.h>
#endif
#include <sys/stat.h>
#include <unistd.h>
#include <unuv.h>
#include <uv.h>
#include <lua_ctx.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#ifndef NDEBUG
#define PATH_START "../"
#else
#define PATH_START "./"
#endif
#define DEFAULT_MULTIPLIER 2500
#define DEFAULT_TIMER_TTL 2000
#define DEFAULT_MASK (QUIET | TALK | PAUSE)

#define TOML_ERR_LEN UINT8_MAX

static char image_filter[] = "png;bmp;jpg;jpeg;gif;";
static char script_filter[] = "lua;";
static char model_filter[] = "opng;";
struct context ctx = {0};

struct layer_table {
    /* metadata */
    char *name;
    char *buffer; /* used for layer info toml file */
    size_t index;
    bool is_animated;

    /* held image */
    uint8_t *image_buffer;
    size_t image_size;

    struct layer_table *next;
};

struct manifest {
    size_t layer_count;
    size_t microphone_trigger;
    int microphone_sensitivity;
    int bg_color;
    struct layer_table *table;
};

static enum un_action update(un_idle *task);
static enum un_action draw(un_idle *task);
static void draw_menubar(bool *ui_focused);

static void load_layer();
static void write_model();
static void load_model();

static void load_script();
static int manifest_load_layers(toml_table_t *conf, struct manifest *manifest);
static struct layer_table *manifest_find_layer(struct manifest *manifest,
    const char *filename);
static void manifest_scaffold(struct manifest *manifest);
static void table_configure_layer(struct layer_table *table,
    struct layer *layer);

/* to be replaced */
static void load_layer_file(uv_work_t *req);
static void after_layer_loaded(uv_work_t *req, int status);
static void load_script_file(uv_work_t *req);
static void after_script_loaded(uv_work_t *req, int status);
static enum un_action update_gif(un_timer *timer);


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
    ctx.editor.layer_manager.selected_layer = -1;
    ctx.editor.mic = &ctx.mic;
    ctx.editor.microphone_trigger = 40;
    ctx.editor.timer_ttl = DEFAULT_TIMER_TTL;
    ctx.mask |= QUIET;
    ctx.welcome_win.show = true;

    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT | FLAG_VSYNC_HINT);
    InitWindow(1024, 640, "OpenPNGStudio");

    SetExitKey(KEY_NULL);
    Font font = LoadFont(PATH_START "assets/fonts/Ubuntu-R.ttf");
    SetTextureFilter(font.texture, TEXTURE_FILTER_TRILINEAR);

    register_icon(UP_ICON, LoadNuklearImage(PATH_START "assets/icons/up.png"));
    register_icon(DOWN_ICON,
        LoadNuklearImage(PATH_START "assets/icons/down.png"));
    register_icon(BACK_ICON,
        LoadNuklearImage(PATH_START "assets/icons/back.png"));
    register_icon(LOOP_ICON,
        LoadNuklearImage(PATH_START "assets/icons/loop.png"));
    register_icon(TRASH_ICON,
        LoadNuklearImage(PATH_START "assets/icons/trash.png"));
    register_icon(SELECT_ICON,
        LoadNuklearImage(PATH_START "assets/icons/select.png"));

    register_icon(DIR_ICON,
        LoadNuklearImage(PATH_START "assets/images/dir.png"));
    register_icon(FILE_ICON,
        LoadNuklearImage(PATH_START "assets/images/file.png"));
    register_icon(DRIVE_ICON,
        LoadNuklearImage(PATH_START "assets/images/drive.png"));

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

    /* LUA */
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

    ctx.editor.background_color = (Color) { 0x18, 0x18, 0x18, 0xFF };

    SetTargetFPS(60);

    /* event loop */
    un_run_idle(ctx.loop, draw);
    un_run_idle(ctx.loop, update);

    un_loop_run(ctx.loop);
    un_loop_del(ctx.loop);

    cleanup_icons();
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

    layer_manager_render(&ctx.editor.layer_manager);

    EndMode2D();

    DrawNuklear(ctx.ctx);
    EndDrawing();

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

static enum un_action update(un_idle *task)
{
    handle_key_mask(&ctx.mask);

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

    set_key_mask(&ctx.mask);

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

        for (int i = 0; i < ctx.gif_cfg.layer->properties.number_of_frames; i++)
            free(ctx.gif_cfg.inputs[i]);
        free(ctx.gif_cfg.inputs);
        ctx.gif_cfg.inputs = NULL;

        int i = ctx.editor.layer_manager.layer_count - 1;

        un_timer *timer = un_timer_new(ctx.loop);
        un_timer_set_data(timer, ctx.editor.layer_manager.layers[i]);
        uint32_t delay = ctx.gif_cfg.layer->properties.frame_delays[0];
        un_timer_start(timer, delay, delay, update_gif);
        ctx.gif_cfg.layer = NULL;
    }

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    if (!ctx.hide_ui) {
        console_draw(nk_ctx, &ui_focused);
        context_about(&ctx, nk_ctx);
        context_keybindings(&ctx, nk_ctx);
    }

    context_welcome(&ctx, nk_ctx);

    if (!ctx.dialog.win.show) {
        if (ctx.dialog.selected_index != -1) {
            if (ctx.loading_state == SELECTING_IMAGE) {
                load_layer();
            } else if (ctx.loading_state == WRITING_MODEL) {
                write_model();
            } else if (ctx.loading_state == LOADING_MODEL) {
                load_model();
            } else if (ctx.loading_state == SELECTING_SCRIPT) {
                load_script();
            }else {
                LOG_W("Unknown state %d", ctx.loading_state);
                ctx.loading_state = NOTHING;
            }
        }
    }

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
        if (wheel != 0) {
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), ctx.camera);
            ctx.camera.offset = GetMousePosition();
            ctx.camera.target = mouseWorldPos;

            float scaleFactor = 1.0f + (0.1f * fabsf(wheel));
            if (wheel < 0) scaleFactor = 1.0f / scaleFactor;
            ctx.camera.zoom = Clamp(ctx.camera.zoom * scaleFactor, 0.125f, 64.0f);
        }
    }

    /* execute lua once */
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

    /* check for pending work */
    if (ctx.image_work_queue != NULL && ctx.image_work_queue->ready &&
        !ctx.configuring_gif)
        context_after_img_load(&ctx, ctx.image_work_queue);

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

        nk_layout_row_static(nk_ctx, 20, 40, 2);

        if (nk_menu_begin_label(nk_ctx, "File", NK_TEXT_LEFT, nk_vec2(200, 200))) {
            nk_layout_row_dynamic(nk_ctx, 25, 1);
            if (nk_menu_item_label(nk_ctx, "Open", NK_TEXT_LEFT)) {
                ctx.dialog.open_for_write = false;
                ctx.dialog.filter = model_filter;
                filedialog_refresh(&ctx.dialog);
                ctx.dialog.win.title = "Load Model";
                filedialog_show(&ctx.dialog);

                ctx.loading_state = LOADING_MODEL;
            }

            if (nk_menu_item_label(nk_ctx, "Save", NK_TEXT_LEFT))
                LOG_W("I don't do anything yet", 0);

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

                if (nk_menu_item_label(nk_ctx, "Load Script", NK_TEXT_LEFT)) {
                    if (ctx.editor.script_manager.to_import == NULL) {
                        ctx.dialog.open_for_write = false;
                        ctx.dialog.filter = script_filter;
                        filedialog_refresh(&ctx.dialog);
                        ctx.dialog.win.title = "Open Script";
                        filedialog_show(&ctx.dialog);
                        
                        ctx.loading_state = SELECTING_SCRIPT;
                    } else {
                        LOG_W("Script is being loaded!", 0);
                    }
                }
            }

            nk_menu_end(nk_ctx);
        }

        if (nk_menu_begin_label(nk_ctx, "Help", NK_TEXT_LEFT, nk_vec2(200, 200))) {
            nk_layout_row_dynamic(nk_ctx, 25, 1);
            if (nk_menu_item_label(nk_ctx, "Keybindings", NK_TEXT_LEFT))
                ctx.keybindings_win.show = true;

            if (nk_menu_item_label(nk_ctx, "About", NK_TEXT_LEFT))
                ctx.about_win.show = true;

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

static void load_model()
{
    struct stat s;
    size_t sz = filedialog_selsz(&ctx.dialog);
    char buffer[sz + 1];
    char errbuf[TOML_ERR_LEN];

    memset(buffer, 0, sz + 1);
    filedialog_selected(&ctx.dialog, sz, buffer);
    model_load(&ctx.model, buffer);
}

static void manifest_scaffold(struct manifest *manifest)
{
    LOG_I("Configuring model", 0);

    ctx.editor.microphone_trigger = manifest->microphone_trigger;
    atomic_store(&ctx.mic.multiplier, manifest->microphone_sensitivity);
    LOG_I("Microphone configured", 0);

    ctx.editor.background_color.r = (manifest->bg_color >> 16) & 0xFF;
    ctx.editor.background_color.g = (manifest->bg_color >> 8) & 0xFF;
    ctx.editor.background_color.b = manifest->bg_color & 0xFF;
    LOG_I("Background configured", 0);

    struct model_layer **layers = calloc(manifest->layer_count,
        sizeof(struct model_layer*));

    for (int i = 0; i < manifest->layer_count; i++)
        layers[i] = calloc(1, sizeof(struct model_layer));

    int i = 0;
    struct layer_table *lazy = manifest->table;
    while (lazy) {
        struct model_layer *layer = layers[i];
        table_configure_layer(lazy, layer);

        if (lazy->is_animated) {
            un_timer *timer = un_timer_new(ctx.loop);
            un_timer_set_data(timer, layer);
            uint32_t delay = layer->delays[0];
            un_timer_start(timer, delay, delay, update_gif);
        }

        lazy = lazy->next;
        i++;
    }

    ctx.editor.layer_manager.layers = layers;
    ctx.editor.layer_manager.layer_count = manifest->layer_count;
    LOG_I("Layers configured", 0);
    LOG_I("Model has been loaded!", 0);
}

/* FIX: Handle failure instead of abort */
static void table_configure_layer(struct layer_table *table,
    struct model_layer *layer)
{
    char errbuf[TOML_ERR_LEN];

    toml_table_t *conf = toml_parse(table->buffer, errbuf, TOML_ERR_LEN);
    if (conf == NULL) {
        LOG_E("Unable to parse layer metadata: %s!", errbuf);
        abort();
    }

    toml_table_t *lay = toml_table_in(conf, "layer");
    if (lay == NULL) {
        LOG_E("Unable to find table [layer] in metadata: %s!", errbuf);
        abort();
    }

    toml_table_t *offset = toml_table_in(lay, "offset");
    if (offset == NULL) {
        LOG_E("Unable to find table offset in layer: %s!", errbuf);
        abort();
    }

    toml_datum_t off_x = toml_double_in(offset, "x");
    if (!off_x.ok) {
        LOG_E("Unable to get x offset: %s!", errbuf);
        abort();
    }
    layer->position_offset.x = off_x.u.d;

    toml_datum_t off_y = toml_double_in(offset, "y");
    if (!off_y.ok) {
        LOG_E("Unable to get y offset: %s!", errbuf);
        abort();
    }
    layer->position_offset.y = off_y.u.d;

    toml_datum_t rotation = toml_double_in(lay, "rotation");
    if (!rotation.ok) {
        LOG_E("Unable to get layer rotation: %s!", errbuf);
        abort();
    }
    layer->rotation = rotation.u.d;

    toml_datum_t mask = toml_int_in(lay, "mask");
    if (!mask.ok) {
        LOG_E("Unable to get layer mask: %s!", errbuf);
        abort();
    }
    layer->mask = mask.u.i;

    for (int i = 0; i <= 26; i++) {
        uint64_t mask = 1ULL << (i + KEY_START);
        if (layer->mask & mask) {
            layer->input_key[0] = 'A' + i;
            layer->input_len = 1;
            break;
        }
    }

    toml_datum_t ttl = toml_int_in(lay, "ttl");
    if (!ttl.ok) {
        LOG_E("Unable to get time to live: %s!", errbuf);
        abort();
    }
    layer->ttl = ttl.u.i;

    toml_datum_t has_toggle = toml_bool_in(lay, "has_toggle");
    if (!has_toggle.ok) {
        LOG_E("Unable to get has toggle: %s!", errbuf);
        abort();
    }
    layer->has_toggle = has_toggle.u.b;

    if (!table->is_animated)
        goto end;

    toml_table_t *animation = toml_table_in(conf, "animation");
    if (animation == NULL) {
        LOG_E("Unable to find table [animation] in metadata: %s!", errbuf);
        abort();
    }

    toml_datum_t frame_count = toml_int_in(animation, "frame_count");
    if (!frame_count.ok) {
        LOG_E("Unable to get frame count: %s!", errbuf);
        abort();
    }
    layer->frames_count = frame_count.u.i;
    layer->delays = calloc(layer->frames_count, sizeof(uint32_t));

    toml_array_t *delays = toml_array_in(animation, "delays");
    if (delays == NULL) {
        LOG_E("Unable to get delays: %s!", errbuf);
        abort();
    }

    for (size_t i = 0; i < layer->frames_count; i++) {
        toml_datum_t delay = toml_int_at(delays, i);
        if (!delay.ok) {
            LOG_E("Unable to get %dth frame delay: %s!", i + 1, errbuf);
            abort();
        }
        layer->delays[i] = delay.u.i;
    }

end:
    if (table->is_animated)
        layer->img = LoadImageAnimFromMemory(".gif", table->image_buffer,
            table->image_size, &layer->frames_count);
    else
        layer->img = LoadImageFromMemory(".png", table->image_buffer,
            table->image_size);

    layer->texture = LoadTextureFromImage(layer->img);
    SetTextureFilter(layer->texture, TEXTURE_FILTER_BILINEAR);
    GenTextureMipmaps(&layer->texture);
    SetTextureWrap(layer->texture, TEXTURE_WRAP_CLAMP);
    layer->name.len = strlen(table->name);
    layer->name.cleanup = false;
    layer->name.buffer = table->name;
    layer->previous_frame = 0;
    layer->current_frame = 0;
    layer->gif_buffer = table->image_buffer;
    layer->gif_size = table->image_size;

    if (!table->is_animated)
        free(table->image_buffer);

    toml_free(conf);
    free(table->buffer);
}

static void write_model()
{
    if (ctx.dialog.selected_index == -2) {
        path_append_file(&ctx.dialog.current_directory,
            strdup(ctx.dialog.file_out_name.buffer));
        size_t sz = path_bufsz(&ctx.dialog.current_directory);
        const char *ext = ".opng";
        int ext_len = strlen(ext);

        char tmpbuf[sz + ext_len + 1];
        memset(tmpbuf, 0, sz + ext_len + 1);
        path_str(&ctx.dialog.current_directory, sz, tmpbuf);
        strcat(tmpbuf, ext);

#ifdef _WIN32
        *tmpbuf = ctx.dialog.current_drive_letter;
#endif
        model_write(&ctx.model, tmpbuf);
        filedialog_up(&ctx.dialog);
        ctx.dialog.file_out_name.cleanup = true;
    } else {
        LOG_E("Selection not yet implemented!", 0);
    }
}

static void load_script()
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

    LOG_I("Preparing script of size %ld to be loaded", s.st_size);

    context_load_script(&ctx, strrchr(buffer, PATH_SEPARATOR) + 1, fd,
        s.st_size, load_script_file, after_script_loaded);
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

static enum un_action update_gif(un_timer *timer)
{
    struct model_layer *layer = un_timer_get_data(timer);

    layer->previous_frame = layer->current_frame;
    un_timer_set_repeat(timer, layer->delays[layer->current_frame]);
    layer->current_frame = (layer->current_frame + 1) % layer->frames_count;

    if (layer->delete) {
        if (!layer->alive) {
            cleanup_layer(layer);
            return DISARM;
        }
    }

    return REARM;
}
