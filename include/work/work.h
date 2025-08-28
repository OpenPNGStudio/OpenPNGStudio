/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stdbool.h>
#include <unuv.h>
#include <uv.h>

struct work;

typedef void (*work_fn)(struct work *work);
typedef void (*work_done)(struct work *work);

struct work {
    work_fn perform;
    work_done finished;
    uv_work_t req;
    void *ctx;
    bool thread_safe;
};

struct work *work_new(work_fn perform, work_done when_finished, bool run_on_thread);
void work_set_context(struct work *work, void *context);

void work_evaluate(struct work *work, un_loop *loop);
