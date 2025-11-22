/* SPDX-License-Identifier: GPL-3.0-or-later */
module writer_images;

import std::io, std::core::test;
import opng_test_common;
import opng;

fn void layer_with_text() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, false)!!;

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
    char[] layer_dir = buf[wr.offsets[DirType.LAYER_INFO]:13];
    char[] image_dir = buf[wr.offsets[DirType.IMAGES]:13];

    usz layer_off;
    usz image_off;
    copy(@as_char_view(layer_off), layer_dir[1:8]);
    copy(@as_char_view(image_off), image_dir[1:8]);

    uint entry_count;
    copy(@as_char_view(entry_count), layer_dir[0x9:4]);

    test::eq(entry_count, 1);

    char[] image = buf[image_off..];

    Image info;
    copy(@as_char_view(info.type), image[0x0:1]);
    copy(@as_char_view(info.id), image[0x1:4]);
    copy(@as_char_view(info.uncompressed_size), image[0x5:8]);
    copy(@as_char_view(info.size), image[0xD:8]);
    copy(@as_char_view(info.offset), image[0x15:8]);

    test::eq(info.type, ImageType.STATIC);
    test::eq(info.id, pair.image_id);
    test::eq(info.size, text.len);
    test::eq(info.size, info.uncompressed_size);

    char[] data = buf[info.offset:info.size];

    test::eq(text, data);
}

fn void layer_with_anim() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_layers()!!;

    IdPair pair = wr.add_layer({
        6, 7, 1000, false, 0xFF, 0, 0
    }, true)!!;

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
    char[] layer_dir = buf[wr.offsets[DirType.LAYER_INFO]:13];
    char[] anim_dir = buf[wr.offsets[DirType.ANIMATIONS]:13];

    usz layer_off;
    usz anim_off;
    copy(@as_char_view(layer_off), layer_dir[1:8]);
    copy(@as_char_view(anim_off), anim_dir[1:8]);

    uint entry_count;
    copy(@as_char_view(entry_count), layer_dir[0x9:4]);

    test::eq(entry_count, 1);

    char[] anim = buf[anim_off..];

    Animation info;
    copy(@as_char_view(info.type), anim[0x0:1]);
    copy(@as_char_view(info.id), anim[0x1:4]);
    copy(@as_char_view(info.easing), anim[0x5:1]);
    copy(@as_char_view(info.mask), anim[0x6:8]);
    copy(@as_char_view(info.data_size), anim[0xE:4]);

    test::eq(info.type, AnimationType.SPINNER);
    test::eq(info.id, pair.animation_id);
    test::eq(info.easing, 0);
    test::eq(info.mask, 0xEE);
    test::eq(info.data_size, text.len);

    char[] data = anim[1+4+1+8+4:info.data_size];

    io::printn((String) data);
    test::eq(text, data);
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
