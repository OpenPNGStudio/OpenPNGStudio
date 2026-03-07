/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::info @if($feature(OPNG_STANDALONE));

import std::io, std::os;
import std::collections::map;
import opng;
import std::core::string::ansi;

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

    Reader? rd = opng::read_file(mem, argv[0].str_view(), { 0x0003 });
    if (catch excuse = rd) {
        io::fprint(io::stderr(), "opng info: ")!!;
        io::fprintn(io::stderr(), excuse.shortname())!!;
        return 1;
    }
    defer rd.free();

    io::printn("Model Info:");
    @ident("version", 2);
    io::print(" = ");
    @integer((rd.header.version & 0xFF00) >> 8);
    io::print(".");
    @integer(rd.header.version & 0xFF);
    io::printn();

    @ident("compression", 2);
    io::print(" = ");
    switch (rd.header.compression_method) {
    case NONE:
        @string("none");
    case LZF:
        @string("lzf");
    case LZ4:
        @string("lz4");
    case ZSTD:
        @string("zstd");
    case XZ:
        @string("xz");
    default:
    }
    io::printn();
    
    @ident("password method", 2);
    io::print(" = ");
    switch (rd.header.password_encryption_method) {
    case NONE:
        @string("none");
    case ARGON2ID:
        @string("argon2id");
    default:
    }
    io::printn();

    @ident("encryption", 2);
    io::print(" = ");
    switch (rd.header.encryption_method) {
    case NONE:
        @string("none");
    case XCHACHA20_POLY1305:
        @string("xchacha20_poly1305");
    default:
    }
    io::printn("\n");

    while (try DirResult res = rd.next_dir()) {
        switch (res.type) {
        case SQLITE:
            rd.load_sqlite(res.value.sqlite)!!;
            
            io::printn("Model Layers:");
            (void) layer_info(&rd);
        case IMAGES:
            io::printn("Model Images:");
            foreach (img : res.value.images) {
                image_info(&rd, img)!!;
            }
        default:
        }
    }

    return 0;
}

fn void? layer_info(Reader *rd, int depth = 2) @local @maydiscard
{
    SQLLayer layer = rd.next_layer()!;
    SQLLayerData data = rd.get_layer_data(layer.data_id)!;

    /* data */
    if (depth > 2) {
        @string(data.name);
        io::printn(":");
    }
    
    if (layer.nchildren > 0) {
        @ident("children", depth);
        io::print(" = ");
        @integer(layer.nchildren);
        io::printn();
    }

    @ident("position", depth);
    io::print("(");
    @ident("x", 0);
    io::print(", ");
    @ident("y", 0);
    io::print(") = ");
    io::print("(");
    @decimal(data.position.x);
    io::print(", ");
    @decimal(data.position.y);
    io::printn(")");

    @ident("scale", depth);
    io::print("(");
    @ident("w", 0);
    io::print(", ");
    @ident("h", 0);
    io::print(") = ");
    io::print("(");
    @decimal(data.scale.x);
    io::print(", ");
    @decimal(data.scale.y);
    io::printn(")");

    @ident("rotation", depth);
    io::print(" = ");
    @decimal(data.rotation);
    io::printn();

    @ident("tint", depth);
    io::print(" = ");
    @tint(data.tint);
    io::printn();

    @ident("timeout", depth);
    io::print(" = ");
    @integer(data.timeout);
    io::printn("ms");

    @ident("mask", depth);
    io::print(" = ");
    @mask(data.mask);
    io::printn();

    @ident("toggle", depth);
    io::print(" = ");
    @boolean(data.toggle);

    if (data.image_id > 0) {
        io::printn();
        @ident("image id", depth);
        io::print(" = ");
        @integer(data.image_id);
    }

    @pool() {
        SQLAnimation[] anims = rd.get_layer_animations(tmem, layer.data_id)!!;

        if (anims.len > 0) {
            io::printn();
            padding(depth);
            io::print(Ansi.BRIGHT_BLUE);
            io::print("animations");
            io::print(Ansi.RESET);
            io::print(" = ");
            @integer(anims.len);
            io::print(":");
        }

        foreach (i, anim : anims) {
            io::printn();
            anim_info(anim, depth + 2);
            if (i + 1 != anims.len) {
                io::printn();
                padding(depth + 2);
                io::print("===");
            }
        }
        
        io::printn("\n");
    };

    for (int i = 0; i < layer.nchildren; i++) {
        padding(depth);
        io::print(Ansi.BRIGHT_BLUE);
        io::print("child layer");
        io::print(Ansi.RESET);
        io::print(" = ");
        layer_info(rd, depth + 2);
    }
}

fn void anim_info(SQLAnimation self, int depth) @local
{
    @ident("type", depth);
    io::print(" = ");
    @integer(self.type);
    io::printn();

    @ident("easing", depth);
    io::print(" = ");
    @integer(self.type);
    io::printn();
    
    @ident("mask", depth);
    io::print(" = ");
    @mask(self.mask);
    io::printn();
    
    @ident("repeat", depth);
    io::print(" = ");
    @boolean(self.repeat);
    io::printn();

    @ident("data", depth);
    io::print(" = [");
    char *ptr = self.data;
    
    for (usz i = 0; i < self.data_size; i++) {
        @integer(ptr[i]);
        if (i + 1 != self.data_size) io::print(", ");
    }

    io::print("]");
}

fn void? image_info(Reader *rd, ImageEntry img) @local @maydiscard
{
    @pool() {
        char[] data = mem::temp_array(char, img.uncompressed_size);
        
        rd.read_into(img.offset, data)!;
        QOIDesc desc;

        @pool() {
            char[] useless = qoi::decode(tmem, data[:img.uncompressed_size],
                &desc)!;
        };

        @ident("id", 2);
        io::print(" = ");
        @integer(img.id);
        io::printn();

        @ident("type", 2);
        io::print(" = ");
        switch (img.type) {
        case STATIC:
            @string("static");
        case ANIMATED:
            @string("animated");
        default:
        }
        io::printn();

        @ident("uncompressed size", 2);
        io::print(" = ");
        @integer(img.uncompressed_size);
        io::printn();

        @ident("size", 2);
        io::print(" = ");
        @integer(img.size);
        io::printn();

        @ident("dimensions", 2);
        io::print("(");
        @ident("w", 0);
        io::print(", ");
        @ident("h", 0);
        io::print(") = ");
        io::print("(");
        @decimal(desc.width);
        io::print(", ");
        @decimal(desc.height);
        io::printn(")");
    };
}

macro void @ident($str, #d) @local
{
    padding(#d);
    io::print(Ansi.BRIGHT_CYAN);
    io::print($str);
    io::print(Ansi.RESET);
}

macro void @integer(#val) @local
{
    io::print(Ansi.BRIGHT_MAGENTA);
    io::printf("%d", #val);
    io::print(Ansi.RESET);
}

macro void @decimal(#val) @local
{
    io::print(Ansi.BRIGHT_MAGENTA);
    io::printf("%.2f", #val);
    io::print(Ansi.RESET);
}

macro void @string(#val) @local
{
    io::print(Ansi.BRIGHT_GREEN);
    io::printf("\"%s\"", #val);
    io::print(Ansi.RESET);
}

macro void @tint(#val) @local
{
    AnsiColor bg = {
        (char) (#val >> 24) & 0xFF,
        (char) (#val >> 16) & 0xFF,
        (char) (#val >> 8) & 0xFF,
        true
    };
    
    io::print(bg);
    bg.bg = false;
    io::print(bg);
    io::printf("#%08x ", #val);
    io::print(Ansi.RESET);
}

macro void @mask(#val) @local
{
    io::print(Ansi.BRIGHT_YELLOW);
    io::printf("0b%033b", #val);
    io::print(Ansi.RESET);
}

macro void @boolean(#val) @local
{
    io::print(Ansi.BRIGHT_RED);
    io::printf("%s", #val == true ? "yes" : "no");
    io::print(Ansi.RESET);
}

fn void padding(int depth) @local
{
    for (int i = 0; i < depth; i++) io::print(" ");
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng info [-h] file\n")!!;
    os::exit(1);
}
