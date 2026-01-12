/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core;
import std::core::env;

import std::io;
import std::io::path;

extern fn isz readlink(ZString path, char[] buf) @if(env::POSIX);

fn Path? whereami() @if(env::LINUX)
{
    char[4096] path;

    readlink("/proc/self/exe", &path);

    ZString zstr = (ZString) &path;

    return path::new(mem, zstr.str_view());
}
