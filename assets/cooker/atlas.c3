/* SPDX-License-Identifier: GPL-3.0-or-later */
module cooker::atlas;

import std::io, std::collections::map, std::math, std::compression::qoi;
import cooker;

struct Size {
    usz w, h;
}

alias Color = char[<4>];

struct Image {
    Color[] pixels;
    usz w, h;
}

extern fn Size pack(Size aprox, cooker::Rect *arr, usz len);

fn void? gen(HashMap{String, Icon} map, cooker::Rect[] arr)
{
    Size aprox = aprox_size(arr);
    log(SIZE, "Aprox atlas size is %dx%d", aprox.w, aprox.h);
    
    Size res = pack(aprox, arr.ptr, arr.len);
    log(PACKED, "Icons can be packed at %dx%d", res.w, res.h);
    
    Color[] img_data = mem::new_array_aligned(Color, res.w * res.h);
    Image atlas = { img_data, res.w, res.h };
    
    map.@each(; String name, Icon icon) {
        cooker::Rect *rect = icon.ref;
        rect.w -= PADDING;
        rect.h -= PADDING;
        rect.x += PADDING / 2;
        rect.y += PADDING / 2;
        
        for (usz y = 0; y < rect.h; y++) {
            Color *row = atlas.row_start(rect.x, rect.y + y);
            
            mem::copy(row, icon.data + (y * rect.w * Color.sizeof),
                rect.w * Color.sizeof);
        }
        
        log(PACK, "Packed icon %s into atlas", name);
    };
    
    char *data_ptr = img_data.ptr;
    qoi::write("icon_atlas.qoi", data_ptr[:img_data.len * Color.sizeof],
        &&{ (uint) res.w, (uint) res.h, RGBA, LINEAR })!;
    log(SAVED, "Atlas has been saved");
}

fn Color *Image.row_start(&self, usz x, usz y) @inline => self.pixels.ptr +
    (y * self.w + x);

fn Size aprox_size(cooker::Rect[] arr)
{
    usz area;
    usz max_w;
    usz max_h;
    
    foreach (r : arr) {
        area += (usz) r.w * r.h;
        if (r.w > max_w) max_w = r.w;
        if (r.h > max_h) max_h = r.h;
    }
    
    usz size = (usz) math::ceil(math::sqrt((double) area));
    
    if (size < max_w) size = max_w;
    if (size < max_h) size = max_h;
    
    size = cooker::next_po2(size);
    return { size, size };
}
