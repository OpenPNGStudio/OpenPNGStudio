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
#include <sys/stat.h>
#include <unistd.h>
#include <unuv.h>
#include <uv.h>

#define PATH_START "../"

static char image_filter[] = "png;bmp;jpg;jpeg;gif";
struct context ctx = {0};

void onAudioData(ma_device* device, void* output, const void* input, ma_uint32 frameCount) {
    struct microphone_data* data = device->pUserData;
    float* inputData = (float*)input;

    float sum = 0.0f;
    for (ma_uint32 i = 0; i < frameCount; i++) {
        sum += inputData[i] * inputData[i];
    }

    data->volume = sqrtf(sum / frameCount) * 100;
}

void draw_grid(int line_width, int spacing, Color color)
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

enum un_action update(un_idle *task);
enum un_action draw(un_idle *task);

void on_open(un_file *file, int result);
enum un_action on_read(un_file *file, char *buffer, int result);

int main()
{
    /* CFG */
    ctx.loop = un_loop_new();
    filedialog_init(&ctx.dialog, 0);
    console_init();

#ifdef _WIN32
    path_append_dir(&ctx.dialog.current_directory, strdup("users"));
    path_append_dir(&cx.dialog.current_directory, strdup(getenv("USERNAME")));
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

enum un_action draw(un_idle *task)
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

enum un_action update(un_idle *task)
{
    bool ui_focused = false;
    struct nk_context *nk_ctx = ctx.ctx;

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    UpdateNuklear(nk_ctx);
    ctx.width = GetScreenWidth();
    ctx.height = GetScreenHeight();

    if (nk_begin(nk_ctx, "Menu", nk_rect(0, 0, ctx.width, 25),
            NK_WINDOW_NO_SCROLLBAR)) {
        if (nk_input_is_mouse_hovering_rect(&nk_ctx->input, nk_window_get_bounds(nk_ctx)))
            ui_focused = true;

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
                ctx.dialog.title = "Open Image File";
                filedialog_show(&ctx.dialog);
                
                if (ctx.loading_state == NOTHING)
                    ctx.loading_state = SELECTING_IMAGE;
            }

            nk_menu_end(nk_ctx);
        }

        nk_menubar_end(nk_ctx);
    }


    nk_end(nk_ctx);

    filedialog_run(&ctx.dialog, nk_ctx, &ui_focused);
    editor_draw(&ctx.editor, ctx.ctx, &ui_focused);

    if (IsKeyPressed(KEY_GRAVE) && IsKeyDown(KEY_LEFT_SHIFT))
      console_show();

    console_draw(nk_ctx, &ui_focused);

    if (!ctx.dialog.show) {
        if (ctx.dialog.selected_index != -1) {
            if (ctx.loading_state == SELECTING_IMAGE) {
                ctx.loading_state = LOADING_IMAGE;
                struct stat s;
                size_t sz = filedialog_selsz(&ctx.dialog);
                char buffer[sz + 1];
                memset(buffer, 0, sz + 1);
                filedialog_selected(&ctx.dialog, sz, buffer);
                if (stat(buffer, &s) == -1) {
                    perror("stat");
                    abort();
                }

                ctx.f.buffer = malloc(s.st_size + 1);
                ctx.f.size = s.st_size;
                ctx.f.name = strdup(strrchr(buffer, PATH_SEPARATOR) + 1);
                enum file_extension ext;

                char *ptr;

                switch (*(ptr = strrchr(ctx.f.name, '.') + 1)) {
                case 'p':
                    ext = F_PNG;
                    break;
                case 'b':
                    ext = F_BMP;
                    break;
                case 'j':
                    ext = F_JPG;
                    break;
                case 'g':
                    ext = F_GIF;
                    break;
                default:
                    LOG_E("%s not supported yet :3", ptr);
                    abort();
                }

                ctx.f.ext = ext;
                un_fs_open(ctx.loop, buffer, O_RDONLY, 0, on_open);
            }

            if (ctx.f.ready) {
                const char *ext = NULL;

                switch (ctx.f.ext) {
                case F_PNG:
                    ext = ".png";
                    break;
                case F_BMP:
                    ext = ".bmp";
                    break;
                case F_JPG:
                    ext = ".jpeg";
                    break;
                case F_GIF:
                    ext = ".gif";
                    break;
                default:
                    LOG_E("I have no idea how you got here silly", 0);
                    abort();
                }

                Image loaded;
                struct model_layer layer = {0};

                if (ctx.f.ext != F_GIF)
                    loaded = LoadImageFromMemory(ext, (unsigned char*) ctx.f.buffer, ctx.f.size);
                else
                    loaded = LoadImageAnimFromMemory(ext, (unsigned char*) ctx.f.buffer, ctx.f.size, &layer.frames_count);

                layer.texture = LoadTextureFromImage(loaded);
                SetTextureFilter(layer.texture, TEXTURE_FILTER_BILINEAR);
                layer.name.len = strlen(ctx.f.name);
                layer.name.cleanup = false;
                layer.name.buffer = ctx.f.name;
                layer.rotation = 180.0f;

                if (ctx.f.ext == F_GIF)
                    layer.img = loaded;

                free(ctx.f.buffer);

                LOG_I("Loaded layer", 0);

                ctx.f.ready = false;
                ctx.loading_state = NOTHING;
                layer_manager_add_layer(&ctx.editor.layer_manager, &layer);
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

    if (WindowShouldClose())
        uv_stop((uv_loop_t*) ctx.loop);

    return REARM;
}

void on_open(un_file *file, int result)
{
    if (result < 0) {
        LOG_E("%s\n", uv_strerror(result));
    } else {
        un_fs_read(file, ctx.f.buffer, BUFSIZ, on_read);
    }
}

enum un_action on_read(un_file *file, char *buffer, int result)
{
    if (result < 0) {
        LOG_E("%s\n", uv_strerror(result));
    } else if (result < BUFSIZ) {
        ctx.f.ready = true;
        un_fs_close(file, NULL);
        return DISARM;
    }

    buffer[result] = 0;
    un_fs_update_buffer(file, READ_BUFFER, buffer + result, BUFSIZ);

    return REARM;
}
