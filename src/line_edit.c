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

#include <stddef.h>
#include <stdlib.h>

#include <ui/line_edit.h>

void line_edit_draw(struct line_edit *edit, struct nk_context *ctx)
{
    if (edit->cleanup) {
        if (edit->buffer != NULL) {
            free(edit->buffer);
        }
        edit->cleanup = false;
        edit->buffer = malloc(1);
        *edit->buffer = 0;
        edit->len = 0;
    }

    int new_len = edit->len;

    nk_edit_string(ctx, NK_EDIT_FIELD, edit->buffer, &new_len, edit->len + 2, nk_filter_default);

    if (new_len > edit->len) {
        edit->buffer = realloc(edit->buffer, ++edit->len + 1);
        edit->buffer[edit->len] = 0;
    } else if (new_len < edit->len) {
        edit->buffer[new_len] = 0;
        edit->len--;
    }
}

void line_edit_cleanup(struct line_edit *edit)
{
    if (edit->cleanup) {
        if (edit->buffer != NULL) {
            free(edit->buffer);
        }
        edit->cleanup = false;
        edit->buffer = malloc(1);
        *edit->buffer = 0;
        edit->len = 0;
    }
}
