#ifndef _CONTEXT_H_
#define _CONTEXT_H_

#include "editor.h"

#ifdef _WIN32
#include <raylib_win32.h>
#endif
#include <miniaudio.h>
#include <uv.h>
#include <raylib.h>
#include <filedialog.h>

struct microphone_data {
    float volume;
    ma_device device;
};

enum fileload_state {
    NOTHING,
    LOADING_IMAGE,
};

enum file_extension {
    F_PNG,
    F_BMP,
    F_JPG,
    F_GIF
};

struct file_loading {
    uv_fs_t close_req;
    uv_fs_t open_req;
    uv_fs_t read_req;
    uv_buf_t buffer;
    char *name;
    enum file_extension ext;
    bool ready;
};

struct context {
    enum fileload_state loading_state;
    /* TODO: rename */
    struct file_loading f;

    uv_loop_t *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;

    Camera2D camera;
    Color background_color;

    struct editor editor;

    struct microphone_data mic;
};

#endif