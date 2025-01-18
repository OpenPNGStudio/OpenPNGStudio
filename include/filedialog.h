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

#pragma once

#include "line_edit.h"
#include "ui/window.h"
#include <messagebox.h>
#include <pathbuf.h>
#include <stdbool.h>
#include <stddef.h>

#include <raylib-nuklear.h>

enum image_type {
    UP_IMG,
    REFRESH_IMG,
    DIR_IMG,
    FILE_IMG,
    IMG_IMG,
    DRIVE_IMG,
    IMG_TYPE_SZ
};

struct dir_entry {
    char *name;
    bool is_file;
    bool hidden;
#ifdef _WIN32
    bool system_hidden;
#endif
    nk_bool selected;
};

struct filedialog {
    /* UI */
    struct window win;
    struct messagebox msg_box;

    /* STATE */
    struct path current_directory;
    struct dir_entry *dir_content;
    size_t content_size;
    int selected_index;
    bool open_for_write;
    struct {
        struct line_edit input;
        bool is_file;
    } new_file;
    struct line_edit search_filter;
    struct line_edit file_out_name;
    bool show_hidden;
    bool submenu_new_open;
    bool context_menu_open;

    #ifdef _WIN32
    char current_drive_letter;
    bool show_system_hidden;
    #endif

    /* CFG */
    const char *filter;
};

void filedialog_init(struct filedialog *dialog, bool write);
/* returns false when in the root of the FS */
bool filedialog_up(struct filedialog *dialog);
void filedialog_enter(struct filedialog *dialog, const char *dir);

/* returns the length of the selected file */
size_t filedialog_selsz(const struct filedialog *dialog);

void filedialog_selected(const struct filedialog *dialog, size_t selsz,
    char *buf);

/* once everything is setup, trigger opening */
void filedialog_show(struct filedialog *dialog);

void filedialog_run(struct filedialog *dialog, struct nk_context *ctx, bool *ui_focused);

void filedialog_deinit(struct filedialog *dialog);

void filedialog_refresh(struct filedialog *dialog);
void filedialog_register_icon(enum image_type type, struct nk_image img);
