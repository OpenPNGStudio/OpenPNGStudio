/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;
import std::io, std::collections::list;

import nk;

// import novacrash;
// import novacrash::options;

import openpngstudio::console;
import openpngstudio::ui;
import openpngstudio::ui::icons;
import openpngstudio::core::model;
import raylib5::rl;
import unuv;
import std::math @public;

import ev;

extern fn int c_main(void *c3_ctx);
extern fn void quit_openpngstudio();

extern void *c_ctx;

fn int main() @winmain {
    Context ctx;
    ctx.init(mem);
    defer ctx.free();

    console::init(&ctx.wm, mem);

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
        Context *ctx = _ctx;
        ctx.loop.stop();
    }, CANCEL, &ctx);

    // novacrash::uses_raylib = true;
    // options::cfg.app_name = "OpenPNGStudio";
    // options::cfg.message = "has reached a";
    //
    // options::cfg.window = {
    //     .title = "OpenPNGStudio crash report",
    //     .width = 500,
    //     .height = 750,
    // };
    //
    // options::cfg.theme = {
    //     .background = { 0x16, 0x16, 0x16, 0xff },
    //     .foreground = { 0xbe, 0xbe, 0xbe, 0xff },
    //     .font = $embed("../assets/fonts/VarelaRound-Regular.ttf"),
    //     .font_size = 22,
    // };
    //
    // static ZString[] phrases = {"!!!", "XXX", "ERROR", "PANIC", "GUH", "WEH", "ABWA"};
    //
    // options::cfg.header = {
    //     .catch_phrases = phrases,
    //     .crash_icon = $embed("../assets/logo.png"),
    //     .title_size = 32,
    // };

    Idle{Context*} update_idle;
    Idle{Context*} draw_idle;

    update_idle.init(&ctx, &update);
    draw_idle.init(&ctx, &draw);

    ctx.loop.add(&update_idle);
    ctx.loop.add(&draw_idle);

    defer icons::cleanup();

    ctx.loop.run(DEFAULT);
    return 0;
}

extern fn void update_nuklear(nk::Context *ctx) @cname("UpdateNuklear");

fn Action update(Idle{Context*} *idle)
{
    Context *ctx = idle.ctx;
    Mask mask = mask::get();
    mask::handle(&mask);
    bool ui_focused = false;

    if (rl::windowShouldClose()) ctx.loop.stop();

    if (rl::isKeyPressed(rl::KEY_TAB)) ctx.editing = !ctx.editing;

    update_nuklear(ctx.nk_ctx);
    ctx.width = rl::getScreenWidth();
    ctx.height = rl::getScreenHeight();

    mask::update(&mask);
    mask::set(mask);

    ctx.panel.ui(ctx.nk_ctx);
    // app_ctx.microphone.update(loop);
    if (rl::isKeyPressed(rl::KEY_GRAVE) && rl::isKeyDown(rl::KEY_LEFT_SHIFT)) {
        console::show(&ctx.wm);
    }

    ctx.wm.update(ctx.width, ctx.height);
    ctx.wm.ui(ctx.nk_ctx, ctx.width, ctx.height);

    FileDialogState state = ctx.file_dialog.get_state();

    if (state == CLOSED) ctx.wm.hide(&ctx.file_dialog);

    if (state == READ_READY || state == WRITE_READY || ctx.override_save) {
        switch (ctx.loading_state) {
        case NOTHING:
            break;
        case SELECTING_IMAGE:
            load_file(ctx);
            break;
        case SELECTING_SCRIPT:
        case WRITING_MODEL:
            write_model(ctx);
        case LOADING_MODEL:
            /* TODO */
            break;
        }

        ctx.loading_state = NOTHING;
        ctx.file_dialog.reset();
        ctx.wm.hide(&ctx.file_dialog);
    }

    ctx.model.engine.tick(ctx.loop.now);

    if (try ImageReq req = ctx.layer_queue.first()) {
        if (req.ready) ctx.layer_queue.pop_front()!!;
    }

    if (try Layer layer = ctx.cleanup_queue.first()) {
        if (layer.can_cleanup()) {
            layer.free();
            ctx.cleanup_queue.pop_front()!!;
        }
    }

    if (!ui_focused) {
        // if (rl::isKeyPressed(KEY_SPACE)) {
        //     ctx.hide_ui = !ctx.hide_ui;
        // }

        if (rl::isMouseButtonDown(MIDDLE)) {
            rl::Vector2 delta = rl::getMouseDelta();
            delta = rl::vector2Scale(delta, -1.0f/ctx.camera.zoom);
            ctx.camera.target = rl::vector2Add(ctx.camera.target, delta);
        }

        float wheel = rl::getMouseWheelMove();
        static float target_zoom = 1.0;
        if (wheel != 0) {
            Vector2 mouseWorldPos = rl::getScreenToWorld2D(rl::getMousePosition(), ctx.camera);
            ctx.camera.offset = rl::getMousePosition();
            ctx.camera.target = mouseWorldPos;

            float scaleFactor = 1.0f + (0.1f * math::abs(wheel));
            if (wheel < 0) scaleFactor = 1.0f / scaleFactor;
            target_zoom = math::clamp(ctx.camera.zoom * scaleFactor, 0.125f, 4.0f);
        }

        ctx.camera.zoom = math::lerp(ctx.camera.zoom, target_zoom, 0.35f);
    }

    if (rl::windowShouldClose()) ctx.loop.stop();

    return REARM;
}

extern fn void draw_nuklear(nk::Context *ctx) @cname("DrawNuklear");

fn Action draw(Idle{Context*} *idle)
{
    Context *ctx = idle.ctx;

    if (rl::windowShouldClose()) ctx.loop.stop();

    rl::Color inverted = {255, 255, 255, 255};
    rl::Color bg = { 0x88, 0x88, 0x88, 0xFF };
    inverted.r -= bg.r;
    inverted.g -= bg.g;
    inverted.b -= bg.b;

    rl::beginDrawing();
    rl::clearBackground(bg);

    if (ctx.editing) draw_grid(1, 60, inverted);

    rl::beginMode2D(ctx.camera);
    ctx.model.mgr.render();
    rl::endMode2D();

    draw_nuklear(ctx.nk_ctx);
    rl::endDrawing();

    if (rl::windowShouldClose()) ctx.loop.stop();

    return REARM;
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

/* TODO: submit work */
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
        ctx.load_layer(path.str_view().zstr_copy(mem));
    }
}

fn void write_model(Context *ctx) @local
{
    List{ZString} selection = ctx.file_dialog.get_selection();

    if (ctx.model_output == null) ctx.model_output = selection[0];
    ctx.override_save = false;

    io::printf("%s\n", ctx.model_output);
}

fn void draw_grid(int line_width, int spacing, rl::Color color)
{
    float width = rl::getScreenWidth();
    float height = rl::getScreenHeight();

    float width_total = width / spacing;
    float width_count = width / spacing;
    float width_pad_half = (width_total - width_count) / 2;

    for (int i = (int) width_pad_half * spacing; i < width; i += spacing) {
        rl::drawLineEx({ i, 0 }, { i, height }, line_width, color);
    }
    
    float height_total = height / spacing;
    float height_count = height / spacing;
    float height_pad_half = (height_total - height_count) / 2;

    for (int i = (int) height_pad_half * spacing; i < height; i += spacing) {
        rl::drawLineEx({ 0, i }, { width, i }, line_width, color);
    }
}
