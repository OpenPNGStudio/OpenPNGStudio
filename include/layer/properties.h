/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdbool.h>
#include <raylib.h>
#include <ui/line_edit.h>

struct layer_properties {
    Image image;
    Texture2D texture;

    Vector2 offset;
    float rotation;
    Color tint;

    struct line_edit name;

    bool has_toggle;
    bool is_animated;
};

