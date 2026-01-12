/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::icons;

import nk;

enum Type : inline int {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    LOOP,
    TRASH,
    CFG,
    CANCEL,
    CHECK,
    MINIMIZE,
    MAXIMIZE,
    COMBO,
    COMBO_OPEN,

    OPEN,
    SAVE,
    SAVE_AS,
    LAYERS,
    SHORTCUTS,
    HELP,

    DIR,
    FILE,
    DRIVE,

    DB_SIZE
}

nk::Image[Type.DB_SIZE] db @local;

fn void set(Type t, nk::Image img) @export("register_icon")
{
    db[t] = img;
}

fn nk::Image get(Type t) @export("get_icon") => db[t];

fn void cleanup() @export("cleanup_icons")
{
}
