#pragma once

/*
 * Mask structure
 * 0-2 bits - state
 * 3-6 bits - mod keys
 * 7-33 bits - ASCII key
 */

/* true when one matches */
enum mask_state {
    QUIET = 1, /* << 0 */
    TALK = 1 << 1,
    PAUSE = 1 << 2,
};

/* true when all selected match */
enum mask_mod {
    SHIFT = 1 << 3,
    CTRL = 1 << 4,
    SUPER = 1 << 5,
    META = 1 << 6,
};

/*
 * 1ULL << (toupper(key) - 'A' + KEY_START)
 * true when one matches, layer can be active with only one keybinding
 */
enum mask_key {
    KEY_START = 7,
};
