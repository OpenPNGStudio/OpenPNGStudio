/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::reader;

import std::core::mem, std::core::mem::allocator;
import std::collections::map;
import opng::types, opng::stream;

faultdef NOT_OPNG_FILE, MAJOR_VERSION_MISMATCH, MINOR_VERSION_MISMATCH,
    COMPRESSION_METHOD_MISMATCH, KDF_METHOD_MISMATCH,
    ENCRYPTION_METHOD_MISMATCH, NO_MORE_DIRS, DIR_TYPE_MISMATCH,
    IMAGE_TYPE_MISMATCH, ANIMATION_TYPE_MISMATCH;

struct DirResult {
    DirType type;
    union value {
        Configuration cfg;
        LayerInfo[] layers;
        Image[] images;
        Animation[] animations;
    }
}

struct Reader {
    Allocator alloc;
    Stream stream;

    Header header;
    usz next_dir;
    usz dir_count;

    HashMap{uint,usz} animation_data_offsets;
}

fn void Reader.free(&self)
{
    self.stream.free();
    self.animation_data_offsets.free();
}

fn DirResult? Reader.read_dir(&self)
{
    if (self.dir_count >= DirType.COUNT) return NO_MORE_DIRS?;

    self.stream.offset(true, self.next_dir)!;
    DirResult res;
    usz offset;
    uint nentries;

    stream::@read(self.stream, res.type)!;
    if (res.type >= COUNT) return DIR_TYPE_MISMATCH?;

    stream::@read(self.stream, offset)!;
    if (offset == 0) return NO_MORE_DIRS?;

    stream::@read(self.stream, nentries)!;

    self.stream.offset(true, offset)!;

    switch (res.type) {
    case CONFIGURATION:
        read_conf(self, &res)!;
        break;
    case LAYER_INFO:
        res.value.layers = allocator::alloc_array(self.alloc, LayerInfo,
            nentries);
        read_layers(self, &res)!;
        break;
    case IMAGES:
        res.value.images = allocator::alloc_array(self.alloc, Image,
            nentries);
        read_images(self, &res)!;
        break;
    case ANIMATIONS:
        res.value.animations = allocator::alloc_array(self.alloc, Animation,
            nentries);
        read_animations(self, &res)!;
        break;
    default:
        unreachable("NOT IMPLEMENTED");
    }

    self.next_dir += types::DIR_SIZE;
    self.dir_count++;

    return res;
}

fn void? Reader.read_image(&self, Image info, char[] out)
{
    self.stream.offset(true, info.offset)!;

    self.stream.read(out)!;
}

fn void? Reader.read_animation_data(&self, Animation info, char[] out)
{
    self.stream.offset(true, self.animation_data_offsets[info.id]!)!;
    defer self.animation_data_offsets.remove(info.id);

    self.stream.read(out)!;
}

fn void? read_conf(Reader *self, DirResult *res)
{
    stream::@read(self.stream, res.value.cfg.microphone_trigger)!;
    stream::@read(self.stream, res.value.cfg.microphone_sensitivity)!;
    stream::@read(self.stream, res.value.cfg.background_color)!;
}

fn void? read_layers(Reader *self, DirResult *res)
{
    foreach (&layer : res.value.layers) {
        stream::@read(self.stream, layer.x)!;
        stream::@read(self.stream, layer.y)!;
        stream::@read(self.stream, layer.timeout)!;
        stream::@read(self.stream, layer.toggle_mode)!;
        stream::@read(self.stream, layer.mask)!;
        stream::@read(self.stream, layer.image_id)!;
        stream::@read(self.stream, layer.animation_id)!;
    }
}

fn void? read_images(Reader *self, DirResult *res)
{
    foreach (&image : res.value.images) {
        stream::@read(self.stream, image.type)!;
        if (image.type >= LIMIT) return IMAGE_TYPE_MISMATCH?;

        stream::@read(self.stream, image.id)!;
        stream::@read(self.stream, image.uncompressed_size)!;
        stream::@read(self.stream, image.size)!;
        stream::@read(self.stream, image.offset)!;
    }
}

fn void? read_animations(Reader *self, DirResult *res)
{
    foreach (&anim : res.value.animations) {
        stream::@read(self.stream, anim.type)!;
        if (anim.type >= LIMIT) return ANIMATION_TYPE_MISMATCH?;

        stream::@read(self.stream, anim.id)!;
        stream::@read(self.stream, anim.easing)!;
        stream::@read(self.stream, anim.mask)!;
        stream::@read(self.stream, anim.data_size)!;

        self.animation_data_offsets[anim.id] = self.stream.offset()!;
        self.stream.skip(anim.data_size)!;
    }
}

module opng;

import std::io, std::io::file;
import std::core::mem;

struct ReaderConfig {
    ushort version;
}

fn Reader? read_memory(Allocator alloc, char[] buffer, ReaderConfig cfg)
{
    Reader r;
    r.alloc = alloc;
    MemoryStream *s = calloc(MemoryStream.sizeof);

    s.buffer = buffer.ptr;
    s.len = buffer.len;
    s.allocated = s.len;
    s.read_only = true;
    r.stream = s;

    init_reader(&r, cfg)!;

    return r;
}

fn Reader? read_file(Allocator alloc, String path, ReaderConfig cfg)
{
    Reader r;
    r.alloc = alloc;
    FileStream *s = calloc(FileStream.sizeof);

    s.file = file::open(path, "r")!;
    r.stream = s;

    init_reader(&r, cfg)!;

    return r;
}

fn void? init_reader(Reader *self, ReaderConfig cfg)
{
    stream::@read(self.stream, self.header.magic)!;

    if (&self.header.magic != "OPNG") return reader::NOT_OPNG_FILE?;

    stream::@read(self.stream, self.header.version)!;

    ushort header_major = self.header.version & 0xFF00;
    header_major >>= char.sizeof * 8;

    ushort cfg_major = cfg.version & 0xFF00;
    cfg_major >>= char.sizeof * 8;

    ushort header_minor = self.header.version & 0x00FF;
    ushort cfg_minor = cfg.version & 0x00FF;

    if (header_major > cfg_major) return reader::MAJOR_VERSION_MISMATCH?;
    if (header_major == cfg_major && header_minor > cfg_minor) return
        reader::MINOR_VERSION_MISMATCH?;

    stream::@read(self.stream, self.header.compression_method)!;
    if (self.header.compression_method >= LIMIT) return
        reader::COMPRESSION_METHOD_MISMATCH?;

    stream::@read(self.stream, self.header.password_encryption_method)!;
    if (self.header.password_encryption_method >= LIMIT) return
        reader::KDF_METHOD_MISMATCH?;

    stream::@read(self.stream, self.header.encryption_method)!;
    if (self.header.encryption_method >= LIMIT) return
        reader::ENCRYPTION_METHOD_MISMATCH?;

    self.next_dir = self.stream.offset()!;
    self.dir_count = 0;
    self.animation_data_offsets.init(self.alloc);
}
