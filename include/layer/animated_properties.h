/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdint.h>

struct animated_layer_properties {
    uint8_t *gif_file_content;
    uint64_t gif_file_size;
    uint32_t *frame_delays;
    uint64_t number_of_frames;
    uint64_t current_frame_index;
    uint64_t previous_frame_index;
};
