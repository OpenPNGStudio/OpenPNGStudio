#ifndef _PATHBUF_H_
#define _PATHBUF_H_

#include <stdbool.h>
#include <stdio.h>

#ifndef _WIN32
#define PATH_SEPARATOR '/'
#else
#define PATH_SEPARATOR '\\'
#endif

struct path {
    bool is_file;
    char *name;
    struct path *next;
};

void append_dir(struct path *path, char *new_path);
void append_file(struct path *path, char *filename);

/* caller must free returned path */
struct path *pop_path(struct path *path);

/* return byte count for the entire path */
size_t path_bufsz(const struct path *path);
/* return byte count for path to the last dir */
size_t path_dirsz(const struct path *path);

/* return base name of the path */
const char *path_basename(const struct path *path);

/* stringify path */
void path_dir(const struct path *path, size_t dir_bufsz, char *buf);
void path_str(const struct path *path, size_t path_bufsz, char *buf);

void deinit_path(struct path *path, bool free_strings);

#endif