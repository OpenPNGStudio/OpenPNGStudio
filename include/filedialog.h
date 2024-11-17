#ifndef _FILEDIALOG_H_
#define _FILEDIALOG_H_

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
    /* STATE */
    struct path current_directory;
    struct dir_entry *dir_content;
    size_t content_size;
    int selected_index;
    bool open_for_write;
    bool show;
    struct nk_rect geometry;
    struct messagebox msg_box;
    #ifdef _WIN32
    char current_drive_letter;
    #endif

    /* CFG */
    unsigned int row_count;
    const char *title;
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

void filedialog_run(struct filedialog *dialog, struct nk_context *ctx);

void filedialog_deinit(struct filedialog *dialog);

void filedialog_register_icon(enum image_type type, struct nk_image img);

#endif