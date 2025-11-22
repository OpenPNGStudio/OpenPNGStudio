/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::stream;

import std, std::io;

faultdef OUT_OF_BOUNDS, ONLY_READING_ALLOWED;

interface Stream {
    fn void? read(char[] data);
    fn void? write(char[] data);
    fn void? skip(usz nbytes);
    fn usz? offset(bool set = false, usz off = 0);
    fn void free();
    fn char[] get_buf();
}

struct MemoryStream (Stream) {
    char *buffer;
    usz len, allocated;
    usz cursor;
    bool read_only;
}

fn void? MemoryStream.write(&self, char[] data) @dynamic
{
    if (self.read_only) return ONLY_READING_ALLOWED?;
    while (self.len + data.len >= self.allocated) grow(self);

    foreach (c : data) {
        self.buffer[self.cursor++] = c;
    }

    self.len = max(self.len, self.cursor);
}

fn void? MemoryStream.read(&self, char[] data) @dynamic
{
    if (self.cursor + data.len > self.len) return OUT_OF_BOUNDS?;

    foreach (&c : data) {
        *c = self.buffer[self.cursor++];
    }
}

fn void? MemoryStream.skip(&self, usz nbytes) @dynamic
{
    if (self.cursor + nbytes > self.allocated) return OUT_OF_BOUNDS?;
    self.cursor += nbytes;
}

fn usz? MemoryStream.offset(&self, bool set = false, usz off = 0) @dynamic
{
    if (!set) return self.cursor;
    if (off > self.len) return OUT_OF_BOUNDS?;
    self.cursor = off;
    return 0;
}

fn void MemoryStream.free(&self) @dynamic
{
    if (!self.read_only) free(self.buffer);
    free(self);
}

fn char[] MemoryStream.get_buf(&self) @dynamic
{
    return self.buffer[:self.len];
}

fn void grow(MemoryStream *self) @local
{
    if (self.allocated == 0) {
        self.allocated = 32;
        self.buffer = malloc(self.allocated * char.sizeof);
    } else {
        self.allocated *= 2;
        self.buffer = realloc(self.buffer, self.allocated * char.sizeof);
    }
}

struct FileStream (Stream) {
    File file;
}

fn void? FileStream.write(&self, char[] data) @dynamic
{
    self.file.write(data)!;
}

fn void? FileStream.read(&self, char[] data) @dynamic
{
    self.file.read(data)!;
}

fn void? FileStream.skip(&self, usz nbytes) @dynamic
{
    self.file.seek(nbytes, CURSOR)!;
}

fn usz? FileStream.offset(&self, bool set = false, usz off = 0) @dynamic
{
    if (!set) return self.file.seek(0, CURSOR)!;
    self.file.seek(off, SET)!;
    return 0;
}

fn void FileStream.free(&self) @dynamic
{
    self.file.close()!!;
    free(self);
}

fn char[] FileStream.get_buf(&self) @dynamic
{
    return {};
}

macro Stream.@write(#self, #val) => #self.write(@as_char_view(#val));
macro Stream.@read(#self, #val) => #self.read(@as_char_view(#val));
