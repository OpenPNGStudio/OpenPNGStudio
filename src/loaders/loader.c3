/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::loaders;

import openpngstudio::image;
import std::core::log;
import raylib5::rl;
import opng::types;

fn bool? load(image::Image *img, String path)
{
    String ext = path[path.rindex_of_char('.')!!..];
    ZString zext = ext.zstr_copy(mem);

    switch (ext) {
    /* possibly animated */
    case ".gif":
    case ".avif":
    case ".jxl":
    case ".webp":
        return possibly_animated(img, ext);
    /* not animated */
    case ".qoi":
    case ".png": /* no apng support */
    case ".bmp":
    case ".jpg":
    case ".jpeg":
    case ".tga":
    case ".psd":
    case ".dds":
        img.image = rl::loadImageFromMemory(zext, img.file_content.ptr, img.file_content.len);
        free(img.file_content.ptr); /* removed for static images */
        img.file_content = {};
        img.type = STATIC;
    default:
        log::error("Unknown file format: %s", ext[1..]);
    }

    free(zext);
    return true;
}

extern fn bool load_avif(rl::Image *out, char[] memory, int *nframes, int **delays);
extern fn bool load_jpegxl(rl::Image *out, char[] memory, int *nframes, int **delays);
extern fn bool load_webp(rl::Image *out, char[] memory, int *nframes, int **delays);

fn bool? possibly_animated(image::Image *img, String ext) @local
{
    switch (ext) {
    case ".gif":
        img.image = rl::loadImageAnimFromMemory(".gif",
            (ZString) img.file_content.ptr, img.file_content.len,
            &img.nframes, &img.delays);
        img.type = ANIMATED_GIF;
    case ".avif":
        if (!load_avif(&img.image, img.file_content, &img.nframes, &img.delays)) return false;
        img.type = ANIMATED_AVIF;
    case ".jxl":
        if (!load_jpegxl(&img.image, img.file_content, &img.nframes, &img.delays)) return false;
        img.type = ANIMATED_JPEG_XL;
    case ".webp":
        if (!load_webp(&img.image, img.file_content, &img.nframes, &img.delays)) return false;
        img.type = ANIMATED_WEBP;
    }

    if (img.nframes == 1) {
        free(img.delays);
        free(img.file_content.ptr); /* removed for static images */
        img.file_content = {};
        img.type = STATIC;
    }
    
    return true;
}
