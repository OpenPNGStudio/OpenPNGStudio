/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdbool.h>
#include <core/mask.h>
#include <c3.h>

struct layer_state {
    c3any_t anim;
    mask_t mask;
    mask_t anim_mask;

    int time_to_live;
    bool active;
    bool is_toggled;
    bool prepare_for_deletion;
    bool is_toggle_timer_ticking;

    int selected_animation;
};

