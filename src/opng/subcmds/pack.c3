/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::pack @if($feature(OPNG_STANDALONE));

import std::io, std::os, std::encoding::json, std::io::path;
import std::collections::object, std::collections::map, std::collections::list;

import opng;

struct Image {
    uint id;
    usz rc;
    char[] buffer;
    ImageType type;
}

struct ParsedLayer {
    SQLLayerData data;
    List{SQLAnimation} animations;
    List{ParsedLayer} children;
    Image *img; String img_name;
}

struct ParseContext @local {
    HashMap{String, Image} images;
}

uint id_counter @local = 1;

fn int _main(int argc, ZString *argv)
{
    ichar c;
    bool verbose = false;

    while ((c = (ichar) getopt(argc, argv, "hv")) != -1) {
        switch (c) {
        case 'v':
            verbose = true;
            break;
        case 'h':
        default:
            usage();
        }
    }

    argc -= optind;
    argv += optind;

    if (argc < 2) usage();

    Writer wr = opng::write_file(mem, argv[1].str_view(), { 0x0003, NONE, NONE,
        NONE })!!;
    defer wr.free();

    ParseContext ctx;
    ctx.images.init(mem);
    
    ParsedLayer root = parse_dir(&ctx, argv[0].str_view())!!;
    io::printn(ctx.images);

    print(&root);

    /*

    w.start_layers()!!;
    HashMap{String, IdPair} ids;
    ids.init(mem);
    defer ids.free();

    model.layers.@each(; String key, ParsedLayer layer) {
        if (verbose) io::printfn("Writing layer info for '%s'", key);
        IdPair id = w.add_layer({ layer.x, layer.y, layer.rotation,
            layer.timeout, layer.toggle_mode, layer.mask, 0, 0 },
            layer.has_anim)!!;

        ids[key] = id;
    };

    w.end_layers()!!;
    w.start_animations()!!;

    ids.@each(; String key, IdPair pair) {
        if (pair.animation_id > 0) {
            if (verbose) io::printfn("Writing layer animation info for '%s'", key);
            ParsedLayer i = model.layers[key]!!;
            w.add_animation({
                i.anim.type, pair.animation_id, i.anim.easing, i.anim.mask,
                i.anim.data_size
            })!!;
            w.add_animation_data(i.anim.data[:i.anim.data_size])!!;
        }
    };
    w.end_animations()!!;

    w.start_image_info()!!;

    ids.@each(; String key, IdPair pair) {
        if (verbose) io::printfn("Writing image info for '%s'", key);
        ParsedLayer i = model.layers[key]!!;
        w.add_image_info({
            i.is_gif ? ANIMATED : STATIC,
            pair.image_id, 0, 0, 0
        })!!;
    };

    w.end_image_info()!!;
    w.start_images()!!;

    ids.@each(; String key, IdPair pair) {
        if (verbose) io::printfn("Writing image for '%s'", key);
        ParsedLayer i = model.layers[key]!!;
        usz len = i.image.seek(0, END)!!;
        i.image.seek(0, SET)!!;

        char *data = malloc(len);
        char[] buf = data[:len];
        i.image.read(buf)!!;

        w.add_image(pair.image_id, buf)!!;

        free(data);
    };

    w.end_images()!!;
    */

    return 0;
}

fn void print(ParsedLayer *layer) @local
{
    io::printn(layer.data);
    
    foreach (&lay : layer.children) {
        print(lay);
    }
}

faultdef EXPECTED_OBJECT, EXPECTED_ARRAY;

fn ParsedLayer? parse_dir(ParseContext *ctx, String path) @local
{
    ParsedLayer root;
    root.children.init(mem);
    root.animations.init(mem);

    @pool() {
        Path dir = path::temp(path)!;

        parse(ctx, &root, dir)!;
    };

    return root;
}

fn bool? parse(ParseContext *self, ParsedLayer *target, Path file) @local
{
    /* is group */
    if (path::is_dir(file)) {
        @pool() {
            PathList files = path::ls(tmem, file)!;

            foreach (f : files) {
                if (f.basename() == "root.json") {
                    parse(self, target, file.tappend(f.basename())!)!;
                } else {
                    ParsedLayer tmp;
                    tmp.children.init(mem);
                    tmp.animations.init(mem);

                    if (parse(self, &tmp, file.tappend(f.basename())!)!) {
                        target.children.push(tmp);
                    }
                }
            }
        };
        
        target.data.name = file.basename().zstr_copy(mem);
    } else { /* is file */
        @pool() {
            String basename = file.basename();
            if (basename.ends_with(".json")) {
                usz index = basename.rindex_of(".")!;
                target.data.name = basename[:index].zstr_copy(mem);
                parse_json(self, target, file, basename == "root.json")!;
            } else if (basename.ends_with(".qoi") || 
                basename.ends_with(".gif")) {
                if (self.images.has_key(basename)) return false;

                self.images[basename] = {
                    id_counter++,
                    1,
                    file::load(mem, file.str_view())!,
                    basename.ends_with(".gif") ? ANIMATED : STATIC,
                };

                return false;
            }
        };
    }
    
    return true;
}

fn void? parse_json(ParseContext *self, ParsedLayer *target, Path file,
    bool ignore_image) @local => @pool()
{
    File f = file::open(file.str_view(), "r")!;
    Object *root = json::tparse(&f)!;

    Object *data = root.get("data")!;
    {
        Object *pos = data.get("position")!;
        if (!pos.is_map()) return EXPECTED_OBJECT~;
        
        target.data.position.x = (float) pos.get_float("x")!;
        target.data.position.y = (float) pos.get_float("y")!;

        Object *scale = data.get("scale")!;

        target.data.scale.x = (float) pos.get_float("x")!;
        target.data.scale.y = (float) pos.get_float("y")!;

        target.data.rotation = (float) data.get_float("rotation")!;
        target.data.tint = data.get_uint("tint")!;
        target.data.timeout = data.get_ulong("timeout")!;
        target.data.mask = data.get_ulong("mask")!;
        target.data.toggle = data.get_bool("toggle_mode")!;
    }

    if (!ignore_image) {
        String img = root.get_string("image")!;
        if (try Image *i = self.images.get_ref(img)) {
            target.img = i;
            target.img_name = "";
            target.data.image_id = i.id;
        } else {
            target.img_name = img;
            target.img = null;
        }
    }

    if (try Object *animations = root.get("animations")) {
        if (!animations.is_array() && !animations.is_empty()) return EXPECTED_ARRAY~;

        for (usz i = 0; i < animations.get_len(); i++) {
            Object *anim = animations.get_at(i);
            SQLAnimation a;

            a.type = anim.get_int("type")!;
            a.mask = anim.get_ulong("mask")!;
            a.easing = anim.get_int("easing")!;
            a.repeat = anim.get_bool("repeat")!;

            Object *anim_data = anim.get("data")!;
            if (!anim_data.is_array()) return EXPECTED_ARRAY~;

            a.data_size = anim_data.get_len();
            a.data = malloc(a.data_size * char.sizeof);

            for (int j = 0; j < a.data_size; j++) {
                ((char*) a.data)[j] = anim_data.get_integer_at(char, i)!;
            }

            target.animations.push(a);
        }
    }
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng pack [-hv] dir outfile\n")!!;
    os::exit(1);
}
