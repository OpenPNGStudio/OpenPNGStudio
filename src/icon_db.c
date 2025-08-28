/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <raylib-nuklear.h>
#include <console.h>
#include <core/icon_db.h>

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
