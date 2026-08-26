/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import openpngstudio::core;
import openpngstudio::ui;
import openpngstudio::ui::filedialogs::builtin;
import openpngstudio::ui::wm;
import openpngstudio::image;
import std::io::file;
import nk;
import fons;
import raylib5::rl;
import std::io::path;
import std::hash::sha256;

import std::collections::linkedlist;

import ev;
import openpngstudio::loaders;
import libc;

enum FileLoadState {
    NOTHING,
    SELECTING_IMAGE,
    SELECTING_SCRIPT,
    WRITING_MODEL,
}

struct Context {
    Loop loop;
    Camera2D camera;
    int font;
    
    FileDialog file_dialog;
    WindowManager wm;
    model::Model model;

    image::Manager image_manager;
    Scene scene;

    ui::Panel panel;
    nk::Context *nk_ctx;
    fons::Context *fons;

    /* State */
    FileLoadState loading_state;
    bool file_lock;
    float width, height;
    Microphone microphone;

    LinkedList{ImageReq} layer_queue;
    LinkedList{Layer} cleanup_queue;

    ZString model_output;
    
    rl::Color ambient;
    Path exe_path;

    rl::Image icon;
    rl::Texture2D restore_icon;

    Outline outline;
    
    Toaster toaster;
    
    Settings settings;
    union dirty_settings {
        bitstruct : char {
            bool scene;
            bool mic;
        }
        char mask;
    }
    
    bitstruct : char {
        bool override_save;
        bool editing;
        bool hide_ui;
    }
}

Context *instance @local = null;

ZString[] edit_filter = gen_open_flags();
ZString[] stream_filter = {"*.opng"};

fn void Context.init(&self, Allocator alloc)
{
    instance = self;

    self.file_lock = false;
    self.exe_path = core::whereami()!!;
    log::info("Executable location: %s", self.exe_path);
    self.ambient = { 0x7E, 0x57, 0xC2, 0xFF };

    self.panel.init(alloc);
    self.wm.init(&self.panel, alloc);

    self.model.mgr.init(&self.wm, alloc);
    self.model.engine.init(alloc);

    self.microphone.init();
    self.wm.register("Microphone Configuration", &self.microphone);

    self.loop.init(alloc);
    self.file_dialog = ui::init_filedialog();
    self.camera.zoom = 1.0f;

    self.override_save = false;
    self.editing = true;
    self.hide_ui = false;

    self.layer_queue.init(alloc);
    self.image_manager.init(alloc);
    self.cleanup_queue.init(alloc);
    self.settings.init(self)!!;
    self.scene.init();
    self.toaster.init(mem);

    self.wm.register("Scene Configurator", &self.scene);
    
    initialize_raylib(self);
}

fn void Context.free(&self)
{
    rl::unloadImage(self.icon);
    unload_nuklear(self.nk_ctx);
    self.loop.free();
    self.microphone.free();
    self.model.free();
    self.wm.free();
    self.panel.free();
    self.layer_queue.free();
    self.image_manager.free();
    self.cleanup_queue.free();
    self.exe_path.free();
    rl::closeWindow();
}

fn void Context.load_layer(&self, ZString path)
{
    self.layer_queue.push({});

    ImageReq *ref = self.layer_queue.get_ref(self.layer_queue.len() - 1);
    ref.path = path;
    ref.ready = false;
    ref.animated = false;
    ref.work.init(ref, fn (self) {
        /* work, separate thread */
        String path = self.ctx.path.str_view();
        image::Image *img = mem::new(image::Image);
        img.file_content = file::load(mem, path)!!;
        img.checksum = sha256::hash(img.file_content);

        image::Image *res = instance.image_manager.get(img);

        if (!res.loaded) {
            loaders::load(res, path)!!;
        } else if (res.file_content.len > 0) {
            loaders::load(img, path)!!;
            res.ref = 1;
            img.ref = 1;
            img.id = res.id;
            res = img;
        }

        if (res != img) {
            free(img.file_content);
            free(img);
        }

        Path pth = path.to_path(mem)!!;
        defer pth.free();
        String base = pth.basename();
        String basename = base[0:base.rindex_of_char('.')!!];
        self.ctx.name = basename.zstr_copy(mem);

        self.ctx.loaded = res;
    }, fn (self) {
        /* after work, main thread */
        image::Image *img = self.ctx.loaded;
        
        log::info("Loaded image with id %d", img.id);

        if (!img.loaded) {
            img.texture = rl::loadTextureFromImage(img.image);
            rl::setTextureFilter(img.texture, BILINEAR);
            rl::genTextureMipmaps(&img.texture);
            rl::setTextureWrap(img.texture, TextureWrap.CLAMP.ordinal);
            img.loaded = true;
        }
        
        if (img.file_content.len == 0) {
            StaticLayer *slay = mem::new(StaticLayer);
            slay.init(mem, self.ctx.name, self.ctx.loaded);
            instance.model.mgr.add(slay);
        } else {
            AnimatedLayer *alay = mem::new(AnimatedLayer);
            alay.init(mem, self.ctx.name, self.ctx.loaded,
                self.ctx.loaded.delays[:self.ctx.loaded.nframes]);
            instance.model.mgr.add(alay);
        }

        self.ctx.ready = true;
        instance.toaster.add(instance, "Layer loaded successfully");

        return DISARM;
    });

    self.loop.add(&ref.work);
}

extern fn nk::Context *init_nuklear_ex(void *ctx, int font, float size)
    @cname("InitNuklearEx");
extern fn void unload_nuklear(nk::Context *ctx) @cname("UnloadNuklear");

fn void initialize_raylib(Context *self) @local
{
    rl::setConfigFlags(rl::FLAG_WINDOW_RESIZABLE | 
        rl::FLAG_WINDOW_TRANSPARENT | rl::FLAG_MSAA_4X_HINT);
    rl::initWindow(1024, 640, "OpenPNGStudio");
    rl::setExitKey(rl::KEY_NULL);
    
    self.fons = fons::init();

    self.font = load_font(self);
    fons::set_font(self.fons, self.font);

    load_icons(self);

    self.nk_ctx = init_nuklear_ex(self.fons, self.font, 18);

    style::apply(self.nk_ctx);

    $if env::WIN32:
        update_titlebar_theme();
    $endif
}

extern fn void update_titlebar_theme() @cname("UpdateTitleBarTheme") @if(env::WIN32);

fn int load_font(Context *self)
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

        return self.fons.add("default", tmp.str_view().zstr_tcopy())!!;
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
            {icons::Type.COMBO_OPEN2, "icons/combo-open2.png"},
            {icons::Type.PICK, "icons/pick.png"},
            {icons::Type.IMAGE, "icons/image.png"},
            {icons::Type.MICROPHONE, "icons/microphone.png"},
            {icons::Type.SWAP, "icons/swap.png"},
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
        
        @pool() {
            Path tmp = dir.tappend("logo.png")!;

            instance.icon = rl::loadImage(tmp.str_view().zstr_tcopy());

            rl::setWindowIcon(instance.icon);
        };

        @pool() {
            Path tmp = dir.tappend("icons/restore.png")!;

            rl::Image img = rl::loadImage(tmp.str_view().zstr_tcopy());
            instance.restore_icon = rl::loadTextureFromImage(img);

            rl::unloadImage(img);
        };

        @pool() {
            Path tmp = dir.tappend("shaders/outline.glsl")!;
            instance.outline.init(tmp.str_view());
            instance.outline.set_color(instance.ambient);
        };
    };
}

fn Context *get_ctx() => instance;

macro ZString[] gen_open_flags()
{
    var $flags = {"*.avif", "*.qoi", "*.png", "*.bmp", "*.jpg", "*.jpeg",
        "*.tga", "*.dds", "*.gif", "*.webp"};
    
    $if $feature(HAS_JXL):
        $flags = $flags +++ "*.jxl";
    $endif
    
    $flags = $flags +++ "*.opng";
    return $flags;
}
