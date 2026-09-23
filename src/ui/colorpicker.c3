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
    bool res, popup_active;
}

import std::io;

fn void ColorPicker.ui(&self, nk::Context *ctx)
{
    nk::Rect bounds = nk::widget_bounds(ctx);
    if (nk::button_color(ctx, nk::rgb_cf(self.color))) self.popup_active = true;

    if (self.popup_active) {
        if (nk::popup_begin(ctx, nk::POPUP_STATIC, "#Color Picker", nk::WINDOW_NO_SCROLLBAR, nk::rect(0, bounds.h * 1.25, 256, 256))) {
            nk::Rect body = nk::window_get_bounds(ctx);
            {
                bool pressed, in_button, in_body;
                pressed = nk::input_is_mouse_pressed(&ctx.input, nk::BUTTON_LEFT);
                in_button = nk::input_is_mouse_hovering_rect(&ctx.input, bounds);
                in_body = nk::input_is_mouse_hovering_rect(&ctx.input, body);

                if (pressed && !(in_body || in_button)) {
                    nk::popup_close(ctx);
                    self.popup_active = false;
                }
            }

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

            nk::popup_end(ctx);
        } else {
            self.popup_active = false;
        }
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
