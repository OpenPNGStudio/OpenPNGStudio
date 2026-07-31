/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::model;

import std::collections::map, std::collections::list;
import openpngstudio;
import opng;
import ev, ev::work;
import std::io;
import std::compression::qoi;
import std::hash::sha256;
import raylib5::rl;
import nk;

/* XXX ensure path separator is not in file name (filedialog) */
fn void? load(String path)
{
    log::info(path);
    ModelLoad *ctx = mem::new(ModelLoad);
    ctx.rd = opng::read_file(mem, path, { 0x0003 })!;
    ctx.state = LOAD_DATA;
    ctx.worker.init(ctx, &load_model, &load_done);
    ctx.loaded.init(mem);
    ctx.roots.init(mem);
    
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    ctx.ctx = app_ctx;
    app_ctx.loop.add(&ctx.worker);
    app_ctx.file_lock = true;
    
    ctx.model.mgr.root.init(mem);
    ctx.model.mgr.conf.init();
    ctx.model.mgr.selected = { NONE, null, null };
    ctx.model.engine.init(mem);
}

enum ModelReadState @local {
    LOAD_DATA,
    LOAD_IMAGES,
    LOAD_LAYERS,
    LAYERS_CONTINUE,
    ANIM_CLONE,
}

struct ModelLoad @local {
    Reader rd;
    openpngstudio::Context *ctx;
    Model model;
    ModelReadState state;
    Work{ModelLoad*} worker;
    
    ImageEntry[] model_images;
    HashMap{uint, image::Image*} loaded;
    
    List{LayerProgress} roots;
    struct anim {
        image::Image *target;
        SQLLayer layer;
        SQLLayerData data;
        LayerGroup *root;
        bool ready;
    }
}

struct LayerProgress @local {
    LayerGroup *root;
    isz remaining;
}

String[] paths @local = {
    [ImageType.STATIC]              = ".qoi",
    [ImageType.ANIMATED_GIF]        = ".gif",
    [ImageType.ANIMATED_AVIF]       = ".avif",
    [ImageType.ANIMATED_JPEG_XL]    = ".jxl",
    [ImageType.ANIMATED_WEBP]       = ".webp",
};

fn void load_model(Work{ModelLoad*} *work) @local
{
    ModelLoad *self = work.ctx;
    
    switch (self.state) {
    case LOAD_DATA:
        while (try DirResult res = self.rd.next_dir()) {
            switch (res.type) {
            case SQLITE:
                self.rd.load_sqlite(res.value.sqlite)!!;
            case IMAGES:
                self.model_images = res.value.images;
            case COUNT:
                break;
            }
        }
    case LOAD_IMAGES:
        ImageEntry img_entry = self.model_images[0];
        
        image::Image *img = mem::new(image::Image);
        img.file_content = mem::new_array(char, img_entry.uncompressed_size);
        self.rd.read_into(img_entry.offset, img.file_content)!!;
        
        img.checksum = sha256::hash(img.file_content);
        
        image::Image *res = self.ctx.image_manager.get(img);
        if (!res.loaded) loaders::load(res, paths[img_entry.type])!!;
        
        if (res != img) free(img);
        
        self.loaded[img_entry.id] = res;
    case LOAD_LAYERS:
    case LAYERS_CONTINUE:
        break;
    case ANIM_CLONE:
        if (self.anim.target.ref > 1) {
            image::Image *res = self.anim.target;
            image::Image *img = mem::new(image::Image);
            
            img.file_content = mem::@clone_slice(res.file_content);
            img.checksum = res.checksum;
            loaders::load(img, paths[res.type])!!;
            res.ref = 1;
            img.ref = 1;
            img.id = res.id;
            self.anim.target = img;
        }
        
        self.anim.ready = true;
        self.state = LAYERS_CONTINUE;
        break;
    }
}

fn ev::Action load_done(Work{ModelLoad*} *work) @local
{
    ModelLoad *self = work.ctx;
    
    switch (self.state) {
    case LOAD_DATA:
        self.state = LOAD_IMAGES;
        return REARM;
    case LOAD_IMAGES:
        self.model_images = self.model_images[1..];
        if (self.model_images.len == 0) nextcase;
        
        return REARM;
    case LOAD_LAYERS:
        SQLLayer layer = self.rd.next_layer()!!;
        SQLLayerData data = self.rd.get_layer_data(layer.data_id)!!;
        
        LayerGroup *root = &self.model.mgr.root;
        self.roots.push({ root, layer.nchildren });
        
        update_values(self, &root.base, data, layer.data_id);
        self.state = LAYERS_CONTINUE;
        nextcase;
    case LAYERS_CONTINUE:
        if (self.anim.ready) {
            image::Image *img = self.anim.target;
            AnimatedLayer *alay = mem::new(AnimatedLayer);
            
            if (!img.loaded) {
                img.texture = rl::loadTextureFromImage(img.image);
                rl::setTextureFilter(img.texture, BILINEAR);
                rl::genTextureMipmaps(&img.texture);
                rl::setTextureWrap(img.texture, TextureWrap.CLAMP.ordinal);
                img.loaded = true;
            }
            
            alay.init(mem, self.anim.data.name, img, img.delays[:img.nframes]);
            update_values(self, &alay.base, self.anim.data,
                self.anim.layer.data_id);
            self.anim.root.add(alay);
            
            self.anim.ready = false;
        }
        
        while (try LayerProgress *top = self.roots.last_ref()) {
            while (top.remaining--) {
                SQLLayer layer = self.rd.next_layer()!!;
                SQLLayerData data = self.rd.get_layer_data(layer.data_id)!!;
                
                /* create and append ground */
                if (layer.nchildren > 0) {
                    LayerGroup *group = mem::new(LayerGroup);
                    group.init(mem, data.name);
                    group.parent = top.root;
                    update_values(self, &group.base, data, layer.data_id);
                    
                    self.roots.push({ group, layer.nchildren });
                    top.root.add(group);
                    break;
                }
                
                image::Image *img = self.loaded[data.image_id]!!;
                
                if (!img.loaded) {
                    img.texture = rl::loadTextureFromImage(img.image);
                    rl::setTextureFilter(img.texture, BILINEAR);
                    rl::genTextureMipmaps(&img.texture);
                    rl::setTextureWrap(img.texture, TextureWrap.CLAMP.ordinal);
                    img.loaded = true;
                } else {
                    img.ref++;
                }
                
                if (img.file_content.len == 0) {
                    StaticLayer *slay = mem::new(StaticLayer);
                    slay.init(mem, data.name, img);
                    update_values(self, slay, data, layer.data_id);
                    top.root.add(slay);
                } else {
                    self.anim = {
                        img,
                        layer,
                        data,
                        top.root,
                        false
                    };
                    
                    self.state = ANIM_CLONE;
                    return REARM;
                }
            }
            
            if (self.roots.last()!!.remaining <= 0) self.roots.pop()!!;
        }
        
        Model old = self.ctx.model;
        self.ctx.model = self.model;
        old.free();
        
        self.ctx.file_lock = false;
        self.ctx.toaster.add(self.ctx, "Model loaded successfully");
    case ANIM_CLONE:
        unreachable("how did you get here");
    }
    
    return DISARM;
}

fn void update_values(ModelLoad *self, StaticLayer *base, SQLLayerData data,
    uint data_id) @local
{
    base.position.x = data.position.x;
    base.position.y = data.position.y;
    base.scale.x = data.scale.x;
    base.scale.y = data.scale.y;
    base.rotation = data.rotation;
    base.tint = uint_to_color(data.tint);
    base.timeout = data.timeout;
    base.mask = data.mask;
    base.toggle = data.toggle;
    
    if (char c = data.mask.get_char(), c > 0) {
        base.input_buffer[0] = c;
        base.input_length = 1;
    }
    
    @pool() {
        SQLAnimation[] anims = self.rd.get_layer_animations(tmem, data_id)!!;
        
        foreach (anim_data : anims) {
            Mask mask = anim_data.mask;
            char c = mask.get_char();
            
            AnimationEntry entry = {
                .a = null,
                .input_buffer = (char[2]) {c, 0},
                .input_length = c != 0 ? 1 : 0,
                .selected_animation = anim_data.type,
                .selected_easing = anim_data.easing,
                .custom_cfg_state = nk::MINIMIZED,
            };
            
            switch (anim_data.type) {
            case 0:
                abort("How did you even get here");
            case 1:
                Spinner *spin = mem::new(Spinner);
                spin.init(360, 2500);
                entry.a = spin;
                self.model.engine.add(spin);
            case 2:
                Shake *shake = mem::new(Shake);
                shake.init(100);
                entry.a = shake;
                self.model.engine.add(shake);
            case 3:
                Fade *fade = mem::new(Fade);
                fade.init(250);
                entry.a = fade;
                self.model.engine.add(fade);
            }
            
            BasicAnimation *anim_base = entry.a.get_base();
            anim_base.mask = mask;
            anim_base.repeat = anim_data.repeat;
            anim_base.easing = anim_data.easing;
            
            entry.a.unpack(anim_data.data[:anim_data.data_size]);
            base.animations.push(entry);
        }
    };
}

fn rl::Color uint_to_color(uint color) @local
{
    rl::Color res;
    res.a = (char) (color & 0xFF);
    res.b = (char) ((color >> 8) & 0xFF);
    res.g = (char) ((color >> 16) & 0xFF);
    res.r = (char) ((color >> 24) & 0xFF);
    
    return res;
}

module std::collections::list <Type>;

fn Type*? List.last_ref(&self)
{
    if (!self.size) return NO_MORE_ELEMENT~;
    return &self.entries[self.size - 1];
}

