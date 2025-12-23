/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdatomic.h>

struct microphone {
    atomic_size_t volume;
    atomic_int multiplier;
};
