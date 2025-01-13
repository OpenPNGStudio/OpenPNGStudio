#ifndef _CONTEXT_H_
#define _CONTEXT_H_

#include "editor.h"

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <miniaudio.h>
#include <uv.h>
#include <unuv.h>
#include <raylib.h>
#include <filedialog.h>

struct microphone_data {
    float volume;
    ma_device device;
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

    un_loop *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;

    Camera2D camera;
    Color background_color;

    struct editor editor;

    struct microphone_data mic;
};

void context_load_image(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after);

#endif
