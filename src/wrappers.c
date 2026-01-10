/* SPDX-License-Identifier: GPL-3.0-or-later */

/* just to improve compilation times */
#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include <raylib-nuklear.h>

static Font nk_font;

void set_nk_font(Font font)
{
    nk_font = font;
}

Font get_nk_font()
{
    return nk_font;
}

#define MINIAUDIO_IMPLEMENTATION
#include <miniaudio.h>
#define RAYGUI_IMPLEMENTATION
#include <raygui.h>
