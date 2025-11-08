/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <ui/line_edit.h>
#include <ui/window.h>
#include <ui/messagebox.h>
#include <core/pathbuf.h>
#include <stdbool.h>
#include <stddef.h>

#include <raylib-nuklear.h>

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

struct filedialog2;

struct filedialog2 *fdialog_init();
void fdialog_run(struct filedialog2 *dialog,
    struct nk_context *ctx, bool *ui_focused);

void fdialog_open_at_home(struct filedialog2 *dialog);
void fdialog_populate(struct filedialog2 *dialog);
void fdialog_set_filter(struct filedialog2 *dialog, const char *filter);

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
