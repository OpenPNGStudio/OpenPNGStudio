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

#pragma once

#include <raylib-nuklear.h>

enum icon_type {
    /* UI Icons */
    UP_ICON,
    DOWN_ICON,
    BACK_ICON,
    SELECT_ICON,
    LOOP_ICON,
    TRASH_ICON,

    /* Image Icons */
    DIR_ICON,
    FILE_ICON,
    DRIVE_ICON,

    /* array size */
    ICON_DB_SIZE
};

void register_icon(enum icon_type type, struct nk_image img);
struct nk_image get_icon(enum icon_type type);

void cleanup_icons();
