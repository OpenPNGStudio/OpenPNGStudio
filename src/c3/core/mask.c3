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
module openpngstudio::core::mask;

import raylib5::rl;
import std::io;

alias Mask = ulong;

/*
 * Mask structure
 * 0-2 bits - state
 * 3-6 bits - mod keys
 * 7-33 bits - ASCII key
 */

/* true when one matches */
const Mask QUIET = 1; /* << 0 */
const Mask TALK = 1 << 1;
const Mask PAUSE = 1 << 2;

/* true when all selected match */
const Mask SHIFT = 1 << 3;
const Mask CTRL = 1 << 4;
const Mask SUPER = 1 << 5;
const Mask META = 1 << 6;

/*
 * 1ULL << (toupper(key) - 'A' + KEY_START)
 * true when one matches, layer can be active with only one keybinding
 */
const Mask KEY_START = 7;

const Mask DEFAULT_LAYER_MASK = QUIET | TALK | PAUSE;

Mask current @local = QUIET;

fn void set(Mask mask) @export("set_current_mask")
{
    current = mask;
}

fn Mask get() @export("get_current_mask")
{
    return current;
}

fn void update(Mask *mask) @export("set_key_mask")
{
    int key = rl::getKeyPressed();
    if (key >= 'A' && key <= 'Z') {
        *mask |= 1UL << ((Mask) key - 'A' + KEY_START);
    }

    if (rl::isKeyPressed(rl::KEY_LEFT_SHIFT) ||
        rl::isKeyPressed(rl::KEY_RIGHT_SHIFT)) *mask |= SHIFT;

    if (rl::isKeyPressed(rl::KEY_LEFT_CONTROL) ||
        rl::isKeyPressed(rl::KEY_RIGHT_CONTROL)) *mask |= CTRL;

    if (rl::isKeyPressed(rl::KEY_LEFT_SUPER) ||
        rl::isKeyPressed(rl::KEY_RIGHT_SUPER)) *mask |= SUPER;

    if (rl::isKeyPressed(rl::KEY_LEFT_ALT) ||
        rl::isKeyPressed(rl::KEY_RIGHT_ALT)) *mask |= META;
}

fn void handle(Mask *mask) @export("handle_key_mask")
{
    Mask m = *mask;
    Mask new_mask = 0;

    for (int i = 0; i <= 26; i++) {
        Mask bit = 1UL << ((Mask) i + KEY_START);
        if (m & bit) {
            if (rl::isKeyDown((KeyboardKey) i + 'A')) new_mask |= bit;
        }
    }

    if (rl::isKeyDown(rl::KEY_LEFT_SHIFT) ||
        rl::isKeyDown(rl::KEY_RIGHT_SHIFT)) new_mask |= SHIFT;

    if (rl::isKeyDown(rl::KEY_LEFT_CONTROL) ||
        rl::isKeyDown(rl::KEY_RIGHT_CONTROL)) new_mask |= CTRL;

    if (rl::isKeyDown(rl::KEY_LEFT_SUPER) ||
        rl::isKeyDown(rl::KEY_RIGHT_SUPER)) new_mask |= SUPER;

    if (rl::isKeyDown(rl::KEY_LEFT_ALT) ||
        rl::isKeyDown(rl::KEY_RIGHT_ALT)) new_mask |= META;

    for (int i = 0; i < 3; i++) new_mask |= 1UL << i;

    *mask &= new_mask;
}

fn bool cmp(Mask mask, Mask target) @export("test_masks")
{
    Mask[3] states = {QUIET, TALK, PAUSE};
    bool res = false;
    bool has_mask = false;

    /* check state */
    for (int i = 0; i < 3; i++) {
        Mask extract_mask = mask & states[i];
        Mask extract_layer = target & states[i];

        if (extract_layer == 0) continue;

        if (extract_mask == extract_layer) {
            res = true;
            break;
        }

        has_mask = true;
    }

    Mask[4] mods = {SHIFT, CTRL, SUPER, META};

    bool is_mod_set = false;
    for (int i = 0; i < 4; i++) {
        if (target & mods[i]) {
            is_mod_set = true;
            break;
        }
    }

    if (is_mod_set) {
        for (int i = 0; i < 4; i++) {
            Mask extract_mask = mask & mods[i];
            Mask extract_layer = target & mods[i];
            if (extract_mask != extract_layer) return false;
        }

        if (has_mask && res == true) { res = true;}
        else if (!has_mask && res == false) { res = true; }
    }

    int has_key = -1;
    for (int i = 0; i <= 26; i++) {
        if (target & ((Mask) 1UL << ((Mask) i + KEY_START))) {
            has_key = i;
            break;
        }
    }

    if (has_key != -1) {
        if (!(mask & ((Mask) 1UL << ((Mask) has_key + KEY_START)))) return false;

        if (has_mask && res == true) { res = true; }
        else if (!has_mask && res == false) { res = true; }
    }

    return res;
}
