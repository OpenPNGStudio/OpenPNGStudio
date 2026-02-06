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
    COMBO_OPEN2,
    PICK,

    OPEN,
    SAVE,
    LAYERS,
    SHORTCUTS,
    HELP,

    DIR,
    FILE,
    DRIVE,

    DB_SIZE
}

nk::Image[Type.DB_SIZE] db @local;

fn void set(Type t, nk::Image img)
{
    db[t] = img;
}

fn nk::Image get(Type t) => db[t];

extern fn void unload_nk_image(nk::Image) @cname("UnloadNuklearImage");

import std::io;

fn void cleanup()
{
    foreach (i, img : &db) unload_nk_image(img);
}
