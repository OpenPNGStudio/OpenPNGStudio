/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;
import std::io;

import nk;

import novacrash;
import novacrash::options;

import openpngstudio::ui;
import openpngstudio::ui::icons;

extern fn int c_main(void *c3_ctx);

extern void *c_ctx;

ZString filter = "qoi;png;bmp;jpg;jpeg;tga;psd;dds;gif;opng";

fn int main() @winmain {
    Context ctx;
    ctx.file_dialog.init(mem);
    ctx.file_dialog.set_filter(filter);
    ctx.file_dialog.populate();
    defer ctx.file_dialog.free()!!;

    ctx.panel.init(mem);
    defer ctx.panel.free();

    ctx.panel.add_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        ctx.file_dialog.open_file();
        ctx.file_dialog.set_filter(filter);
        ctx.file_dialog.populate();
        ctx.file_dialog.set_title("Open File");
        ctx.file_dialog.show();
    }, OPEN, &ctx);

    ctx.panel.add_entry(fn void(void *ctx) {
        save(ctx, false);
    }, SAVE, &ctx);

    ctx.panel.add_entry(fn void(void *ctx) {
        save(ctx, true);
    }, SAVE_AS, &ctx);

    ctx.panel.add_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        io::printn("hello, world");
    }, LAYERS, &ctx);

    ctx.panel.add_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        io::printn("hello, world");
    }, SHORTCUTS, &ctx);

    ctx.panel.add_entry(fn void(void *_ctx) {
        Context *ctx = _ctx;
        io::printn("hello, world");
    }, HELP, &ctx);

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

    return c_main(&ctx);
}

fn void update(Context *app_ctx, bool hide_ui) @export("update")
{
    nk::Context *ctx = app_ctx.nk_ctx;
    if (!hide_ui) app_ctx.panel.ui(ctx);

    bool focused = false;

    app_ctx.file_dialog.run(ctx, &focused);

    FileDialogState state = app_ctx.file_dialog.get_state();

    if (state == READ_READY || state == WRITE_READY || app_ctx.override_save) {
        switch (app_ctx.loading_state) {
        case NOTHING:
            break;
        case SELECTING_IMAGE:
            load_layer();
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
    ctx.file_dialog.set_title("Save Model As");
    ctx.file_dialog.show();

    ctx.loading_state = WRITING_MODEL;
}

fn void load_layer() @local
{
}

fn void write_model(Context *ctx) @local
{
    ZString* selection = ctx.file_dialog.get_selection();

    if (ctx.model_output == null) ctx.model_output = selection[0];
    ctx.override_save = false;

    io::printf("%s\n", ctx.model_output);
}
