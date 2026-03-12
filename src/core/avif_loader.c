#include <avif/avif.h>
#include <raylib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

bool load_avif_image(Image *out, const uint8_t *memory, const size_t size)
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

    if (avifDecoderNextImage(decoder) != AVIF_RESULT_OK)
        goto cleanup;

    avifRGBImageSetDefaults(&img, decoder->image);
    res = avifRGBImageAllocatePixels(&img);
    if (res != AVIF_RESULT_OK)
        goto cleanup;

    res = avifImageYUVToRGB(decoder->image, &img);
    if (res != AVIF_RESULT_OK)
        goto cleanup;

    out->data = img.pixels;
    out->mipmaps = 1;

    if (img.depth > 8) {
        out->format = decoder->alphaPresent ? PIXELFORMAT_UNCOMPRESSED_R16G16B16A16 : PIXELFORMAT_UNCOMPRESSED_R16G16B16;
        ImageFormat(out, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
    } else {
        out->format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    }

cleanup:
    // avifRGBImageFreePixels(&img);
    avifDecoderDestroy(decoder);

    return res == AVIF_RESULT_OK;
}