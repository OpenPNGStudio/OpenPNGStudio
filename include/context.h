/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifndef _CONTEXT_H_
#define _CONTEXT_H_

#include <work/scheduler.h>
#include <stdint.h>
#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <miniaudio.h>
#include <uv.h>
#include <unuv.h>
#include <stdatomic.h>
#include <raylib.h>
#include <core/microphone.h>
#include <ui/messagebox.h>
#if 0
#include <lua.h>
#endif
#include <core/mask.h>
#include <model/model.h>

enum program_mode {
    EDIT_MODE,
    STREAM_MODE,
};

enum file_extension {
    F_PNG,
    F_BMP,
    F_JPG,
    F_GIF
};

struct image_load_req {
    Image img;
    uv_work_t req;
    uint8_t *buffer;
    uint8_t *gif_buffer;
    int *delays;
    size_t size;
    char *name;
    const char *ext;
    struct image_load_req *next;
    int fd;
    int frames_count;
    bool ready;
};

struct script_load_req {
    uv_work_t req;
    uint8_t *buffer;
    size_t size;
    char *name;
    struct script_load_req *next;
    int fd;
    bool is_mmapped;
    bool ready;
};

struct context {
    /* STATE */
    struct image_load_req *image_work_queue;
#if 0
    lua_State *L;
#endif
    struct script_load_req *script_work_queue;

    struct work_scheduler sched;

    un_loop *loop;
    struct nk_context *ctx;
    struct filedialog2 *fdialog;
    float width, height;

    mask_t mask;

    Camera2D camera;

    struct panel *panel;

    enum program_mode mode;
    bool hide_ui;

    void *c3_ctx;
};

un_loop *get_loop();

void context_load_image(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after);
void context_load_script(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after);

void context_submit_work(struct context *ctx, ...);

void context_after_img_load(struct context *ctx, struct image_load_req *req);

void context_about(struct context *context, struct nk_context *ctx);
void context_welcome(struct context *context, struct nk_context *ctx);
void context_keybindings(struct context *context, struct nk_context *ctx);

void context_init_lua(struct context *context);

#endif
