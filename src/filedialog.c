#include "messagebox.h"
#include "raylib.h"
#include "str.h"
#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <pathbuf.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <filedialog.h>
#include <string.h>
#include <sys/stat.h>

#include <raylib-nuklear.h>
#include <unistd.h>

#ifdef _WIN32
#include <fileapi.h>
#include <errhandlingapi.h>
#include <winerror.h>
#define DEFFILEMODE (S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH)/* 0666*/
#endif

struct new_file {
    char *buffer;
    int len;
    bool is_file;
    bool cleanup;
};

struct input_buffer {
    char *buffer;
    int len;
    bool cleanup;
};

static struct nk_image images[IMG_TYPE_SZ] = {0};
static char img_filter[] = "png;bmp;jpg;jpeg;gif;psd";

static int hide_file(const char *path);
static int on_new_file(struct nk_context *ctx, struct messagebox *box);
static int on_search(struct nk_context *ctx, struct messagebox *box);
static int entry_comparar(const void *p1, const void *p2);
#ifndef _WIN32
static struct dir_entry *append_file(struct filedialog *dialog, const char *name);
#else
static struct dir_entry *append_file(struct filedialog *dialog, const char *name, const char *full_path);
#endif
static const char *filter_out(const char *filename, const char *filter);
static void init_content(struct filedialog *dialog);
static void deinit_content(struct filedialog *dialog);

void filedialog_init(struct filedialog *dialog, bool write)
{
#ifdef _WIN32
    dialog->current_drive_letter = 'C';
#endif
    filedialog_deinit(dialog);
    dialog->open_for_write = write;
    init_content(dialog);
}

bool filedialog_up(struct filedialog *dialog)
{
    struct path *prev = path_pop(&dialog->current_directory);
    if (prev == NULL && dialog->current_directory.name != NULL) {
        free(dialog->current_directory.name);
        dialog->current_directory.name = NULL;
        dialog->current_directory.is_file = false;

        deinit_content(dialog);
        init_content(dialog);

        return true;
    }

    if (prev == NULL)
        return false;

    deinit_content(dialog);
    init_content(dialog);

    free(prev->name);
    free(prev);

    return true;
}

void filedialog_enter(struct filedialog *dialog, const char *dir)
{
    path_append_dir(&dialog->current_directory, strdup(dir));

    deinit_content(dialog);
    init_content(dialog);
}

size_t filedialog_selsz(const struct filedialog *dialog)
{
    if (dialog->selected_index == -1)
        return 0;

    size_t sz = path_dirsz(&dialog->current_directory);
    struct dir_entry *e = dialog->dir_content + dialog->selected_index;

    return sz + (e->is_file == true ? 0 : 1) + strlen(e->name);
}

void filedialog_selected(const struct filedialog *dialog, size_t selsz,
    char *buf)
{
    if (dialog->selected_index == -1)
        return;

    struct dir_entry *e = dialog->dir_content + dialog->selected_index;

    size_t sz = path_dirsz(&dialog->current_directory);
    path_dir(&dialog->current_directory, selsz, buf);

#ifdef _WIN32
    *buf = dialog->current_drive_letter;
#endif

    buf += sz - 1;
    selsz -= sz;

    sz = sized_strncpy(buf, e->name, selsz);
    buf += sz;
    selsz -= sz;

    if (e->is_file == false && selsz > 0)
        *buf = PATH_SEPARATOR;
}

void filedialog_show(struct filedialog *dialog)
{
    dialog->show = true;
}

void filedialog_run(struct filedialog *dialog, struct nk_context *ctx)
{
    if (dialog->title == NULL)
        dialog->title = ":3";

    if (dialog->geometry.x == 0 && dialog->geometry.y == 0 &&
        dialog->geometry.w == 0 && dialog->geometry.h == 0) {

        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 80.0f;
        float h = height / 100.0f * 80.0f;
        float x = (width - w) / 2.0f;
        float y = (height - h) / 2.0f;

        dialog->geometry = nk_rect(x, y, w, h);
    }

    static struct new_file new_filereq = {0};
    static struct input_buffer search_filter = {0};
    static bool show_hiden = false;
#ifdef _WIN32
    static bool show_system_hidden = false;
#endif

    if (dialog->show) {
        if (nk_begin(ctx, dialog->title, dialog->geometry,
                NK_WINDOW_TITLE | NK_WINDOW_CLOSABLE | NK_WINDOW_MOVABLE |
                NK_WINDOW_SCALABLE | NK_WINDOW_BORDER)) {
            
            messagebox_run(&dialog->msg_box, ctx);
            /* title bar*/

            nk_layout_row_template_begin(ctx, 32);
            nk_layout_row_template_push_static(ctx, 32);
            nk_layout_row_template_push_dynamic(ctx);
            nk_layout_row_template_push_static(ctx, 32);
            nk_layout_row_template_end(ctx);

            if (nk_button_image(ctx, images[UP_IMG])) {
                filedialog_up(dialog);
                free(search_filter.buffer);
                search_filter.cleanup = false;
                search_filter.buffer = NULL;
                search_filter.len = 0;
            }

            size_t sz = path_dirsz(&dialog->current_directory);
            char buf[sz + 1];
            memset(buf, 0, sz + 1);
            path_dir(&dialog->current_directory, sz, buf);

#ifdef _WIN32
            *buf = dialog->current_drive_letter;
#endif            

            int len = sz;

            nk_edit_string(ctx, NK_EDIT_DEACTIVATED, buf, &len, sz, nk_filter_default);

            if (nk_button_image(ctx, images[REFRESH_IMG])) {
                deinit_content(dialog);
                init_content(dialog);
            }

            /* sidebar and file grid */

            struct nk_rect total = nk_window_get_content_region(ctx);

            nk_layout_row_begin(ctx, NK_DYNAMIC, total.h - 80, 1);

            nk_layout_row_push(ctx, NK_UNDEFINED);
            struct nk_rect bounds = nk_layout_space_bounds(ctx);
            bounds.h += 30;

            if (nk_group_begin(ctx, "Files", NK_WINDOW_BORDER)) {
                static bool new_open = false;
                static bool context_open = false;
                context_open = dialog->msg_box.res != -1;

                if (nk_contextual_begin(ctx, 0, nk_vec2(256, 256), bounds)) {
                    if (!context_open) {
                        nk_contextual_close(ctx);
                        goto ctx_end;
                    }

                    nk_layout_row_dynamic(ctx, 25, 1);

                    struct nk_vec2 old_padding = ctx->style.window.group_padding;
                    ctx->style.window.group_padding = nk_vec2(0, 0);

                    if (nk_group_begin(ctx, "New", NK_WINDOW_NO_SCROLLBAR)) {
                        struct nk_style_button style = ctx->style.combo.button;
                        style.text_alignment = NK_TEXT_LEFT;
                        nk_layout_row_template_begin(ctx, 25);
                        nk_layout_row_template_push_dynamic(ctx);
                        nk_layout_row_template_push_static(ctx, 25);
                        nk_layout_row_template_end(ctx);

                        if (nk_button_label_styled(ctx, &style, "New") ||
                            nk_button_symbol_styled(ctx, &style, NK_SYMBOL_TRIANGLE_DOWN)){
                            new_open = !new_open;
                        }

                        nk_group_end(ctx);
                    }

                    ctx->style.window.group_padding = old_padding;

                    if (new_open) {
                        nk_layout_row_dynamic(ctx, 2, 1);
                        nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
                        nk_layout_row_dynamic(ctx, 25, 1);
                        if (nk_contextual_item_label(ctx, "File", NK_TEXT_LEFT)) {
                            new_filereq.is_file = true;
                            new_filereq.cleanup = true;
                            dialog->msg_box = messagebox_custom("New File", on_new_file, &new_filereq);
                            nk_contextual_close(ctx);
                            goto ctx_end;
                        }

                        if (nk_contextual_item_label(ctx, "Directory", NK_TEXT_LEFT)) {
                            new_filereq.is_file = false;
                            new_filereq.cleanup = true;
                            dialog->msg_box = messagebox_custom("New Directory", on_new_file, &new_filereq);
                            nk_contextual_close(ctx);
                            goto ctx_end;
                        }
                        nk_layout_row_dynamic(ctx, 2, 1);
                        nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
                        nk_layout_row_dynamic(ctx, 25, 1);
                    }

                    if (nk_contextual_item_label(ctx, "Search", NK_TEXT_LEFT)) {
                        search_filter.cleanup = true;
                        dialog->msg_box = messagebox_custom("Search", on_search, &search_filter);
                        nk_contextual_close(ctx);
                        goto ctx_end;
                    }

                    nk_checkbox_label(ctx, "Show hidden files", &show_hiden);
#ifdef _WIN32
                    nk_checkbox_label(ctx, "Show system files", &show_system_hidden);
#endif

ctx_end:
                    nk_contextual_end(ctx);
                } else {
                    new_open = false;
                }

                nk_layout_row_template_begin(ctx, 32);
                nk_layout_row_template_push_static(ctx, 32);
                nk_layout_row_template_push_dynamic(ctx);
                nk_layout_row_template_end(ctx);

                for (size_t i = 0; i < dialog->content_size; i++) {
                    struct dir_entry *e = dialog->dir_content + i;
                    if (i != dialog->selected_index)
                        e->selected = false;

                    if (e->hidden && !show_hiden)
                        continue;
#ifdef _WIN32
                    if (e->system_hidden && !show_system_hidden)
                        continue;
#endif

                    if (search_filter.buffer != NULL)
                        if (strncmp(search_filter.buffer, e->name, search_filter.len) != 0)
                            continue;

                    nk_bool prev = e->selected;
                    enum image_type type = DIR_IMG;

                    if (e->is_file)
                        type++;

                    if (filter_out(e->name, img_filter) != NULL)
                        type = IMG_IMG;

                    nk_image(ctx, images[type]);
                    nk_selectable_label(ctx, e->name, NK_TEXT_LEFT, &e->selected);

                    if (e->selected) {
                        dialog->selected_index = i;
                    }

                    if (prev == true && e->selected == false) {
                        if (!e->is_file) {
                            filedialog_enter(dialog, e->name);
                            if (search_filter.buffer != NULL) {
                                free(search_filter.buffer);
                                search_filter.cleanup = false;
                                search_filter.buffer = NULL;
                                search_filter.len = 0;
                            }
                            goto end;
                        } else {
                            if (dialog->selected_index != -1)
                                dialog->show = false;
                        }
                    }
                }

#ifdef _WIN32
                if (dialog->current_directory.next == NULL && dialog->current_directory.name == NULL) {
                    struct nk_style_button style = ctx->style.contextual_button;
                    style.hover = ctx->style.contextual_button.normal;
                    style.text_alignment = NK_TEXT_LEFT;

                    nk_layout_row_dynamic(ctx, 2, 1);
                    nk_rule_horizontal(ctx, ctx->style.window.border_color, false);
                    nk_layout_row_dynamic(ctx, 32, 1);

                    nk_label(ctx, "Other Locations: ", NK_TEXT_LEFT);

                    nk_layout_row_template_begin(ctx, 32);
                    nk_layout_row_template_push_static(ctx, 32);
                    nk_layout_row_template_push_dynamic(ctx);
                    nk_layout_row_template_end(ctx);

                    DWORD drives = GetLogicalDrives();
                    for (int i = 0; i < 26; i++) {
                        if (drives & (1 << i)) {
                            char drive[] = {'A', ':', 0};
                            drive[0] += i;

                            nk_image(ctx, images[DRIVE_IMG]);
                            if (nk_button_label_styled(ctx, &style, drive)) {
                                
                                dialog->current_drive_letter = drive[0];
                                free(search_filter.buffer);
                                search_filter.cleanup = false;
                                search_filter.buffer = NULL;
                                search_filter.len = 0;

                                deinit_content(dialog);
                                init_content(dialog);
                                goto end;
                            }
                        }
                    }
                }
#endif
end:
                nk_group_end(ctx);
            }

            nk_layout_row_end(ctx);
            nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
            nk_layout_row_push(ctx, 0.7f);

            const char *selected = "";
            if (dialog->selected_index != -1)
                selected = dialog->dir_content[dialog->selected_index].name;

            len = strlen(selected) + 1;

            nk_edit_string(ctx, NK_EDIT_DEACTIVATED, (char*) selected, &len, len, nk_filter_default);
            nk_widget_disable_end(ctx);
            nk_layout_row_push(ctx, 0.2f);

            struct nk_vec2 new_size = nk_widget_size(ctx);

            const char *filter = NULL;
            if (dialog->filter != NULL)
                filter = dialog->filter;

            if (filter != NULL && nk_combo_begin_label(ctx, "Filters", nk_vec2(new_size.x, 100))) {
                nk_layout_row_dynamic(ctx, 30, 1);
                const char *iter = filter;
                do {
                    const char *prev = iter;
                    if (*prev == 0)
                        break;

                    iter = strchrnul(iter, ';');
                    size_t len = iter - prev;
                    char split[len + 1];
                    memset(split, 0, len + 1);
                    memcpy(split, prev, len);
                    nk_label(ctx, split, NK_TEXT_LEFT);
                } while (iter++);

                nk_combo_end(ctx);
            } else {
                if (filter == NULL)
                    nk_label(ctx, "Every File", NK_TEXT_CENTERED);
            }

            nk_layout_row_push(ctx, 0.1f);
            if (nk_button_label(ctx, "Select")) {
                if (dialog->selected_index != -1) {
                    struct dir_entry *e = dialog->dir_content +
                        dialog->selected_index;

                    if (!e->is_file)
                        filedialog_enter(dialog, e->name);
                    else
                        dialog->show = false;
                } else
                    dialog->msg_box = messagebox_error("Select a File",
                        "Please select a file!");
            }

            nk_layout_row_end(ctx);

            if (dialog->msg_box.userdata == &new_filereq) {
                if (dialog->msg_box.res == 1) {
                    path_append_file(&dialog->current_directory,strdup(new_filereq.buffer));

                    size_t sz = path_bufsz(&dialog->current_directory);
                    char tmpbuf[sz + 1];
                    memset(tmpbuf, 0, sz + 1);
                    path_str(&dialog->current_directory, sz, tmpbuf);

#ifdef _WIN32
                    *tmpbuf = dialog->current_drive_letter;
#endif

                    if (new_filereq.is_file) {
                        int fd = open(tmpbuf, O_CREAT, DEFFILEMODE);

                        filedialog_up(dialog);

                        if (fd == -1) {
#ifndef _WIN32
                            if (errno == EACCES) {
#else
                            DWORD err = GetLastError();
                            if (err == ERROR_ACCESS_DENIED) {
#endif
                                dialog->msg_box =
                                    messagebox_error("Error", "Permissions Denied!");
#ifdef _WIN32
                            } else if (err == ERROR_NO_MORE_FILES) {
                                dialog->msg_box =
                                    messagebox_error("Error", "File Exists!");
#endif
                            } else {
                                perror("open");
                                abort();
                            }
                        } else {
                            close(fd);
                        }
                    } else {
#ifndef _WIN32
                        int res = mkdir(tmpbuf, 0755);
#else
                        int res = mkdir(tmpbuf);
#endif
                        filedialog_up(dialog);

                        if (res == -1) {
#ifndef _WIN32
                            switch (errno) {
                            case EACCES:
                                dialog->msg_box =
                                    messagebox_error("Error", "Permissions Denied!");
                                break;
                            case EEXIST:
                                dialog->msg_box =
                                    messagebox_error("Error", "Directory Exists!");
                                break;
#else
                            switch (GetLastError()) {
                            case ERROR_ACCESS_DENIED:
                                dialog->msg_box =
                                    messagebox_error("Error", "Permissions Denied!");
                                break;
                            case ERROR_NO_MORE_FILES:
                                dialog->msg_box =
                                    messagebox_error("Error", "Directory Exists!");
                                break;
#endif
                            default:
                                perror("mkdir");
                                abort();
                            }
                        }
                    }

                    dialog->msg_box.userdata = NULL;
                }
            }
        } else {
            struct nk_vec2 wprop = nk_window_get_position(ctx);
            dialog->geometry.x = wprop.x;
            dialog->geometry.y = wprop.y;

            wprop = nk_window_get_size(ctx);

            dialog->geometry.w = wprop.x;
            dialog->geometry.h = wprop.y;

            dialog->show = false;
        }

        nk_end(ctx);
    }
}

void filedialog_deinit(struct filedialog *dialog)
{
    path_deinit(&dialog->current_directory, true);
    dialog->current_directory.is_file = false;
    dialog->current_directory.name = NULL;

    deinit_content(dialog);

    dialog->open_for_write = false;
    dialog->show = false;

    dialog->geometry = nk_rect(0, 0, 0, 0);
}

static void init_content(struct filedialog *dialog)
{
    size_t sz = path_dirsz(&dialog->current_directory);
    char buf[sz + 1];
    memset(buf, 0, sz + 1);
    path_dir(&dialog->current_directory, sz, buf);

#ifndef _WIN32
    int fd = open(buf, O_RDONLY | O_DIRECTORY);

    if (fd == -1) {
        if (errno == EACCES) {
            dialog->msg_box = messagebox_error("Error", "Permissions Denied!");
            return;
        }

        printf("About to abort on path: %s\n", buf);
        perror("open");
        abort();
    }

    DIR *dir = fdopendir(fd);
#else
    *buf = dialog->current_drive_letter;
    DIR *dir = opendir(buf);
    if (dir == NULL) {
        if (GetLastError() == ERROR_ACCESS_DENIED) {
            dialog->msg_box = messagebox_error("Error", "Permissions Denied!");
            return;
        }

        printf("About to abort on path: %s\n", buf);
        perror("open");
        abort();
    }
#endif

    struct dirent *entry = NULL;

    while ((entry = readdir(dir)) != NULL) {
        size_t len = strlen(entry->d_name);
        if (len == 1 || len == 2) {
            if (len == 1 && *entry->d_name == '.')
                continue;

            if (*entry->d_name == '.' && entry->d_name[1] == '.')
                continue;
        }

#ifndef _WIN32
        switch (entry->d_type) {
        case DT_DIR:
            append_file(dialog, entry->d_name)->is_file = false;
            break;
        case DT_REG: {
            const char *out = filter_out(entry->d_name, dialog->filter);

            if (out != NULL)
                append_file(dialog, out);

            break;
        }
        case DT_UNKNOWN: {
#endif
            struct stat s;
            size_t full_sz = path_dirsz(&dialog->current_directory);
            char full_buf[full_sz + 1];
            memset(full_buf, 0, full_sz + 1);
            path_dir(&dialog->current_directory, full_sz, full_buf);

            strcat(full_buf, entry->d_name);
#ifndef _WIN32
            int res = lstat(full_buf, &s);
#else
            *full_buf = dialog->current_drive_letter;
            int res = stat(full_buf, &s);
#endif
            if (res == -1) {
                printf("Failing on '%s'\n", entry->d_name);
                perror("stat");
                abort();
            }

            if (S_ISDIR(s.st_mode)) {
#ifndef _WIN32
                append_file(dialog, entry->d_name)->is_file = false;
#else
                append_file(dialog, entry->d_name, full_buf)->is_file = false;
#endif
            } else if (S_ISREG(s.st_mode)) {
                const char *out = filter_out(entry->d_name, dialog->filter);

                if (out != NULL) {
#ifndef _WIN32
                    append_file(dialog, out);
#else
                    append_file(dialog, out, full_buf);
#endif
                }
            }

#ifndef _WIN32
            break;
        }
        default:
            continue;
        }
#endif
    }

    /* sort */
    qsort(dialog->dir_content, dialog->content_size, sizeof(struct dir_entry), entry_comparar);

    closedir(dir);
}

static void deinit_content(struct filedialog *dialog)
{
    if (dialog->dir_content != NULL) {
        for (size_t i = 0; i < dialog->content_size; i++) {
            free(dialog->dir_content[i].name);
        }

        free(dialog->dir_content);
    }

    dialog->content_size = 0;
    dialog->dir_content = NULL;
    dialog->selected_index = -1;
}

static const char *filter_out(const char *filename, const char *filter)
{
    const char *iter = filter;
    const char *ext = strrchr(filename, '.');

    if (filter == NULL)
        return filename;

    if (ext == NULL)
        return NULL;

    ext++;

    do {
        char *next = strchrnul(iter, ';');

        *next = 0;

        if (strcmp(ext, iter) == 0)
            return filename;

        iter = next + 1;

        if (*iter == 0)
            break;

        *next = ';';
    } while (iter != NULL);

    return NULL;
}

#ifndef _WIN32
static struct dir_entry *append_file(struct filedialog *dialog, const char *name)
#else
static struct dir_entry *append_file(struct filedialog *dialog, const char *name, const char *full_path)
#endif
{
    dialog->dir_content = realloc(
        dialog->dir_content, sizeof(struct dir_entry) * ++dialog->content_size);

    struct dir_entry *e = dialog->dir_content + (dialog->content_size - 1);
    e->selected = false;
    e->is_file = true;
    e->hidden = false;
    e->name = strdup(name);

#ifndef _WIN32
    e->hidden = hide_file(name) == 1;
#else
    e->hidden = hide_file(full_path) == 1;
    e->system_hidden = hide_file(full_path) == 2;
#endif

    return e;
}

static int hide_file(const char *path)
{
#ifndef _WIN32
    if (*path == '.')
        return 1;
#else
    DWORD attributes = GetFileAttributes(path);
    if (attributes & FILE_ATTRIBUTE_SYSTEM)
        return 2;

    if (attributes & FILE_ATTRIBUTE_HIDDEN)
        return 1;
#endif
    return 0;
}

void filedialog_register_icon(enum image_type type, struct nk_image img)
{
    images[type] = img;
}

static int entry_comparar(const void *p1, const void *p2)
{
    const struct dir_entry *e1 = p1;
    const struct dir_entry *e2 = p2;

    if (e1->is_file != e2->is_file)
        return e1->is_file - e2->is_file;

    return strcmp(e1->name, e2->name);
}

static int on_new_file(struct nk_context *ctx, struct messagebox *box)
{
    struct new_file *req = box->userdata;

    if (req->cleanup) {
        if (req->buffer != NULL) {
            free(req->buffer);
        }
        req->cleanup = false;
        req->buffer = malloc(1);
        *req->buffer = 0;
        req->len = 0;
    }

    int new_len = req->len;

    nk_layout_row_dynamic(ctx, 25, 1);
    nk_label(ctx, "Enter name: ", NK_TEXT_LEFT);
    nk_edit_string(ctx, NK_EDIT_SIMPLE, req->buffer, &new_len, req->len + 2, nk_filter_default);

    if (new_len > req->len) {
        req->buffer = realloc(req->buffer, ++req->len + 1);
        req->buffer[req->len] = 0;
    } else if (new_len < req->len) {
        req->buffer[new_len] = 0;
        req->len--;
    }

    struct nk_rect bounds = nk_window_get_content_region(ctx);

    bounds.h -= 25 * 4;

    nk_layout_row_dynamic(ctx, bounds.h, 1);
    nk_label(ctx, " ", NK_TEXT_LEFT);

    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
    nk_layout_row_push(ctx, 0.7f);
    nk_label(ctx, " ", NK_TEXT_LEFT);

    nk_layout_row_push(ctx, 0.15f);
    if (nk_button_label(ctx, "Cancel"))
        return 0;

    nk_layout_row_push(ctx, 0.14f);
    if (nk_button_label(ctx, "Ok"))
        return 1;

    return -1;
}

static int on_search(struct nk_context *ctx, struct messagebox *box)
{
    struct input_buffer *req = box->userdata;

    if (req->cleanup) {
        if (req->buffer != NULL) {
            free(req->buffer);
        }
        req->cleanup = false;
        req->buffer = malloc(1);
        *req->buffer = 0;
        req->len = 0;
    }

    int new_len = req->len;

    nk_layout_row_dynamic(ctx, 25, 1);
    nk_label(ctx, "Search term: ", NK_TEXT_LEFT);
    nk_edit_string(ctx, NK_EDIT_SIMPLE, req->buffer, &new_len, req->len + 2, nk_filter_default);

    if (new_len > req->len) {
        req->buffer = realloc(req->buffer, ++req->len + 1);
        req->buffer[req->len] = 0;
    } else if (new_len < req->len) {
        req->buffer[new_len] = 0;
        req->len--;
    }

    struct nk_rect bounds = nk_window_get_content_region(ctx);

    bounds.h -= 25 * 4;

    nk_layout_row_dynamic(ctx, bounds.h, 1);
    nk_label(ctx, " ", NK_TEXT_LEFT);

    nk_layout_row_begin(ctx, NK_DYNAMIC, 30, 3);
    nk_layout_row_push(ctx, 0.85f);
    nk_label(ctx, " ", NK_TEXT_LEFT);

    nk_layout_row_push(ctx, 0.14f);
    if (nk_button_label(ctx, "Ok"))
        return 0;

    return -1;
}