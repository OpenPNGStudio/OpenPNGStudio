/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifdef OPNG_STANDALONE
#include <stdbool.h>
#include <opng.h>

#define STBI_ONLY_GIF
#define STB_IMAGE_IMPLEMENTATION
#include <stdint.h>
#include <vendor/stb_image.h>

bool load_gif(const uint8_t *memory, const size_t size, struct image_data *out)
{
    int comp = 0;
    int *delays = NULL;
    free(stbi_load_gif_from_memory(memory, size, &delays, &out->width, &out->height, &out->nframes, &comp, 4));
    free(delays);
    return true;
}

#endif
