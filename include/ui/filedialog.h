/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <raylib-nuklear.h>

#ifndef _WIN32
#define PATH_SEPARATOR '/'
#else
#define PATH_SEPARATOR '\\'
#endif

enum filedialog2_state {
    CLOSED,
    BROWSING,
    READ_READY,
    WRITE_READY,
};

struct filedialog2;

struct filedialog2 *fdialog_init();
void fdialog_run(struct filedialog2 *dialog,
    struct nk_context *ctx, bool *ui_focused);

void fdialog_show(struct filedialog2 *dialog);
enum filedialog2_state fdialog_get_state(struct filedialog2 *dialog);
void fdialog_populate(struct filedialog2 *dialog);
void fdialog_set_filter(struct filedialog2 *dialog, const char *filter);
void fdialog_set_title(struct filedialog2 *dialog, const char *title);
void fdialog_free(struct filedialog2 *dialog);
void fdialog_open_file(struct filedialog2 *dialog);
void fdialog_write_file(struct filedialog2 *dialog);
char **fdialog_get_selection(struct filedialog2 *dialog);
void fdialog_reset(struct filedialog2 *dialog);
