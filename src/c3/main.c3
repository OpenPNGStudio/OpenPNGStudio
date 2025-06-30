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
module openpngstudio::layer;
import std::io;

import novacrash;
import novacrash::options;

extern fn int c_main();

fn int main() {
    novacrash::uses_raylib = true;
    options::cfg.app_name = "OpenPNGStudio";
    options::cfg.message = "has reached a";

    options::cfg.window = {
        .title = "OpenPNGStudio crash report",
        .width = 500,
        .height = 750,
    };

    options::cfg.theme = {
        .background = { 0x28, 0x28, 0x28, 0xff },
        .foreground = { 0xaf, 0xaf, 0xaf, 0xff },
        .ambient = { 0x15, 0x5d, 0xfc, 0xff },
        .font = $embed("../../assets/fonts/Ubuntu-R.ttf"),
        .font_size = 22,
    };

    static ZString[] phrases = {"!!!", "XXX", "ERROR", "PANIC", "GUH", "WEH"};

    options::cfg.header = {
        .catch_phrases = phrases,
        /* .crash_icon = $embed(...), */
        .title_size = 32,
    };

    return c_main();
}
