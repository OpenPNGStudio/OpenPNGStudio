/* SPDX-License-Identifier: GPL-3.0-or-later */

#include "console.h"
#include <core/microphone.h>
#include <math.h>
#include <miniaudio.h>
#include <stdatomic.h>

static ma_device device;
static ma_device_config config;

static void on_data(ma_device* device, void* output, const void* input,
    ma_uint32 frame_count);

void mic_setup(struct microphone *self)
{
    ma_result result;

    config = ma_device_config_init(ma_device_type_capture);
    config.capture.format = ma_format_f32;
    config.capture.channels = 1;
    config.sampleRate = 44100;
    config.dataCallback = on_data;

    result = ma_device_init(NULL, &config, &device);
    if (result != MA_SUCCESS) {
        LOG_E("Failed to initialize device.\n", 0);
        return;
    }

    device.pUserData = self;
    result = ma_device_start(&device);

    if (result != MA_SUCCESS)
        LOG_E("Failed to start device.\n", 0);
}

void mic_free()
{
    ma_device_uninit(&device);
}

static void on_data(ma_device* device, void* output, const void* input,
    ma_uint32 frame_count)
{
    struct microphone *mic = device->pUserData;
    float *data = (float*) input;

    float sum = 0.0f;

    for (ma_uint32 i = 0; i < frame_count; i++) {
        sum += data[i] * data[i];
    }

    atomic_store(&mic->volume, sqrtf(sum / frame_count) * 
        atomic_load(&mic->multiplier));
}
