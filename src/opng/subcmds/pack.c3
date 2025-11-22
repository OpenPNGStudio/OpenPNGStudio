/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::pack @if($feature(OPNG_STANDALONE));

import std::io, std::os, std::encoding::json;
import std::collections::object;
import std::collections::map;

import opng;

struct ParsedAnim {
    AnimationType type;
    char easing;
    ulong mask;
    uint data_size;
    char *data;
}

struct ParsedLayer {
    int x, y;
    float rotation;
    uint timeout;
    bool toggle_mode;
    ulong mask;
    File image;
    bool has_anim, is_gif;
    ParsedAnim anim;
}

struct ParsedConfig {
    usz mic_trigger;
    uint sensitivity, bg_color;
}

struct Model {
    ParsedConfig cfg;
    HashMap{String, ParsedLayer} layers;
}

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

    if (verbose) io::printfn("Opening file '%s'", argv[1]);

    Writer w = opng::write_file(mem, argv[1].str_view(), { 0x0003, NONE, NONE,
        NONE })!!;
    defer w.free();

    if (verbose) io::printfn("Parsing dir '%s'", argv[0]);

    Model model = parse_dir(argv[0].str_view())!!;

    if (verbose) io::printfn("Configuring");
    w.start_configure({
        model.cfg.mic_trigger, model.cfg.sensitivity, model.cfg.bg_color
    })!!;

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

    return 0;
}

faultdef NOT_DIR, MISSING_IMAGES, EXPECTED_JSON, INCORRECT_DATA_SIZE;

fn Model? parse_dir(String path) @local
{
    Model mod;
    bool has_config, has_layers, has_images, has_animations;

    Path cfg, layers, images, anims;

    @pool() {
        Path p = path.to_tpath()!;

        if (!path::is_dir(p)) return NOT_DIR?;

        PathList files = path::ls(tmem, p)!;

        foreach (file : files) {
            switch (file.str_view()) {
            case "conf.json":
                cfg = p.tappend("conf.json")!;
                has_config = true;
                break;
            case "layers":
                layers = p.tappend("layers")!;
                has_layers = true;
                break;
            case "images":
                images = p.tappend("images")!;
                has_images = true;
                break;
            case "animations":
                anims = p.tappend("animations")!;
                has_animations = true;
                break;
            }
        }

        File conf = file::open(cfg.str_view(), "r")!;
        Object *root = json::tparse(&conf)!;

        mod.cfg.mic_trigger = root.get_ulong("microphone_trigger")!;
        mod.cfg.sensitivity = root.get_uint("microphone_sensitivity")!;
        mod.cfg.bg_color = root.get_uint("background_color")!;

        if (has_layers && !has_images) return MISSING_IMAGES?;

        conf.close()!;

        mod.layers = parse_layers(layers)!;
        mod.layers.@each_entry(; Entry{String,ParsedLayer} *entry) {
            @pool() {
                bool gif = false;
                Path img = images.tappend(entry.key.tconcat(".qoi"))!;
                if (!path::exists(img)) {
                    img = images.tappend(entry.key.tconcat(".gif"))!;
                    gif = true;
                }

                entry.value.image = file::open(img.str_view(), "r")!;
                entry.value.is_gif = gif;

                Path anim = anims.tappend(entry.key.tconcat(".json"))!;
                if (path::exists(anim)) {
                    entry.value.has_anim = true;
                    entry.value.anim = parse_anim(anim)!;
                }
            };
        };
    };

    return mod;
}

fn ParsedAnim? parse_anim(Path file) @local
{
    ParsedAnim parsed;

    @pool() {
        File f = file::open(file.str_view(), "r")!;

        Object *root = json::tparse(&f)!;

        parsed.type = (AnimationType) root.get_char("type")!;
        parsed.easing = root.get_char("easing")!;
        parsed.mask = root.get_ulong("mask")!;
        parsed.data_size = root.get_uint("data_size")!;
        parsed.data = malloc(parsed.data_size);

        Object *data = root.get("data")!;
        if (data.get_len() != parsed.data_size) return INCORRECT_DATA_SIZE?;

        for (uint i = 0; i < parsed.data_size; i++) {
            parsed.data[i] = data.get_integer_at(char, i)!;
        }

        f.close()!;
    };

    return parsed;
}

fn HashMap{String, ParsedLayer}? parse_layers(Path layers_dir) @local
{
    HashMap{String, ParsedLayer} layers;
    layers.init(mem);
    @pool() {
        PathList list = path::ls(tmem, layers_dir)!;

        foreach (lay : list) {
            if (lay.extension()! != "json") return EXPECTED_JSON?;
            String name = lay.name_no_extension()!;

            ParsedLayer layer;
            @pool() {
                Path file_path = layers_dir.tappend(lay.str_view())!;
                File f = file::open(file_path.str_view(), "r")!;

                Object *root = json::tparse(&f)!;
                layer.x = root.get_int("x")!;
                layer.y = root.get_int("y")!;
                layer.rotation = (float) root.get_float("rotation")!;
                layer.timeout = root.get_uint("timeout")!;
                layer.toggle_mode = root.get_bool("toggle_mode")!;
                layer.mask = root.get_ulong("mask")!;

                f.close()!;
            };

            layers[name] = layer;
        }
    };

    return layers;
}

fn String? Path.name_no_extension(&self)
{
    String basename = self.basename();
    usz index = basename.rindex_of(".")!;

    if (index == 0 || index == basename.len) return basename;
    return basename[:index];
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng pack [-hv] dir outfile\n")!!;
    os::exit(1);
}
