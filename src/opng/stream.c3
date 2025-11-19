/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::stream;

import std;

faultdef OUT_OF_BOUNDS;

interface Stream {
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
}

fn void? MemoryStream.write(&self, char[] data) @dynamic
{
    while (self.len + data.len >= self.allocated) grow(self);

    foreach (c : data) {
        self.buffer[self.cursor++] = c;
    }

    self.len = max(self.len, self.cursor);
}

fn void? MemoryStream.skip(&self, usz nbytes) @dynamic
{
    if (self.cursor + nbytes >= self.allocated) return OUT_OF_BOUNDS?;
    self.cursor += nbytes;
}

fn usz? MemoryStream.offset(&self, bool set = false, usz off = 0) @dynamic
{
    if (!set) return self.cursor;
    self.cursor = off;
    return 0;
}

fn void MemoryStream.free(&self) @dynamic
{
    free(self.buffer);
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

/*
struct FileStream (Stream) {
}
*/

<*
@require $defined(Stream s = #stream)
*>
macro @write(#stream, #val) => #stream.write(@as_char_view(#val));
