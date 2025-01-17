#include "archive.h"
#include "archive_entry.h"
#include "console.h"
#include "editor.h"
#include "gif_config.h"
#include "layermgr.h"
#include "toml.h"
#include <fcntl.h>
#include <filedialog.h>
#include <sys/types.h>
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

#define TOML_ERR_LEN UINT8_MAX

static char image_filter[] = "png;bmp;jpg;jpeg;gif";
static char model_filter[] = "opng";
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
static int manifest_load_layers(toml_table_t *conf, struct manifest *manifest);
static struct layer_table *manifest_find_layer(struct manifest *manifest,
    const char *filename);
static void manifest_scaffold(struct manifest *manifest);
static void table_configure_layer(struct layer_table *table,
    struct model_layer *layer);

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

        int i = ctx.editor.layer_manager.layer_count - 1;

        un_timer *timer = un_timer_new(ctx.loop);
        un_timer_set_data(timer, ctx.editor.layer_manager.layers[i]);
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
            } else if (ctx.loading_state == LOADING_MODEL) {
                load_model();
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
            if (nk_menu_item_label(nk_ctx, "Open", NK_TEXT_LEFT)) {
                ctx.dialog.open_for_write = false;
                ctx.dialog.filter = model_filter;
                filedialog_refresh(&ctx.dialog);
                ctx.dialog.win.title = "Load Model";
                filedialog_show(&ctx.dialog);

                ctx.loading_state = LOADING_MODEL;
            }

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

static void load_model()
{
    struct stat s;
    size_t sz = filedialog_selsz(&ctx.dialog);
    char buffer[sz + 1];
    char errbuf[TOML_ERR_LEN];

    memset(buffer, 0, sz + 1);
    filedialog_selected(&ctx.dialog, sz, buffer);

    if (stat(buffer, &s) == -1) {
        perror("stat");
        abort();
    }

    int fd = open(buffer, O_RDONLY);
    void *mapped = mmap(NULL, s.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (mapped == MAP_FAILED) {
        perror("mmap");
        abort();
    }

    LOG_I("Preparing to load %s", buffer);

    struct archive *a = archive_read_new();
    struct archive_entry *en;
    int res;
    struct manifest manifest = {0};

    archive_read_support_filter_zstd(a);
    archive_read_support_format_tar(a);
    res = archive_read_open_memory(a, mapped, s.st_size);
    if (res != ARCHIVE_OK) {
        LOG_E("Something went wrong when reading archive! %s",
            archive_error_string(a));
        abort();
    }

    while ((archive_read_next_header(a, &en)) == ARCHIVE_OK) {
        mode_t type = archive_entry_filetype(en);
        const char *pathname = archive_entry_pathname(en);

        if (type == AE_IFREG) {
            if (pathname[0] == 'm' && strcmp(pathname, "manifest.toml") == 0) {
                LOG_I("Reading model manifest", 0);
                size_t size = archive_entry_size(en);
                char *config_str = calloc(size, 1);
                archive_read_data(a, config_str, size);

                toml_table_t* conf = toml_parse(config_str, errbuf,
                    TOML_ERR_LEN);
                if (conf == NULL) {
                    LOG_E("Unable to parse manifest file: %s!", errbuf);
                    break;
                }

                toml_table_t *model = toml_table_in(conf, "model");
                if (model == NULL) {
                    LOG_E("Unable to find table [model] in manifest: %s!",
                        errbuf);
                    break;
                }

                toml_datum_t layer_count = toml_int_in(model, "layer_count");
                if (!layer_count.ok) {
                    LOG_E("Unable to get layer count: %s!", errbuf);
                    break;
                }
                manifest.layer_count = layer_count.u.i;

                toml_table_t *microphone = toml_table_in(conf, "microphone");
                if (microphone == NULL) {
                    LOG_E("Unable to find table [microphone] in manifest: %s!",
                        errbuf);
                    break;
                }

                toml_datum_t trigger = toml_int_in(microphone, "trigger");
                if (!trigger.ok) {
                    LOG_E("Unable to get microphone activation trigger: %s!",
                        errbuf);
                    break;
                }
                manifest.microphone_trigger = trigger.u.i;

                toml_datum_t sensitivity = toml_int_in(microphone,
                    "sensitivity");
                if (!sensitivity.ok) {
                    LOG_E("Unable to get microphone sensitivity: %s!", errbuf);
                    break;
                }
                manifest.microphone_sensitivity = sensitivity.u.i;

                toml_table_t *scene = toml_table_in(conf, "scene");
                if (scene == NULL) {
                    LOG_E("Unable to find table [scene] in manifest: %s!",
                        errbuf);
                    break;
                }

                toml_datum_t bg_color = toml_int_in(scene, "bg_color");
                if (!bg_color.ok) {
                    LOG_E("Unable to get background color: %s!", errbuf);
                    break;
                }
                manifest.bg_color = bg_color.u.i;

                if (!manifest_load_layers(conf, &manifest))
                    break;

                LOG_I("Parsed model manifest successfully!", 0);

                toml_free(conf);
                free(config_str);
                continue;
            } else if (pathname[0] == 'l' &&
                strncmp(pathname, "layers/", 7) == 0) {
                struct layer_table *layer = manifest_find_layer(&manifest,
                    pathname);

                if (layer != NULL) {
                    const char *ext = strrchr(pathname, '.') + 1;
                    size_t data_size = archive_entry_size(en);
                    if (strcmp(ext, "toml") == 0) {
                        layer->buffer = calloc(data_size, 1);
                        archive_read_data(a, layer->buffer, data_size);
                    } else {
                        layer->image_size = data_size;
                        layer->image_buffer = calloc(data_size, 1);
                        archive_read_data(a, layer->image_buffer, data_size);
                    }
                } else {
                    LOG_E("Unable to find layer %s! Is it defined in the "
                        "manifest?", pathname);
                    break;
                }
            } else
                LOG_W("Stray file in model - %s???", pathname);
        } else if (type == S_IFDIR) {
            if (strcmp(pathname, "layers/") != 0)
                LOG_W("Stray directory in model - %s???", pathname);
        }

        archive_read_data_skip(a);
    }
    archive_read_free(a);
    munmap(mapped, s.st_size);
    close(fd);

    manifest_scaffold(&manifest);
}

static int manifest_load_layers(toml_table_t *conf, struct manifest *manifest)
{
    char errbuf[TOML_ERR_LEN];
    struct layer_table *lazy = NULL;

    toml_array_t *array = toml_array_in(conf, "layer");
    if (array == NULL) {
        LOG_E("Unable to find array [[layer]] in manifest: %s!", errbuf);
        return 0;
    }

    for (size_t i = 0; i < manifest->layer_count; i++) {
        struct layer_table *table = calloc(1, sizeof(struct layer_table));
        toml_table_t *layer = toml_table_at(array, i);
        if (layer == NULL) {
            LOG_E("Unable to get layer info: %s!", errbuf);
            free(table);
            return 0;
        }

        toml_datum_t name = toml_string_in(layer, "name");
        if (!name.ok) {
            LOG_E("Unable to get layer name: %s!", errbuf);
            free(table);
            return 0;
        }
        table->name = name.u.s;

        toml_datum_t index = toml_int_in(layer, "index");
        if (!index.ok) {
            LOG_E("Unable to get layer index: %s!", errbuf);
            free(table);
            return 0;
        }
        table->index = index.u.i;

        toml_datum_t is_animated = toml_bool_in(layer, "is_animated");
        if (!is_animated.ok) {
            LOG_E("Unable to get if layer is animated: %s!", errbuf);
            free(table);
            return 0;
        }
        table->is_animated = is_animated.u.b;

        if (lazy == NULL) {
            manifest->table = table;
            lazy = table;
        } else {
            lazy->next = table;
            lazy = table;
        }
    }

    return 1;
}

static struct layer_table *manifest_find_layer(struct manifest *manifest,
    const char *filename)
{
    const char *start = strrchr(filename, '-') + 1;
    size_t index = atoll(start);

    struct layer_table *lazy = manifest->table;
    while (lazy) {
        if (lazy->index == index)
            return lazy;

        lazy = lazy->next;
    }

    return NULL;
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

    toml_datum_t ttl = toml_int_in(lay, "ttl");
    if (!ttl.ok) {
        LOG_E("Unable to get time to live: %s!", errbuf);
        abort();
    }
    layer->ttl = ttl.u.i;

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
        filedialog_up(&ctx.dialog);
        struct archive *a = archive_write_new();
        struct archive_entry *en = archive_entry_new();

        archive_write_add_filter_zstd(a);
        archive_write_set_format_pax_restricted(a);
        archive_write_open_filename(a, tmpbuf);

        /* write */
        char *out = editor_tomlify(&ctx.editor);
        int str_len = strlen(out) + 1;
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
            struct model_layer *layer = ctx.editor.layer_manager.layers[i];
            {
                out = layer_tomlify(layer);
                str_len = strlen(out) + 1;
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
    struct model_layer *layer = un_timer_get_data(timer);

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
