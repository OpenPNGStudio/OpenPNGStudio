/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <webp/demux.h>
#include <webp/decode.h>

#include <stdbool.h>
#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>

bool load_webp(Image *out, const uint8_t *memory, const size_t size, int *nframes, int **delays)
{
    const WebPData data = { .bytes = memory, .size = size };
    WebPAnimDecoderOptions options;
    WebPAnimDecoderOptionsInit(&options);
    options.color_mode = MODE_RGBA;
    options.use_threads = true;

    WebPAnimDecoder *decoder = WebPAnimDecoderNew(&data, &options);
    WebPAnimInfo anim_info;

    WebPAnimDecoderGetInfo(decoder, &anim_info);

    out->width = (int) anim_info.canvas_width;
    out->height = (int) anim_info.canvas_height;
    out->format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    out->mipmaps = 1;

    if (anim_info.frame_count > 1) {
        *nframes = (int) anim_info.frame_count;
        *delays = malloc(sizeof(int) * anim_info.frame_count);
    } else {
        *nframes = 1;
        *delays = NULL;
    }

    const size_t img_size = out->width * out->height * sizeof(Color);
    out->data = malloc(img_size * anim_info.frame_count);
    int32_t passed = 0;

    for (uint32_t i = 0; i < anim_info.frame_count; i++) {
        if (WebPAnimDecoderHasMoreFrames(decoder)) {
            uint8_t *image;
            int timestamp;
            WebPAnimDecoderGetNext(decoder, &image, &timestamp);

            uint8_t *ptr = out->data;
            memcpy(ptr + img_size * i, image, img_size);

            if (anim_info.frame_count > 1) {
                (*delays)[i] = timestamp - passed;
                passed = timestamp;
            }
        }
    }

    WebPAnimDecoderDelete(decoder);

    return true;
}