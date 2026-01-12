/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;
import std::io, std::collections::list;

import nk;

import novacrash;
import novacrash::options;

import openpngstudio::console;
import openpngstudio::ui;
import openpngstudio::ui::icons;
import openpngstudio::core::model;
import raylib5::rl;
import unuv;

extern fn int c_main(void *c3_ctx);
extern fn void quit_openpngstudio();

extern void *c_ctx;

ZString filter = "qoi;png;bmp;jpg;jpeg;tga;psd;dds;gif;opng";

fn int main() @winmain {
    Context ctx;
    ctx.ambient = { 0x7E, 0x57, 0xC2, 0xFF };
    ctx.panel.init(mem);
    defer ctx.panel.free();

    ctx.wm.init(&ctx.panel, mem);
    defer ctx.wm.free();

    ctx.file_dialog.init(ctx.wm.next_id(), mem);
    ctx.file_dialog.set_filter(filter);
    ctx.file_dialog.populate();
    defer ctx.file_dialog.free()!!;

    ctx.model.mgr.init(&ctx.wm, mem);
    console::init(&ctx.wm, mem);

    ctx.wm.register("File Dialog", &ctx.file_dialog);

    ctx.panel.add_left_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        ctx.file_dialog.open_files();
        ctx.file_dialog.set_filter(filter);
        ctx.file_dialog.populate();
        ctx.file_dialog.set_title(&ctx.wm, "Open File");
        ctx.file_dialog.show(&ctx.wm);
        ctx.loading_state = SELECTING_IMAGE;
    }, OPEN, &ctx);

    ctx.panel.add_left_entry(fn void(void *ctx) {
        save(ctx, true);
    }, SAVE, &ctx);

    ctx.panel.add_left_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        ctx.wm.show(&ctx.model.mgr);
    }, LAYERS, &ctx);

    ctx.panel.add_left_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        io::printn("hello, world");
    }, SHORTCUTS, &ctx);

    ctx.panel.add_right_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        io::printn("hello, world");
    }, HELP, &ctx);

    ctx.panel.add_right_entry(fn void(void *_ctx) {
        quit_openpngstudio();
    }, CANCEL, &ctx);

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
        .crash_icon = $embed("../assets/logo.png"),
        .title_size = 32,
    };

    ctx.exe_path = core::whereami()!!;

    ctx.microphone.init();
    defer ctx.microphone.free();

    defer icons::cleanup();

    return c_main(&ctx);
}

fn void update(Context *app_ctx, bool hide_ui, unuv::UnLoop *loop) @export("update")
{
    app_ctx.width = rl::getScreenWidth();
    app_ctx.height = rl::getScreenHeight();
    nk::Context *ctx = app_ctx.nk_ctx;
    if (!hide_ui) app_ctx.panel.ui(ctx);

    app_ctx.microphone.update(loop);

    bool focused = false;

    if (rl::isKeyPressed(rl::KEY_GRAVE) && rl::isKeyDown(rl::KEY_LEFT_SHIFT)) {
        console::show(&app_ctx.wm);
    }

    app_ctx.wm.update(app_ctx.width, app_ctx.height);
    app_ctx.wm.ui(ctx, app_ctx.width, app_ctx.height);

    FileDialogState state = app_ctx.file_dialog.get_state();

    if (state == CLOSED) app_ctx.wm.hide(&app_ctx.file_dialog);

    if (state == READ_READY || state == WRITE_READY || app_ctx.override_save) {
        switch (app_ctx.loading_state) {
        case NOTHING:
            break;
        case SELECTING_IMAGE:
            load_file(app_ctx);
            break;
        case SELECTING_SCRIPT:
        case WRITING_MODEL:
            write_model(app_ctx);
        case LOADING_MODEL:
            /* TODO */
            break;
        }

        app_ctx.loading_state = NOTHING;
        app_ctx.file_dialog.reset();
        app_ctx.wm.hide(&app_ctx.file_dialog);
    }
}

fn void save(void *_ctx, bool save_as) @local
{
    Context *ctx = _ctx;

    if (save_as) ctx.model_output = null;

    if (ctx.model_output != null) {
        ctx.loading_state = WRITING_MODEL;
        ctx.override_save = true;
        return;
    }

    ctx.file_dialog.write_file();
    ctx.file_dialog.set_filter(null);
    ctx.file_dialog.populate();
    ctx.file_dialog.set_title(&ctx.wm, "Save Model As");
    ctx.file_dialog.show(&ctx.wm);

    ctx.loading_state = WRITING_MODEL;
}

extern fn void c_load_layer(ZString s);

fn void load_file(Context *ctx) @local
{
    List{ZString} selection = ctx.file_dialog.get_selection();

    if (selection.len() == 1) {
        String path = selection[0].str_view();

        if (path.ends_with(".opng")) {
            io::printf("%s\n", path);
            return;
        }
    }

    foreach (path : selection) {
        if (path.str_view().ends_with(".opng")) continue;
        c_load_layer(path);
    }
}

fn void write_model(Context *ctx) @local
{
    List{ZString} selection = ctx.file_dialog.get_selection();

    if (ctx.model_output == null) ctx.model_output = selection[0];
    ctx.override_save = false;

    io::printf("%s\n", ctx.model_output);
}

extern fn nk::Image load_nk_image(ZString path) @extern("LoadNuklearImage");

struct TmpIcon @private {
    icons::Type type;
    String path;
}

fn rl::Font load_font(Context *ctx) @export("load_font")
{
    @pool() {
        Path dir = ctx.exe_path.parent()!!;
        if (dir.basename() == "build") {
            dir = dir.parent()!!;
            dir = dir.tappend("assets")!!;
        } else {
            dir = dir.parent()!!;
            dir = dir.tappend("share")!!;
            dir = dir.tappend("OpenPNGStudio")!!;
        }
        
        Path tmp = dir.tappend("fonts/VarelaRound-Regular.ttf")!!;

        return rl::loadFont(tmp.str_view().zstr_tcopy());
    };
}

fn void load_icons(Context *ctx) @export("load_icons")
{
    load_icons2(ctx.exe_path)!!;
}

fn void? load_icons2(Path exe_path) @local
{
    @pool() {
        Path dir = exe_path.parent()!;
        if (dir.basename() == "build") {
            dir = dir.parent()!;
            dir = dir.tappend("assets")!;
        } else {
            dir = dir.parent()!;
            dir = dir.tappend("share")!;
            dir = dir.tappend("OpenPNGStudio")!;
        }

        var $icons = {
            {icons::Type.LEFT, "icons/back.png"},
            {icons::Type.RIGHT, "icons/forward.png"},
            {icons::Type.UP, "icons/up.png"},
            {icons::Type.DOWN, "icons/down.png"},
            {icons::Type.LOOP, "icons/loop.png"},
            {icons::Type.TRASH, "icons/trash.png"},
            {icons::Type.CFG, "icons/cfg.png"},
            {icons::Type.CANCEL, "icons/cancel.png"},
            {icons::Type.CHECK, "icons/check.png"},
            {icons::Type.MINIMIZE, "icons/minimize.png"},
            {icons::Type.MAXIMIZE, "icons/maximize.png"},
            {icons::Type.COMBO, "icons/combo.png"},
            {icons::Type.COMBO_OPEN, "icons/combo-open.png"},
            {icons::Type.OPEN, "icons/open.png"},
            {icons::Type.SAVE, "icons/save.png"},
            {icons::Type.LAYERS, "icons/layers.png"},
            {icons::Type.SHORTCUTS, "icons/shortcuts.png"},
            {icons::Type.HELP, "icons/help.png"},
            {icons::Type.DIR, "images/dir.png"},
            {icons::Type.FILE, "images/file.png"},
            {icons::Type.DRIVE, "images/drive.png"},
        };

        $foreach $icon : $icons:
            @pool() {
                TmpIcon $i = (TmpIcon) $icon;

                Path tmp = dir.tappend($i.path)!;
                icons::set($i.type, load_nk_image(tmp.str_view().zstr_tcopy()));
            };
        $endforeach
    };
}
