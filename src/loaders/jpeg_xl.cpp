/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <jxl/codestream_header.h>
#include <jxl/decode.h>
#include <jxl/decode_cxx.h>
#include <jxl/resizable_parallel_runner.h>
#include <jxl/resizable_parallel_runner_cxx.h>
#include <jxl/types.h>

#include <raylib.h>
#include <cassert>
#include <cstring>
#include <vector>

extern "C" {

bool load_jpegxl(Image *out, const uint8_t *memory, const size_t size, int *nframes, int **delays)
{
    JxlResizableParallelRunnerPtr runner = JxlResizableParallelRunnerMake(nullptr);

    JxlDecoderPtr decoder = JxlDecoderMake(nullptr);
    if (JxlDecoderSubscribeEvents(decoder.get(), JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE
        | JXL_DEC_FRAME) != JXL_DEC_SUCCESS)
        return false;

    if (JxlDecoderSetParallelRunner(decoder.get(), JxlResizableParallelRunner, runner.get()) !=
        JXL_DEC_SUCCESS)
        return false;

    JxlBasicInfo info;
    JxlFrameHeader frame;
    constexpr JxlPixelFormat format = {
        .num_channels = 4,
        .data_type = JXL_TYPE_UINT8,
        .endianness = JXL_NATIVE_ENDIAN,
        .align = 0
    };

    JxlDecoderSetInput(decoder.get(), memory, size);
    JxlDecoderCloseInput(decoder.get());

    std::vector<uint8_t*> frames;
    std::vector<int> jxl_delays;

    bool end = false;

    while (!end) {
        switch (JxlDecoderProcessInput(decoder.get())) {
        case JXL_DEC_BASIC_INFO:
            if (JxlDecoderGetBasicInfo(decoder.get(), &info) != JXL_DEC_SUCCESS)
                return false;

            out->width = static_cast<int>(info.xsize);
            out->height = static_cast<int>(info.ysize);
            out->format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
            out->mipmaps = 1;
            JxlResizableParallelRunnerSetThreads(runner.get(),
                JxlResizableParallelRunnerSuggestThreads(info.xsize, info.ysize));
            break;
        case JXL_DEC_NEED_IMAGE_OUT_BUFFER:
        {
            size_t buffer_size;

            if (JxlDecoderImageOutBufferSize(decoder.get(), &format, &buffer_size) != JXL_DEC_SUCCESS)
                return false;

            const size_t image_size = out->width * out->height * sizeof(Color);
            assert(image_size == buffer_size && "Invalid buffer size");

            auto *pixels = static_cast<uint8_t*>(malloc(image_size));
            if (JxlDecoderSetImageOutBuffer(decoder.get(), &format, pixels, image_size) != JXL_DEC_SUCCESS)
                return false;

            frames.push_back(pixels);
            break;
        }
        case JXL_DEC_FRAME:
        {
            if (JxlDecoderGetFrameHeader(decoder.get(), &frame) != JXL_DEC_SUCCESS)
                return false;

            if (!info.have_animation)
                break;

            const uint32_t ms = (frame.duration * 1000) * info.animation.tps_denominator / info.animation.tps_numerator;
            jxl_delays.push_back(static_cast<int>(ms));
            break;
        }
        case JXL_DEC_FULL_IMAGE:
            break;
        case JXL_DEC_SUCCESS:
            end = true;
            break;
        default:
            return false;
        }
    }

    *nframes = static_cast<int>(frames.size());
    if (info.have_animation) {
        *delays = static_cast<int*>(malloc(jxl_delays.size() * sizeof(int)));
    } else {
        *delays = nullptr;
    }

    const size_t image_size = out->width * out->height * sizeof(Color);

    std::memcpy(*delays, jxl_delays.data(), jxl_delays.size() * sizeof(int));
    out->data = malloc(image_size * frames.size());

    for (size_t i = 0; i < frames.size(); i++) {
        auto *ptr = static_cast<uint8_t *>(out->data);
        const uint8_t *pixels = frames[i];

        std::memcpy(ptr + image_size * i, pixels, image_size);
    }

    return true;
}

}