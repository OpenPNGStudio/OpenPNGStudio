module novacrash::ui @if(!$feature(CUSTOM_FRONTEND));

import raylib5::rl;
import raygui::rg;
import novacrash::trace;
import std::core::string;
import std::io::path;
import std::collections::maybe;
import std::math::random;
import novacrash::options;
import libc;
import std::core::env;

struct Ui {
    String msg, file, fun;
    uint line;
    StackTrace *trace;
    bool toggle_full_path;

    rl::Font font;
    usz phrase_index;
    Options *o;
    Maybe{Texture} icon;

    int w, h;
}

macro @set_default(#cfg, #value) @private => #cfg = #cfg ?: ($typeof(#cfg)) #value;

macro @set_default_color(#cfg, $value) @private {
    #cfg.r = #cfg.r ?: $value.r;
    #cfg.g = #cfg.g ?: $value.g;
    #cfg.b = #cfg.b ?: $value.b;
    #cfg.a = #cfg.a ?: $value.a;
}

faultdef RAYLIB_DIDNT_INIT;

fn void? Ui.init(&self, String msg, String file, String fun, uint line, StackTrace *trace)
{
    /* set default values */
    @set_default(options::cfg.app_name, "App");
    @set_default(options::cfg.message, "has encountered a");

    @set_default(options::cfg.window.title, "Novacrash Report");
    @set_default(options::cfg.window.width, 600);
    @set_default(options::cfg.window.height, 850);

    @set_default_color(options::cfg.theme.background, (Color) { 0x16, 0x16, 0x16, 0xFF });
    @set_default_color(options::cfg.theme.foreground, (Color) { 0xEB, 0xEB, 0xEB, 0xFF });
    @set_default_color(options::cfg.theme.ambient, (Color) { 0x17, 0xA0, 0x85, 0xFF });
    @set_default(options::cfg.theme.font, {});
    @set_default(options::cfg.theme.spacing, 2);
    @set_default(options::cfg.theme.font_size, 20);
    @set_default(options::cfg.theme.padding, 10);

    @set_default(options::cfg.header.crash_icon, {});
    @set_default(options::cfg.header.icon_size.x, 128);
    @set_default(options::cfg.header.icon_size.y, 128);
    @set_default(options::cfg.header.title_size, 48);

    static ZString[] options = {"XXX", "!!!"};
    @set_default(options::cfg.header.catch_phrases, options);

    self.msg = msg;
    self.file = file;
    self.fun = fun;
    self.line = line;
    self.trace = trace;
    self.o = &options::cfg;

$if env::OS_TYPE != WIN32 && !env::os_is_darwin():
    ZString session_type = "tty";
    if (ZString x11 = libc::getenv("DISPLAY")) { session_type = x11; }
    else if (ZString wayland = libc::getenv("WAYLAND")) { session_type = wayland; }
    if (session_type == "tty") return RAYLIB_DIDNT_INIT?;
$endif

    if (novacrash::uses_raylib && rl::isWindowReady()) rl::closeWindow();

    rl::setTraceLogLevel(ERROR);
    rl::setConfigFlags(rl::FLAG_WINDOW_RESIZABLE);

    self.w = self.o.window.width;
    self.h = self.o.window.height;

    rl::initWindow(self.w, self.h, self.o.window.title);
    if (!rl::isWindowReady()) return RAYLIB_DIDNT_INIT?;
    rl::setTargetFPS(60);

    if (self.o.theme.font.len > 0) {
        Font fnt = rl::loadFontFromMemory(".ttf", self.o.theme.font.ptr,
            self.o.theme.font.len,
            (int) self.o.header.title_size, null, 0);
        rl::setTextureFilter(fnt.texture, TRILINEAR);
        self.font = fnt;
    } else { self.font = rl::getFontDefault(); }

    if (self.o.header.crash_icon.len > 0) {
        Image img = rl::loadImageFromMemory(".png", self.o.header.crash_icon.ptr,
            self.o.header.crash_icon.len);
        defer rl::unloadImage(img);
        rl::imageResize(&img, (int) self.o.header.icon_size.x,
            (int) self.o.header.icon_size.y);
        self.icon.set(rl::loadTextureFromImage(img));
    }

    self.phrase_index = random::rand_in_range(0, self.o.header.catch_phrases.len - 1);
}

fn void? draw(Ui *self)
{

    Rectangle panel_rec = { 10, 0, (float) rl::getScreenWidth() - 20, 0 };
    Rectangle panel_content_rec;
    Rectangle panel_view;
    Vector2 panel_scroll;

    int bg_color = rl::colorToInt(self.o.theme.background);
    int fg_color = rl::colorToInt(self.o.theme.foreground);
    int ambient_color = rl::colorToInt(self.o.theme.ambient);

    rg::guiSetStyle(DEFAULT, 19, bg_color); /* BACKGROUND_COLOR */
    rg::guiSetStyle(DEFAULT, 2, fg_color); /* TEXT_COLOR_NORMAL */
    rg::guiSetStyle(DEFAULT, 0, fg_color); /* BORDER_COLOR_NORMAL */
    rg::guiSetStyle(DEFAULT, 6, fg_color); /* BORDER_COLOR_PRESSED */
    rg::guiSetStyle(DEFAULT, 3, fg_color); /* BORDER_COLOR_FOCUSED */
    rg::guiSetStyle(DEFAULT, 18, fg_color); /* LINE_COLOR */
    rg::guiSetStyle(DEFAULT, 5, ambient_color); /* TEXT_COLOR_FOCUSED */
    rg::guiSetStyle(DEFAULT, 8, ambient_color); /* TEXT_COLOR_PRESSED */

    rg::guiSetStyle(BUTTON, 5, bg_color);
    rg::guiSetStyle(BUTTON, 1, bg_color); /* BASE_COLOR_NORMAL */
    rg::guiSetStyle(BUTTON, 4, fg_color); /* BASE_COLOR_FOCUSED */
    rg::guiSetStyle(BUTTON, 7, fg_color); /* BASE_COLOR_PRESSED */

    rg::guiSetStyle(SLIDER, 0, ambient_color);
    rg::guiSetStyle(SLIDER, 3, ambient_color);
    rg::guiSetStyle(SLIDER, 6, ambient_color);

    rg::guiSetStyle(STATUSBAR, 1, bg_color);
    rg::guiSetStyle(SCROLLBAR, 19, ambient_color);

    rg::guiSetStyle(CHECKBOX, 0, fg_color);
    rg::guiSetStyle(CHECKBOX, 3, ambient_color);
    rg::guiSetStyle(CHECKBOX, 6, ambient_color);

    rg::guiSetStyle(DEFAULT, 12, 0); /* BORDER_WIDTH */
    rg::guiSetStyle(DEFAULT, 16, (CInt) self.o.theme.font_size); /* TEXT_SIZE */

    rg::guiSetFont(self.font);

    while (!rl::windowShouldClose()) {
        rl::beginDrawing();
        rl::clearBackground(self.o.theme.background);
        self.w = rl::getScreenWidth();
        self.h = rl::getScreenHeight();
        float y = self.draw_title();

        rl::drawLineEx((Vector2) { .x = self.o.theme.padding, .y = y }, (Vector2) {
            .x = self.w - self.o.theme.padding,
            .y = y,
        }, 2, self.o.theme.foreground);
        y += self.o.theme.padding;

        float width = self.w - self.o.theme.padding * 2;

        rg::guiSetStyle(DEFAULT, 2, ambient_color);
        rg::guiLabel({
            .x = self.o.theme.padding,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width,
        }, self.msg);
        rg::guiSetStyle(DEFAULT, 2, fg_color);
        y += self.o.theme.font_size + self.o.theme.padding;

        rg::guiLabel({
            .x = self.o.theme.padding,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width,
        }, "Options:");
        y += self.o.theme.font_size + self.o.theme.padding;

        rg::guiSetStyle(DEFAULT, 12, 2);
        rg::guiCheckBox({
            .x = self.o.theme.padding,
            .y = y,
            .height = self.o.theme.font_size,
            .width = self.o.theme.font_size,
        }, "Enable full trace paths", &self.toggle_full_path);
        rg::guiSetStyle(DEFAULT, 12, 0);
        y += self.o.theme.font_size + self.o.theme.padding;

        rg::guiLabel({
            .x = self.o.theme.padding,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width,
        }, "Stack Trace:");
        y += self.o.theme.font_size + self.o.theme.padding / 2;

        rl::drawRectangleLinesEx({
            .x = self.o.theme.padding,
            .y = y,
            .width = width,
            .height = self.o.theme.font_size + 4,
        }, 2, self.o.theme.foreground);
        y += 2;

        float width_forth = width / 3.5;

        rg::guiLabel({
            .x = self.o.theme.padding + 4,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width_forth / 2,
        }, "Line");

        rg::guiLabel({
            .x = self.o.theme.padding + 4 + width_forth / 2,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width_forth,
        }, "Function");

        rg::guiLabel({
            .x = self.o.theme.padding + width_forth + width_forth / 2 + 4,
            .y = y,
            .height = self.o.theme.font_size,
            .width = width - width_forth,
        }, "File");
        y += self.o.theme.font_size;

        panel_rec.y = y;
        panel_rec.height = self.h - panel_rec.y - self.o.theme.padding;
        panel_rec.width = self.w - self.o.theme.padding * 2;

        rg::guiSetStyle(DEFAULT, 12, 2);
        rg::guiScrollPanel(panel_rec, null, panel_content_rec, &panel_scroll, &panel_view);
        rg::guiSetStyle(DEFAULT, 12, 0);
        rl::beginScissorMode((int) panel_view.x, (int) panel_view.y,
            (int) panel_view.width, (int) panel_view.height);

        float content_height = y;
        float content_width = 0;

        foreach (i, &tr : self.trace.backtrace) {
            if (i < 4) continue;
            if (tr.function == "???") continue;
            @pool() {
                Path file;
                if (tr.has_file()) { file = path::temp(tr.file)!; }
                else { file = path::temp("???")!; }

                String path_str = self.toggle_full_path ? file.str_view() : file.basename();

                ZString str = string::tformat_zstr("%d", tr.line);
                rg::guiLabel({
                    .x = self.o.theme.padding + panel_scroll.x + 4,
                    .y = content_height + 4 + panel_scroll.y,
                    .height = self.o.theme.font_size,
                    .width = width_forth / 2,
                }, str);

                str = tr.function.zstr_tcopy();
                rg::guiLabel({
                    .x = self.o.theme.padding + panel_scroll.x + 4 + width_forth / 2,
                    .y = content_height + 4 + panel_scroll.y,
                    .height = self.o.theme.font_size,
                    .width = width_forth,
                }, str);

                str = path_str.zstr_tcopy();

                rl::drawTextEx(self.font, str, (Vector2) {
                    .x = self.o.theme.padding + panel_scroll.x + width_forth + width_forth / 2 + 4,
                    .y = content_height + 4 + panel_scroll.y,
                }, self.o.theme.font_size, self.o.theme.spacing,
                    self.o.theme.foreground);

                Vector2 w = rl::measureTextEx(self.font, str, self.o.theme.font_size, self.o.theme.spacing);
                if (w.x + width_forth + width_forth / 2 > content_width) {
                    content_width = w.x + 8 + width_forth + width_forth / 2;
                }

                content_height += w.y;
            };
        }

        panel_content_rec.height = content_height - y + 8;
        panel_content_rec.width = content_width;
        rl::endScissorMode();
        rl::endDrawing();
    }
}

fn float Ui.draw_title(&self) @private {
    float width = self.w - self.o.theme.padding * 3;
    float y = self.o.theme.padding;
    float x = self.o.theme.padding;
    float to_sub = 0;

    if (self.icon.has_value) {
        Texture t = self.icon.get()!!;

        rl::drawTexture(t, (int) self.o.theme.padding, (int) self.o.theme.padding, rl::WHITE);
        x = x * 2 + self.o.header.icon_size.x;
        to_sub = self.o.header.icon_size.x;
    }
    
    ZString phrase = self.o.header.catch_phrases[self.phrase_index];
    int prev_height = rg::guiGetStyle(DEFAULT, 16);
    rg::guiSetStyle(DEFAULT, 16, (int) self.o.header.title_size);
    rg::guiLabel({ .x = x, .y = y,
            .height = self.o.header.title_size,
            .width = width - to_sub,
        }, phrase);

    rg::guiSetStyle(DEFAULT, 16, prev_height);

    y += rl::measureTextEx(self.font, phrase, self.o.header.title_size, 
        self.o.theme.padding).y;

    @pool() {
        ZString str = string::tformat_zstr("%s %s panic", self.o.app_name, self.o.message);
        rg::guiLabel({
            .x = x,
            .y = y,
            .height = self.o.header.title_size,
            .width = width - to_sub,
        }, str);
        y += rl::measureTextEx(self.font, str, self.o.header.title_size, 
                self.o.theme.padding).y;
    };

    return (to_sub == 0 ? y : self.o.header.icon_size.y) + self.o.theme.padding * 2;
}
