#pragma once

#include "miniaudio.h"
#include <stdatomic.h>

struct microphone_data {
    atomic_size_t volume;
    atomic_int multiplier;
    ma_device device;
};
