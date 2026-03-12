#include <assert.h>
#include <avif/avif.h>
#include <raylib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool load_avif(Image *out, const uint8_t *memory, const size_t size, int *nframes, int **delays)
{
    avifRGBImage img = { 0 };

    avifDecoder *decoder = avifDecoderCreate();
    if (decoder == NULL)
        return false;

    avifResult res = avifDecoderSetIOMemory(decoder, memory, size);
    if (res != AVIF_RESULT_OK)
        goto cleanup;

    res = avifDecoderParse(decoder);
    if (res != AVIF_RESULT_OK)
        goto cleanup;

    out->width = (int) decoder->image->width;
    out->height = (int) decoder->image->height;
    out->format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    out->mipmaps = 1;

    if (decoder->imageCount > 1) {
        *nframes = decoder->imageCount;
        *delays = malloc(sizeof(int) * decoder->imageCount);
    } else {
        *nframes = 1;
        *delays = NULL;
    }

    const size_t img_size = out->width * out->height * sizeof(Color);
    out->data = malloc(img_size * decoder->imageCount);

    for (int frame = 0; avifDecoderNextImage(decoder) == AVIF_RESULT_OK; frame++) {
        img.format = AVIF_RGB_FORMAT_RGBA;
        img.depth = 8;
        avifRGBImageSetDefaults(&img, decoder->image);

        res = avifRGBImageAllocatePixels(&img);
        if (res != AVIF_RESULT_OK)
            goto cleanup;

        res = avifImageYUVToRGB(decoder->image, &img);
        if (res != AVIF_RESULT_OK)
            goto cleanup;

        assert(img.depth == 8 && "AVIF input is not 8 bit");

        uint8_t *ptr = out->data;
        memcpy(ptr + img_size * frame, img.pixels, img_size);

        if (decoder->imageCount > 1) {
            avifImageTiming timing;
            avifDecoderNthImageTiming(decoder, frame, &timing);

            (*delays)[frame] = (int) (timing.duration * 1000);
        }
    }

    res = AVIF_RESULT_OK;
cleanup:
    avifRGBImageFreePixels(&img);
    avifDecoderDestroy(decoder);

    return res == AVIF_RESULT_OK;
}