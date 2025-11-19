/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;
import std::io;

import novacrash;
import novacrash::options;

extern fn int c_main();

fn int main() @winmain {
    novacrash::uses_raylib = true;
    options::cfg.app_name = "OpenPNGStudio";
    options::cfg.message = "has reached a";

    options::cfg.window = {
        .title = "OpenPNGStudio crash report",
        .width = 500,
        .height = 750,
    };

    options::cfg.theme = {
        .background = { 0x16, 0x16, 0x16, 0xff },
        .foreground = { 0xbe, 0xbe, 0xbe, 0xff },
        .font = $embed("../assets/fonts/VarelaRound-Regular.ttf"),
        .font_size = 22,
    };
    
    static ZString[] phrases = {"!!!", "XXX", "ERROR", "PANIC", "GUH", "WEH"};

    options::cfg.header = {
        .catch_phrases = phrases,
        .crash_icon = $embed("../assets/images/crash.png"),
        .title_size = 32,
    };

    return c_main();
}
