/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include "console.h"
#include <fcntl.h>
#include <sys/types.h>
#include <raylib.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <core/nk.h>

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

struct context ctx = {0};
void *c_ctx = &ctx;


/* to be replaced */
static void load_layer_file(uv_work_t *req);
static void after_layer_loaded(uv_work_t *req, int status);

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

void quit_openpngstudio();

void quit_openpngstudio()
{
    uv_stop((uv_loop_t*) ctx.loop);
}

static enum un_action draw(un_idle *task)
{
    // if (ctx.mode == EDIT_MODE)
    //     draw_grid(1, 60, inverted);

    return REARM;
}

static enum un_action c_update(un_idle *task)
{
    struct nk_context *nk_ctx = ctx.ctx;

    // if (IsKeyPressed(KEY_TAB)) {
    //     if (ctx.mode == EDIT_MODE) 
    //         ctx.mode = STREAM_MODE;
    //     else
    //         ctx.mode = EDIT_MODE;
    // }
    //

    // /* check for pending work */
    // if (ctx.image_work_queue != NULL && ctx.image_work_queue->ready)
    //     context_after_img_load(&ctx, ctx.image_work_queue);

    return REARM;
}

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
