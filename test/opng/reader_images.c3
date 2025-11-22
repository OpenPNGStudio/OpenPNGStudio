/* SPDX-License-Identifier: GPL-3.0-or-later */
module reader_basic;

import std::io, std::core::test, std::core::mem::allocator;
import opng_test_common;
import opng;

fn void layer_with_text() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer(opng_test_common::INFO, false)!!;

    wr.end_layers()!!;

    wr.start_image_info()!!;

    wr.add_image_info({
        STATIC,
        pair.image_id,
        0, 0, 0
    })!!;

    wr.end_image_info()!!;

    wr.start_images()!!;

    String text = "Hello, World!";
    wr.add_image(pair.image_id, text)!!;

    wr.end_images()!!;

    test::eq(wr.images_to_update.len(), 0);
    char[] buf = wr.stream.get_buf();

    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;
    test::eq(res.type, DirType.LAYER_INFO);
    test::eq(res.value.layers.len, 1);
    allocator::free(mem, res.value.layers.ptr);

    res = rd.read_dir()!!;
    defer allocator::free(mem, res.value.images.ptr);
    test::eq(res.type, DirType.IMAGES);
    test::eq(res.value.images.len, 1);

    Image info = res.value.images[0];

    test::eq(info.type, ImageType.STATIC);
    test::eq(info.id, pair.image_id);
    test::eq(info.size, text.len);
    test::eq(info.size, info.uncompressed_size);

    char[64] out;

    rd.read_image(info, out[:text.len])!!;

    test::eq(text, out[:text.len]);
}

fn void layer_with_anim() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer(opng_test_common::INFO, true)!!;

    wr.end_layers()!!;
    wr.start_animations()!!;
    String text = "Hello, World!";

    wr.add_animation({
        SPINNER,
        pair.animation_id,
        0, 0xEE, text.len
    })!!;

    wr.add_animation_data(text)!!;

    wr.end_animations()!!;

    test::eq(wr.images_to_update.len(), 0);
    char[] buf = wr.stream.get_buf();

    Reader rd = opng::read_memory(mem, buf, opng_test_common::RCFG)!!;
    defer rd.free();

    DirResult res = rd.read_dir()!!;
    test::eq(res.type, DirType.LAYER_INFO);
    test::eq(res.value.layers.len, 1);
    allocator::free(mem, res.value.layers.ptr);

    res = rd.read_dir()!!;

    Animation info = res.value.animations[0];
    defer allocator::free(mem, res.value.animations.ptr);

    test::eq(info.type, AnimationType.SPINNER);
    test::eq(info.id, pair.animation_id);
    test::eq(info.easing, 0);
    test::eq(info.mask, 0xEE);
    test::eq(info.data_size, text.len);

    char[64] data;

    rd.read_animation_data(info, data[:info.data_size])!!;

    test::eq(text, data[:info.data_size]);

    test::eq(rd.animation_data_offsets.len(), 0);
}
