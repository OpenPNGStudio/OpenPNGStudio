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
    LOADING_IMAGE,
};

enum file_extension {
    F_PNG,
    F_BMP,
    F_JPG,
    F_GIF
};

struct file_loading {
    char *buffer;
    size_t size;
    un_file *file;
    char *name;
    enum file_extension ext;
    bool ready;
};

struct context {
    enum fileload_state loading_state;
    /* TODO: rename */
    struct file_loading f;

    un_loop *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;

    Camera2D camera;
    Color background_color;

    struct editor editor;

    struct microphone_data mic;
};

#endif
