/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::icondb;

import nk;

enum IconType : const int {
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
}

extern fn void register_icon(IconType type, nk::Image img);
extern fn nk::Image get_icon(IconType type);

extern fn void cleanup_icons();
