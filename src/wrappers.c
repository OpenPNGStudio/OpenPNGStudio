/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <stdio.h>

#ifdef _WIN32
// move the windows functions to new names
// note that you can't call these functions or structures from your code, but you should not neeed to
#define CloseWindow CloseWindowWin32
#define Rectangle RectangleWin32
#define ShowCursor ShowCursorWin32
#define LoadImageA LoadImageAWin32
#define LoadImageW LoadImageWin32
#define DrawTextA DrawTextAWin32
#define DrawTextW DrawTextWin32
#define DrawTextExA DrawTextExAWin32
#define DrawTextExW DrawTextExWin32
#define PlaySoundA PlaySoundAWin32
// include windows
#define WIN32_LEAN_AND_MEAN 
#include <windows.h>

// remove all our redfintions so that raylib can define them properly
#undef CloseWindow
#undef Rectangle
#undef ShowCursor
#undef LoadImage 
#undef LoadImageA
#undef LoadImageW
#undef DrawText 
#undef DrawTextA
#undef DrawTextW
#undef DrawTextEx 
#undef DrawTextExA
#undef DrawTextExW
#undef PlaySoundA
#endif

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
