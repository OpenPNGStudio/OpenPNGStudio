/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::filedialogs::win32 @if(env::WIN32);

import openpngstudio;
import std::net::url;
import ev;
import std::io;

struct WinFileDialog (FileDialog) {
    WString filter, title;
    FileList res;

    bool is_ready;
    bool multiple;
}

bool is_open @local;
Work{WinFileDialog*} worker @local;

fn WinFileDialog *init()
{
    WinFileDialog *self = mem::new(WinFileDialog);
    self.is_ready = false;

    return self;
}

fn void WinFileDialog.open(&self, ZString title, bool multiple) @dynamic
{
    if (is_open) return;
    is_open = true;

    if (self.title) free(self.title);
    self.title = title.str_view().to_wstring(mem)!!;
    self.multiple = multiple;

    Context *ctx = openpngstudio::get_ctx();

    worker.init(self, fn (work) {
        WinFileDialog *self = work.ctx;

        self.res = win32_open_file(self.title, self.multiple, self.filter);
    }, fn (work) {
        WinFileDialog *self = work.ctx;

        if (self.res.len == -1) {
            self.is_ready = false;
            is_open = false;
        } else {
            self.is_ready = true;
        }

        return DISARM;
    });

    worker.register(&ctx.loop);
}

fn void WinFileDialog.save(&self, ZString title) @dynamic
{
    if (is_open) return;
    is_open = true;

    if (self.title) free(self.title);
    self.title = title.str_view().to_wstring(mem)!!;

    Context *ctx = openpngstudio::get_ctx();

    worker.init(self, fn (work) {
        WinFileDialog *self = work.ctx;

        self.res = win32_save_file(self.title, self.filter);
    }, fn (work) {
        WinFileDialog *self = work.ctx;

        if (self.res.len == -1) {
            self.is_ready = false;
            is_open = false;
        } else {
            self.is_ready = true;
        }

        return DISARM;
    });

    worker.register(&ctx.loop);
}

fn void WinFileDialog.set_filter(&self, ZString[] extensions) @dynamic => @pool()
{
    if (self.filter) free(self.filter);

    DString b;
    b.tinit();

    ZString[] less = extensions[:^1];
    foreach (s : less) {
        b.append_string(s.str_view());
        b.append_char(';');
    }

    b.append_string(extensions[^1].str_view());

    self.filter = b.str_view().to_wstring(mem)!!;
}

fn bool WinFileDialog.ready(&self) @dynamic => self.is_ready;
fn Url[] WinFileDialog.uris(&self) @dynamic
{
    Url[] uris = mem::new_array(Url, self.res.len);

    for (long i = 0; i < self.res.len; i++) {
        String str = string::from_wstring(mem, self.res.files[i])!!;

        uris[i].path = str;
        uris[i].allocator = mem;
    }

    self.is_ready = false;
    is_open = false;
    return uris;
}

/* bindings */
struct FileList {
    WString *files;
    long len;
}

extern fn FileList win32_open_file(WString title, bool multiple, WString ext);
extern fn FileList win32_save_file(WString title, WString ext);