module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE));

import std::io, std::collections::object, std::encoding::json;

import raylib5::rl, oxy_reporter::crash, oxy_reporter::report;

char[] ded_png = $embed("../../assets/Oxy/ded.png");
char[] icon_png = $embed("../../assets/logo.png");
char[] font_ttf = $embed("../../assets/fonts/VarelaRound-Regular.ttf");
char[] check_png = $embed("../../assets/icons/check.png");

File f;
Font font @local;
Texture2D check @local;

extern fn void update_titlebar_theme() @cname("UpdateTitleBarTheme") @if(env::WIN32);
extern fn void init_style(Font font);

constdef GuiState : int {
    END,
    MAIN_SCREEN,
    REPORT_SCREEN,
}

fn void draw_text(ZString text, int x, int y, int height, Color tint) @builtin
    => rl::drawTextEx(font, text, {x, y}, height, 1, tint);

fn bool draw_check(int x, int y, bool active) @builtin
{
    Rectangle bounds = { x, y, 20, 20 };

    rl::drawRectangleRounded(bounds, 0.5f, 8, {0x38, 0x38, 0x38, 0xFF});

    if (active) {
        rl::drawTextureEx(check, { (float) x + 2, (float) y + 2 }, 0, 0.25f, rl::WHITE);
    }

    if (rl::checkCollisionRecs(bounds, { rl::getMouseX(), rl::getMouseY(), 1, 1 }) && rl::isMouseButtonReleased(LEFT)) {
        return !active;
    }

    return active;
}

fn bool draw_button(int x, int y, ZString text, Color bg = {0x38, 0x38, 0x38, 0xFF}) @builtin
{
    float padding_x = 12.0f;
    float padding_y = 6.0f;

    Vector2 text_size = rl::measureTextEx(font, text, 18, 1);

    Rectangle bounds = {
        (float) x, (float) y,
        text_size.x + (padding_x * 2.0f), text_size.y + (padding_y * 2.0f)
    };

    bool hovered = rl::checkCollisionRecs(bounds, { (float) rl::getMouseX(), (float) rl::getMouseY(), 1.0f, 1.0f });

    Color bg_color = hovered ? (Color) { bg.r + 0x10, bg.g + 0x10, bg.b + 0x10, 0xFF } : bg;
    rl::drawRectangleRounded(bounds, 0.3f, 8, bg_color);

    rl::drawTextEx(font, text, {bounds.x + padding_x, bounds.y + padding_y}, 18, 1, rl::WHITE);
    return hovered && rl::isMouseButtonReleased(LEFT);
}

fn void main(String[] args)
{
    File core;
    ulong len = 0;
    bool needs_compression = false;
    GuiState state = MAIN_SCREEN;

    f = file::open("log.txt", "w")!!;
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
        if (args[1] != "NO CORE") core = file::open(args[1], "rb")!!;
        /* pass it through zstd, or it'll be fat */
        if (args[1].ends_with(".core")) needs_compression = true;
    $endif

    /* GUI */
    rl::setConfigFlags(rl::FLAG_MSAA_4X_HINT);
    rl::initWindow(448, 568, "Crash Report");
    defer rl::closeWindow();

    Image icon = rl::loadImageFromMemory(".png", icon_png.ptr, icon_png.len);
    defer rl::unloadImage(icon);
    rl::setWindowIcon(icon);
    rl::setExitKey(rl::KEY_NULL);

    $if env::WIN32:
        update_titlebar_theme();
    $endif

    Image oxy_img = rl::loadImageFromMemory(".png", ded_png.ptr, ded_png.len);
    Texture2D oxy = rl::loadTextureFromImage(oxy_img);
    rl::setTextureFilter(oxy, TextureFilter.BILINEAR);

    rl::unloadImage(oxy_img);
    defer rl::unloadTexture(oxy);

    Image check_img = rl::loadImageFromMemory(".png", check_png.ptr, check_png.len);
    check = rl::loadTextureFromImage(check_img);
    rl::setTextureFilter(check, TextureFilter.BILINEAR);

    rl::unloadImage(check_img);
    defer rl::unloadTexture(check);

    font = rl::loadFontFromMemory(".ttf", font_ttf.ptr, font_ttf.len, 32, null, 0);
    rl::setTextureFilter(font.texture, TextureFilter.BILINEAR);

    init_style(font);
    rl::setTargetFPS(60);

    while LOOP: (!rl::windowShouldClose())
    {
        if (state == END) break;

        rl::beginDrawing();
        rl::clearBackground({0x20, 0x20, 0x20, 0xFF});

        switch (state) {
        case END:
            break LOOP;
        case MAIN_SCREEN:
            state = crash::draw(oxy);
        case REPORT_SCREEN:
            state = report::draw();
        }

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