/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::info @if($feature(OPNG_STANDALONE));

import std::io, std::os;
import std::collections::map;
import opng;

import std::compression::qoi;

fn int _main(int argc, ZString *argv)
{
    ichar c;

    while ((c = (ichar) getopt(argc, argv, "h")) != -1) {
        switch (c) {
        case 'h':
        default:
            usage();
        }
    }

    argc -= optind;
    argv += optind;

    if (argc < 1) usage();


    Reader? r = opng::read_file(mem, argv[0].str_view(), { 0x0003 });

    if (catch excuse = r) {
        io::fprint(io::stderr(), "opng info: ")!!;
        io::fprintn(io::stderr(), excuse.shortname())!!;
        return 1;
    }

    defer r.free();

    while (try DirResult res = r.read_dir()) {
        switch (res.type) {
        case CONFIGURATION:
            io::printn("Model Configuration:");
            io::printfn("microphone trigger = %d",
                res.value.cfg.microphone_trigger);
            io::printfn("microphone sensitivity = %d",
                res.value.cfg.microphone_sensitivity);
            io::printfn("background color (RGBA) = %X",
                res.value.cfg.background_color);
            break;
        case LAYER_INFO:
            io::printn("Model Layers:");
            foreach (&layer : res.value.layers) {
                io::printfn("\tid = %d", layer.image_id);
                io::printfn("\t(x,y) = (%d,%d)", layer.x, layer.y);
                io::printfn("\trotation = %f", layer.rotation);
                io::printfn("\ttimeout = %dms", layer.timeout);
                io::printfn("\thas toggle? %s", layer.toggle_mode ? "yes" :
                    "no");
                io::printfn("\tmask = %033b", layer.mask);

                io::printfn("\thas animation? %s", layer.animation_id > 0 ?
                    "yes" : "no");

                if (layer.animation_id > 0) {
                    io::printfn("\tanimation id = %d", layer.animation_id);
                }
            }
            free(res.value.layers.ptr);
            break;
        case IMAGES:
            io::printn("Layer Images:");
            foreach (image : res.value.images) {
                io::printfn("\tid = %d", image.id);
                io::printfn("\ttype = %s", image.type);
                io::printfn("\tuncompressed size = %d",
                    image.uncompressed_size);
                io::printfn("\tsize = %d", image.size);

                char *buf = malloc(image.uncompressed_size);
                defer free(buf);
                r.read_image(image, buf[:image.uncompressed_size])!!;
                QOIDesc desc;

                @pool() {
                    char[] useless = qoi::decode(tmem,
                        buf[:image.uncompressed_size], &desc)!!;

                };

                io::printfn("\t(width,height) = (%d,%d)", desc.width,
                    desc.height);
            }
            free(res.value.images.ptr);
            break;
        case ANIMATIONS:
            io::printn("Layer Animations:");
            foreach (anim : res.value.animations) {
                io::printfn("\tid = %d", anim.id);
                io::printfn("\ttype = %s", anim.type);
                io::printfn("\teasing = %d", anim.easing);
                io::printfn("\tmask = %033b", anim.mask);
                io::printfn("\tdata size = %d", anim.data_size);

                io::printf("\tanimation data = [");
                char *buf = malloc(anim.data_size);
                defer free(buf);
                r.read_animation_data(anim, buf[:anim.data_size])!!;

                foreach (i, byte : buf[:anim.data_size]) {
                    io::printf("%x", byte);
                    if (i + 1 < anim.data_size) io::print(", ");
                }
                io::printn("]");
            }
            free(res.value.animations.ptr);
            break;
        default:
            break;
        }
    }

    return 0;
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng info [-h] file\n")!!;
    os::exit(1);
}

fn String fault.shortname(self)
{
    String name = self.nameof;
    return name[name.index_of("::") + 2..]!!;
}
