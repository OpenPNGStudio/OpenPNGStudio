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

void path_append_dir(struct path *path, char *new_path);
void path_append_file(struct path *path, char *filename);

/* 
 * caller must free returned path
 * if the function returns NULL, it means there is nothing to pop,
 * it's the same object, just so the caller doesn't accidentally free
 * the memory it uses
 */
struct path *path_pop(struct path *path);

/* return byte count for the entire path */
size_t path_bufsz(const struct path *path);
/* return byte count for path to the last dir */
size_t path_dirsz(const struct path *path);

/* return base name of the path */
const char *path_basename(const struct path *path);

/* stringify path */
void path_dir(const struct path *path, size_t dir_bufsz, char *buf);
void path_str(const struct path *path, size_t path_bufsz, char *buf);

void path_deinit(struct path *path, bool free_strings);

#endif
