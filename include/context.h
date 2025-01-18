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

#ifndef _CONTEXT_H_
#define _CONTEXT_H_


#include "ui/window.h"
#include <stdint.h>
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
    WRITING_MODEL,
    LOADING_MODEL,
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
    struct window about_win;

    enum program_mode mode;
    bool hide_ui;
};

void context_load_image(struct context *ctx, const char *name,
    int fd, size_t size, uv_work_cb work, uv_after_work_cb after);

void context_about(struct context *context, struct nk_context *ctx);

#endif
