/* SPDX-License-Identifier: GPL-3.0-or-later */
module reader_basic;

import std::io, std::core::test, std::core::mem::allocator;
import opng_test_common;
import opng;

fn void basic() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    char[] buf = wr.stream.get_buf();
    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    rd.free();
}

fn void configuration() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_configure({1000, 2000, 0x161616FF})!!;

    char[] buf = wr.stream.get_buf();
    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;

    test::eq(res.type, DirType.CONFIGURATION);
    test::eq(res.value.cfg.microphone_trigger, 1000);
    test::eq(res.value.cfg.microphone_sensitivity, 2000);
    test::eq(res.value.cfg.background_color, 0x161616FF);
}

fn void empty_layers() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;
    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();
    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;

    test::eq(res.type, DirType.LAYER_INFO);
    test::eq(res.value.layers.len, 0);
}

fn void layers_with_layer() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();

    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;
    defer allocator::free(mem, res.value.layers.ptr);

    test::eq(res.type, DirType.LAYER_INFO);
    test::eq(res.value.layers.len, 1);

    LayerInfo info = res.value.layers[0];

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);
}
