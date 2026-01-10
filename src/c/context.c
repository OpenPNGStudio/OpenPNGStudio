/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifdef _WIN32
#include <raylib_win32.h>
#endif

#include "console.h"

#include <assert.h>
#include "uv.h"
#include <context.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <sys/mman.h>
#include <unistd.h>
#else
#include <mman.h>
#endif

#define PAGE_SIZE 4096 /* usual size */

#if 0
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#endif

#include <layer/layer.h>

void context_load_image(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after)
{
    struct image_load_req *req = NULL;
    if (ctx->image_work_queue == NULL)
        req = calloc(1, sizeof(struct image_load_req));
    else {
        req = ctx->image_work_queue;

        while (req->next)
            req = req->next;

        req->next = calloc(1, sizeof(struct image_load_req));
        req = req->next;
    }

    /* prepare request */
    req->buffer = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
    if (req->buffer == MAP_FAILED) {
        perror("mmap");
        abort();
    }
    req->size = size;
    req->name = strdup(name);
    req->ext = strrchr(req->name, '.');
    req->fd = fd;
    req->delays = NULL;

    /* deploy */
    if (ctx->image_work_queue == NULL)
        ctx->image_work_queue = req;

    if (strcmp(req->ext, ".gif") == 0)
        req->gif_buffer = malloc(size);

    req->req.data = req;
    uv_queue_work((uv_loop_t*) ctx->loop, &req->req, work, after);
}

void context_load_script(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after)
{
    struct script_load_req *req = NULL;
    if (ctx->script_work_queue == NULL)
        req = calloc(1, sizeof(struct script_load_req));
    else {
        req = ctx->script_work_queue;

        while (req->next)
            req = req->next;

        req->next = calloc(1, sizeof(struct script_load_req));
        req = req->next;
    }

    /* prepare request */
    if (size < PAGE_SIZE) {
        req->is_mmapped = false;
        req->buffer = malloc(size);
        if (req->buffer == NULL) {
            perror("malloc");
            abort();
        }

    } else {
        req->is_mmapped = true;
        req->buffer = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
        if (req->buffer == MAP_FAILED) {
            perror("mmap");
            abort();
        }
    }
    req->size = size;
    req->name = strdup(name);
    req->fd = fd;

    /* deploy */
    if (ctx->script_work_queue == NULL)
        ctx->script_work_queue = req;

    req->req.data = req;
    uv_queue_work((uv_loop_t*) ctx->loop, &req->req, work, after);
}

void context_submit_work(struct context *ctx, ...)
{
    assert(0 && "Not implemented yet!");
}

void layer_manager_add_layer(void *c3_ctx, struct layer *layer);

void context_after_img_load(struct context *ctx, struct image_load_req *req)
{
    struct layer *layer = NULL;
    struct animated_layer *anim_layer = NULL;

    if (req->gif_buffer != NULL)
        layer = layer_new_animated(req->img, req->frames_count,
            req->gif_buffer, req->size, req->delays);
    else
        layer = layer_new(req->img);
    
    LOG_I("Loaded layer \"%s\"", req->name);
    layer_override_name(layer, req->name);

    layer_manager_add_layer(ctx->c3_ctx, layer);

    if (layer->properties.is_animated) {
        anim_layer = layer_get_animated(layer);
        layer_animated_start(anim_layer, ctx->loop);                
    }

    /* cleanup */
    ctx->image_work_queue = req->next;
    munmap(req->buffer, req->size);
    close(req->fd);
    free(req);
}
