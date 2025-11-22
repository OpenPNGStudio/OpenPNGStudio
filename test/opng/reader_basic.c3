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

    IdPair pair = wr.add_layer(opng_test_common::INFO, false)!!;

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

fn void layers_with_cfg_and_layer() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_configure({1000, 2000, 0x161616FF})!!;
    wr.start_layers()!!;

    IdPair pair = wr.add_layer(opng_test_common::INFO, false)!!;

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();

    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;

    test::eq(res.type, DirType.CONFIGURATION);
    test::eq(res.value.cfg.microphone_trigger, 1000);
    test::eq(res.value.cfg.microphone_sensitivity, 2000);
    test::eq(res.value.cfg.background_color, 0x161616FF);

    res = rd.read_dir()!!;
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

fn void layers_with_layer_and_cfg() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer(opng_test_common::INFO, false)!!;

    wr.end_layers()!!;

    wr.start_configure({1000, 2000, 0x161616FF})!!;

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

    DirResult res2 = rd.read_dir()!!;

    test::eq(res2.type, DirType.CONFIGURATION);
    test::eq(res2.value.cfg.microphone_trigger, 1000);
    test::eq(res2.value.cfg.microphone_sensitivity, 2000);
    test::eq(res2.value.cfg.background_color, 0x161616FF);
    test::eq(info.animation_id, pair.animation_id);
}

fn void layers_with_2_layers() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer(opng_test_common::INFO, false)!!;

    IdPair pair2 = wr.add_layer({
        7, 6, 0, 2000, true, 0xDD, 0, 0
    }, true)!!;

    wr.end_layers()!!;

    char[] buf = wr.stream.get_buf();

    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;
    defer allocator::free(mem, res.value.layers.ptr);

    test::eq(res.type, DirType.LAYER_INFO);
    test::eq(res.value.layers.len, 2);

    LayerInfo info = res.value.layers[0];

    test::eq(info.x, 6);
    test::eq(info.y, 7);
    test::eq(info.timeout, 1000);
    test::eq(info.toggle_mode, false);
    test::eq(info.mask, 0xFF);
    test::eq(info.image_id, pair.image_id);
    test::eq(info.animation_id, pair.animation_id);

    info = res.value.layers[1];

    test::eq(info.x, 7);
    test::eq(info.y, 6);
    test::eq(info.timeout, 2000);
    test::eq(info.toggle_mode, true);
    test::eq(info.mask, 0xDD);
    test::eq(info.image_id, pair2.image_id);
    test::eq(info.animation_id, pair2.animation_id);
}
