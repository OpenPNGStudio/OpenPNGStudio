/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <core/microphone.h>
#include <work/scheduler.h>

struct model {
    struct work_scheduler *scheduler;
    struct microphone_data *mic;
};

void model_write(struct model *model, const char *path);
void model_load(un_loop *loop, struct model *model, const char *path);
