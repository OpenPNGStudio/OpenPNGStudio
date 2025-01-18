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

#ifndef _LINE_EDIT_H_
#define _LINE_EDIT_H_

#include <raylib-nuklear.h>
#include <stdbool.h>

struct line_edit {
    char *buffer;
    int len;
    bool cleanup;
};

void line_edit_cleanup(struct line_edit *edit);
void line_edit_draw(struct line_edit *edit, struct nk_context *ctx);

#endif
