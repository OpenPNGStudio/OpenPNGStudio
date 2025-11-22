/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::writer;

import std;
import std::collections::map;

import opng::types, opng::stream;

enum State {
    DEFAULT,
    LAYER_INFO,
    IMAGE_INFO,
    IMAGES,
    ANIMATIONS
}

struct Writer {
    Stream stream;
    State state;
    usz[DirType.COUNT] offsets;
    usz dirs_start, nlayers, nimages, nanims;

    uint image_ids, animation_ids;

    HashMap{uint,usz} images_to_update;
}

fn void Writer.free(&self)
{
    self.stream.free();
    self.images_to_update.free();
}

fn void? Writer.start_configure(&self, Configuration cfg)
{
    usz offset = self.stream.offset()!;
    uint nentries = 0; /* ignored */

    find_dir(self, CONFIGURATION)!;
    DirType t = CONFIGURATION;

    stream::@write(self.stream, t)!;
    stream::@write(self.stream, offset)!;
    stream::@write(self.stream, nentries)!;

    self.stream.offset(true, offset)!;

    stream::@write(self.stream, cfg.microphone_trigger)!;
    stream::@write(self.stream, cfg.microphone_sensitivity)!;
    stream::@write(self.stream, cfg.background_color)!;
}

<*
@require self.state == DEFAULT
@require self.nlayers == 0 : "Layers were already written"
*>
fn void? Writer.start_layers(&self)
{
    self.state = LAYER_INFO;
    usz offset = self.stream.offset()!;

    find_dir(self, LAYER_INFO)!;
    DirType t = LAYER_INFO;

    stream::@write(self.stream, t)!;
    stream::@write(self.stream, offset)!;
    stream::@write(self.stream, self.nlayers)!;

    self.stream.offset(true, offset)!;
}

<*
@require self.state == DEFAULT
@require self.nimages == 0 : "Image info was already written"
*>
fn void? Writer.start_image_info(&self)
{
    self.state = IMAGE_INFO;
    usz offset = self.stream.offset()!;

    find_dir(self, IMAGES)!;
    DirType t = IMAGES;

    stream::@write(self.stream, t)!;
    stream::@write(self.stream, offset)!;
    stream::@write(self.stream, self.nimages)!;

    self.stream.offset(true, offset)!;
}

<*
@require self.state == DEFAULT
@require self.nimages > 0 : "Image info needs to be written"
*>
fn void? Writer.start_images(&self)
{
    self.state = IMAGES;
}

<*
@require self.state == DEFAULT
@require self.nanims == 0 : "Animations were written"
*>
fn void? Writer.start_animations(&self)
{
    self.state = ANIMATIONS;
    usz offset = self.stream.offset()!;

    find_dir(self, ANIMATIONS)!;
    DirType t = ANIMATIONS;

    stream::@write(self.stream, t)!;
    stream::@write(self.stream, offset)!;
    stream::@write(self.stream, self.nanims)!;

    self.stream.offset(true, offset)!;
}

<*
@require self.state == IMAGES
*>
fn void? Writer.end_images(&self)
{
    self.state = DEFAULT;
}

<*
@require self.state == IMAGE_INFO
*>
fn void? Writer.end_image_info(&self)
{
    usz offset = self.stream.offset()!;

    find_dir(self, IMAGES)!;

    self.stream.skip(0x9)!;
    stream::@write(self.stream, self.nimages)!;

    self.stream.offset(true, offset)!;

    self.state = DEFAULT;
}

<*
@require self.state == LAYER_INFO
*>
fn void? Writer.end_layers(&self)
{
    usz offset = self.stream.offset()!;

    find_dir(self, LAYER_INFO)!;

    self.stream.skip(0x9)!;
    stream::@write(self.stream, self.nlayers)!;

    self.stream.offset(true, offset)!;

    self.state = DEFAULT;
}

<*
@require self.state == ANIMATIONS
*>
fn void? Writer.end_animations(&self)
{
    usz offset = self.stream.offset()!;

    find_dir(self, ANIMATIONS)!;

    self.stream.skip(0x9)!;
    stream::@write(self.stream, self.nanims)!;

    self.stream.offset(true, offset)!;

    self.state = DEFAULT;
}

<*
@require self.state == LAYER_INFO
*>
fn IdPair? Writer.add_layer(&self, LayerInfo info, bool is_animated)
{
    IdPair pair;
    pair.image_id = self.image_ids++;
    if (is_animated) pair.animation_id = self.animation_ids++;

    stream::@write(self.stream, info.x)!;
    stream::@write(self.stream, info.y)!;
    stream::@write(self.stream, info.timeout)!;
    stream::@write(self.stream, info.toggle_mode)!;
    stream::@write(self.stream, info.mask)!;
    stream::@write(self.stream, pair.image_id)!;
    stream::@write(self.stream, pair.animation_id)!;
    self.nlayers++;

    return pair;
}

<*
@require self.state == IMAGE_INFO
*>
fn void? Writer.add_image_info(&self, Image info)
{
    usz offset = self.stream.offset()!;

    stream::@write(self.stream, info.type)!;
    stream::@write(self.stream, info.id)!;
    stream::@write(self.stream, info.uncompressed_size)!;
    stream::@write(self.stream, info.size)!;
    stream::@write(self.stream, info.offset)!;
    self.nimages++;

    self.images_to_update[info.id] = offset;
}

<*
@require self.state == IMAGES
*>
fn void? Writer.add_image(&self, uint id, char[] buffer)
{
    /* TODO: Handle compression and encryption */
    usz offset = self.stream.offset()!;
    usz info_offset = self.images_to_update[id]!;
    defer self.images_to_update.remove(id);

    self.stream.offset(true, info_offset)!;
    self.stream.skip(0x5)!;

    usz len = buffer.len;

    stream::@write(self.stream, len)!;
    stream::@write(self.stream, len)!;
    stream::@write(self.stream, offset)!;

    self.stream.offset(true, offset)!;
    self.stream.write(buffer)!;
}

<*
@require self.state == ANIMATIONS
*>
fn void? Writer.add_animation(&self, Animation info)
{
    stream::@write(self.stream, info.type)!;
    stream::@write(self.stream, info.id)!;
    stream::@write(self.stream, info.easing)!;
    stream::@write(self.stream, info.mask)!;
    stream::@write(self.stream, info.data_size)!;
    self.nanims++;
}

<*
@require self.state == ANIMATIONS
*>
fn void? Writer.add_animation_data(&self, char[] data)
{
    self.stream.write(data)!;
}

fn void? find_dir(Writer *self, DirType type) @local
{
    if (self.offsets[type] == 0) {
        usz largest = 0;
        for (int i = 0; i < DirType.COUNT; i++) {
            largest = max(largest, self.offsets[i]);
        }

        if (largest > 0) {
            largest += types::DIR_SIZE;  /* to offset already written dir */
        } else {
            largest = self.dirs_start;
        }

        self.offsets[type] = largest;
    }

    self.stream.offset(true, self.offsets[type])!;
}

module opng;

import std::io::file;

struct WriterConfig {
    ushort version;
    Compression compression;
    Kdf kdf;
    Encryption encryption;
}

fn Writer? write_memory(Allocator alloc, WriterConfig cfg)
{
    Writer w;
    w.stream = (MemoryStream*) calloc(MemoryStream.sizeof);

    init_writer(&w, alloc, cfg)!;

    return w;
}

fn Writer? write_file(Allocator alloc, String path, WriterConfig cfg)
{
    Writer w;
    FileStream *s = calloc(FileStream.sizeof);
    s.file = file::open(path, "w")!;
    w.stream = s;

    init_writer(&w, alloc, cfg)!;

    return w;
}

fn void? init_writer(Writer *self, Allocator alloc, WriterConfig cfg) @local
{
    self.animation_ids = 1;
    self.image_ids = 1;
    self.images_to_update.init(alloc);

    self.stream.write("OPNG")!;
    stream::@write(self.stream, cfg.version)!;
    stream::@write(self.stream, cfg.compression)!;
    stream::@write(self.stream, cfg.kdf)!;
    stream::@write(self.stream, cfg.encryption)!;

    self.dirs_start = self.stream.offset()!;

    char[DirType.COUNT * types::DIR_SIZE] empty;
    self.stream.write(&empty)!;
}
