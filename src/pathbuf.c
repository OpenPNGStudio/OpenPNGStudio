#include "str.h"
#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <pathbuf.h>

void append_dir(struct path *path, char *new_path)
{
    assert(path != NULL);

    if (path->name == NULL) {
        path->name = new_path;
        return;
    }

    struct path *iter = path;
    for (; iter->next != NULL; iter = iter->next);

    iter->next = calloc(1, sizeof(*path));
    if (iter->next == NULL)
        abort();

    assert(iter->is_file == false);

    iter->next->name = new_path;
}

void append_file(struct path *path, char *filename)
{
    assert(path != NULL);

    if (path->name == NULL) {
        path->name = filename;
        path->is_file = true;
        return;
    }

    struct path *iter = path;
    for (; iter->next != NULL; iter = iter->next);

    iter->next = calloc(1, sizeof(*path));
    if (iter->next == NULL)
        abort();

    assert(iter->is_file == false);

    iter->next->name = filename;
    iter->next->is_file = true;
}

struct path *pop_path(struct path *path);

size_t path_bufsz(const struct path *path)
{
    assert(path != NULL);

#ifndef _WIN32
    size_t bufsz = 1; /* separator length is 1 */
#else
    size_t bufsz = 3; /* include drive letter */
#endif

    const struct path *iter = path;

    while (iter != NULL) {
        bufsz += strlen(iter->name);

        if (!iter->is_file)
            bufsz++; /* separator */

        iter = iter->next;
    }

    return bufsz;
}

size_t path_dirsz(const struct path *path);

const char *path_basename(const struct path *path);

void path_dir(const struct path *path, size_t dir_bufsz, char *buf);

void path_str(const struct path *path, size_t path_bufsz, char *buf)
{
    assert(path != NULL);

#ifndef _WIN32
    *buf = PATH_SEPARATOR;
#else
    memcpy(buf, "C:\\", 3); /* drive letter will be C most of the time */
#endif

    buf++;
    path_bufsz--;

    const struct path *iter = path;

    while (iter != NULL && path_bufsz > 0) {
        if (iter->is_file)
            path_bufsz--; /* no separator is next */

        size_t wrote = sized_strncpy(buf, iter->name, path_bufsz);
        path_bufsz -= wrote;

        buf += wrote;

        if (iter->is_file)
            return;

        if (path_bufsz <= 0)
            return;

        path_bufsz -= 1; /* separator */
        *buf = PATH_SEPARATOR;
        buf++;

        iter = iter->next;
    }
}

void deinit_path(struct path *path, bool free_strings)
{
    assert(path != NULL);

    struct path *iter = path->next;

    while (iter != NULL) {
        struct path *prev = iter;
        iter = iter->next;

        if (free_strings)
            free(prev->name);

        free(prev);
    }
}