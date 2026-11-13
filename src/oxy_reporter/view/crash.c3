module oxy_reporter::crash @if($feature(OXY_REPORTER_STANDALONE));

import std::io;
import std::core::string;

import oxy_reporter;
import raylib5::rl;

bool crash_info = true;
bool application_log = true;
bool system_env = false;
char[129] message;
ZString str = &message;

extern fn int guiTextBox(Rectangle bounds, ZString text, int text_size, bool editable) @cname("GuiTextBox");

fn GuiState draw(Texture2D icon)
{
    rl::drawTextureEx(icon, { 10, -10 }, 0, 1, rl::WHITE);

    draw_text("OpenPNGStudio crashed", 145, 24, 26, rl::WHITE);
    draw_text("Select what you'd like to package", 145, 60, 18, rl::WHITE);
    draw_text("to help troubleshoot the problem.", 145, 82, 18, rl::WHITE);

    draw_text("What to include:", 10, 128, 20, rl::WHITE);
    rl::drawRectangleLines(10, 150, 428, 240, rl::WHITE);

    if (!oxy_reporter::no_core) {
        crash_info = draw_check(15, 160, crash_info);
    } else {
        draw_check(15, 160, false);
    }

    draw_text("Crash State & Memory Dump (Recommended)", 40, 160, 20, rl::WHITE);
    draw_text("Exact call stack, crash signal & memory snapshot.", 40, 184, 18, rl::WHITE);
    draw_text("Provides the highest chance of finding the bug.", 40, 204, 18, rl::WHITE);

    if (!oxy_reporter::no_core) {
        draw_text("Note: captures RAM state; may contain images,", 40, 224, 18, rl::YELLOW);
        draw_text("they aren't kept after bug was found.", 40, 244, 18, rl::YELLOW);
    } else {
        draw_text("Note: no crash state was captured,", 40, 224, 18, rl::YELLOW);
        draw_text("thus this option is disabled.", 40, 244, 18, rl::YELLOW);
    }

    application_log = draw_check(15, 280, application_log);
    draw_text("Application Runtime Log", 40, 280, 20, rl::WHITE);

    draw_text("Standard app events and console log up to crash.", 40, 304, 18, rl::WHITE);

    system_env = draw_check(15, 340, system_env);
    draw_text("System Environment", 40, 340, 20, rl::WHITE);
    draw_text("OS Release, CPU, GPU, display server type.", 40, 364, 18, rl::WHITE);

    draw_text("Quick Note (Optional):", 10, 405, 20, rl::WHITE);
    @pool() {
        usz len = str.len();
        ZString out = string::tformat_zstr("%d/128", len);

        draw_text(out, 390 - (10 * (len >= 100 ? 2 : (len >= 10 ? 1 : 0))),
            405, 18, len >= 128 ? rl::RED : (len >= 96 ? rl::YELLOW : rl::WHITE));
    };
    rl::drawRectangleRounded({ 10, 427, 428, 32 }, 0.5f, 8, {0x19, 0x19, 0x19, 0xFF});
    guiTextBox({ 12, 427, 426, 32 }, &message, message.len, true);

    draw_text("Briefly describe what you were doing.", 10, 463, 18, rl::GRAY);

    if (draw_button(10, 527, "Don't Save")) return END;

    if (draw_button(285, 527, "Generate Report", { 0x7E, 0x57, 0xC2, 0xFF })) return PACK;

    return MAIN_SCREEN;
}
