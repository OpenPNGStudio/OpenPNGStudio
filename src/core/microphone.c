/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <core/microphone.h>
#include <math.h>
#include <miniaudio.h>
#include <stdatomic.h>

static ma_context context;
static ma_device device;
static ma_device_config config;

static void on_data(ma_device* device, void* output, const void* input,
    ma_uint32 frame_count);

void mic_setup(struct microphone *self)
{
    ma_result result;

    if (ma_context_init(NULL, 0, NULL, &context)) {
        /* TODO: somehow allow C to log stuff */
        return;
    }

    config = ma_device_config_init(ma_device_type_capture);
    config.capture.format = ma_format_f32;
    config.capture.channels = 1;
    config.sampleRate = 44100;
    config.dataCallback = on_data;

    result = ma_device_init(NULL, &config, &device);
    if (result != MA_SUCCESS) {
        // LOG_E("Failed to initialize device.\n", 0);
        return;
    }

    device.pUserData = self;
    result = ma_device_start(&device);

    // if (result != MA_SUCCESS)
    //     LOG_E("Failed to start device.\n", 0);
}

struct device {
    char *name;
    ma_device_id *id;
};

void switch_device(struct microphone *self, struct device target)
{
    ma_result result;

    ma_device_stop(&device);
    ma_device_uninit(&device);

    config = ma_device_config_init(ma_device_type_capture);
    config.capture.pDeviceID = target.id;
    config.capture.format = ma_format_f32;
    config.capture.channels = 1;
    config.sampleRate = 44100;
    config.dataCallback = on_data;

    result = ma_device_init(&context, &config, &device);
    if (result != MA_SUCCESS) return;

    device.pUserData = self;
    result = ma_device_start(&device);
}

struct device *mic_enumerate(int *len)
{
    ma_result result;
    ma_device_info *device_infos;
    ma_uint32 count;

    result = ma_context_get_devices(&context, NULL, NULL, &device_infos, &count);
    if (result != MA_SUCCESS) {
        return NULL;
    }

    int iter = 0;
    struct device *devices = malloc(sizeof(*devices) * count);

    for (int i = 0; i < count; i++) {
        devices[iter].id = malloc(sizeof(ma_device_id));
        *devices[iter].id = device_infos[i].id;
        devices[iter].name = device_infos[i].name;

        iter++;
    }

    *len = iter;

    return devices;
}

void mic_free()
{
    ma_device_stop(&device);
    ma_device_uninit(&device);
    ma_context_uninit(&context);
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
