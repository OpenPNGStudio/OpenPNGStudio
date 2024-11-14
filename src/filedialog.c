#include "str.h"
#include <dirent.h>
#include <fcntl.h>
#include <pathbuf.h>
#include <stdio.h>
#include <stdlib.h>
#include <filedialog.h>
#include <string.h>
#include <sys/stat.h>

static struct dir_entry *append_file(struct filedialog *dialog, const char *name);
static const char *filter_out(const char *filename, const char *filter);
static void init_content(struct filedialog *dialog);
static void deinit_content(struct filedialog *dialog);

void filedialog_init(struct filedialog *dialog, bool write)
{
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
    path_append_dir(&dialog->current_directory, (char*) dir);

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

    buf += sz;
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

void filedialog_run(struct filedialog *dialog)
{
}

void filedialog_deinit(struct filedialog *dialog)
{
    path_deinit(&dialog->current_directory, true);
    dialog->current_directory.is_file = false;
    dialog->current_directory.name = NULL;

    deinit_content(dialog);

    dialog->row_width = 0;
    dialog->open_for_write = false;
    dialog->show = false;
}

static void init_content(struct filedialog *dialog)
{
    size_t sz = path_dirsz(&dialog->current_directory);
    char buf[sz + 1];
    memset(buf, 0, sz + 1);
    path_dir(&dialog->current_directory, sz, buf);

    int fd = open(buf, O_RDONLY | O_DIRECTORY);

    if (fd == -1) {
        perror("open");
        abort();
    }

    DIR *dir = fdopendir(fd);

    struct dirent *entry = NULL;

    while ((entry = readdir(dir)) != NULL) {
        size_t len = strlen(entry->d_name);
        if (len == 1 || len == 2) {
            if (len == 1 && *entry->d_name == '.')
                continue;

            if (*entry->d_name == '.' && entry->d_name[1] == '.')
                continue;
        }

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
            struct stat s;
            if (lstat(entry->d_name, &s) == -1) {
                perror("lstat");
                abort();
            }

            if (S_ISDIR(s.st_mode)) {
                append_file(dialog, entry->d_name)->is_file = false;
            } else if (S_ISREG(s.st_mode)) {
                const char *out = filter_out(entry->d_name, dialog->filter);

                if (out != NULL)
                    append_file(dialog, out);
            }

            break;
        }
        default:
            continue;
        }
    }

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

static struct dir_entry *append_file(struct filedialog *dialog, const char *name)
{
    dialog->dir_content = realloc(
        dialog->dir_content, sizeof(struct dir_entry) * ++dialog->content_size);

    struct dir_entry *e = dialog->dir_content + (dialog->content_size - 1);
    e->is_file = true;
    e->name = strdup(name);

    return e;
}