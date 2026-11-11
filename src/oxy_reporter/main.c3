module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE));

import std::io, std::collections::object, std::encoding::json;

import raylib5::rl;

char[] ded_png = $embed("../../assets/Oxy/ded.png");
char[] icon_png = $embed("../../assets/logo.png");
char[] font_ttf = $embed("../../assets/fonts/VarelaRound-Regular.ttf");

extern fn void update_titlebar_theme() @cname("UpdateTitleBarTheme") @if(env::WIN32);

fn void main(String[] args)
{
    File core;
    ulong len = 0;

    File f = file::open("log.txt", "w")!!;
    defer (void) f.close();

    File dump = file::open("crash.dmp", "w")!!;
    defer (void) dump.close();

    $if !env::FREEBSD:
        @pool() {
            Path envelope = path::temp(args[1])!!;
            Path root = envelope.parent().parent()!!;
            Path dump_path;

            for (int i = 0; i < 2; i++) {
                PathList files = path::ls(tmem, root)!!;
                foreach (_file : files) {
                    String file = _file.str_view();
                    if (file.ends_with(".run")) {
                        root = root.tappend(file)!!;
                        break;
                    } else if (file.ends_with(".dmp")) {
                        dump_path = root.tappend(file)!!;
                        break;
                    }
                }
            }

            core = file::open(dump_path.str_view(), "rb")!!;
        };
    $else
        core = file::open(args[1], "rb")!!;
        /* pass it through zstd, or it'll be fat */
    $endif

    /* GUI */
    rl::initWindow(448, 568, "Crash Reporter");
    defer rl::closeWindow();

    Image icon = rl::loadImageFromMemory(".png", icon_png.ptr, icon_png.len);
    defer rl::unloadImage(icon);
    rl::setWindowIcon(icon);

    $if env::WIN32:
        update_titlebar_theme();
    $endif

    Image oxy_img = rl::loadImageFromMemory(".png", ded_png.ptr, ded_png.len);
    Texture2D oxy = rl::loadTextureFromImage(oxy_img);
    rl::setTextureFilter(oxy, TextureFilter.BILINEAR);

    rl::unloadImage(oxy_img);
    defer rl::unloadTexture(oxy);

    Font font = rl::loadFontFromMemory(".ttf", font_ttf.ptr, font_ttf.len, 32, null, 0);

    while (!rl::windowShouldClose())
    {
        rl::beginDrawing();
        rl::clearBackground(rl::RAYWHITE);

        rl::drawTextureEx(oxy, {10, 0}, 0, 0.25f, rl::WHITE);
        rl::drawTextEx(font, "OpenPNGStudio has", { 148, 10 }, 32, 1, rl::BLACK);
        rl::drawTextEx(font, "crashed", { 148, 50 }, 32, 1, rl::BLACK);
        rl::endDrawing();
    }
}

module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE) && env::WIN32);

import std::core::main_stub;

fn int win_main(void *handle, void *prev_handle, Char16 *cmd_line, int show_cmd) @export("WinMain")
{
    return main_stub::@win_main_args(main, handle, prev_handle, cmd_line, show_cmd);
}

fn int win_main_cli(int argc, char **argv) @export("main")
{
    return main_stub::@main_args(main, argc, argv);
}