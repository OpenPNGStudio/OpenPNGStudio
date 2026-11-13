module oxy_reporter::report @if($feature(OXY_REPORTER_STANDALONE));

import std::io;
import std::core::string;
import std::os::process;

import oxy_reporter;
import oxy_reporter::pack;
import raylib5::rl;

const char[] INVITE_LINK = {
    0x32, 0x2E, 0x2E, 0x2A, 0x29, 0x60, 0x75, 0x75,
    0x3E, 0x33, 0x29, 0x39, 0x35, 0x28, 0x3E, 0x74,
    0x3D, 0x3D, 0x75,
    0x34, 0x17, 0x3B, 0x0D, 0x6C, 0x1D, 0x0F, 0x0F,
    0x03, 0x19
};

fn GuiState draw(Texture2D icon)
{
    rl::drawTextureEx(icon, { 10, 0 }, 0, 1, rl::WHITE);

    draw_text("Crash report ready!", 145, 24, 26, rl::WHITE);
    draw_text("Your report has been generated and", 145, 60, 18, rl::WHITE);
    draw_text("saved to your device.", 145, 82, 18, rl::WHITE);

    rl::drawRectangleLines(10, 140, 428, 58, rl::WHITE);
    draw_text("Saved to:", 20, 150, 20, rl::WHITE);
    draw_text(pack::pretty_loc, 20, 172, 18, rl::WHITE);

    draw_text("How to provide the crash report:", 10, 220, 20, rl::WHITE);

    draw_text("1. Click \"Join Discord\" below to enter the community", 30, 245, 18, rl::WHITE);
    draw_text("discord server.", 50, 261, 18, rl::WHITE);
    draw_text("2. Head to the #crash-reports channel.", 30, 284, 18, rl::WHITE);
    draw_text("3. Open a ticket and drag-and-drop the crash", 30, 308, 18, rl::WHITE);
    draw_text("report file there.", 50, 325, 18, rl::WHITE);

    draw_text("The ticket is private between you and developers.", 10, 370, 20, rl::WHITE);

    if (draw_button(10, 527, "Show in Folder")) open_dir();

    if (draw_button(247, 527, "Join Discord", { 88, 101, 242, 0xFF })) join_discord();

    if (draw_button(375, 527, "Done", { 0x7E, 0x57, 0xC2, 0xFF })) return END;

    return REPORT_SCREEN;
}

fn void open_dir()
{
    $if env::WIN32:
        (void) process::spawn({"explorer.exe", pack::root_dir.str_view()}, INHERIT_ENV);
    $else
        (void) process::spawn({"xdg-open", pack::root_dir.str_view()}, INHERIT_ENV);
    $endif
}

extern fn void shellExecute(void *a, ZString action, ZString url, void *b, void *c, int showcmd) @if(env::WIN32) @cname("ShellExecuteA");

fn void join_discord() => @pool()
{
    char[INVITE_LINK.len] buffer;

    foreach (i, &c : buffer) {
        *c = INVITE_LINK[i] ^ 0x5A;
    }

    String url = (String) &buffer;

    $if env::WIN32:
        shellExecute(null, "open", url.zstr_tcopy(), null, null, 1);
    $else
        (void) process::spawn({"xdg-open", url}, INHERIT_ENV);
    $endif
}
