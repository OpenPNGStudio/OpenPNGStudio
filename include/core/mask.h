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

#include <nuklear.h>
#include <stdint.h>
#include <stdbool.h>

typedef uint64_t mask_t;

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

#define DEFAULT_MASK (QUIET | TALK | PAUSE)

void set_current_mask(mask_t mask);
mask_t get_current_mask();

void set_key_mask(mask_t *mask);
void handle_key_mask(mask_t *mask);
bool test_masks(mask_t mask, mask_t target);
void configure_mask(mask_t *mask, char *input, int *size, struct nk_context *ctx);
