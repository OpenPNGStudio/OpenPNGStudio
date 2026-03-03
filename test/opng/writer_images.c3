/* SPDX-License-Identifier: GPL-3.0-or-later */
module writer_images;

import std::io, std::core::test;
import opng_test_common;
import opng;

fn void layer_with_text() @test
{
    Writer wr = opng::write_memory(mem, opng_test_common::CFG)!!;
    defer wr.free();

    wr.start_sqlite()!!;
    uint _id = wr.add_layer_data(opng_test_common::DATA)!!;
    wr.add_layer({0, _id})!!;
    wr.end_sqlite()!!;

    char[] img = opng_test_common::IMG;

    wr.start_images()!!;
    wr.add_image(STATIC, 0, img)!!;
    wr.end_images()!!;
    
    test::eq(wr.images.len(), 1);
    char[] buf = wr.stream.get_buf();
    
    char[] image_dir = buf[wr.offsets[DirType.IMAGES]:13];

    Dir images;
    copy(@as_char_view(images.type), image_dir[:1]);
    copy(@as_char_view(images.offset), image_dir[1:8]);
    copy(@as_char_view(images.nentries), image_dir[1 + 8:4]);
    
    test::eq(images.type, DirType.IMAGES);
    test::eq(images.nentries, 1);

    char[] image_infos = buf[images.offset..];

    ImageEntry info;

    copy(@as_char_view(info.type), image_infos[:1]);
    copy(@as_char_view(info.id), image_infos[1:4]);
    copy(@as_char_view(info.uncompressed_size), image_infos[1 + 4:8]);
    copy(@as_char_view(info.size), image_infos[1 + 4 + 8:8]);
    copy(@as_char_view(info.offset), image_infos[1 + 4 + 8 + 8:8]);

    test::eq(info.type, ImageType.STATIC);
    test::eq(info.id, 0);
    test::eq(info.size, img.len);
    test::eq(info.size, info.uncompressed_size);

    char[] data = buf[info.offset:info.size];

    test::eq(img, data);
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
