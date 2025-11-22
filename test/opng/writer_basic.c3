/* SPDX-License-Identifier: GPL-3.0-or-later */
module writer_basic;

import std::io, std::core::test;
import opng_test_common;
import opng;

fn void basic() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    char[] buf = wr.stream.get_buf();

    test::eq(buf[:4], "OPNG"); /* magic */

    ushort ver;
    copy(@as_char_view(ver), buf[4:2]);

    test::eq(ver, 0x0003);

    test::eq(buf[0x6], 0);
    test::eq(buf[0x7], 0);
    test::eq(buf[0x8], 0);

    test::eq(wr.dirs_start, 9);
}

fn void configuration() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_configure({1000, 2000, 0x161616FF})!!;

    char[] buf = wr.stream.get_buf();
    char[] dirs = buf[wr.dirs_start:DirType.COUNT * 13];

    usz offset;
    copy(@as_char_view(offset), dirs[1:8]);

    test::eq(offset, 9 + DirType.COUNT * 13); /* location of CONFIGURATION */

    char[] cfg = buf[wr.dirs_start + DirType.COUNT * 13..];

    usz trigger;
    uint sensitivity;
    uint color;

    copy(@as_char_view(trigger), cfg[:8]);
    copy(@as_char_view(sensitivity), cfg[0x8:4]);
    copy(@as_char_view(color), cfg[0xC:4]);

    test::eq(trigger, 1000);
    test::eq(sensitivity, 2000);
    test::eq(color, 0x161616FF);
}

fn void configuration_corruption_check() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_configure({1000, 2000, 0x161616FF})!!;
    wr.start_layers()!!;
    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    char[] dirs = buf[wr.dirs_start:DirType.COUNT * 13];

    usz offset;
    copy(@as_char_view(offset), dirs[1:8]);

    test::eq(offset, 9 + DirType.COUNT * 13); /* location of CONFIGURATION */

    char[] cfg = buf[wr.dirs_start + DirType.COUNT * 13..];

    usz trigger;
    uint sensitivity;
    uint color;

    copy(@as_char_view(trigger), cfg[:8]);
    copy(@as_char_view(sensitivity), cfg[0x8:4]);
    copy(@as_char_view(color), cfg[0xC:4]);

    test::eq(trigger, 1000);
    test::eq(sensitivity, 2000);
    test::eq(color, 0x161616FF);
}

fn void layers() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    test::eq(wr.state, State.LAYER_INFO);

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    char[] dirs = buf[wr.dirs_start:DirType.COUNT * 13];

    uint entry_count;
    copy(@as_char_view(entry_count), dirs[0x9:4]);

    test::eq(entry_count, 0);
}

fn void layers_with_layer() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

    test::eq(pair.image_id, 1);
    test::eq(pair.animation_id, 0);

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    char[] dirs = buf[wr.dirs_start:DirType.COUNT * 13];

    uint entry_count;
    copy(@as_char_view(entry_count), dirs[0x9:4]);

    test::eq(entry_count, 1);

    char[] layer = buf[wr.dirs_start + DirType.COUNT * 13..];

    LayerInfo info;
    copy(@as_char_view(info.x), layer[0x0:4]);
    copy(@as_char_view(info.y), layer[0x4:4]);
    copy(@as_char_view(info.timeout), layer[0x8:4]);
    copy(@as_char_view(info.toggle_mode), layer[0xC:1]);
    copy(@as_char_view(info.mask), layer[0xD:8]);
    copy(@as_char_view(info.image_id), layer[0x15:4]);
    copy(@as_char_view(info.animation_id), layer[0x19:4]);

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);
}

fn void layers_with_cfg_and_layer() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_configure({1000, 2000, 0x161616FF})!!;
    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

    test::eq(pair.image_id, 1);
    test::eq(pair.animation_id, 0);

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    char[] cfg_dir = buf[wr.offsets[DirType.CONFIGURATION]:13];
    char[] layer_dir = buf[wr.offsets[DirType.LAYER_INFO]:13];

    usz cfg_off;
    usz layer_off;
    copy(@as_char_view(cfg_off), cfg_dir[1:8]);
    copy(@as_char_view(layer_off), layer_dir[1:8]);

    uint entry_count;
    copy(@as_char_view(entry_count), layer_dir[0x9:4]);

    test::eq(entry_count, 1);

    char[] layer = buf[layer_off..];

    LayerInfo info;
    copy(@as_char_view(info.x), layer[0x0:4]);
    copy(@as_char_view(info.y), layer[0x4:4]);
    copy(@as_char_view(info.timeout), layer[0x8:4]);
    copy(@as_char_view(info.toggle_mode), layer[0xC:1]);
    copy(@as_char_view(info.mask), layer[0xD:8]);
    copy(@as_char_view(info.image_id), layer[0x15:4]);
    copy(@as_char_view(info.animation_id), layer[0x19:4]);

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);

    char[] cfg = buf[cfg_off..];

    usz trigger;
    uint sensitivity;
    uint color;

    copy(@as_char_view(trigger), cfg[:8]);
    copy(@as_char_view(sensitivity), cfg[0x8:4]);
    copy(@as_char_view(color), cfg[0xC:4]);

    test::eq(trigger, 1000);
    test::eq(sensitivity, 2000);
    test::eq(color, 0x161616FF);
}

fn void layers_with_layer_and_cfg() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

    test::eq(pair.image_id, 1);
    test::eq(pair.animation_id, 0);

    wr.end_layers()!!;

    wr.start_configure({1000, 2000, 0x161616FF})!!;

    char[] buf = wr.stream.get_buf();
    char[] cfg_dir = buf[wr.offsets[DirType.CONFIGURATION]:13];
    char[] layer_dir = buf[wr.offsets[DirType.LAYER_INFO]:13];

    usz cfg_off;
    usz layer_off;
    copy(@as_char_view(cfg_off), cfg_dir[1:8]);
    copy(@as_char_view(layer_off), layer_dir[1:8]);

    uint entry_count;
    copy(@as_char_view(entry_count), layer_dir[0x9:4]);

    test::eq(entry_count, 1);

    char[] layer = buf[layer_off..];

    LayerInfo info;
    copy(@as_char_view(info.x), layer[0x0:4]);
    copy(@as_char_view(info.y), layer[0x4:4]);
    copy(@as_char_view(info.timeout), layer[0x8:4]);
    copy(@as_char_view(info.toggle_mode), layer[0xC:1]);
    copy(@as_char_view(info.mask), layer[0xD:8]);
    copy(@as_char_view(info.image_id), layer[0x15:4]);
    copy(@as_char_view(info.animation_id), layer[0x19:4]);

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);

    char[] cfg = buf[cfg_off..];

    usz trigger;
    uint sensitivity;
    uint color;

    copy(@as_char_view(trigger), cfg[:8]);
    copy(@as_char_view(sensitivity), cfg[0x8:4]);
    copy(@as_char_view(color), cfg[0xC:4]);

    test::eq(trigger, 1000);
    test::eq(sensitivity, 2000);
    test::eq(color, 0x161616FF);
}

fn void layers_with_2_layers() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

    IdPair pair2 = wr.add_layer({
        7, 6, 2000, true, 0xDD, 0, 0
    }, true)!!;

    test::eq(pair.image_id, 1);
    test::eq(pair.animation_id, 0);

    test::eq(pair2.image_id, 2);
    test::eq(pair2.animation_id, 1);

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    char[] dirs = buf[wr.dirs_start:DirType.COUNT * 13];

    uint entry_count;
    copy(@as_char_view(entry_count), dirs[0x9:4]);

    test::eq(entry_count, 2);

    char[] layer = buf[wr.dirs_start + DirType.COUNT * 13..];

    LayerInfo info;
    copy(@as_char_view(info.x), layer[0x0:4]);
    copy(@as_char_view(info.y), layer[0x4:4]);
    copy(@as_char_view(info.timeout), layer[0x8:4]);
    copy(@as_char_view(info.toggle_mode), layer[0xC:1]);
    copy(@as_char_view(info.mask), layer[0xD:8]);
    copy(@as_char_view(info.image_id), layer[0x15:4]);
    copy(@as_char_view(info.animation_id), layer[0x19:4]);

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);

    layer = layer[0x1D..];

    info;
    copy(@as_char_view(info.x), layer[0x0:4]);
    copy(@as_char_view(info.y), layer[0x4:4]);
    copy(@as_char_view(info.timeout), layer[0x8:4]);
    copy(@as_char_view(info.toggle_mode), layer[0xC:1]);
    copy(@as_char_view(info.mask), layer[0xD:8]);
    copy(@as_char_view(info.image_id), layer[0x15:4]);
    copy(@as_char_view(info.animation_id), layer[0x19:4]);

    test::eq(info.x, 7);
    test::eq(info.y, 6);
    test::eq(info.timeout, 2000);
    test::eq(info.toggle_mode, true);
    test::eq(info.mask, 0xDD);
    test::eq(info.image_id, pair2.image_id);
    test::eq(info.animation_id, pair2.animation_id);
}

<*
@require dest.len >= src.len
*>
fn void copy(char[] dest, char[] src) @local
{
    foreach (i, c : src) {
        dest[i] = c;
    }
}
