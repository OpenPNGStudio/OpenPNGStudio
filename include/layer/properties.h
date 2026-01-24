/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdbool.h>
#include <raylib.h>

struct layer_properties {
    Image image;
    Texture2D texture;

    Vector2 offset;
    float rotation;
    Color tint;

    bool has_toggle;
    bool is_animated;
};

