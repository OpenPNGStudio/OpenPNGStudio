/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::writer;

import std;

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
    usz dirs_start, nlayers;

    uint image_ids, animation_ids;
}

const DIR_SIZE = 13; /* 1 + 8 + 4 */

fn void Writer.free(&self)
{
    self.stream.free();
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

fn void? find_dir(Writer *self, DirType type) @local
{
    if (self.offsets[type] == 0) {
        usz largest = 0;
        for (int i = 0; i < DirType.COUNT; i++) {
            largest = max(largest, self.offsets[i]);
        }

        if (largest > 0) {
            largest += DIR_SIZE;  /* to offset already written dir */
        } else {
            largest = self.dirs_start;
        }

        self.offsets[type] = largest;
    }

    self.stream.offset(true, self.offsets[type])!;
}

module opng;

fn Writer? write_memory()
{
    Writer w;
    w.animation_ids = 1;
    w.image_ids = 1;

    MemoryStream *s = calloc(MemoryStream.sizeof);
    w.stream = s;
    w.stream.write("OPNG")!;
    ushort ver = 0x0003;
    stream::@write(w.stream, ver)!;
    Compression comp = NONE;
    Kdf kdf = NONE;
    Encryption enc = NONE;
    stream::@write(w.stream, comp)!;
    stream::@write(w.stream, kdf)!;
    stream::@write(w.stream, enc)!;

    w.dirs_start = w.stream.offset()!;

    char[DirType.COUNT * writer::DIR_SIZE] empty;
    w.stream.write(&empty)!;

    return w;
}

fn Writer write_file(ZString *path)
{
    unreachable("unimplemented");
}
