module openpngstudio;

import openpngstudio::core;
import openpngstudio::ui;
import openpngstudio::ui::wm;
import openpngstudio::image;
import std::io::file;
import nk;
import raylib5::rl;
import std::io::path;
import std::hash::sha256;

import std::collections::linkedlist;

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

    image::Manager image_manager;

    ui::Panel panel;
    nk::Context *nk_ctx;

    /* State */
    FileLoadState loading_state;
    float width, height;
    Microphone microphone;

    LinkedList{ImageReq} layer_queue;

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

    self.file_dialog.init(alloc);
    self.file_dialog.set_filter(filter);
    self.file_dialog.populate();

    self.model.mgr.init(&self.wm, alloc);
    self.model.engine.init(alloc);

    self.wm.register("File Dialog", &self.file_dialog);
    self.microphone.init();

    self.loop.init(alloc);
    self.camera.zoom = 1.0f;

    self.override_save = false;
    self.editing = true;
    self.hide_ui = false;

    self.layer_queue.init(alloc);
    self.image_manager.init(alloc);

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
    self.layer_queue.free();
    self.image_manager.free();
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
        image::Image *img = malloc(image::Image.sizeof);
        img.file_content = file::load(mem, path)!!;
        img.checksum = sha256::hash(img.file_content);

        image::Image *res = instance.image_manager.get(img);

        if (res.ref == 1) {
            if (path.ends_with(".gif")) {
                self.ctx.animated = true;
                unreachable("unimplemented");
            } else {
                String ext = path[path.rindex_of_char('.')!!..];
                ZString zext = ext.zstr_copy(mem);
                res.image = rl::loadImageFromMemory(zext, 
                    img.file_content.ptr, img.file_content.len);
                free(zext);
                free(res.file_content.ptr); /* stays only for GIFs */
                res.file_content = {};
            }
        }

        if (res != img) free(img);

        Path pth = path.to_path(mem)!!;
        defer pth.free();
        String base = pth.basename();
        String basename = base[0:base.rindex_of_char('.')!!];
        self.ctx.name = basename.zstr_copy(mem);
        
        self.ctx.loaded = res;
    }, fn (self) {
        /* after work, main thread */
        image::Image *img = self.ctx.loaded;

        if (img.ref == 1) img.texture = rl::loadTextureFromImage(img.image);

        self.ctx.ready = true;

        if (!self.ctx.animated) {
            StaticLayer *slay = malloc(StaticLayer.sizeof);
            slay.init(mem, self.ctx.name, self.ctx.loaded);
            instance.model.mgr.add(slay);
        }
        return DISARM;
    });

    self.loop.add(&ref.work);
}

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
            {icons::Type.COMBO_OPEN2, "icons/combo-open2.png"},
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
        
        @pool() {
            Path tmp = dir.tappend("logo.png")!;

            rl::Image icon = rl::loadImage(tmp.str_view().zstr_tcopy());

            rl::setWindowIcon(icon);
        };
    };
}

fn Context *get_ctx() => instance;

// fn void Context.add_layer(&self, StaticLayer *layer) @export("layer_manager_add_layer")
// {
//     self.model.mgr.add_layer(layer);
// }
