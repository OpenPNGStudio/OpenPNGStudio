/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <raylib-nuklear.h>

enum icon_type {
    /* UI Icons */
    LEFT_ICON,
    RIGHT_ICON,
    UP_ICON,
    DOWN_ICON,
    SELECT_ICON,
    LOOP_ICON,
    TRASH_ICON,
    CFG_ICON,
    CANCEL_ICON,
    CHECK_ICON,
    MINIMIZE_ICON,

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
