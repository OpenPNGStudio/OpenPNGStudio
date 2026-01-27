/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::core;
import openpngstudio::ui;
import openpngstudio::ui::wm;
import nk;
import raylib5::rl;
import std::io::path;

import ev;

enum FileLoadState {
    NOTHING,
    SELECTING_IMAGE,
    SELECTING_SCRIPT,
    WRITING_MODEL,
    LOADING_MODEL,
}

/* NOT C context !! */
struct Context {
    Loop loop;
    Camera2D camera;
    rl::Font font;

    FileDialog file_dialog;
    WindowManager wm;
    model::Model model;

    ui::Panel panel;
    nk::Context *nk_ctx;

    /* State */
    FileLoadState loading_state;
    float width, height;
    Microphone microphone;

    ZString model_output;

    bitstruct : char {
        bool override_save;
        bool editing;
        bool hide_ui;
    }

    rl::Color ambient;
    Path exe_path;
}

Context *instance @local = null;

ZString filter = "qoi;png;bmp;jpg;jpeg;tga;psd;dds;gif;opng";

fn void Context.init(&self, Allocator alloc)
{
    self.exe_path = core::whereami()!!;
    self.ambient = { 0x7E, 0x57, 0xC2, 0xFF };

    self.panel.init(alloc);
    self.wm.init(&self.panel, alloc);

    self.file_dialog.init(self.next_id(), alloc);
    self.file_dialog.set_filter(filter);
    self.file_dialog.populate();

    self.model.mgr.init(&self.wm, alloc);

    self.wm.register("File Dialog", &self.file_dialog);
    self.microphone.init();

    self.loop.init(alloc);
    self.camera.zoom = 1.0f;

    self.override_save = false;
    self.editing = true;
    self.hide_ui = false;

    initialize_raylib(self);
    instance = self;
}

fn void Context.free(&self)
{
    unload_nuklear(self.nk_ctx);
    rl::closeWindow();
    self.loop.free();
    self.microphone.free();
    self.file_dialog.free()!!;
    self.wm.free();
    self.panel.free();
}

fn int Context.next_id(&self) => self.wm.next_id();

extern fn nk::Context *init_nuklear_ex(rl::Font font, float size)
    @cname("InitNuklearEx");
extern fn void unload_nuklear(nk::Context *ctx) @cname("UnloadNuklear");

fn void initialize_raylib(Context *self) @local
{
    rl::setConfigFlags(rl::FLAG_WINDOW_RESIZABLE);
    rl::initWindow(1024, 640, "OpenPNGStudio");
    rl::setExitKey(rl::KEY_NULL);

    self.font = load_font(self);
    rl::setTextureFilter(self.font.texture, BILINEAR);

    load_icons(self);

    self.nk_ctx = init_nuklear_ex(self.font, 18);
    set_nk_font(self.font);

    rl::setTargetFPS(60);
    style::apply(self.nk_ctx);
}

extern fn void set_nk_font(rl::Font font);

fn rl::Font load_font(Context *self)
{
    @pool() {
        Path dir = self.exe_path.parent()!!;
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

extern fn nk::Image load_nk_image(ZString path) @extern("LoadNuklearImage");

struct TmpIcon @private {
    icons::Type type;
    String path;
}

fn void load_icons(Context *ctx) @local
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
            {icons::Type.PICK, "icons/pick.png"},
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

fn Context *get_ctx() => instance;

fn void Context.add_layer(&self, StaticLayer *layer) @export("layer_manager_add_layer")
{
    self.model.mgr.add_layer(layer);
}
