#ifndef _CONTEXT_H_
#define _CONTEXT_H_


#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <miniaudio.h>
#include <uv.h>
#include <unuv.h>
#include "editor.h"
#include <stdatomic.h>
#include <raylib.h>
#include <filedialog.h>
#include <gif_config.h>
#include <microphone.h>

enum program_mode {
    EDIT_MODE,
    STREAM_MODE,
};

enum fileload_state {
    NOTHING,
    SELECTING_IMAGE,
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
    unsigned char *buffer;
    size_t size;
    char *name;
    const char *ext;
    struct image_load_req *next;
    int fd;
    int frames_count;
    bool ready;
};

struct context {
    enum fileload_state loading_state;
    struct image_load_req *image_work_queue;
    bool configuring_gif;

    un_loop *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;

    Camera2D camera;

    struct editor editor;
    struct gif_configurator gif_cfg;
    struct microphone_data mic;

    enum program_mode mode;
    bool hide_ui;
};

void context_load_image(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after);

#endif
