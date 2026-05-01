/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::model;

import openpngstudio::ui;
import openpngstudio::image;
import openpngstudio::layer;
import openpngstudio::animation;

import opng;
import raylib5::rl;
import ev, ev::work;
import std::io;
import std::compression::qoi;

struct Model {
    layer::Manager mgr;
    animation::Engine engine;
}

fn void Model.free(&self)
{
    self.mgr.free();
    self.engine.free();
}

/* XXX ensure path separator is not in file name (filedialog) */
fn void? Model.save(&self, String path)
{
    ModelSave *ctx = mem::new(ModelSave);
    ctx.model = self;
    
    @pool() {
        String out = path;
        
        if (!out.ends_with(".opng")) {
            out = out.tconcat(".opng");
        }

        ctx.wr = opng::write_file(mem, out, { 0x0003, NONE, NONE, NONE })!;
    };

    ctx.state = WRITING_LAYERS;
    ctx.worker.init(ctx, &write_layers, &write_done);

    Context *app_ctx = openpngstudio::get_ctx();
    app_ctx.loop.add(&ctx.worker);
    app_ctx.file_lock = true;
}

enum ModelSaveState @local {
    WRITING_LAYERS,
    WRITING_IMAGES,
}

struct ModelSave @local {
    Writer wr;
    Model *model;
    ModelSaveState state;
    Work{ModelSave*} worker;
}

extern fn void *qoi_encode(void *data, QOIDesc *desc, int *out_len);

fn void write_layers(Work{ModelSave*} *work) @local
{
    ModelSave *self = work.ctx;

    switch (self.state) {
    case WRITING_LAYERS:
        self.wr.start_sqlite()!!;
        self.model.mgr.root.pack(&self.wr)!!;
        self.wr.end_sqlite()!!;
    case WRITING_IMAGES:
        Context *app_ctx = openpngstudio::get_ctx();
        
        self.wr.start_images()!!;

        app_ctx.image_manager.images.@each(; image::Image* img) {
            if (img.file_content.len > 0) {
                write_animated(self, img)!!;
            } else {
                write_static(self, img)!!;
            }
        };

        self.wr.end_images()!!;
        break;
    }
}

fn void? write_static(ModelSave *self, image::Image *img) @local
{
    if (img.image.format != UNCOMPRESSED_R8G8B8A8) {
        rl::imageFormat(&img.image, UNCOMPRESSED_R8G8B8A8);
    }

    usz size = (usz) img.image.width * img.image.height * 4;
    
    QOIDesc desc = {
        img.image.width,
        img.image.height,
        RGBA,
        LINEAR
    };

    @pool() {
        char[] encoded = qoi::encode(mem, img.image.data[:size], &desc)!;
        self.wr.add_image(STATIC, img.id, encoded)!;
    };
}

fn void? write_animated(ModelSave *self, image::Image *img) @local
{
    self.wr.add_image(img.type, img.id, img.file_content)!;
}

fn ev::Action write_done(Work{ModelSave*} *work) @local
{
    ModelSave *self = work.ctx;

    switch (self.state) {
    case WRITING_LAYERS:
        self.state = WRITING_IMAGES;
        return REARM;
    case WRITING_IMAGES:
        Context *app_ctx = openpngstudio::get_ctx();
        
        self.wr.free();
        app_ctx.file_lock = false;
    default:
    }
    return DISARM;
}
