/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import nk;
import raylib5::rl;
import std::ascii;
import libc;

struct ColorPicker {
    nk::Colorf color;
    char[7] buffer;
    int buffer_len;
    bool res;
}

import std::io;

fn void ColorPicker.ui(&self, nk::Context *ctx)
{
    if (nk::group_begin(ctx, "Color Picker", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 216, 1);
        bool res = nk::color_pick(ctx, &self.color, nk::RGB);
        if (self.res != res && !res) {
            rl::Color color = openpngstudio::color_from_nk_f(self.color);
            libc::sprintf(&self.buffer, "%02x%02x%02x", color.r, 
                color.g, color.b);
            self.buffer_len = 6;
        }

        self.res = res;

        nk::layout_row_dynamic(ctx, 30, 1);
        nk::edit_string(ctx, nk::EDIT_FIELD, (CChar*) &self.buffer, 
            &self.buffer_len, 7, &nk::filter_hex);

        if (self.buffer_len == 6 && !res) self.convert_hex();

        nk::group_end(ctx);
    }
}

fn char hex_char_to_num(char c) @local
{
    c = ascii::to_upper(c);

    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }

    return 0xFF;
}

fn void ColorPicker.convert_hex(&self)
{
    rl::Color color;
    char *str = &self.buffer;

    color.r = hex_char_to_num(str[0]);
    color.r = (color.r << 4) + hex_char_to_num(str[1]);
    color.g = hex_char_to_num(str[2]);
    color.g = (color.g << 4) + hex_char_to_num(str[3]);
    color.b = hex_char_to_num(str[4]);
    color.b = (color.b << 4) + hex_char_to_num(str[5]);
    color.a = 0xFF;

    self.color = openpngstudio::color_to_nk_f(color);
}
