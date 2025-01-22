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

#include <raylib-nuklear.h>
#include <console.h>
#include <icon_db.h>

static struct nk_image db[ICON_DB_SIZE] = {0};

void register_icon(enum icon_type type, struct nk_image img)
{
    db[type] = img;
}

struct nk_image get_icon(enum icon_type type)
{
    return db[type];
}

void cleanup_icons()
{
    for (int i = 0; i < ICON_DB_SIZE; i++)
        UnloadNuklearImage(db[i]);
}
