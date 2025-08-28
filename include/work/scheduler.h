/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <work/work.h>
#include <work/queue.h>
#include <unuv.h>

struct work_scheduler {
    struct work_queue queue;
    un_loop *loop;
};

void work_scheduler_add_work(struct work_scheduler *sched, struct work *work);
void work_scheduler_run(struct work_scheduler *sched);
